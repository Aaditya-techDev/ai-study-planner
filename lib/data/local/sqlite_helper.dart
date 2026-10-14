import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/timetable_entry_model.dart';
import '../models/academic_task_model.dart';
import '../models/study_session_model.dart';
import '../models/study_plan_model.dart';

/// Production-ready Offline-First SQLite Local Database Helper with seamless Web fallback.
/// Ensures full CRUD operations on mobile (Android/iOS) and persistent SharedPreferences/in-memory on Web/Desktop.
class SQLiteHelper {
  static final SQLiteHelper instance = SQLiteHelper._init();
  static Database? _database;

  // Local caches for Flutter Web and test environments
  final Map<String, User> _webUsers = {};
  final Map<String, TimetableEntry> _webTimetable = {};
  final Map<String, AcademicTask> _webTasks = {};
  final Map<String, StudySession> _webSessions = {};
  StudyPlan? _webActivePlan;
  bool _isWebInitialized = false;

  SQLiteHelper._init();

  /// Ensures cached data is restored from local storage on Web
  Future<void> ensureInitialized() async {
    if (!kIsWeb || _isWebInitialized) return;
    _isWebInitialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Restore tasks
      final tasksJson = prefs.getString(AppConstants.keyWebTasks);
      if (tasksJson != null && tasksJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(tasksJson);
        for (final item in decoded) {
          final task = AcademicTask.fromMap(Map<String, dynamic>.from(item));
          _webTasks[task.taskId] = task;
        }
      }

      // Restore timetable
      final timetableJson = prefs.getString(AppConstants.keyWebTimetable);
      if (timetableJson != null && timetableJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(timetableJson);
        for (final item in decoded) {
          final entry = TimetableEntry.fromMap(Map<String, dynamic>.from(item));
          _webTimetable[entry.entryId] = entry;
        }
      }

      // Restore study sessions
      final sessionsJson = prefs.getString(AppConstants.keyWebSessions);
      if (sessionsJson != null && sessionsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        for (final item in decoded) {
          final session = StudySession.fromMap(Map<String, dynamic>.from(item));
          _webSessions[session.sessionId] = session;
        }
      }

      // Restore active study plan
      final planJson = prefs.getString(AppConstants.keyWebActivePlan);
      if (planJson != null && planJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(planJson);
        _webActivePlan = StudyPlan.fromMap(decoded, loadedSessions: _webSessions.values.toList());
      }
    } catch (e) {
      debugPrint('Error restoring web cache: $e');
    }
  }

  Future<void> _persistWebTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webTasks.values.map((t) => t.toMap()).toList();
      await prefs.setString(AppConstants.keyWebTasks, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _persistWebTimetable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _webTimetable.values.map((e) => e.toMap()).toList();
      await prefs.setString(AppConstants.keyWebTimetable, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _persistWebPlanAndSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionList = _webSessions.values.map((s) => s.toMap()).toList();
      await prefs.setString(AppConstants.keyWebSessions, jsonEncode(sessionList));
      if (_webActivePlan != null) {
        await prefs.setString(AppConstants.keyWebActivePlan, jsonEncode(_webActivePlan!.toMap()));
      } else {
        await prefs.remove(AppConstants.keyWebActivePlan);
      }
    } catch (_) {}
  }

  /// Returns the native SQLite database instance, or null if executing on Flutter Web.
  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        userId TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        preferences TEXT,
        availableStudyHours INTEGER NOT NULL DEFAULT 4
      )
    ''');

    // 2. Timetable entries table (Lectures, Labs, Tutorials)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTimetable} (
        entryId TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        day TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT
      )
    ''');

    // 3. Academic Tasks table (Assignments and Exams)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTasks} (
        taskId TEXT PRIMARY KEY,
        subject TEXT NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        priority TEXT NOT NULL,
        estWorkload INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending'
      )
    ''');

    // 4. Study Sessions table (AI Scheduled Blocks)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableStudySessions} (
        sessionId TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        duration INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending',
        subject TEXT,
        taskTitle TEXT
      )
    ''');

    // 5. Study Plans table (Container for active horizon plan)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableStudyPlans} (
        planId TEXT PRIMARY KEY,
        createdAt TEXT NOT NULL,
        status TEXT NOT NULL,
        sessionsJson TEXT
      )
    ''');
  }

  // ==========================================
  //               USER CRUD
  // ==========================================

  Future<void> insertUser(User user) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webUsers[user.userId] = user;
      return;
    }
    final db = await database;
    await db?.insert(
      AppConstants.tableUsers,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getUser(String userId) async {
    if (kIsWeb) {
      await ensureInitialized();
      return _webUsers[userId];
    }
    final db = await database;
    final maps = await db?.query(
      AppConstants.tableUsers,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    if (maps != null && maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webUsers[user.userId] = user;
      return;
    }
    final db = await database;
    await db?.update(
      AppConstants.tableUsers,
      user.toMap(),
      where: 'userId = ?',
      whereArgs: [user.userId],
    );
  }

  // ==========================================
  //            TIMETABLE CRUD
  // ==========================================

  Future<List<TimetableEntry>> getAllTimetableEntries() async {
    if (kIsWeb) {
      await ensureInitialized();
      final list = _webTimetable.values.toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    }
    final db = await database;
    final result = await db?.query(
      AppConstants.tableTimetable,
      orderBy: 'startTime ASC',
    );
    return result?.map((json) => TimetableEntry.fromMap(json)).toList() ?? [];
  }

  Future<void> insertTimetableEntry(TimetableEntry entry) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webTimetable[entry.entryId] = entry;
      await _persistWebTimetable();
      return;
    }
    final db = await database;
    await db?.insert(
      AppConstants.tableTimetable,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webTimetable[entry.entryId] = entry;
      await _persistWebTimetable();
      return;
    }
    final db = await database;
    await db?.update(
      AppConstants.tableTimetable,
      entry.toMap(),
      where: 'entryId = ?',
      whereArgs: [entry.entryId],
    );
  }

  Future<void> deleteTimetableEntry(String entryId) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webTimetable.remove(entryId);
      await _persistWebTimetable();
      return;
    }
    final db = await database;
    await db?.delete(
      AppConstants.tableTimetable,
      where: 'entryId = ?',
      whereArgs: [entryId],
    );
  }

  // ==========================================
  //           ACADEMIC TASKS CRUD
  // ==========================================

  Future<List<AcademicTask>> getAllTasks() async {
    if (kIsWeb) {
      await ensureInitialized();
      final list = _webTasks.values.toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    }
    final db = await database;
    final result = await db?.query(
      AppConstants.tableTasks,
      orderBy: 'dueDate ASC',
    );
    return result?.map((json) => AcademicTask.fromMap(json)).toList() ?? [];
  }

  Future<List<AcademicTask>> getPendingTasks() async {
    if (kIsWeb) {
      await ensureInitialized();
      final list = _webTasks.values.where((t) => t.isPending).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    }
    final db = await database;
    final result = await db?.query(
      AppConstants.tableTasks,
      where: "status = 'Pending'",
      orderBy: 'dueDate ASC',
    );
    return result?.map((json) => AcademicTask.fromMap(json)).toList() ?? [];
  }

  Future<AcademicTask?> getTaskById(String taskId) async {
    if (kIsWeb) {
      await ensureInitialized();
      return _webTasks[taskId];
    }
    final db = await database;
    final result = await db?.query(
      AppConstants.tableTasks,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    if (result != null && result.isNotEmpty) {
      return AcademicTask.fromMap(result.first);
    }
    return null;
  }

  Future<void> insertTask(AcademicTask task) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webTasks[task.taskId] = task;
      await _persistWebTasks();
      return;
    }
    final db = await database;
    await db?.insert(
      AppConstants.tableTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(AcademicTask task) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webTasks[task.taskId] = task;
      await _persistWebTasks();
      return;
    }
    final db = await database;
    await db?.update(
      AppConstants.tableTasks,
      task.toMap(),
      where: 'taskId = ?',
      whereArgs: [task.taskId],
    );
  }

  Future<void> deleteTask(String taskId) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webTasks.remove(taskId);
      await _persistWebTasks();
      return;
    }
    final db = await database;
    await db?.delete(
      AppConstants.tableTasks,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }

  // ==========================================
  //      STUDY PLANS & SESSIONS CRUD
  // ==========================================

  /// Saves a newly generated StudyPlan.
  /// Uses an atomic SQLite database transaction to insert the plan record
  /// and replace all study sessions.
  Future<void> saveStudyPlan(StudyPlan plan) async {
    if (kIsWeb) {
      await ensureInitialized();
      _webActivePlan = plan;
      _webSessions.clear();
      for (final s in plan.sessions) {
        _webSessions[s.sessionId] = s;
      }
      await _persistWebPlanAndSessions();
      return;
    }

    final db = await database;
    await db?.transaction((txn) async {
      await txn.insert(
        AppConstants.tableStudyPlans,
        plan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Clear previous active sessions to ensure synchronization
      await txn.delete(AppConstants.tableStudySessions);

      for (final session in plan.sessions) {
        await txn.insert(
          AppConstants.tableStudySessions,
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Retrieves the latest active study plan with all scheduled study sessions.
  Future<StudyPlan?> getLatestStudyPlan() async {
    if (kIsWeb) {
      await ensureInitialized();
      return _webActivePlan;
    }

    final db = await database;
    final plans = await db?.query(
      AppConstants.tableStudyPlans,
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (plans == null || plans.isEmpty) return null;

    final sessionsResult = await db?.query(
      AppConstants.tableStudySessions,
      orderBy: 'date ASC, startTime ASC',
    );

    final sessions = sessionsResult
            ?.map((m) => StudySession.fromMap(m))
            .toList() ??
        [];

    return StudyPlan.fromMap(plans.first, loadedSessions: sessions);
  }

  /// Updates status for a single study session ('Pending' or 'Complete')
  Future<void> updateStudySessionStatus(String sessionId, String status) async {
    if (kIsWeb) {
      await ensureInitialized();
      final s = _webSessions[sessionId];
      if (s != null) {
        _webSessions[sessionId] = s.copyWith(status: status);
        if (_webActivePlan != null) {
          final updated = _webActivePlan!.sessions.map((x) {
            return x.sessionId == sessionId ? x.copyWith(status: status) : x;
          }).toList();
          _webActivePlan = _webActivePlan!.copyWith(sessions: updated);
        }
        await _persistWebPlanAndSessions();
      }
      return;
    }

    final db = await database;
    await db?.update(
      AppConstants.tableStudySessions,
      {'status': status},
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
  }

  /// Wipes all tables and in-memory caches (used for logout / app reset)
  Future<void> clearAllData() async {
    if (kIsWeb) {
      _webUsers.clear();
      _webTimetable.clear();
      _webTasks.clear();
      _webSessions.clear();
      _webActivePlan = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(AppConstants.keyWebTasks);
        await prefs.remove(AppConstants.keyWebTimetable);
        await prefs.remove(AppConstants.keyWebSessions);
        await prefs.remove(AppConstants.keyWebActivePlan);
        await prefs.remove(AppConstants.keyTasksSeeded);
        await prefs.remove(AppConstants.keyTimetableSeeded);
      } catch (_) {}
      return;
    }

    final db = await database;
    await db?.delete(AppConstants.tableUsers);
    await db?.delete(AppConstants.tableTimetable);
    await db?.delete(AppConstants.tableTasks);
    await db?.delete(AppConstants.tableStudySessions);
    await db?.delete(AppConstants.tableStudyPlans);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyTasksSeeded);
      await prefs.remove(AppConstants.keyTimetableSeeded);
    } catch (_) {}
  }

  /// Closes the SQLite database if initialized
  Future<void> close() async {
    if (!kIsWeb && _database != null) {
      await _database?.close();
      _database = null;
    }
  }
}
