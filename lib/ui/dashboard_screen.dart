import 'package:flutter/material.dart';
import '../services/widget_data_service.dart';
import '../services/theme_controller.dart';
import '../services/preferences_service.dart';
import '../services/log_service.dart';
import '../widgets/theme_toggle.dart';
import 'day_schedule_page.dart';

class DashboardScreen extends StatefulWidget {
  final ThemeController themeController;
  const DashboardScreen({super.key, required this.themeController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  static const int _totalPages = 14;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedSection;

  // GlobalKeys to trigger refresh on individual pages
  final Map<int, GlobalKey<dynamic>> _pageKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSection();
    _syncWidget();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset to today's page and refresh data
      if (_pageController.hasClients && _currentPage != 0) {
        _pageController.jumpToPage(0);
      }
      setState(() {
        _currentPage = 0;
        _pageKeys.clear();
      });
      _syncWidget();
    }
  }

  Future<void> _loadSection() async {
    final section = await PreferencesService.getSelectedSection();
    if (mounted) setState(() => _selectedSection = section);
  }

  Future<void> _syncWidget() async {
    try {
      await WidgetDataService.refreshWidget(immediate: true);
    } catch (e, stack) {
      LogService.error('Widget sync failed', e, stack);
    }
  }

  DateTime _dateForIndex(int index) {
    return DateTime.now().add(Duration(days: index));
  }

  void _onDataChanged() {
    // Re-sync the widget (only today's data matters for widget)
    _syncWidget();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ClassWidget'),
            if (_selectedSection != null && _selectedSection!.isNotEmpty)
              Text(
                'Section: $_selectedSection',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ThemeToggle(controller: widget.themeController),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force rebuild the current page
              setState(() {
                _pageKeys.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator dots
          _buildPageIndicator(),
          // Swipeable pages
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                _pageKeys.putIfAbsent(index, () => GlobalKey());
                return DaySchedulePage(
                  key: _pageKeys[index],
                  date: _dateForIndex(index),
                  pageIndex: index,
                  onDataChanged: _onDataChanged,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'import_fab',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/import');
              if (result == true) {
                setState(() => _pageKeys.clear());
                _syncWidget();
              }
            },
            child: const Icon(Icons.file_upload_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_task_fab',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add-task');
              if (result == true) {
                setState(() => _pageKeys.clear());
                _syncWidget();
              }
            },
            icon: const Icon(Icons.add_task),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    final theme = Theme.of(context);
    // Show a compact row: left arrow, dots for nearby pages, right arrow
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left chevron
          GestureDetector(
            onTap: _currentPage > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
            child: Icon(
              Icons.chevron_left,
              color: _currentPage > 0
                  ? theme.colorScheme.primary
                  : theme.disabledColor,
            ),
          ),
          const SizedBox(width: 4),
          // Dots — show up to 7 centered around the current page
          ...List.generate(_totalPages.clamp(0, 7), (i) {
            final startIndex = (_currentPage - 3).clamp(0, _totalPages - 7);
            final dotIndex = startIndex + i;
            if (dotIndex >= _totalPages) return const SizedBox.shrink();
            final isActive = dotIndex == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }),
          const SizedBox(width: 4),
          // Right chevron
          GestureDetector(
            onTap: _currentPage < _totalPages - 1
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
            child: Icon(
              Icons.chevron_right,
              color: _currentPage < _totalPages - 1
                  ? theme.colorScheme.primary
                  : theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
