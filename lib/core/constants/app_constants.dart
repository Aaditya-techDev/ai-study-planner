/// Application Constants and Configuration Settings
class AppConstants {
  static const String appName = 'AI Study Planner';
  static const String appVersion = '1.0.0';
  static const String subtitle = 'Smart Academic Scheduler for Tertiary Students';

  // SQLite Database Configuration
  static const String databaseName = 'ai_study_planner.db';
  static const int databaseVersion = 1;

  // Table Names
  static const String tableUsers = 'users';
  static const String tableTimetable = 'timetable_entries';
  static const String tableTasks = 'academic_tasks';
  static const String tableStudySessions = 'study_sessions';
  static const String tableStudyPlans = 'study_plans';

  // SharedPreferences Keys
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyAvailableHours = 'available_study_hours';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyDeadlineAlertsEnabled = 'deadline_alerts_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyActiveUserId = 'active_user_id';
  static const String keyTasksSeeded = 'tasks_seeded_v1';
  static const String keyTimetableSeeded = 'timetable_seeded_v1';
  static const String keyWebTasks = 'web_academic_tasks_cache';
  static const String keyWebTimetable = 'web_timetable_cache';
  static const String keyWebSessions = 'web_sessions_cache';
  static const String keyWebActivePlan = 'web_active_plan_cache';
  static const String keyWebUsers = 'web_users_cache';

  // Defaults
  static const int defaultAvailableHours = 4; // Daily study target
  static const String defaultGeminiModel = 'gemini-1.5-flash';
  
  // Day of week abbreviations
  static const List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  static const List<String> taskTypes = ['Assignment', 'Exam'];
  static const List<String> taskPriorities = ['High', 'Medium', 'Low'];
}
