import 'dart:convert';
import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import '../utils/constants.dart';
import 'preferences_service.dart';
import 'log_service.dart';

class WidgetDataService {
  static Timer? _debounceTimer;

  /// Centralized entry point for widget refreshes.
  /// Uses debouncing by default to prevent excessive updates.
  /// Set [immediate] to true for critical updates (e.g. app launch).
  static Future<void> refreshWidget({bool immediate = false}) async {
    if (immediate) {
      _debounceTimer?.cancel();
      LogService.log('Immediate widget refresh triggered.',
          tag: 'WidgetDataService');
      await syncSchedule();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      LogService.log('Debounced widget refresh executing...',
          tag: 'WidgetDataService');
      await syncSchedule();
      _debounceTimer = null;
    });
  }

  /// Cancels any pending widget updates.
  static void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Syncs today's and tomorrow's events to the Home Widget.
  /// The Kotlin side dynamically filters for "today" using system time,
  /// which ensures correct display even after midnight without app wake-up.
  static Future<void> syncSchedule() async {
    try {
      final dbHelper = DatabaseHelper();
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final tomorrow =
          DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      // Fetch today's and tomorrow's events for widget display
      final List<ScheduleEvent> todayEvents =
          await dbHelper.getEventsForDateRange(today, tomorrow);

      // Filter: All classes for today + only incomplete tasks for today
      final displayEvents =
          todayEvents.where((e) => e.type == 'class' || !e.completed).toList();

      final List<Map<String, dynamic>> eventMaps = displayEvents.map((e) {
        return {
          AppConstants.keyId: e.id,
          AppConstants.keyTitle: e.title,
          AppConstants.keyStartTime: e.startTime,
          AppConstants.keyEndTime: e.endTime,
          AppConstants.keyProfessor: e.professor,
          AppConstants.keyType: e.type,
          AppConstants.keyCompleted: e.completed,
          AppConstants.keyDate: e.date,
        };
      }).toList();

      final Map<String, dynamic> payload = {
        AppConstants.keyEvents: eventMaps,
        AppConstants.keyShowProfessorNames:
            await PreferencesService.getShowProfessorNames(),
      };

      final String jsonData = jsonEncode(payload);

      await HomeWidget.saveWidgetData<String>(
          AppConstants.keyScheduleData, jsonData);

      await HomeWidget.updateWidget(
        name: AppConstants.androidWidgetName,
        androidName: AppConstants.androidWidgetName,
      );

      LogService.log('Widget updated successfully.', tag: 'WidgetDataService');
    } catch (e, stack) {
      LogService.error('Failed to sync widget data', e, stack);
    }
  }
}
