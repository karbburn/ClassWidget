import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_item.dart';
import '../repositories/repository_providers.dart';
import '../providers/widget_data_provider.dart';
import '../services/log_service.dart';
import 'package:intl/intl.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    LogService.log('Loading tasks...', tag: 'TasksScreen');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    try {
      final tasks = await ref.read(taskRepositoryProvider).getAllTasks();
      LogService.log('Fetched ${tasks.length} tasks from DB', tag: 'TasksScreen');
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e, stack) {
      LogService.error('Failed to load tasks', e, stack);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _toggleTask(TaskItem task) async {
    await ref.read(taskRepositoryProvider).toggleCompletion(task);
    _loadTasks();
    await ref.read(widgetRefreshProvider).refresh(immediate: true);
  }

  Future<void> _deleteTask(int id) async {
    await ref.read(taskRepositoryProvider).deleteTask(id);
    _loadTasks();
    await ref.read(widgetRefreshProvider).refresh(immediate: true);
  }

  void _showTaskDialog([TaskItem? task]) {
    final titleController = TextEditingController(text: task?.title);
    final courseController = TextEditingController(text: task?.relatedCourse);
    DateTime? selectedDate =
        task?.dueDate != null ? DateTime.parse(task!.dueDate!) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ]),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 12,
              left: 24,
              right: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  task == null ? 'New Task' : 'Edit Task',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(
                    labelText: 'Related Course (Optional)',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary:
                                  theme.colorScheme.primary, // Selection color
                              onPrimary: theme.colorScheme.onPrimary,
                              surface: theme.colorScheme.surface,
                              onSurface: theme.textTheme.bodyLarge?.color ??
                                  Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color:
                                theme.inputDecorationTheme.labelStyle?.color),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null
                              ? 'Set Due Date'
                              : 'Due: ${DateFormat('MMM d, yyyy').format(selectedDate!)}',
                          style: TextStyle(
                            color: selectedDate == null
                                ? theme.inputDecorationTheme.labelStyle?.color
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: selectedDate == null
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.edit_calendar,
                            color: theme.inputDecorationTheme.labelStyle?.color,
                            size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;

                    final newTask = TaskItem(
                      id: task?.id,
                      title: titleController.text.trim(),
                      relatedCourse: courseController.text.trim().isEmpty
                          ? null
                          : courseController.text.trim(),
                      dueDate: selectedDate != null
                          ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                          : null,
                      isCompleted: task?.isCompleted ?? false,
                    );

                    if (task == null) {
                      await ref.read(taskRepositoryProvider).createTask(newTask);
                    } else {
                      await ref.read(taskRepositoryProvider).updateTask(newTask);
                    }

                    if (context.mounted) Navigator.pop(context);
                    _loadTasks();
                    await ref
                        .read(widgetRefreshProvider)
                        .refresh(immediate: true);
                  },
                  child: Text(task == null ? 'CREATE TASK' : 'SAVE CHANGES'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorState()
              : _tasks.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: LayoutBuilder(
                          builder: (context, constraints) => SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: constraints.maxHeight,
                                  child: _buildEmptyState(),
                                ),
                              )),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return _buildTaskItem(task);
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add_task),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Colors.red.withValues(alpha: 0.7)),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                  width: 2),
            ),
            child: Icon(Icons.assignment_turned_in_outlined,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up! 🎉',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add homework or reminders to stay organized.',
            style: TextStyle(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime date, ThemeData theme, bool isCompleted) {
    if (isCompleted) {
      return theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5) ??
          Colors.grey;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);

    if (dueDate.isBefore(today)) return const Color(0xFFEF4444); // Red
    if (dueDate.isAtSameMomentAs(today)) {
      return theme.colorScheme.primary; // Gold
    }
    return theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6) ??
        Colors.grey;
  }

  Widget _buildTaskItem(TaskItem task) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(task.id ?? task.title),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        if (task.id != null) {
          _deleteTask(task.id!);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          onTap: () => _showTaskDialog(task),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleTask(task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: task.isCompleted ? 0 : 2,
                      ),
                      color: task.isCompleted
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: task.isCompleted
                        ? Icon(Icons.check,
                            size: 16, color: theme.colorScheme.onPrimary)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: task.isCompleted
                              ? FontWeight.normal
                              : FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.5)
                              : null,
                        ),
                      ),
                      if (task.relatedCourse != null || task.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              if (task.relatedCourse != null)
                                Row(
                                  children: [
                                    Icon(Icons.school,
                                        size: 14,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withValues(alpha: 0.5)),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.relatedCourse!,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: theme
                                              .textTheme.bodyMedium?.color
                                              ?.withValues(alpha: 0.7)),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              if (task.dueDate != null && task.dueDate!.isNotEmpty)
                                Builder(builder: (context) {
                                  final parsedDate = DateTime.tryParse(task.dueDate!);
                                  if (parsedDate == null) return const SizedBox.shrink();
                                  return Row(
                                    children: [
                                      Icon(Icons.event,
                                          size: 14,
                                          color: _getDueDateColor(
                                              parsedDate,
                                              theme,
                                              task.isCompleted)),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d').format(parsedDate),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _getDueDateColor(
                                              parsedDate,
                                              theme,
                                              task.isCompleted),
                                          fontWeight: FontWeight.w500,
                                          decoration: task.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                  onPressed: () => _confirmDeleteTask(task),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTask(TaskItem task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && task.id != null) {
      await _deleteTask(task.id!);
    }
  }
}
