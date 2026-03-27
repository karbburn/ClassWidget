import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 36,
      width: 72,
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
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            alignment: _getAlignment(themeMode),
            child: FractionallySizedBox(
              widthFactor: 1 / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
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
          Row(
            children: [
              _buildOption(context, ref, ThemeMode.light,
                  Icons.light_mode_outlined, themeMode),
              _buildOption(context, ref, ThemeMode.dark,
                  Icons.dark_mode_outlined, themeMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, WidgetRef ref, ThemeMode mode,
      IconData icon, ThemeMode currentMode) {
    final isSelected = currentMode == mode;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
        return Alignment.centerLeft;
      default:
        return Alignment.centerLeft;
    }
  }
}
