import 'package:flutter_test/flutter_test.dart';
import 'package:classwidget/models/task_item.dart';
import 'package:classwidget/models/schedule_event.dart';

void main() {
  group('TaskItem Model Tests', () {
    test('fromMap creates TaskItem correctly', () {
      final map = {
        'id': 1,
        'title': 'Math Homework',
        'due_date': '2026-04-03',
        'related_course': 'Mathematics',
        'is_completed': 0,
      };
      final task = TaskItem.fromMap(map);
      expect(task.id, 1);
      expect(task.title, 'Math Homework');
      expect(task.dueDate, '2026-04-03');
      expect(task.relatedCourse, 'Mathematics');
      expect(task.isCompleted, false);
    });

    test('fromMap handles completed task', () {
      final map = {
        'id': 2,
        'title': 'Submit Report',
        'due_date': '2026-04-05',
        'related_course': null,
        'is_completed': 1,
      };
      final task = TaskItem.fromMap(map);
      expect(task.isCompleted, true);
      expect(task.relatedCourse, isNull);
    });

    test('toMap excludes id for insert safety', () {
      final task = TaskItem(
        id: 5,
        title: 'Test Task',
        dueDate: '2026-04-10',
        isCompleted: false,
      );
      final map = task.toMap();
      expect(map.containsKey('id'), false);
      expect(map['title'], 'Test Task');
      expect(map['due_date'], '2026-04-10');
      expect(map['is_completed'], 0);
    });

    test('toMap converts isCompleted to int', () {
      final task = TaskItem(title: 'Done Task', isCompleted: true);
      expect(task.toMap()['is_completed'], 1);
    });

    test('copyWith creates modified copy', () {
      final original = TaskItem(
        id: 1,
        title: 'Original',
        isCompleted: false,
      );
      final modified = original.copyWith(isCompleted: true);
      expect(modified.isCompleted, true);
      expect(modified.title, 'Original');
      expect(modified.id, 1);
    });

    test('copyWith does not mutate original', () {
      final original = TaskItem(title: 'Test', isCompleted: false);
      original.copyWith(title: 'Changed');
      expect(original.title, 'Test');
    });
  });

  group('ScheduleEvent Model Tests', () {
    test('fromMap creates ScheduleEvent correctly', () {
      final map = {
        'id': 10,
        'title': 'Physics',
        'start_time': '09:00',
        'end_time': '10:30',
        'professor': 'Dr. Smith',
        'section': 'A',
        'type': 'class',
        'notes': null,
        'completed': 0,
        'is_imported': 1,
        'date': '2026-04-03',
      };
      final event = ScheduleEvent.fromMap(map);
      expect(event.id, 10);
      expect(event.title, 'Physics');
      expect(event.startTime, '09:00');
      expect(event.endTime, '10:30');
      expect(event.professor, 'Dr. Smith');
      expect(event.type, 'class');
      expect(event.completed, false);
      expect(event.isImported, true);
      expect(event.date, '2026-04-03');
    });

    test('toMap excludes id for insert', () {
      final event = ScheduleEvent(
        title: 'Test',
        startTime: '09:00',
        endTime: '10:00',
        type: 'class',
        date: '2026-04-03',
      );
      final map = event.toMap();
      expect(map.containsKey('id'), false);
      expect(map['title'], 'Test');
      expect(map['completed'], 0);
    });

    test('fromMap handles task type with completion', () {
      final map = {
        'id': 20,
        'title': 'Submit Essay',
        'start_time': '',
        'end_time': '',
        'professor': null,
        'section': null,
        'type': 'task',
        'notes': 'Draft ready',
        'completed': 1,
        'is_imported': 0,
        'date': '2026-04-05',
      };
      final event = ScheduleEvent.fromMap(map);
      expect(event.type, 'task');
      expect(event.completed, true);
      expect(event.isImported, false);
      expect(event.notes, 'Draft ready');
    });

    test('fromMap handles null/missing fields gracefully', () {
      final map = <String, dynamic>{
        'id': null,
        'title': null,
        'start_time': null,
        'end_time': null,
      };
      final event = ScheduleEvent.fromMap(map);
      expect(event.id, isNull);
      expect(event.title, '');
      expect(event.startTime, '');
      expect(event.type, 'class'); // default
    });

    test('fromMap handles bool completed values', () {
      final map = {
        'title': 'Test',
        'start_time': '',
        'end_time': '',
        'type': 'task',
        'completed': true,
        'is_imported': false,
        'date': '2026-04-03',
      };
      final event = ScheduleEvent.fromMap(map);
      expect(event.completed, true);
      expect(event.isImported, false);
    });
  });
}
