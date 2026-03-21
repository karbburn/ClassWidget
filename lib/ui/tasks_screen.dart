import 'package:flutter/material.dart';
import '../models/task_item.dart';
import '../database/database_helper.dart';
import '../services/widget_data_service.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final dbHelper = DatabaseHelper();
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final taskMaps = await dbHelper.getTasks();
    setState(() {
      _tasks = taskMaps.map((m) => TaskItem.fromMap(m)).toList();
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(TaskItem task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await dbHelper.updateTask(updated.toMap());
    _loadTasks();
    await WidgetDataService.refreshWidget(immediate: true);
  }

  Future<void> _deleteTask(int id) async {
    await dbHelper.deleteTask(id);
    _loadTasks();
    await WidgetDataService.refreshWidget(immediate: true);
  }

  void _showTaskDialog([TaskItem? task]) {
    final titleController = TextEditingController(text: task?.title);
    final courseController = TextEditingController(text: task?.relatedCourse);
    DateTime? selectedDate = task?.dueDate != null ? DateTime.parse(task!.dueDate!) : null;

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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ]
            ),
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
                      color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  task == null ? 'New Task' : 'Edit Task',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: theme.colorScheme.primary, // Selection color
                              onPrimary: theme.colorScheme.onPrimary,
                              surface: theme.colorScheme.surface,
                              onSurface: theme.textTheme.bodyLarge?.color ?? Colors.black,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: theme.inputDecorationTheme.labelStyle?.color),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate == null 
                            ? 'Set Due Date' 
                            : 'Due: ${DateFormat('MMM d, yyyy').format(selectedDate!)}',
                          style: TextStyle(
                            color: selectedDate == null 
                                ? theme.inputDecorationTheme.labelStyle?.color 
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.edit_calendar, color: theme.inputDecorationTheme.labelStyle?.color, size: 20),
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
                      relatedCourse: courseController.text.trim().isEmpty ? null : courseController.text.trim(),
                      dueDate: selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null,
                      isCompleted: task?.isCompleted ?? false,
                    );

                    if (task == null) {
                      await dbHelper.insertTask(newTask.toMap());
                    } else {
                      await dbHelper.updateTask(newTask.toMap());
                    }

                    if (mounted) Navigator.pop(context);
                    _loadTasks();
                    await WidgetDataService.refreshWidget(immediate: true);
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
          : _tasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskItem(task);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add_task),
        label: const Text('New Task'),
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
              border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2), width: 2),
            ),
            child: Icon(Icons.assignment_turned_in_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up! 🎉',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add homework or reminders to stay organized.',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Color _getDueDateColor(DateTime date, ThemeData theme, bool isCompleted) {
    if (isCompleted) return theme.textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);

    if (dueDate.isBefore(today)) return const Color(0xFFEF4444); // Red
    if (dueDate.isAtSameMomentAs(today)) return theme.colorScheme.primary; // Gold
    return theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
  }

  Widget _buildTaskItem(TaskItem task) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: ValueKey(task.id),
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
      onDismissed: (_) => _deleteTask(task.id!),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: theme.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
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
                        color: task.isCompleted ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: task.isCompleted ? 0 : 2,
                      ),
                      color: task.isCompleted ? theme.colorScheme.primary : Colors.transparent,
                    ),
                    child: task.isCompleted 
                        ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
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
                          fontWeight: task.isCompleted ? FontWeight.normal : FontWeight.w600,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5) : null,
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
                                    Icon(Icons.school, size: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                                    const SizedBox(width: 4),
                                    Text(
                                      task.relatedCourse!, 
                                      style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              if (task.dueDate != null)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event, 
                                      size: 14, 
                                      color: _getDueDateColor(DateTime.parse(task.dueDate!), theme, task.isCompleted)
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('MMM d').format(DateTime.parse(task.dueDate!)),
                                      style: TextStyle(
                                        fontSize: 13, 
                                        color: _getDueDateColor(DateTime.parse(task.dueDate!), theme, task.isCompleted), 
                                        fontWeight: FontWeight.w500,
                                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
