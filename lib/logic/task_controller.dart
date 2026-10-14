import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/academic_task_model.dart';
import '../data/repositories/task_repository.dart';
import '../services/notification_service.dart';

/// Controller managing state, filtering, urgency sorting, and local/cloud persistence
/// for Academic Tasks (Assignments and Examinations).
class TaskController extends ChangeNotifier {
  final TaskRepository _repository;
  final NotificationService _notificationService;
  final Uuid _uuid = const Uuid();

  List<AcademicTask> _tasks = [];
  String _selectedFilter = 'All'; // 'All', 'Assignment', 'Exam'
  String _statusFilter = 'All'; // 'All', 'Pending', 'Complete'
  bool _isLoading = false;
  String? _errorMessage;

  TaskController({
    TaskRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? TaskRepository(),
        _notificationService = notificationService ?? NotificationService.instance {
    loadTasks();
  }

  // Getters
  List<AcademicTask> get tasks => List.unmodifiable(_tasks);
  String get selectedFilter => _selectedFilter;
  String get statusFilter => _statusFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get completedCount => _tasks.where((t) => t.isComplete).length;
  int get pendingCount => _tasks.where((t) => t.isPending).length;
  int get totalCount => _tasks.length;
  double get completionPercentage =>
      _tasks.isEmpty ? 0.0 : (completedCount / _tasks.length);

  /// Returns tasks filtered by type and status, strictly sorted by academic urgency:
  /// 1. Pending tasks precede completed tasks.
  /// 2. Nearest deadline (earliest due date) first.
  /// 3. Higher priority ('High' > 'Medium' > 'Low').
  /// 4. Higher workload hours.
  List<AcademicTask> get filteredTasks {
    final filtered = _tasks.where((t) {
      final matchesType = _selectedFilter == 'All' || t.type.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesStatus = _statusFilter == 'All' ||
          (_statusFilter == 'Pending' && t.isPending) ||
          (_statusFilter == 'Complete' && t.isComplete);
      return matchesType && matchesStatus;
    }).toList();

    filtered.sort((a, b) => _compareTasksByUrgency(a, b));
    return filtered;
  }

  /// Sets the type filter ('All', 'Assignment', 'Exam')
  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Sets the status filter ('All', 'Pending', 'Complete')
  void setStatusFilter(String status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      notifyListeners();
    }
  }

  /// Loads tasks from local SQLite repository and schedules device deadline alarms.
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();

      // Seed initial sample academic tasks ONLY on the very first launch if database is pristine
      final prefs = await SharedPreferences.getInstance();
      final hasSeeded = prefs.getBool(AppConstants.keyTasksSeeded) ?? false;

      if (!hasSeeded && _tasks.isEmpty) {
        await _seedSampleTasks();
        await prefs.setBool(AppConstants.keyTasksSeeded, true);
        _tasks = await _repository.getTasks();
      }

      // Automatically sort master list by urgency
      _tasks.sort((a, b) => _compareTasksByUrgency(a, b));

      // Schedule device 24h reminders for all pending assessments
      await _notificationService.scheduleAllTaskDeadlines(_tasks);
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new AcademicTask in 3 taps or fewer from the UI.
  /// Persists to SQLite first, queues for Firestore sync, and schedules deadline alarms.
  Future<AcademicTask> addTask({
    required String subject,
    required String title,
    required String type,
    required String dueDate,
    required String priority,
    required int estWorkload,
  }) async {
    final task = AcademicTask(
      taskId: _uuid.v4(),
      subject: subject.trim(),
      title: title.trim(),
      type: type,
      dueDate: dueDate,
      priority: priority,
      estWorkload: estWorkload,
      status: 'Pending',
    );

    try {
      await _repository.addTask(task);
      await _notificationService.scheduleTaskDeadlineNotification(task);
      await loadTasks();
      return task;
    } catch (e) {
      _errorMessage = 'Failed to save task: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing AcademicTask in SQLite and cloud sync.
  Future<void> updateTask(AcademicTask task) async {
    try {
      await _repository.updateTask(task);
      if (task.isPending) {
        await _notificationService.scheduleTaskDeadlineNotification(task);
      }
      await loadTasks();
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      notifyListeners();
    }
  }

  /// Toggles task status between 'Pending' and 'Complete'.
  Future<void> toggleTaskStatus(AcademicTask task) async {
    try {
      await _repository.toggleTaskStatus(task);
      await loadTasks();
    } catch (e) {
      _errorMessage = 'Failed to toggle task status: $e';
      notifyListeners();
    }
  }

  /// Deletes a task from SQLite and refreshes state.
  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      await loadTasks();
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      notifyListeners();
    }
  }

  /// Comparator ordering tasks by urgency:
  /// - Pending assessments prioritized before Completed assessments
  /// - Closest deadline first (ascending dueDate)
  /// - Priority weight (High=3 > Medium=2 > Low=1)
  /// - Workload hours descending
  int _compareTasksByUrgency(AcademicTask a, AcademicTask b) {
    if (a.isPending && b.isComplete) return -1;
    if (a.isComplete && b.isPending) return 1;

    // Compare due dates (e.g. '2026-10-15' vs '2026-10-18')
    final dateComp = a.dueDate.compareTo(b.dueDate);
    if (dateComp != 0) return dateComp;

    // If due on the same date, compare priority weight
    final pA = _priorityScore(a.priority);
    final pB = _priorityScore(b.priority);
    if (pA != pB) return pB.compareTo(pA);

    // If priority is equal, compare workload
    return b.estWorkload.compareTo(a.estWorkload);
  }

  int _priorityScore(String priority) {
    switch (priority.trim().toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
      default:
        return 1;
    }
  }

  /// Seeds realistic AUT university tertiary coursework tasks for cold-start demo
  Future<void> _seedSampleTasks() async {
    final now = DateTime.now();
    final sampleTasks = [
      AcademicTask(
        taskId: _uuid.v4(),
        subject: 'COMP826',
        title: 'Assignment 2 - Flutter Mobile App',
        type: 'Assignment',
        dueDate: now.add(const Duration(days: 3)).toIso8601String().split('T').first,
        priority: 'High',
        estWorkload: 8,
        status: 'Pending',
      ),
      AcademicTask(
        taskId: _uuid.v4(),
        subject: 'COMP806',
        title: 'Software Architecture Synthesis Report',
        type: 'Assignment',
        dueDate: now.add(const Duration(days: 6)).toIso8601String().split('T').first,
        priority: 'Medium',
        estWorkload: 5,
        status: 'Pending',
      ),
      AcademicTask(
        taskId: _uuid.v4(),
        subject: 'COMP811',
        title: 'Research Methodology Final Examination',
        type: 'Exam',
        dueDate: now.add(const Duration(days: 10)).toIso8601String().split('T').first,
        priority: 'High',
        estWorkload: 12,
        status: 'Pending',
      ),
      AcademicTask(
        taskId: _uuid.v4(),
        subject: 'COMP826',
        title: 'Milestone 1 Scoping & Architectural Spec',
        type: 'Assignment',
        dueDate: now.subtract(const Duration(days: 14)).toIso8601String().split('T').first,
        priority: 'High',
        estWorkload: 6,
        status: 'Complete',
      ),
    ];

    for (final task in sampleTasks) {
      await _repository.addTask(task);
    }
  }
}
