import 'package:intl/intl.dart';

class TimeHelpers {
  /// Normalizes various time formats (9:00, 09:00, 9:00 AM) to HH:mm (24h)
  static String normalizeTime(String value, {int cutoff = 8}) {
    try {
      value = value
          .trim()
          .toUpperCase()
          .replaceAll('.', ':')
          .replaceAll('AM', ' AM')
          .replaceAll('PM', ' PM')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Handle AM/PM
      if (value.contains('AM') || value.contains('PM')) {
        final format = DateFormat("h:mm a");
        final dateTime = format.parse(value);
        return DateFormat("HH:mm").format(dateTime);
      }

      // Handle H:mm or HH:mm
      if (value.contains(':')) {
        final parts = value.split(':');
        int hour = int.tryParse(parts[0]) ?? 0;
        final minuteStr = parts.length > 1 ? parts[1].trim() : '00';

        // If hour is 12, it's noon (not morning or afternoon)
        // If hour is 0, it's midnight
        // Otherwise, apply cutoff logic only if no AM/PM suffix was present
        if (hour > 0 &&
            hour < cutoff &&
            !value.contains('AM') &&
            !value.contains('PM')) {
          hour += 12;
        }

        final hStr = hour.toString().padLeft(2, '0');
        final mStr = minuteStr.padLeft(2, '0').substring(0, 2);
        return '$hStr:$mStr';
      }

      return "00:00";
    } catch (e) {
      return "00:00";
    }
  }

  /// Normalizes dates (17/03/2024, 17-Mar-24, March 17) to yyyy-MM-dd
  static String normalizeDate(String value) {
    try {
      final raw = value.trim();
      if (raw.isEmpty || raw == "null") return "";

      // Try native ISO 8601 parse first (handles Excel native DateTime strings)
      final isoDate = DateTime.tryParse(raw);
      if (isoDate != null) return formatDate(isoDate);

      // Try common formats
      final formats = [
        'dd-MM-yyyy',
        'dd/MM/yyyy',
        'yyyy-MM-dd',
        'dd MMM yyyy',
        'dd MMMM yyyy',
        'MMMM dd, yyyy',
        'dd-MMM-yy',
        'dd/MM/yy',
        'dd-MMM-yyyy',
        'd-MMM-yy',
        'dd MMM', // e.g., 17 Mar
        'dd-MMM', // e.g., 17-Mar
        'dd/MM',
      ];

      for (var f in formats) {
        try {
          final date = DateFormat(f).parse(raw);
          // If year is very small (e.g. 1970/1 from default), use current year
          DateTime finalDate = date;
          if (date.year < 100) {
            // Handle 2-digit years (e.g. 24 -> 2024)
            finalDate = DateTime(2000 + date.year, date.month, date.day);
          } else if (date.year <= 1970) {
            // If year is default epoch (Excel/DB artifact), assume current year
            finalDate = DateTime(DateTime.now().year, date.month, date.day);
          }
          return formatDate(finalDate);
        } catch (_) {}
      }

      // Fallback: search for numbers
      final match =
          RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(raw);
      if (match != null) {
        int day = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        if (year < 100) year += 2000;
        return formatDate(DateTime(year, month, day));
      }

      return "";
    } catch (e) {
      return "";
    }
  }

  static DateTime getTodayStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime getTodayEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  /// Returns total minutes from start of day for comparison
  static int getMinutes(String time) {
    try {
      final parts = time.split(':');
      return ((int.tryParse(parts[0]) ?? 0) * 60) +
          (int.tryParse(parts[1]) ?? 0);
    } catch (_) {
      return 0;
    }
  }
}
