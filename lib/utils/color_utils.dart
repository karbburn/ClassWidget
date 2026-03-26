import 'package:flutter/material.dart';

class ColorUtils {
  static final List<Color> _curatedColors = [
    const Color(0xFFE57373), // Red
    const Color(0xFF81C784), // Green
    const Color(0xFF64B5F6), // Blue
    const Color(0xFFFFB74D), // Orange
    const Color(0xFFBA68C8), // Purple
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFFFF8A65), // Deep Orange
    const Color(0xFF90A4AE), // Blue Grey
  ];

  static final Map<String, Color> _colorCache = {};
  static const int _maxCacheSize = 100;

  /// Deterministically assigns a stable color to a given string
  static Color getSubjectColor(String title, {Color? fallback}) {
    if (title.isEmpty) return fallback ?? _curatedColors[0];

    if (_colorCache.containsKey(title)) {
      return _colorCache[title]!;
    }

    int hash = 0;
    for (int i = 0; i < title.length; i++) {
      hash = title.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final index = hash.abs() % _curatedColors.length;
    final color = _curatedColors[index];

    if (_colorCache.length >= _maxCacheSize) {
      _colorCache.remove(_colorCache.keys.first);
    }
    _colorCache[title] = color;
    return color;
  }
}
