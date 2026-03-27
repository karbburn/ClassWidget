import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/schedule_event.dart';
import '../providers/widget_data_provider.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final ScheduleEvent? eventToEdit;
  const AddTaskScreen({super.key, this.eventToEdit});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _notesController.text = event.notes ?? '';
      _selectedDate = DateTime.parse(event.date);
      if (event.startTime.isNotEmpty) {
        final parts = event.startTime.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
        if (hour != null && minute != null) {
          _startTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
      if (event.endTime.isNotEmpty) {
        final parts = event.endTime.split(':');
        final hour = int.tryParse(parts[0]);
        final minute = parts.length > 1 ? int.tryParse(parts[1]) : 0;
        if (hour != null && minute != null) {
          _endTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startTime != null && _endTime != null) {
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time')),
        );
        return;
      }
    }

    final task = ScheduleEvent(
      id: widget.eventToEdit?.id,
      title: _titleController.text,
      startTime: _startTime != null
          ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
          : '',
      endTime: _endTime != null
          ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
          : '',
      type: 'task',
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      completed: widget.eventToEdit?.completed ?? false,
      isImported: false,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );

    if (widget.eventToEdit != null) {
      final taskMap = {
        'id': widget.eventToEdit!.id,
        'title': _titleController.text,
        'start_time': _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : '',
        'end_time': _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : '',
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'is_completed': widget.eventToEdit!.completed ? 1 : 0,
        'due_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'related_course': null,
      };
      await DatabaseHelper().updateTask(taskMap);
    } else {
      await DatabaseHelper().insertEvent(task);
    }
    await ref.read(widgetRefreshProvider).refresh(immediate: true);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventToEdit == null ? 'Add Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle:
                    Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
                leading: const Icon(Icons.calendar_today),
                trailing: const Icon(Icons.edit, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(_startTime?.format(context) ?? 'Optional'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _startTime = picked);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(_endTime?.format(context) ?? 'Optional'),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _endTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              if (_startTime != null || _endTime != null)
                TextButton(
                  onPressed: () => setState(() {
                    _startTime = null;
                    _endTime = null;
                  }),
                  child: const Text('Clear Times'),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                    widget.eventToEdit == null ? 'Save Task' : 'Update Task'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
