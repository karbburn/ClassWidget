import 'package:flutter_test/flutter_test.dart';
import 'package:classwidget/services/time_helpers.dart';

void main() {
  group('TimeHelpers.normalizeTime', () {
    test('normalizes 24h format HH:mm', () {
      expect(TimeHelpers.normalizeTime('14:30'), '14:30');
    });

    test('normalizes single-digit hour (above cutoff stays unchanged)', () {
      expect(TimeHelpers.normalizeTime('9:00'), '09:00'); // 9 >= cutoff(8), no +12
    });

    test('normalizes AM/PM format', () {
      expect(TimeHelpers.normalizeTime('2:30 PM'), '14:30');
      expect(TimeHelpers.normalizeTime('11:00 AM'), '11:00');
    });

    test('handles malformed input gracefully', () {
      expect(TimeHelpers.normalizeTime('abc'), '00:00');
      expect(TimeHelpers.normalizeTime(''), '00:00');
      expect(TimeHelpers.normalizeTime(':'), '00:00');
    });

    test('respects cutoff parameter', () {
      // With cutoff=8, hour 7 → 7+12=19, hour 9 → 9+12=21
      expect(TimeHelpers.normalizeTime('7:00', cutoff: 8), '19:00');
      // With cutoff=6, hour 7 → stays 7 (7 >= 6)
      expect(TimeHelpers.normalizeTime('7:00', cutoff: 6), '07:00');
    });
  });

  group('TimeHelpers.normalizeDate', () {
    test('parses ISO 8601 dates', () {
      expect(TimeHelpers.normalizeDate('2024-03-17'), '2024-03-17');
    });

    test('parses dd/MM/yyyy format', () {
      expect(TimeHelpers.normalizeDate('17/03/2024'), '2024-03-17');
    });

    test('parses dd-MM-yyyy format', () {
      expect(TimeHelpers.normalizeDate('17-03-2024'), '2024-03-17');
    });

    test('handles 2-digit years', () {
      final result = TimeHelpers.normalizeDate('17/03/24');
      expect(result, '2024-03-17');
    });

    test('returns empty string for empty input', () {
      expect(TimeHelpers.normalizeDate(''), '');
      expect(TimeHelpers.normalizeDate('null'), '');
    });

    test('returns empty string for garbage input', () {
      expect(TimeHelpers.normalizeDate('not-a-date'), '');
    });
  });

  group('TimeHelpers.getMinutes', () {
    test('converts HH:mm to total minutes', () {
      expect(TimeHelpers.getMinutes('00:00'), 0);
      expect(TimeHelpers.getMinutes('01:30'), 90);
      expect(TimeHelpers.getMinutes('14:15'), 855);
      expect(TimeHelpers.getMinutes('23:59'), 1439);
    });

    test('returns 0 for malformed input', () {
      expect(TimeHelpers.getMinutes('abc'), 0);
      expect(TimeHelpers.getMinutes(''), 0);
      expect(TimeHelpers.getMinutes(':'), 0);
    });
  });
}
