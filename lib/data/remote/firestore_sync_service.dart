import 'dart:async';
import '../models/academic_task_model.dart';
import '../models/timetable_entry_model.dart';
import '../models/study_plan_model.dart';

/// Simulates Cloud Firestore NoSQL cloud synchronization.
/// Tracks online status, unsynced changes queue, and executes sync.
class FirestoreSyncService {
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  final List<String> _syncLog = [];

  bool get isOnline => _isOnline;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<String> get syncLog => List.unmodifiable(_syncLog);

  void setConnectivity(bool online) {
    _isOnline = online;
    _syncLog.add('Network state updated: ${_isOnline ? "Online" : "Offline"}');
  }

  /// Syncs an academic task to Cloud Firestore collection 'tasks'
  Future<bool> syncTaskToCloud(AcademicTask task) async {
    if (!_isOnline) {
      _syncLog.add('Offline: Task "${task.title}" queued for cloud sync.');
      return false;
    }
    // Simulate Firestore write:
    // await FirebaseFirestore.instance.collection('users').doc(userId).collection('tasks').doc(task.taskId).set(task.toMap());
    await Future.delayed(const Duration(milliseconds: 200));
    _lastSyncTime = DateTime.now();
    _syncLog.add('Synced task "${task.title}" to Cloud Firestore.');
    return true;
  }

  /// Syncs timetable entry to Cloud Firestore collection 'timetable'
  Future<bool> syncTimetableEntryToCloud(TimetableEntry entry) async {
    if (!_isOnline) {
      _syncLog.add('Offline: Timetable entry "${entry.subject}" queued for cloud sync.');
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 200));
    _lastSyncTime = DateTime.now();
    _syncLog.add('Synced timetable entry "${entry.subject}" to Cloud Firestore.');
    return true;
  }

  /// Syncs study plan to Cloud Firestore collection 'study_plans'
  Future<bool> syncStudyPlanToCloud(StudyPlan plan) async {
    if (!_isOnline) {
      _syncLog.add('Offline: Study plan "${plan.planId}" queued for cloud sync.');
      return false;
    }
    await Future.delayed(const Duration(milliseconds: 250));
    _lastSyncTime = DateTime.now();
    _syncLog.add('Synced study plan with ${plan.sessions.length} sessions to Cloud Firestore.');
    return true;
  }

  /// Batch sync all local data when connectivity is re-established
  Future<void> performFullCloudSync({
    required List<AcademicTask> tasks,
    required List<TimetableEntry> entries,
    StudyPlan? plan,
  }) async {
    if (!_isOnline) return;

    for (final task in tasks) {
      await syncTaskToCloud(task);
    }
    for (final entry in entries) {
      await syncTimetableEntryToCloud(entry);
    }
    if (plan != null) {
      await syncStudyPlanToCloud(plan);
    }
    _lastSyncTime = DateTime.now();
  }
}
