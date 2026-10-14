import 'package:uuid/uuid.dart';
import '../local/sqlite_helper.dart';
import '../models/academic_task_model.dart';
import '../models/study_plan_model.dart';
import '../models/timetable_entry_model.dart';
import '../remote/firestore_sync_service.dart';
import '../remote/gemini_ai_service.dart';

class StudyPlanRepository {
  final SQLiteHelper _sqliteHelper;
  final GeminiAIService _aiService;
  final FirestoreSyncService _syncService;
  final Uuid _uuid = const Uuid();

  StudyPlanRepository({
    SQLiteHelper? sqliteHelper,
    GeminiAIService? aiService,
    FirestoreSyncService? syncService,
  })  : _sqliteHelper = sqliteHelper ?? SQLiteHelper.instance,
        _aiService = aiService ?? GeminiAIService(),
        _syncService = syncService ?? FirestoreSyncService();

  Future<StudyPlan?> getActiveStudyPlan() async {
    return await _sqliteHelper.getLatestStudyPlan();
  }

  Future<StudyPlan> generateNewStudyPlan({
    required List<AcademicTask> incompleteTasks,
    required List<TimetableEntry> timetableEntries,
    required int availableDailyHours,
    required String? apiKey,
  }) async {
    // 1. Call Gemini AI Service (or intelligent fallback)
    final sessions = await _aiService.generateSchedule(
      incompleteTasks: incompleteTasks,
      timetableEntries: timetableEntries,
      availableDailyHours: availableDailyHours,
      apiKey: apiKey,
    );

    // 2. Assemble new StudyPlan entity
    final plan = StudyPlan(
      planId: _uuid.v4(),
      createdAt: DateTime.now().toIso8601String(),
      status: 'Active',
      sessions: sessions,
    );

    // 3. Save to local SQLite database
    await _sqliteHelper.saveStudyPlan(plan);

    // 4. Asynchronously sync to Cloud Firestore
    _syncService.syncStudyPlanToCloud(plan);

    return plan;
  }

  Future<void> updateSessionStatus(String sessionId, String status) async {
    await _sqliteHelper.updateStudySessionStatus(sessionId, status);
  }
}
