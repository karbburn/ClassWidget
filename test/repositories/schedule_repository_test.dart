import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:classwidget/repositories/schedule_repository.dart';
import 'package:classwidget/database/database_helper.dart';
import 'package:classwidget/models/schedule_event.dart';

void main() {
  late DatabaseHelper dbHelper;
  late ScheduleRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    repository = ScheduleRepository(dbHelper);
    await dbHelper.clearAllData();
  });

  group('ScheduleRepository', () {
    test('getEventsForDate returns correct events', () async {
      final event = ScheduleEvent(
        title: 'Physics',
        startTime: '09:00',
        endTime: '10:00',
        type: 'class',
        date: '2026-04-03',
      );
      await repository.insertEvent(event);

      final events = await repository.getEventsForDate('2026-04-03');
      expect(events.length, 1);
      expect(events.first.title, 'Physics');
      expect(events.first.startTime, '09:00');
    });

    test('getEventsForDate returns empty for non-existent date', () async {
      final events = await repository.getEventsForDate('2026-01-01');
      expect(events, isEmpty);
    });

    test('getMaxEventDate returns latest date', () async {
      await repository.insertEvent(ScheduleEvent(
        title: 'Event 1',
        startTime: '09:00',
        endTime: '10:00',
        type: 'class',
        date: '2026-04-01',
      ));
      await repository.insertEvent(ScheduleEvent(
        title: 'Event 2',
        startTime: '09:00',
        endTime: '10:00',
        type: 'class',
        date: '2026-04-05',
      ));

      final maxDate = await repository.getMaxEventDate();
      expect(maxDate, '2026-04-05');
    });

    test('getMaxEventDate returns null when no events', () async {
      final maxDate = await repository.getMaxEventDate();
      expect(maxDate, isNull);
    });

    test('importSchedule replaces imported events atomically', () async {
      // Insert initial imported events
      await repository.insertEvent(ScheduleEvent(
        title: 'Old Event',
        startTime: '09:00',
        endTime: '10:00',
        type: 'class',
        date: '2026-04-01',
        isImported: true,
      ));

      // Import new events
      final newEvents = [
        ScheduleEvent(
          title: 'New Event 1',
          startTime: '09:00',
          endTime: '10:00',
          type: 'class',
          date: '2026-04-02',
          isImported: true,
        ),
        ScheduleEvent(
          title: 'New Event 2',
          startTime: '11:00',
          endTime: '12:00',
          type: 'class',
          date: '2026-04-02',
          isImported: true,
        ),
      ];
      await repository.importSchedule(newEvents);

      // Verify old imported event is gone
      final oldEvents = await repository.getEventsForDate('2026-04-01');
      expect(oldEvents, isEmpty);

      // Verify new events exist
      final newEventsResult = await repository.getEventsForDate('2026-04-02');
      expect(newEventsResult.length, 2);
    });

    test('deleteEvent removes single event', () async {
      final event = ScheduleEvent(
        title: 'To Delete',
        startTime: '09:00',
        endTime: '10:00',
        type: 'class',
        date: '2026-04-03',
      );
      final id = await repository.insertEvent(event);

      await repository.deleteEvent(id);

      final events = await repository.getEventsForDate('2026-04-03');
      expect(events, isEmpty);
    });

    test('getNextEvent returns next upcoming event', () async {
      await repository.insertEvent(ScheduleEvent(
        title: 'First Class',
        startTime: '08:00',
        endTime: '09:00',
        type: 'class',
        date: '2026-04-03',
      ));
      await repository.insertEvent(ScheduleEvent(
        title: 'Second Class',
        startTime: '10:00',
        endTime: '11:00',
        type: 'class',
        date: '2026-04-03',
      ));

      final nextEvent = await repository.getNextEvent('2026-04-03', '09:00');
      expect(nextEvent, isNotNull);
      expect(nextEvent!.title, 'Second Class');
    });

    test('getNextEvent returns null when no more events', () async {
      await repository.insertEvent(ScheduleEvent(
        title: 'Only Class',
        startTime: '08:00',
        endTime: '09:00',
        type: 'class',
        date: '2026-04-03',
      ));

      final nextEvent = await repository.getNextEvent('2026-04-03', '10:00');
      expect(nextEvent, isNull);
    });
  });
}
