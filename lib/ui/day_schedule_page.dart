import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import '../services/time_helpers.dart';
import '../utils/color_utils.dart';
import 'add_task_screen.dart';

class DaySchedulePage extends StatefulWidget {
  final DateTime date;
  final int pageIndex;
  final VoidCallback? onDataChanged;

  const DaySchedulePage({
    super.key,
    required this.date,
    required this.pageIndex,
    this.onDataChanged,
  });

  @override
  State<DaySchedulePage> createState() => _DaySchedulePageState();
}

class _DaySchedulePageState extends State<DaySchedulePage>
    with AutomaticKeepAliveClientMixin {
  List<ScheduleEvent>? _events;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true; // Cache pages when swiping

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final events = await DatabaseHelper().getEventsForDateTime(widget.date);
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTaskCompletion(ScheduleEvent event) async {
    await DatabaseHelper().updateEventCompletion(event.id!, !event.completed);
    _loadEvents();
    widget.onDataChanged?.call();
  }

  String get _headerLabel {
    final dayName = DateFormat('EEEE').format(widget.date);
    switch (widget.pageIndex) {
      case 0:
        return '$dayName · Today';
      case 1:
        return '$dayName · Tomorrow';
      default:
        return '$dayName · ${DateFormat('MMM d').format(widget.date)}';
    }
  }

  Widget _buildProgressBar(ThemeData theme) {
    if (_events == null || _events!.isEmpty) return const SizedBox.shrink();
    if (widget.pageIndex != 0) return const SizedBox.shrink();

    final classes = _events!.where((e) => e.type != 'task').toList();
    if (classes.isEmpty) return const SizedBox.shrink();

    final nowMinutes = TimeHelpers.getMinutes(DateFormat('HH:mm').format(DateTime.now()));
    int completedCount = 0;
    
    for (final c in classes) {
      if (c.endTime.isNotEmpty) {
        if (TimeHelpers.getMinutes(c.endTime) < nowMinutes) {
          completedCount++;
        }
      }
    }

    final progress = completedCount / classes.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '$completedCount of ${classes.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return Column(
      children: [
        // Day header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Text(
            _headerLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const Divider(height: 1),
        _buildProgressBar(theme),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_events == null || _events!.isEmpty)
                  ? _buildEmptyState(theme)
                  : _buildEventList(theme),
        ),
      ],
    );
  }


  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2), width: 2),
            ),
            child: Icon(Icons.event_available_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            widget.pageIndex == 0 ? "Your day is clear! 🎉" : "Nothing scheduled",
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Take a break or add a new task.",
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(ThemeData theme) {
    final now = DateTime.now();
    final isToday = widget.pageIndex == 0;
    final currentTimeMinutes = isToday
        ? TimeHelpers.getMinutes(DateFormat('HH:mm').format(now))
        : -1;

    return RefreshIndicator(
      color: theme.colorScheme.primary,
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _events!.length,
        itemBuilder: (context, index) {
          final event = _events![index];
          final isTask = event.type == 'task';

          bool isCurrent = false;
          if (isToday && !isTask && event.startTime.isNotEmpty && event.endTime.isNotEmpty) {
            final startMinutes = TimeHelpers.getMinutes(event.startTime);
            final endMinutes = TimeHelpers.getMinutes(event.endTime);
            isCurrent = currentTimeMinutes >= startMinutes && currentTimeMinutes <= endMinutes;
          }
          
          final subjectColor = isTask ? Colors.transparent : ColorUtils.getSubjectColor(event.title);

          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 200 + (index * 100).clamp(0, 400)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: isTask ? () => _toggleTaskCompletion(event) : null,
              onLongPress: isTask
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddTaskScreen(eventToEdit: event)),
                      );
                      if (result == true) {
                        _loadEvents();
                        widget.onDataChanged?.call();
                      }
                    }
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: isCurrent 
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                  boxShadow: [
                    if (isCurrent)
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Accent Color Strip
                        if (!isTask)
                          Container(
                            width: 6,
                            color: subjectColor,
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                if (isTask)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Checkbox(
                                      value: event.completed,
                                      onChanged: (_) => _toggleTaskCompletion(event),
                                      shape: const CircleBorder(),
                                      activeColor: theme.colorScheme.primary,
                                      checkColor: theme.colorScheme.surface,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        event.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          decoration: event.completed ? TextDecoration.lineThrough : null,
                                          color: event.completed ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5) : null,
                                        ),
                                      ),
                                      if (event.startTime.isNotEmpty || event.endTime.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            event.startTime.isEmpty
                                                ? 'All Day'
                                                : '${event.startTime} - ${event.endTime}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                              decoration: event.completed ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'NOW',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                if (isTask && event.notes != null && !isCurrent)
                                  Icon(Icons.notes, size: 16, color: theme.disabledColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
