import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:classwidget/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    test('returns consistent color for same title', () {
      final color1 = ColorUtils.getSubjectColor('Mathematics');
      final color2 = ColorUtils.getSubjectColor('Mathematics');
      expect(color1, equals(color2));
    });

    test('returns a color for empty string', () {
      final color = ColorUtils.getSubjectColor('');
      expect(color, isA<Color>());
    });

    test('different titles can produce different colors', () {
      final colors = <Color>{};
      for (final title in ['Math', 'Physics', 'Chemistry', 'English', 'History', 'Biology']) {
        colors.add(ColorUtils.getSubjectColor(title));
      }
      expect(colors.length, greaterThanOrEqualTo(2));
    });

    test('memoization returns cached result', () {
      final color1 = ColorUtils.getSubjectColor('Test Subject');
      final color2 = ColorUtils.getSubjectColor('Test Subject');
      expect(identical(color1, color2), isTrue);
    });
  });
}
