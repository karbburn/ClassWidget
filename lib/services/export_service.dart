import '../models/schedule_event.dart';
import '../database/database_helper.dart';
import 'log_service.dart';

class ExportService {
  static Future<String?> exportToCsv(
      {String? startDate, String? endDate}) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      final List<Map<String, dynamic>> maps;
      if (startDate != null && endDate != null) {
        maps = await db.query('events',
            where: 'date >= ? AND date <= ?',
            whereArgs: [startDate, endDate],
            orderBy: 'date ASC, start_time ASC');
      } else {
        maps = await db.query('events', orderBy: 'date ASC, start_time ASC');
      }

      final events =
          List.generate(maps.length, (i) => ScheduleEvent.fromMap(maps[i]));

      if (events.isEmpty) return null;

      final StringBuffer csvBuffer = StringBuffer();
      // Header
      csvBuffer.writeln('date,start,end,course,professor,section,is_imported');

      for (var e in events) {
        csvBuffer.writeln('${e.date},${e.startTime},${e.endTime},'
            '"${e.title.replaceAll('"', '""')}",'
            '"${e.professor?.replaceAll('"', '""') ?? ""}",'
            '"${e.section?.replaceAll('"', '""') ?? ""}",'
            '${e.isImported ? 1 : 0}');
      }

      return csvBuffer.toString();
    } catch (e, stack) {
      LogService.error('Export failed', e, stack);
      return null;
    }
  }
}
