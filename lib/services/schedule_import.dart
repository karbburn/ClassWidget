import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/schedule_event.dart';
import '../database/database_helper.dart';
import 'time_helpers.dart';
import 'log_service.dart';

class ImportResult {
  final bool success;
  final String message;
  final int classesAdded;
  final int duplicatesSkipped;
  final int invalidRows;
  final String? section;

  ImportResult({
    required this.success,
    required this.message,
    this.classesAdded = 0,
    this.duplicatesSkipped = 0,
    this.invalidRows = 0,
    this.section,
  });
}

class ScheduleImport {
  final dbHelper = DatabaseHelper();
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  /// Parses a file and returns the list of events (Phase 3: Preview Flow)
  Future<List<ScheduleEvent>?> pickAndParse() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        withData: false,
      );

      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      if (await file.length() > _maxFileSizeBytes) throw Exception("File too large (>10MB)");

      if (file.path.endsWith('.xlsx')) {
        return await _parseExcel(file);
      } else if (file.path.endsWith('.csv')) {
        return await _parseCsv(file);
      }
      return null;
    } catch (e) {
      LogService.error('Parsing failed', e);
      rethrow;
    }
  }

  /// Commits a list of events atomically with deduplication
  Future<ImportResult> commitImport(List<ScheduleEvent> events) async {
    try {
      if (events.isEmpty) return ImportResult(success: false, message: "No classes to import");
      
      // Deduplicate: title + date + startTime must be unique
      final Map<String, ScheduleEvent> uniqueEvents = {};
      for (var e in events) {
        final key = "${e.title}-${e.date}-${e.startTime}";
        if (!uniqueEvents.containsKey(key)) {
          uniqueEvents[key] = e;
        }
      }
      
      final deduplicatedList = uniqueEvents.values.toList();
      LogService.info("Deduplication: ${events.length} -> ${deduplicatedList.length}");
      await dbHelper.importScheduleTransaction(deduplicatedList);
      
      return ImportResult(
        success: true, 
        message: "Imported ${deduplicatedList.length} classes successfully!",
        classesAdded: deduplicatedList.length,
        section: deduplicatedList.isNotEmpty ? deduplicatedList.first.section : null,
      );
    } catch (e) {
      return ImportResult(success: false, message: "Import failed: ${e.toString()}");
    }
  }

  /// Picks a file and starts the import process (Direct Flow)
  Future<ImportResult> pickAndImport() async {
    final events = await pickAndParse();
    if (events == null) return ImportResult(success: false, message: "No file selected");
    return await commitImport(events);
  }

  Future<List<ScheduleEvent>> _parseExcel(File file) async {
    final bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final List<ScheduleEvent> events = [];

    for (var entry in excel.tables.entries) {
      final sheetName = entry.key;
      final table = entry.value;
      if (table.rows.isEmpty) continue;

      // 1. Discovery Phase: Find the Time Slot Header Row and Date Column
      int? headerRowIdx;
      final Map<int, String> timeSlots = {}; // column index -> "HH:mm-HH:mm"
      int dateColumnIdx = 0; // Default

      // Search first 15 rows for a time-slot header
      for (int r = 0; r < 15 && r < table.rows.length; r++) {
        final row = table.rows[r];
        for (int c = 0; c < row.length; c++) {
          final val = row[c]?.value?.toString() ?? "";
          // Look for time slot like 08:30 - 09:30 or 8:30-9:30 or 14:00 to 15:00
          if ((val.contains('-') || val.toLowerCase().contains(' to ')) && 
              RegExp(r'\d{1,2}[:.]\d{2}').hasMatch(val)) {
            timeSlots[c] = val.replaceAll(' to ', '-');
            headerRowIdx = r;
          }
        }
        if (headerRowIdx != null && timeSlots.length > 1) break;
      }

      if (timeSlots.isEmpty) {
        final fallbackEvents = await _parseExcelLinearFallback(table);
        for (var e in fallbackEvents) {
          e.section = sheetName; // Ensure sheet name is assigned
        }
        events.addAll(fallbackEvents);
        continue; // Try next sheet
      }

      // Detect Date Column: Look for common keywords or date formats
      for (int c = 0; c < table.rows[headerRowIdx!].length; c++) {
        final val = table.rows[headerRowIdx][c]?.value?.toString().toLowerCase() ?? "";
        if (val.contains('date') || val.contains('day') || val.contains('sl.')) {
          dateColumnIdx = c;
          break;
        }
      }

      LogService.info("Processing sheet: $sheetName");
      
      // 2. Extraction Phase
      String? lastSeenDate;
      Set<int> rowsToSkip = {}; // Track rows that are just professor names for the row above
      
      for (int r = headerRowIdx + 1; r < table.rows.length; r++) {
        if (rowsToSkip.contains(r)) continue;
        
        final row = table.rows[r];
        if (row.isEmpty) continue;

        // Update Date
        String? currentDateVal;
        if (dateColumnIdx < row.length) {
          currentDateVal = row[dateColumnIdx]?.value?.toString();
          if (currentDateVal != null && currentDateVal.isNotEmpty && currentDateVal != "null") {
            final normalized = TimeHelpers.normalizeDate(currentDateVal);
            if (normalized.isNotEmpty) {
              LogService.info("Found Date: $currentDateVal -> $normalized");
              lastSeenDate = normalized;
            }
          }
        }

        if (lastSeenDate == null) continue;

        // Process each identified time slot column
        for (var entry in timeSlots.entries) {
          final colIdx = entry.key;
          final timeRange = entry.value;

          if (colIdx >= row.length) continue;
          
          final title = row[colIdx]?.value?.toString();
          if (title == null || title.trim().isEmpty || title == "null" || title.toLowerCase() == "refresh") continue;

          // Check if professor is in the same cell (separated by \n) or row below
          String courseTitle = title;
          String? professor;

          if (title.contains('\n')) {
             final parts = title.split('\n');
             courseTitle = parts[0];
             professor = parts.length > 1 ? parts[1] : null;
          } else {
            // Check if next row (r+1) has a value at colIdx but NO signifiant date change
            if (r + 1 < table.rows.length) {
              final nextRow = table.rows[r + 1];
              final nextRowDateVal = dateColumnIdx < nextRow.length ? nextRow[dateColumnIdx]?.value?.toString() : null;
              
              // If date is empty OR matches current row's date exactly, it might be a sub-row (professor)
              final isDuplicateDate = (nextRowDateVal == null || nextRowDateVal.isEmpty || nextRowDateVal == "null" || nextRowDateVal == currentDateVal);
              
              if (isDuplicateDate && colIdx < nextRow.length) {
                final String? profVal = nextRow[colIdx]?.value?.toString();
                if (profVal != null && profVal.isNotEmpty && profVal != "null") {
                  final String profLower = profVal.toLowerCase().trim();
                  // Strongly identify as professor if starts with Prof/Dr or is likely a name
                  if (profLower.contains('prof') || profLower.contains('dr.') || profVal.split(' ').length >= 2) {
                    professor = profVal;
                    // Note: We don't necessarily skip the WHOLE next row because other columns might have actual classes
                    // But if this column is a professor, we definitely don't want to import it as a class later
                  }
                }
              }
            }
          }

          final times = timeRange.split('-');
          if (times.length < 2) continue;
          
          final startRaw = times[0].trim();
          final endRaw = times[1].trim();

          final startTime = TimeHelpers.normalizeTime(startRaw);
          final endTime = TimeHelpers.normalizeTime(endRaw);
          final normalizedDate = TimeHelpers.normalizeDate(lastSeenDate);

          // Stricter validation to prevent junk imports
          final String titleLower = courseTitle.toLowerCase().trim();
          if (courseTitle.trim().length < 3) continue; 
          
          // Skip if it looks like a professor name (prevents duplicate boxes)
          if (titleLower.startsWith('prof') || 
              titleLower.startsWith('dr.') || 
              titleLower.contains('professor')) continue;
              
          if (startTime == "00:00" && endTime == "00:00") continue; 
          if (lastSeenDate == null) continue; 

          events.add(ScheduleEvent(
            title: courseTitle.trim(),
            startTime: startTime,
            endTime: endTime,
            professor: professor?.trim() == "null" ? null : professor?.trim(),
            section: sheetName, 
            type: 'class',
            isImported: true,
            date: normalizedDate,
          ));
        }
      }
    }
    return events;
  }

  Future<List<ScheduleEvent>> _parseExcelLinearFallback(Sheet table) async {
    final List<ScheduleEvent> events = [];
    final timeRegex = RegExp(r'\d{1,2}[:.]\d{2}');

    for (var row in table.rows.skip(1)) {
      if (row.length < 4) continue;
      final rawDate = row[0]?.value?.toString();
      final rawStart = row[1]?.value?.toString();
      final rawEnd = row[2]?.value?.toString();
      final rawTitle = row[3]?.value?.toString();
      
      if (rawStart == null || rawEnd == null || rawTitle == null) continue;
      
      final titleStr = rawTitle.trim();
      if (titleStr.isEmpty || titleStr == "null" || titleStr.toLowerCase() == "refresh") continue;

      // Basic time validation
      if (!timeRegex.hasMatch(rawStart) || !timeRegex.hasMatch(rawEnd)) continue;

      final startTime = TimeHelpers.normalizeTime(rawStart);
      final endTime = TimeHelpers.normalizeTime(rawEnd);
      final normalizedDate = TimeHelpers.normalizeDate(rawDate ?? '');

      if (titleStr.length < 3) continue;
      if (startTime == "00:00" && endTime == "00:00") continue;

      events.add(ScheduleEvent(
        title: titleStr,
        startTime: startTime,
        endTime: endTime,
        professor: row.length > 4 ? row[4]?.value?.toString() : null,
        section: null, // Will be set by caller
        type: 'class',
        isImported: true,
        date: normalizedDate,
      ));
    }
    return events;
  }

  Future<List<ScheduleEvent>> _parseCsv(File file) async {
    final input = await file.readAsString();
    final List<List<dynamic>> rows = [];
    
    // Simple manual CSV parser to avoid package conflicts
    final lines = input.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      // Handle basic quoted fields
      final fields = <String>[];
      bool inQuotes = false;
      StringBuffer buffer = StringBuffer();
      
      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          fields.add(buffer.toString().trim());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      }
      fields.add(buffer.toString().trim());
      rows.add(fields);
    }

    final List<ScheduleEvent> events = [];
    if (rows.isEmpty) return events;

    for (var row in rows.skip(1)) {
      if (row.length < 4) continue;

      final rawDate = row[0].toString();
      final rawStart = row[1].toString();
      final rawEnd = row[2].toString();
      final rawTitle = row[3].toString();

      if (rawStart.isEmpty || rawEnd.isEmpty || rawTitle.isEmpty) continue;

      final startTime = TimeHelpers.normalizeTime(rawStart);
      final endTime = TimeHelpers.normalizeTime(rawEnd);
      final normalizedDate = TimeHelpers.normalizeDate(rawDate);

      if (rawTitle.length < 3) continue;
      if (startTime == "00:00" && endTime == "00:00") continue;

      events.add(ScheduleEvent(
        title: rawTitle,
        startTime: startTime,
        endTime: endTime,
        professor: row.length > 4 ? row[4].toString() : null,
        section: row.length > 5 ? row[5].toString() : null,
        type: 'class',
        isImported: true,
        date: normalizedDate,
      ));
    }
    return events;
  }
}
