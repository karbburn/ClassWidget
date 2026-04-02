import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_repository.dart';
import 'schedule_repository.dart';
import '../providers/database_provider.dart';

/// Provides a TaskRepository backed by the shared DatabaseHelper.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(databaseProvider));
});

/// Provides a ScheduleRepository backed by the shared DatabaseHelper.
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.read(databaseProvider));
});
