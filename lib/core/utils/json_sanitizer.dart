import 'dart:convert';
import '../../data/models/academic_task_model.dart';
import '../../data/models/timetable_entry_model.dart';

/// Helper to sanitize and format data payloads sent to external AI APIs.
/// Strictly enforces privacy constraints:
/// - Strips user email, userId, student IDs, personal names.
/// - Encodes only anonymous task constraints and timetable commitments.
class JsonSanitizer {
  static Map<String, dynamic> buildSanitizedAiPayload({
    required List<AcademicTask> incompleteTasks,
    required List<TimetableEntry> timetableEntries,
    required int availableDailyHours,
    required DateTime scheduleStartDate,
    int daysToSchedule = 7,
  }) {
    // 1. Sanitize academic tasks (only academic metadata)
    final sanitizedTasks = incompleteTasks.map((t) {
      return {
        'taskId': t.taskId,
        'subject': t.subject,
        'title': t.title,
        'type': t.type,
        'dueDate': t.dueDate,
        'priority': t.priority,
        'estWorkloadHours': t.estWorkload,
      };
    }).toList();

    // 2. Sanitize fixed commitments (day, time slots, subject)
    final sanitizedTimetable = timetableEntries.map((e) {
      return {
        'day': e.day,
        'startTime': e.startTime,
        'endTime': e.endTime,
        'subject': e.subject,
      };
    }).toList();

    return {
      'metadata': {
        'planningHorizonDays': daysToSchedule,
        'availableDailyStudyHours': availableDailyHours,
        'startDate': scheduleStartDate.toIso8601String().split('T').first,
      },
      'tasks': sanitizedTasks,
      'staticTimetableCommitments': sanitizedTimetable,
    };
  }

  static String toJsonString(Map<String, dynamic> payload) {
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
