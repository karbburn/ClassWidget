import 'package:flutter/material.dart';
import '../services/theme_controller.dart';

class ThemeToggle extends StatelessWidget {
  final ThemeController controller;

  const ThemeToggle({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 36,
      width: 108, // Fixed width for consistent segmented feel (36 * 3)
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withOpacity(0.5) 
            : const Color(0xFF94A3B8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Stack(
        children: [
          // Sliding Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut, // More organic feel like framer-motion
            alignment: _getAlignment(controller.themeMode),
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF38BDF8) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Icons
          Row(
            children: [
              _buildOption(context, ThemeMode.system, Icons.monitor_outlined),
              _buildOption(context, ThemeMode.light, Icons.light_mode_outlined),
              _buildOption(context, ThemeMode.dark, Icons.dark_mode_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, ThemeMode mode, IconData icon) {
    final isSelected = controller.themeMode == mode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.updateThemeMode(mode),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? (isDark ? Colors.white : theme.colorScheme.primary)
                : (isDark ? Colors.white70 : Colors.black45),
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Alignment.center;
      case ThemeMode.dark:
        return Alignment.centerRight;
      case ThemeMode.system:
      default:
        return Alignment.centerLeft;
    }
  }
}
