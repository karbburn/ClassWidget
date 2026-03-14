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
  /// Uses debouncing to prevent excessive updates.
  static void refreshWidget() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      LogService.log('Refreshing widget data...', tag: 'WidgetDataService');
      await syncTodaySchedule();
    });
  }

  /// Syncs today's schedule to the Home Widget with minimal payload
  static Future<void> syncTodaySchedule() async {
    try {
      final dbHelper = DatabaseHelper();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final currentTime = DateFormat('HH:mm').format(DateTime.now());
      
      final List<ScheduleEvent> allEvents = await dbHelper.getEventsForDate(today);
      
      // Filter: All classes + only incomplete tasks
      final displayEvents = allEvents.where((e) => e.type == 'class' || !e.completed).toList();
      
      // Sort: Chronological, untimed at bottom
      displayEvents.sort((a, b) {
        if (a.startTime.isEmpty && b.startTime.isNotEmpty) return 1;
        if (a.startTime.isNotEmpty && b.startTime.isEmpty) return -1;
        return a.startTime.compareTo(b.startTime);
      });

      final List<Map<String, dynamic>> eventMaps = displayEvents.map((e) {
        bool isCurrent = false;
        if (e.type == 'class' && e.startTime.isNotEmpty && e.endTime.isNotEmpty) {
           isCurrent = currentTime.compareTo(e.startTime) >= 0 && 
                       currentTime.compareTo(e.endTime) <= 0;
        }
                             
        return {
          'id': e.id,
          'title': e.title,
          'time': e.startTime.isEmpty ? 'All Day' : '${e.startTime} - ${e.endTime}',
          'professor': e.professor,
          'isCurrent': isCurrent,
          'type': e.type,
          'completed': e.completed,
        };
      }).toList();

      final Map<String, dynamic> payload = {
        'events': eventMaps,
        'isEmpty': displayEvents.isEmpty,
        'dayName': DateFormat('EEEE').format(DateTime.now()),
        'showProfessorNames': await PreferencesService.getShowProfessorNames(),
      };

      // Feature #18: Add Next Class Countdown if applicable
      final nextEvent = await dbHelper.getNextEvent(today, currentTime);
      if (nextEvent != null) {
        payload['nextTitle'] = nextEvent.title;
        payload['nextTime'] = nextEvent.startTime;
        
        final nextStart = DateFormat('HH:mm').parse(nextEvent.startTime);
        final now = DateFormat('HH:mm').parse(currentTime);
        payload['minutesUntilNext'] = nextStart.difference(now).inMinutes;
      }

      final String jsonData = jsonEncode(payload);

      await HomeWidget.saveWidgetData<String>('today_schedule', jsonData);
      
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
