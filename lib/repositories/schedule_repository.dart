import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import '../services/log_service.dart';

/// Repository for schedule/event-specific database operations.
/// Provides a clean API over the raw DatabaseHelper methods.
class ScheduleRepository {
  final DatabaseHelper _db;

  ScheduleRepository(this._db);

  /// Fetches events for a specific date string (yyyy-MM-dd).
  Future<List<ScheduleEvent>> getEventsForDate(String date) async {
    return await _db.getEventsForDate(date);
  }

  /// Fetches events for a specific DateTime.
  Future<List<ScheduleEvent>> getEventsForDateTime(DateTime date) async {
    return await _db.getEventsForDateTime(date);
  }

  /// Fetches events for a date range (inclusive).
  Future<List<ScheduleEvent>> getEventsForDateRange(
      String startDate, String endDate) async {
    return await _db.getEventsForDateRange(startDate, endDate);
  }

  /// Fetches today's events.
  Future<List<ScheduleEvent>> getTodayEvents() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _db.getEventsForDate(today);
  }

  /// Gets the next upcoming event after [currentTime] on [date].
  Future<ScheduleEvent?> getNextEvent(String date, String currentTime) async {
    return await _db.getNextEvent(date, currentTime);
  }

  /// Inserts a single event.
  Future<int> insertEvent(ScheduleEvent event) async {
    return await _db.insertEvent(event);
  }

  /// Atomically replaces all imported events with [events].
  Future<void> importSchedule(List<ScheduleEvent> events) async {
    await _db.importScheduleTransaction(events);
    LogService.log(
        'ScheduleRepository: imported ${events.length} events',
        tag: 'ScheduleRepo');
  }

  /// Toggles the completion of an event by ID.
  Future<void> toggleCompletion(int id, bool completed) async {
    await _db.updateEventCompletion(id, completed);
  }

  /// Deletes a single event by ID.
  Future<void> deleteEvent(int id) async {
    await _db.deleteEvent(id);
  }

  /// Deletes only imported events.
  Future<void> deleteImportedEvents() async {
    await _db.deleteImportedEvents();
  }

  /// Gets the maximum event date in the database.
  Future<String?> getMaxEventDate() async {
    return await _db.getMaxEventDate();
  }

  /// Clears all data from the events table.
  Future<void> clearAllData() async {
    await _db.clearAllData();
  }
}
