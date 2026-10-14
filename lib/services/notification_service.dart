import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../data/models/academic_task_model.dart';
import '../data/models/study_session_model.dart';

/// Notification Service for Study Sessions and 24-hour Task Deadlines
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool notificationsEnabled = true;
  bool deadlineAlertsEnabled = true;

  NotificationService._init();

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _initialized = true;
  }

  /// Schedules a notification for the exact start time of a generated StudySession
  Future<void> scheduleStudySessionNotification(StudySession session) async {
    if (!notificationsEnabled || kIsWeb) return;

    try {
      final dateParts = session.date.split('-');
      final timeParts = session.startTime.split(':');
      if (dateParts.length != 3 || timeParts.length != 2) return;

      final sessionDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      // Only schedule if in future
      if (sessionDateTime.isBefore(DateTime.now())) return;

      final scheduledTz = tz.TZDateTime.from(sessionDateTime, tz.local);
      final notificationId = session.sessionId.hashCode.abs() % 100000;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Study Session Starting: ${session.subject ?? "Study Block"}',
        'Time to study ${session.taskTitle ?? "your academic task"} (${session.duration} mins)',
        scheduledTz,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'study_sessions_channel',
            'Study Sessions',
            channelDescription: 'Notifications for upcoming scheduled study sessions',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error scheduling session notification: $e');
    }
  }

  /// Schedules a notification exactly 24 hours before an AcademicTask due date
  Future<void> scheduleTaskDeadlineNotification(AcademicTask task) async {
    if (!deadlineAlertsEnabled || kIsWeb) return;

    try {
      final dateParts = task.dueDate.split('-');
      if (dateParts.length != 3) return;

      final dueDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        9, // 9:00 AM on due date
      );

      final reminderDateTime = dueDateTime.subtract(const Duration(hours: 24));
      if (reminderDateTime.isBefore(DateTime.now())) return;

      final scheduledTz = tz.TZDateTime.from(reminderDateTime, tz.local);
      final notificationId = (task.taskId.hashCode.abs() % 100000) + 100000;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '24h Deadline Alert: ${task.type}',
        '${task.title} (${task.subject}) is due in 24 hours!',
        scheduledTz,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadlines_channel',
            'Assessment Deadlines',
            channelDescription: '24-hour reminder before assignment and exam deadlines',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      print('Error scheduling deadline notification: $e');
    }
  }

  Future<void> scheduleAllPlanSessions(List<StudySession> sessions) async {
    for (final session in sessions) {
      if (!session.isComplete) {
        await scheduleStudySessionNotification(session);
      }
    }
  }

  Future<void> scheduleAllTaskDeadlines(List<AcademicTask> tasks) async {
    for (final task in tasks) {
      if (task.isPending) {
        await scheduleTaskDeadlineNotification(task);
      }
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
