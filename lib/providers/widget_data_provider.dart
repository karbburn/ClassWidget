import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../models/schedule_event.dart';
import '../utils/constants.dart';
import '../services/preferences_service.dart';
import '../services/log_service.dart';
import 'database_provider.dart';

final widgetRefreshProvider = Provider<WidgetRefreshService>((ref) {
  final service = WidgetRefreshService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class WidgetRefreshService {
  final Ref _ref;
  Timer? _debounceTimer;

  WidgetRefreshService(this._ref);

  Future<void> refresh({bool immediate = false}) async {
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
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  Future<void> syncSchedule() async {
    try {
      final dbHelper = _ref.read(databaseProvider);
      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);
      final tomorrow =
          DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      final List<ScheduleEvent> todayEvents =
          await dbHelper.getEventsForDateRange(today, tomorrow);

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

      await Future.delayed(const Duration(milliseconds: 100));
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
