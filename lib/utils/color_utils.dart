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

  /// Deterministically assigns a stable color to a given string
  static Color getSubjectColor(String title) {
    if (title.isEmpty) return _curatedColors[0];
    
    int hash = 0;
    for (int i = 0; i < title.length; i++) {
      hash = title.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    final index = hash.abs() % _curatedColors.length;
    return _curatedColors[index];
  }
}
