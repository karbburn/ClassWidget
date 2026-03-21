import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import '../services/time_helpers.dart';
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
          Icon(Icons.event_available_outlined,
              size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            widget.pageIndex == 0 ? 'Your day is clear! 🎉' : 'Nothing scheduled',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('No classes or tasks for this day.'),
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
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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

          return Card(
            elevation: isCurrent ? 4 : 1,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isCurrent
                  ? BorderSide(color: theme.colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              onTap: isTask ? () => _toggleTaskCompletion(event) : null,
              onLongPress: isTask
                  ? () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AddTaskScreen(eventToEdit: event)),
                      );
                      if (result == true) {
                        _loadEvents();
                        widget.onDataChanged?.call();
                      }
                    }
                  : null,
              leading: isTask
                  ? Checkbox(
                      value: event.completed,
                      onChanged: (_) => _toggleTaskCompletion(event),
                      shape: const CircleBorder(),
                    )
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isCurrent
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest)
                            .withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCurrent ? Icons.play_arrow : Icons.class_outlined,
                        color: isCurrent ? theme.colorScheme.primary : null,
                      ),
                    ),
              title: Text(
                event.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration:
                      event.completed ? TextDecoration.lineThrough : null,
                  color: event.completed ? Colors.grey : null,
                ),
              ),
              subtitle: Text(
                event.startTime.isEmpty
                    ? 'All Day'
                    : '${event.startTime} - ${event.endTime}',
                style: TextStyle(
                  decoration:
                      event.completed ? TextDecoration.lineThrough : null,
                ),
              ),
              trailing: isCurrent
                  ? const Badge(label: Text('Now'))
                  : isTask && event.notes != null
                      ? const Icon(Icons.notes, size: 16)
                      : null,
            ),
          );
        },
      ),
    );
  }
}
