import 'package:flutter/material.dart';
import '../services/widget_data_service.dart';
import '../services/theme_controller.dart';
import '../services/preferences_service.dart';
import '../services/log_service.dart';
import '../widgets/theme_toggle.dart';
import 'day_schedule_page.dart';
import '../database/database_helper.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  final ThemeController themeController;
  const DashboardScreen({super.key, required this.themeController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _totalPages = 500; // Efficient default buffer (approx 1.3 years)
  late PageController _pageController;
  int _currentPage = AppConstants.centerIndex;
  String? _selectedSection;

  // GlobalKeys to trigger refresh on individual pages
  final Map<int, GlobalKey<dynamic>> _pageKeys = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: AppConstants.centerIndex);
    WidgetsBinding.instance.addObserver(this);
    _loadSection();
    _loadMaxDateAndSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetToToday();
      _loadMaxDateAndSync();
    }
  }

  void _resetToToday() {
    if (_pageController.hasClients &&
        _currentPage != AppConstants.centerIndex) {
      _pageController.jumpToPage(AppConstants.centerIndex);
    }
    setState(() {
      _currentPage = AppConstants.centerIndex;
      _pageKeys.clear();
    });
  }

  Future<void> _loadMaxDateAndSync() async {
    final maxDateStr = await DatabaseHelper().getMaxEventDate();
    if (mounted) {
      setState(() {
        if (maxDateStr != null) {
          try {
            final maxDate = DateTime.parse(maxDateStr);
            final today = DateTime.now();
            final daysToMax = maxDate.difference(today).inDays;
            // Cap at 120 days as per user's 4-month request, but always allow at least 15 days
            final futureBuffer = daysToMax.clamp(15, 120);
            _totalPages = AppConstants.centerIndex + futureBuffer + 1;
          } catch (_) {
            _totalPages = AppConstants.centerIndex + 120; // fallback
          }
        } else {
          _totalPages = AppConstants.centerIndex + 120; // fallback if no data
        }
      });
    }
    _syncWidget();
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
    final today = DateTime.now();
    final dayOffset = index - AppConstants.centerIndex;
    return DateTime(today.year, today.month, today.day)
        .add(Duration(days: dayOffset));
  }

  void _onDataChanged() {
    _syncWidget();
    _loadMaxDateAndSync(); // Recalculate limits if data changed
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
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
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
              setState(() {
                _pageKeys.clear();
              });
              _loadMaxDateAndSync();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPageIndicator(),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _totalPages,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  // Optimization: Remove keys for pages further than ±50 from current page
                  _pageKeys.removeWhere(
                      (keyIndex, _) => (keyIndex - index).abs() > 50);
                });
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
    );
  }

  Widget _buildPageIndicator() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(width: 8),
            // Dynamic sliding window of 7 days around _currentPage
            ...List.generate(7, (i) {
              final dotIndex = _currentPage - 3 + i;
              if (dotIndex < 0 || dotIndex >= _totalPages) {
                return const SizedBox.shrink();
              }

              final isActive = dotIndex == _currentPage;
              final date = _dateForIndex(dotIndex);
              final dayName = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun'
              ][date.weekday - 1];

              return GestureDetector(
                onTap: () => _pageController.animateToPage(dotIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isActive
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: isActive
                        ? null
                        : Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive
                          ? theme.colorScheme.onPrimary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
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
      ),
    );
  }
}
