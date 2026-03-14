import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import '../services/time_helpers.dart';
import '../services/widget_data_service.dart';
import '../services/theme_controller.dart';
import '../services/preferences_service.dart';
import '../widgets/theme_toggle.dart';
import '../services/log_service.dart';
import 'add_task_screen.dart';
import 'import_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ThemeController themeController;
  const DashboardScreen({super.key, required this.themeController});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ScheduleEvent> _allEvents = [];
  bool _isLoading = true;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final todayStr = TimeHelpers.formatDate(DateTime.now());
      final events = await DatabaseHelper().getEventsForDate(todayStr);
      final section = await PreferencesService.getSelectedSection();
      
      // Sort logic: Timed events first, then untimed events at bottom
      events.sort((a, b) {
        if (a.startTime.isEmpty && b.startTime.isNotEmpty) return 1;
        if (a.startTime.isNotEmpty && b.startTime.isEmpty) return -1;
        return a.startTime.compareTo(b.startTime);
      });

      if (mounted) {
        setState(() {
          _allEvents = events;
          _selectedSection = section;
          _isLoading = false;
        });
      }
      WidgetDataService.refreshWidget();
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'))
        );
      }
      LogService.error('Dashboard load failed', e, stack);
    }
  }

  Future<void> _toggleTaskCompletion(ScheduleEvent event) async {
    await DatabaseHelper().updateEventCompletion(event.id!, !event.completed);
    _loadData();
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
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allEvents.isEmpty
              ? _buildEmptyState()
              : _buildEventList(),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'import_fab',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/import');
              if (result == true) _loadData();
            },
            child: const Icon(Icons.file_upload_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_task_fab',
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/add-task');
              if (result == true) _loadData();
            },
            icon: const Icon(Icons.add_task),
            label: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          const Text('Your day is clear! 🎉',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('No classes or tasks scheduled for today.'),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/import'),
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Import Schedule'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final now = DateTime.now();
    final currentTimeMinutes = TimeHelpers.getMinutes(DateFormat('HH:mm').format(now));

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allEvents.length,
        itemBuilder: (context, index) {
          final event = _allEvents[index];
          final isTask = event.type == 'task';
          
          bool isCurrent = false;
          if (!isTask && event.startTime.isNotEmpty && event.endTime.isNotEmpty) {
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
                ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                : BorderSide.none,
            ),
            child: ListTile(
              onTap: isTask ? () => _toggleTaskCompletion(event) : null,
              onLongPress: isTask ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddTaskScreen(eventToEdit: event)),
                );
                if (result == true) _loadData();
              } : null,
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
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.surfaceContainerHighest).withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCurrent ? Icons.play_arrow : Icons.class_outlined,
                      color: isCurrent ? Theme.of(context).colorScheme.primary : null,
                    ),
                  ),
              title: Text(
                event.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: event.completed ? TextDecoration.lineThrough : null,
                  color: event.completed ? Colors.grey : null,
                ),
              ),
              subtitle: Text(
                event.startTime.isEmpty ? 'All Day' : '${event.startTime} - ${event.endTime}',
                style: TextStyle(
                  decoration: event.completed ? TextDecoration.lineThrough : null,
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
