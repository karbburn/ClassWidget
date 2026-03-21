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
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                task == null ? 'Add New Task' : 'Edit Task',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(
                  labelText: 'Related Course (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(selectedDate == null 
                  ? 'Set Due Date' 
                  : 'Due: ${DateFormat('MMM d, yyyy').format(selectedDate!)}'),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit_calendar),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 24),
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(task == null ? 'CREATE TASK' : 'SAVE CHANGES'),
              ),
            ],
          ),
        ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No tasks yet!', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Add homework or reminders to stay organized.', style: TextStyle(color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskItem task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => _showTaskDialog(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleTask(task),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    if (task.relatedCourse != null || task.dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            if (task.relatedCourse != null)
                              Row(
                                children: [
                                  const Icon(Icons.school, size: 12, color: Colors.blueGrey),
                                  const SizedBox(width: 4),
                                  Text(task.relatedCourse!, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                  const SizedBox(width: 12),
                                ],
                              ),
                            if (task.dueDate != null)
                              Row(
                                children: [
                                  const Icon(Icons.event, size: 12, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d').format(DateTime.parse(task.dueDate!)),
                                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _deleteTask(task.id!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
