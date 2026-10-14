import 'package:flutter/foundation.dart';
import '../data/models/academic_task_model.dart';
import '../data/models/study_plan_model.dart';
import '../data/models/study_session_model.dart';
import '../data/models/timetable_entry_model.dart';
import '../data/repositories/study_plan_repository.dart';
import '../services/notification_service.dart';

/// Controller managing AI study schedule generation, session status tracking,
/// date filtering, and persistence.
class StudyPlanController extends ChangeNotifier {
  final StudyPlanRepository _repository;
  final NotificationService _notificationService;

  StudyPlan? _activePlan;
  bool _isGenerating = false;
  String? _errorMessage;
  String _selectedDateFilter = 'All';

  StudyPlanController({
    StudyPlanRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? StudyPlanRepository(),
        _notificationService = notificationService ?? NotificationService.instance {
    loadActivePlan();
  }

  // Getters
  StudyPlan? get activePlan => _activePlan;
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String get selectedDateFilter => _selectedDateFilter;

  /// Returns all sessions sorted chronologically by date and start time
  List<StudySession> get allSessions {
    if (_activePlan == null) return [];
    final sessions = List<StudySession>.from(_activePlan!.sessions);
    sessions.sort((a, b) {
      final dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return a.startTime.compareTo(b.startTime);
    });
    return sessions;
  }

  /// Returns sessions filtered by selected calendar date filter
  List<StudySession> get filteredSessions {
    if (_activePlan == null) return [];
    final sessions = allSessions;
    if (_selectedDateFilter == 'All') return sessions;
    return sessions.where((s) => s.date == _selectedDateFilter).toList();
  }

  int get totalSessionsCount => allSessions.length;
  int get completedSessionsCount => allSessions.where((s) => s.isComplete).length;
  int get pendingSessionsCount => allSessions.where((s) => !s.isComplete).length;

  double get planProgress =>
      totalSessionsCount == 0 ? 0.0 : (completedSessionsCount / totalSessionsCount);

  /// Next incomplete session for display on the Home Dashboard
  StudySession? get nextUpcomingSession {
    final pending = allSessions.where((s) => !s.isComplete).toList();
    return pending.isNotEmpty ? pending.first : null;
  }

  /// Sets the active calendar date filter ('All' or 'YYYY-MM-DD')
  void setDateFilter(String dateStr) {
    if (_selectedDateFilter != dateStr) {
      _selectedDateFilter = dateStr;
      notifyListeners();
    }
  }

  /// Loads the most recent active study plan from local SQLite storage
  Future<void> loadActivePlan() async {
    try {
      _activePlan = await _repository.getActiveStudyPlan();
    } catch (e) {
      _errorMessage = 'Failed to load active study plan: $e';
    } finally {
      notifyListeners();
    }
  }

  /// Core AI Generation Workflow:
  /// 1. Validates presence of pending academic tasks.
  /// 2. Sanitizes input payload (Zero PII).
  /// 3. Queries Google Gemini 1.5 Flash (or runs onboard heuristic scheduler).
  /// 4. Saves newly generated plan to SQLite and queues Cloud Firestore sync.
  /// 5. Schedules device notification alarms for upcoming study sessions.
  Future<bool> generateOrRegeneratePlan({
    required List<AcademicTask> incompleteTasks,
    required List<TimetableEntry> timetableEntries,
    required int availableDailyHours,
    required String? apiKey,
  }) async {
    if (incompleteTasks.isEmpty) {
      _errorMessage = 'No pending academic tasks available to schedule.';
      notifyListeners();
      return false;
    }

    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPlan = await _repository.generateNewStudyPlan(
        incompleteTasks: incompleteTasks,
        timetableEntries: timetableEntries,
        availableDailyHours: availableDailyHours,
        apiKey: apiKey,
      );

      _activePlan = newPlan;
      _selectedDateFilter = 'All';

      // Schedule device alarm reminders for all generated sessions
      await _notificationService.scheduleAllPlanSessions(newPlan.sessions);

      _isGenerating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Plan generation failed: ${e.toString()}';
      _isGenerating = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggles session completion state, updates SQLite, and updates local reactive state.
  Future<void> toggleSessionStatus(StudySession session) async {
    if (_activePlan == null) return;

    final newStatus = session.isComplete ? 'Pending' : 'Complete';
    final updatedSession = session.copyWith(status: newStatus);

    try {
      await _repository.updateSessionStatus(session.sessionId, newStatus);

      final updatedList = _activePlan!.sessions.map((s) {
        return s.sessionId == session.sessionId ? updatedSession : s;
      }).toList();

      _activePlan = _activePlan!.copyWith(sessions: updatedList);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update study session: $e';
      notifyListeners();
    }
  }
}
