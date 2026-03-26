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
      width: 72, // Fixed width for consistent segmented feel (36 * 2)
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : const Color(0xFF94A3B8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
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
              widthFactor: 1 / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme
                      .primary, // Using theme Primary (Gold) instead of hardcoded blue
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
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

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.updateThemeMode(mode),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? theme.colorScheme
                    .onPrimary // Black/Dark icon on the Gold background
                : theme.colorScheme.onSurface
                    .withValues(alpha: 0.5), // Muted for unselected
          ),
        ),
      ),
    );
  }

  Alignment _getAlignment(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Alignment.centerRight;
      case ThemeMode.light:
      default:
        return Alignment.centerLeft;
    }
  }
}
