import 'dart:convert';
import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import 'preferences_service.dart';
import 'log_service.dart';

class WidgetDataService {
  static const String androidWidgetName = 'ClassWidgetProvider';
  static Timer? _debounceTimer;

  /// Centralized entry point for widget refreshes. 
  /// Uses debouncing by default to prevent excessive updates.
  /// Set [immediate] to true for critical updates (e.g. app launch).
  static Future<void> refreshWidget({bool immediate = false}) async {
    if (immediate) {
      _debounceTimer?.cancel();
      LogService.log('Immediate widget refresh triggered.', tag: 'WidgetDataService');
      await syncSchedule();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      LogService.log('Debounced widget refresh executing...', tag: 'WidgetDataService');
      await syncSchedule();
    });
  }

  /// Syncs a rolling 7-day window of events to the Home Widget.
  /// The Kotlin side dynamically filters for "today" using system time,
  /// which ensures correct display even after midnight without app wake-up.
  static Future<void> syncSchedule() async {
    try {
      final dbHelper = DatabaseHelper();
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final endDate = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 6)));

      // Fetch all events for 7 days
      final List<ScheduleEvent> allEvents = await dbHelper.getEventsForDateRange(today, endDate);
      
      // Filter: All classes + only incomplete tasks
      final displayEvents = allEvents.where((e) => e.type == 'class' || !e.completed).toList();

      final List<Map<String, dynamic>> eventMaps = displayEvents.map((e) {
        return {
          'id': e.id,
          'title': e.title,
          'startTime': e.startTime,
          'endTime': e.endTime,
          'professor': e.professor,
          'type': e.type,
          'completed': e.completed,
          'date': e.date,
        };
      }).toList();

      final Map<String, dynamic> payload = {
        'events': eventMaps,
        'showProfessorNames': await PreferencesService.getShowProfessorNames(),
      };

      final String jsonData = jsonEncode(payload);

      await HomeWidget.saveWidgetData<String>('schedule_data', jsonData);
      
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
      );
      
      LogService.log('Widget updated successfully.', tag: 'WidgetDataService');
    } catch (e, stack) {
      LogService.error('Failed to sync widget data', e, stack);
    }
  }
}
