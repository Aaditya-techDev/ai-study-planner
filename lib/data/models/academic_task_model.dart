/// Represents an academic assessment (Assignment or Exam) to complete.
class AcademicTask {
  final String taskId;
  final String subject;
  final String title;
  final String type; // 'Assignment' or 'Exam'
  final String dueDate; // 'YYYY-MM-DD'
  final String priority; // 'High', 'Medium', 'Low'
  final int estWorkload; // In hours
  final String status; // 'Pending' or 'Complete'

  const AcademicTask({
    required this.taskId,
    required this.subject,
    required this.title,
    required this.type,
    required this.dueDate,
    required this.priority,
    required this.estWorkload,
    this.status = 'Pending',
  });

  bool get isComplete => status.toLowerCase() == 'complete';
  bool get isPending => !isComplete;

  AcademicTask copyWith({
    String? taskId,
    String? subject,
    String? title,
    String? type,
    String? dueDate,
    String? priority,
    int? estWorkload,
    String? status,
  }) {
    return AcademicTask(
      taskId: taskId ?? this.taskId,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      estWorkload: estWorkload ?? this.estWorkload,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'subject': subject,
      'title': title,
      'type': type,
      'dueDate': dueDate,
      'priority': priority,
      'estWorkload': estWorkload,
      'status': status,
    };
  }

  factory AcademicTask.fromMap(Map<String, dynamic> map) {
    return AcademicTask(
      taskId: map['taskId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? 'Assignment',
      dueDate: map['dueDate'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      estWorkload: (map['estWorkload'] as num?)?.toInt() ?? 2,
      status: map['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory AcademicTask.fromJson(Map<String, dynamic> json) =>
      AcademicTask.fromMap(json);
}
