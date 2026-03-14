class ScheduleEvent {
  final int? id;
  final String title;
  final String startTime; // Format: HH:mm (optional for untimed tasks)
  final String endTime;   // Format: HH:mm (optional for untimed tasks)
  final String? professor;
  String? section;
  final String type;      // 'class' or 'task'
  final String? notes;
  final bool completed;
  final bool isImported;
  final String date;       // Format: YYYY-MM-DD

  ScheduleEvent({
    this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.professor,
    this.section, // Made non-final
    required this.type,
    this.notes,
    this.completed = false,
    this.isImported = false,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime,
      'end_time': endTime,
      'professor': professor,
      'section': section,
      'type': type,
      'notes': notes,
      'completed': completed ? 1 : 0,
      'is_imported': isImported ? 1 : 0,
      'date': date,
    };
  }

  factory ScheduleEvent.fromMap(Map<String, dynamic> map) {
    return ScheduleEvent(
      id: map['id'] as int?,
      title: map['title']?.toString() ?? '',
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      professor: map['professor']?.toString(),
      section: map['section']?.toString(),
      type: map['type']?.toString() ?? 'class',
      notes: map['notes']?.toString(),
      completed: (map['completed'] is bool) ? map['completed'] as bool : map['completed'] == 1,
      isImported: (map['is_imported'] is bool) ? map['is_imported'] as bool : map['is_imported'] == 1,
      date: map['date']?.toString() ?? '',
    );
  }
}
