class TaskItem {
  final int? id;
  final String title;
  final String? dueDate; // yyyy-MM-dd
  final String? relatedCourse;
  final bool isCompleted;

  TaskItem({
    this.id,
    required this.title,
    this.dueDate,
    this.relatedCourse,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'due_date': dueDate,
      'related_course': relatedCourse,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'],
      title: map['title'],
      dueDate: map['due_date'],
      relatedCourse: map['related_course'],
      isCompleted: map['is_completed'] == 1,
    );
  }

  TaskItem copyWith({
    int? id,
    String? title,
    String? dueDate,
    String? relatedCourse,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      relatedCourse: relatedCourse ?? this.relatedCourse,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
