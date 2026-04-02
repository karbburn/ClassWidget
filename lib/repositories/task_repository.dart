import '../database/database_helper.dart';
import '../models/task_item.dart';
import '../services/log_service.dart';

/// Repository for task-specific database operations.
/// Provides a clean API over the raw DatabaseHelper methods.
class TaskRepository {
  final DatabaseHelper _db;

  TaskRepository(this._db);

  /// Fetches all tasks, sorted by completion then date.
  Future<List<TaskItem>> getAllTasks() async {
    try {
      final maps = await _db.getTasks();
      LogService.log('TaskRepository: fetched ${maps.length} tasks');
      return maps.map((m) => TaskItem.fromMap(m)).toList();
    } catch (e, stack) {
      LogService.error('TaskRepository.getAllTasks failed', e, stack);
      return [];
    }
  }

  /// Inserts a new task. Returns the new row ID.
  Future<int> createTask(TaskItem task) async {
    return await _db.insertTask(task.toMap());
  }

  /// Updates an existing task. Returns the number of rows affected.
  Future<int> updateTask(TaskItem task) async {
    return await _db.updateTask(task.toMapWithId());
  }

  /// Deletes a task by ID. Returns the number of rows affected.
  Future<int> deleteTask(int id) async {
    return await _db.deleteTask(id);
  }

  /// Toggles the completion state of a task.
  Future<void> toggleCompletion(TaskItem task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    final map = updated.toMap();
    map['id'] = updated.id;
    await _db.updateTask(map);
  }
}
