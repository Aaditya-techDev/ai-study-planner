import '../local/sqlite_helper.dart';
import '../models/academic_task_model.dart';
import '../remote/firestore_sync_service.dart';

/// Repository for Academic Tasks (Assignments and Exams)
class TaskRepository {
  final SQLiteHelper _sqliteHelper;
  final FirestoreSyncService _syncService;

  TaskRepository({
    SQLiteHelper? sqliteHelper,
    FirestoreSyncService? syncService,
  })  : _sqliteHelper = sqliteHelper ?? SQLiteHelper.instance,
        _syncService = syncService ?? FirestoreSyncService();

  Future<List<AcademicTask>> getTasks() async {
    return await _sqliteHelper.getAllTasks();
  }

  Future<List<AcademicTask>> getPendingTasks() async {
    return await _sqliteHelper.getPendingTasks();
  }

  Future<void> addTask(AcademicTask task) async {
    // 1. Save to SQLite
    await _sqliteHelper.insertTask(task);

    // 2. Sync to Cloud Firestore
    _syncService.syncTaskToCloud(task);
  }

  Future<void> updateTask(AcademicTask task) async {
    await _sqliteHelper.updateTask(task);
    _syncService.syncTaskToCloud(task);
  }

  Future<void> deleteTask(String taskId) async {
    await _sqliteHelper.deleteTask(taskId);
  }

  Future<void> toggleTaskStatus(AcademicTask task) async {
    final newStatus = task.isComplete ? 'Pending' : 'Complete';
    final updated = task.copyWith(status: newStatus);
    await updateTask(updated);
  }
}
