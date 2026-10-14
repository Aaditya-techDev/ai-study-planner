import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_planner/core/utils/date_time_utils.dart';
import 'package:ai_study_planner/core/utils/json_sanitizer.dart';
import 'package:ai_study_planner/data/models/academic_task_model.dart';
import 'package:ai_study_planner/data/models/timetable_entry_model.dart';
import 'package:ai_study_planner/data/models/study_session_model.dart';
import 'package:ai_study_planner/data/models/study_plan_model.dart';

void main() {
  group('AI Study Planner Unit Tests', () {
    test('AcademicTask Model Serialization & Status', () {
      final task = AcademicTask(
        taskId: 't1',
        subject: 'COMP826',
        title: 'Assignment 2',
        type: 'Assignment',
        dueDate: '2026-10-15',
        priority: 'High',
        estWorkload: 6,
        status: 'Pending',
      );

      expect(task.isPending, isTrue);
      expect(task.isComplete, isFalse);

      final map = task.toMap();
      expect(map['taskId'], 't1');
      expect(map['subject'], 'COMP826');

      final reconstructed = AcademicTask.fromMap(map);
      expect(reconstructed.title, 'Assignment 2');
      expect(reconstructed.estWorkload, 6);
    });

    test('TimetableEntry Model Serialization', () {
      final entry = TimetableEntry(
        entryId: 'e1',
        subject: 'COMP826 Lecture',
        day: 'Monday',
        startTime: '10:00',
        endTime: '12:00',
        location: 'WG-401',
      );

      final map = entry.toMap();
      final fromMap = TimetableEntry.fromMap(map);
      expect(fromMap.subject, 'COMP826 Lecture');
      expect(fromMap.day, 'Monday');
      expect(fromMap.startTime, '10:00');
    });

    test('StudyPlan & StudySession Serialization', () {
      final session = StudySession(
        sessionId: 's1',
        taskId: 't1',
        date: '2026-10-12',
        startTime: '14:00',
        duration: 90,
        status: 'Pending',
        subject: 'COMP826',
        taskTitle: 'Assignment 2',
      );

      final plan = StudyPlan(
        planId: 'p1',
        createdAt: '2026-10-11T12:00:00Z',
        sessions: [session],
      );

      final map = plan.toMap();
      final restored = StudyPlan.fromMap(map);
      expect(restored.sessions.length, 1);
      expect(restored.sessions.first.duration, 90);
    });

    test('Zero PII Sanitizer Test', () {
      final tasks = [
        AcademicTask(
          taskId: 't1',
          subject: 'COMP826',
          title: 'Assignment 2',
          type: 'Assignment',
          dueDate: '2026-10-15',
          priority: 'High',
          estWorkload: 6,
        ),
      ];

      final timetable = [
        TimetableEntry(
          entryId: 'e1',
          subject: 'Lecture',
          day: 'Monday',
          startTime: '10:00',
          endTime: '12:00',
          location: 'WG-401',
        ),
      ];

      final payload = JsonSanitizer.buildSanitizedAiPayload(
        incompleteTasks: tasks,
        timetableEntries: timetable,
        availableDailyHours: 4,
        scheduleStartDate: DateTime(2026, 10, 11),
      );

      final jsonString = JsonSanitizer.toJsonString(payload);

      // Verify no PII is present
      expect(jsonString.contains('email'), isFalse);
      expect(jsonString.contains('userId'), isFalse);
      expect(jsonString.contains('studentId'), isFalse);
      expect(jsonString.contains('name'), isFalse);

      // Verify academic constraints are present
      expect(jsonString.contains('COMP826'), isTrue);
      expect(jsonString.contains('availableDailyStudyHours'), isTrue);
    });

    test('DateTimeUtils Date formatting and calculation', () {
      final today = DateTime.now();
      final dateStr = DateTimeUtils.formatDate(today);
      expect(dateStr, isNotEmpty);

      final target = today.add(const Duration(days: 2));
      final remaining = DateTimeUtils.daysRemaining(target);
      expect(remaining, 2);
    });
  });
}
