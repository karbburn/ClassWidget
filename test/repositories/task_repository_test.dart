import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:classwidget/repositories/task_repository.dart';
import 'package:classwidget/database/database_helper.dart';
import 'package:classwidget/models/task_item.dart';

void main() {
  late DatabaseHelper dbHelper;
  late TaskRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    repository = TaskRepository(dbHelper);
    // Clear database before each test
    await dbHelper.clearAllData();
  });

  group('TaskRepository', () {
    test('getAllTasks returns empty list when no tasks', () async {
      final tasks = await repository.getAllTasks();
      expect(tasks, isEmpty);
    });

    test('createTask inserts task', () async {
      final task = TaskItem(title: 'Test Task', dueDate: '2026-04-10');
      final id = await repository.createTask(task);
      expect(id, greaterThan(0));

      final tasks = await repository.getAllTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Test Task');
      expect(tasks.first.dueDate, '2026-04-10');
    });

    test('updateTask modifies existing task', () async {
      final task = TaskItem(title: 'Original', isCompleted: false);
      final id = await repository.createTask(task);

      final updated = TaskItem(id: id, title: 'Updated', isCompleted: true);
      await repository.updateTask(updated);

      final tasks = await repository.getAllTasks();
      expect(tasks.first.title, 'Updated');
      expect(tasks.first.isCompleted, true);
    });

    test('deleteTask removes task', () async {
      final task = TaskItem(title: 'To Delete');
      final id = await repository.createTask(task);

      await repository.deleteTask(id);

      final tasks = await repository.getAllTasks();
      expect(tasks, isEmpty);
    });

    test('toggleCompletion flips isCompleted', () async {
      final task = TaskItem(title: 'Toggle Test', isCompleted: false);
      await repository.createTask(task);

      final tasks = await repository.getAllTasks();
      expect(tasks.first.isCompleted, false);

      await repository.toggleCompletion(tasks.first);

      final updatedTasks = await repository.getAllTasks();
      expect(updatedTasks.first.isCompleted, true);
    });

    test('createTask with related course', () async {
      final task = TaskItem(
        title: 'Math Homework',
        dueDate: '2026-04-15',
        relatedCourse: 'Mathematics',
      );
      await repository.createTask(task);

      final tasks = await repository.getAllTasks();
      expect(tasks.first.relatedCourse, 'Mathematics');
    });
  });
}
