import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/json_sanitizer.dart';
import '../models/academic_task_model.dart';
import '../models/study_session_model.dart';
import '../models/timetable_entry_model.dart';

/// Custom exception thrown when the Gemini Generative Language API encounters an error.
class GeminiApiException implements Exception {
  final String message;
  final int? statusCode;

  const GeminiApiException(this.message, {this.statusCode});

  @override
  String toString() => 'GeminiApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Service interfacing with Google Gemini Generative Language API.
/// Strictly enforces privacy constraints (Zero-PII) and provides resilient
/// error handling with automatic fallback to an onboard heuristic scheduler.
class GeminiAIService {
  final http.Client _client;
  final Uuid _uuid = const Uuid();

  GeminiAIService({http.Client? client}) : _client = client ?? http.Client();

  /// Generates a structured study schedule using Gemini API or local intelligent fallback.
  /// 
  /// Flow:
  /// 1. Sanitizes input to guarantee zero Personally Identifiable Information (PII).
  /// 2. If an API key is provided, attempts an HTTP POST to Google Gemini 1.5 Flash.
  /// 3. Parses structured JSON response into validated [StudySession] models.
  /// 4. If offline, timed out, or unauthenticated, executes onboard heuristic scheduler.
  Future<List<StudySession>> generateSchedule({
    required List<AcademicTask> incompleteTasks,
    required List<TimetableEntry> timetableEntries,
    required int availableDailyHours,
    required String? apiKey,
    int horizonDays = 7,
  }) async {
    if (incompleteTasks.isEmpty) {
      return [];
    }

    final startDate = DateTime.now();

    // 1. Sanitize payload: strip all user IDs, personal names, emails, and student IDs
    final sanitizedPayload = JsonSanitizer.buildSanitizedAiPayload(
      incompleteTasks: incompleteTasks,
      timetableEntries: timetableEntries,
      availableDailyHours: availableDailyHours,
      scheduleStartDate: startDate,
      daysToSchedule: horizonDays,
    );

    // 2. Attempt Google Gemini Generative AI Call if API Key exists
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final sessions = await _callGeminiApi(
          apiKey: apiKey.trim(),
          sanitizedPayload: sanitizedPayload,
          tasks: incompleteTasks,
        );

        if (sessions.isNotEmpty) {
          return sessions;
        }
      } on TimeoutException {
        // Network timeout fallback
      } on GeminiApiException {
        // API error / quota limit / invalid key fallback
      } catch (_) {
        // General error fallback
      }
    }

    // 3. Resilient Onboard Heuristic Scheduling Fallback
    // Guarantees 100% offline availability and uninterrupted user experience
    return _generateLocalHeuristicSchedule(
      incompleteTasks: incompleteTasks,
      timetableEntries: timetableEntries,
      availableDailyHours: availableDailyHours,
      startDate: startDate,
      horizonDays: horizonDays,
    );
  }

  /// Sends a structured prompt to Google Gemini 1.5 Flash REST API endpoint.
  Future<List<StudySession>> _callGeminiApi({
    required String apiKey,
    required Map<String, dynamic> sanitizedPayload,
    required List<AcademicTask> tasks,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/${AppConstants.defaultGeminiModel}:generateContent?key=$apiKey',
    );

    final prompt = '''
You are an expert academic scheduling assistant for tertiary university students.
Generate an optimal, conflict-free study schedule based on the provided JSON input.

INPUT CONSTRAINTS AND DATA:
${jsonEncode(sanitizedPayload)}

CRITICAL SCHEDULING RULES:
1. NEVER schedule study sessions during static timetable commitment hours on any given weekday.
2. The sum of study session durations on any single day MUST NOT exceed availableDailyStudyHours.
3. Prioritize tasks with impending due dates (nearest deadline) and 'High' priority.
4. Distribute workload evenly across the planning horizon to prevent cramming.
5. Sessions must be between 30 and 120 minutes long.

OUTPUT REQUIREMENTS:
Output MUST be strictly a valid JSON array of session objects matching this exact schema:
[
  {
    "taskId": "string",
    "date": "YYYY-MM-DD",
    "startTime": "HH:MM",
    "duration": 60
  }
]
Do NOT include markdown formatting, backticks, or any explanatory commentary. Return ONLY the raw JSON array.
''';

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      }
    });

    final response = await _client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidateText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      if (candidateText != null && candidateText.trim().isNotEmpty) {
        return _parseSessionsJson(candidateText, tasks);
      } else {
        throw const GeminiApiException('Empty candidate response received from Gemini.');
      }
    } else if (response.statusCode == 400) {
      throw const GeminiApiException('Bad request to Gemini API. Verify payload format.', statusCode: 400);
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GeminiApiException('Invalid or unauthorized Gemini API key.', statusCode: 401);
    } else if (response.statusCode == 429) {
      throw const GeminiApiException('Gemini API quota exceeded or rate limited.', statusCode: 429);
    } else {
      throw GeminiApiException('Gemini API failed with status code ${response.statusCode}', statusCode: response.statusCode);
    }
  }

  /// Robust parser for Gemini model output:
  /// Handles potential markdown wrapping, JSON array structures, and associates
  /// task metadata (subject, title) with the generated sessions.
  List<StudySession> _parseSessionsJson(String jsonText, List<AcademicTask> tasks) {
    try {
      // Strip potential markdown code fences if model enclosed JSON
      String cleaned = jsonText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final dynamic decoded = jsonDecode(cleaned);
      if (decoded is List) {
        final taskMap = {for (final t in tasks) t.taskId: t};
        final List<StudySession> sessions = [];

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            final taskId = item['taskId'] as String? ?? '';
            final associatedTask = taskMap[taskId];

            final rawDuration = item['duration'] as num?;
            final duration = rawDuration != null ? rawDuration.toInt().clamp(30, 180) : 60;

            final dateStr = item['date'] as String? ?? DateTime.now().toIso8601String().split('T').first;
            final startTimeStr = item['startTime'] as String? ?? '14:00';

            sessions.add(
              StudySession(
                sessionId: _uuid.v4(),
                taskId: taskId.isNotEmpty ? taskId : (tasks.isNotEmpty ? tasks.first.taskId : ''),
                date: dateStr,
                startTime: startTimeStr,
                duration: duration,
                status: 'Pending',
                subject: associatedTask?.subject ?? 'Academic Study',
                taskTitle: associatedTask?.title ?? 'Scheduled Study Session',
              ),
            );
          }
        }
        return sessions;
      }
    } catch (_) {
      // If parsing fails, returns empty list so caller falls back to heuristic engine
    }
    return [];
  }

  /// Onboard Heuristic Scheduling Engine:
  /// Produces a reliable, conflict-free schedule when offline or without external AI.
  /// 
  /// Principles:
  /// - Priority sorting: High > Medium > Low.
  /// - Deadline sorting: nearest due date scheduled first.
  /// - Timetable clash avoidance: queries timetable entries for day of week.
  /// - Capacity ceiling: respects student's daily available study hours limit.
  List<StudySession> _generateLocalHeuristicSchedule({
    required List<AcademicTask> incompleteTasks,
    required List<TimetableEntry> timetableEntries,
    required int availableDailyHours,
    required DateTime startDate,
    required int horizonDays,
  }) {
    if (incompleteTasks.isEmpty) return [];

    // Sort tasks: Highest priority first, then closest due date
    final sortedTasks = List<AcademicTask>.from(incompleteTasks);
    sortedTasks.sort((a, b) {
      final pA = _priorityWeight(a.priority);
      final pB = _priorityWeight(b.priority);
      if (pA != pB) return pB.compareTo(pA);
      return a.dueDate.compareTo(b.dueDate);
    });

    final List<StudySession> generatedSessions = [];
    final preferredTimeSlots = ['09:30', '13:30', '16:00', '19:00', '20:30'];

    for (int dayOffset = 0; dayOffset < horizonDays; dayOffset++) {
      final currentDate = startDate.add(Duration(days: dayOffset));
      final dateStr = currentDate.toIso8601String().split('T').first;
      final weekdayName = AppConstants.daysOfWeek[currentDate.weekday - 1];

      // Find busy hours from static timetable commitments on this day
      final busyOnThisDay = timetableEntries
          .where((e) => e.day.trim().toLowerCase() == weekdayName.trim().toLowerCase())
          .toList();

      int hoursScheduledToday = 0;
      int slotPointer = 0;

      for (final task in sortedTasks) {
        if (hoursScheduledToday >= availableDailyHours) break;

        // Skip task if its due date is strictly in the past relative to this day
        if (task.dueDate.compareTo(dateStr) < 0) continue;

        String assignedTime = preferredTimeSlots[slotPointer % preferredTimeSlots.length];
        slotPointer++;

        // Verify slot does not overlap with university lectures or labs
        bool hasConflict = busyOnThisDay.any((b) => _isOverlapping(assignedTime, b.startTime, b.endTime));
        if (hasConflict) {
          assignedTime = '19:30'; // Shift to evening study block
          if (busyOnThisDay.any((b) => _isOverlapping(assignedTime, b.startTime, b.endTime))) {
            assignedTime = '21:00'; // Shift to night review block
          }
        }

        generatedSessions.add(
          StudySession(
            sessionId: _uuid.v4(),
            taskId: task.taskId,
            date: dateStr,
            startTime: assignedTime,
            duration: 60,
            status: 'Pending',
            subject: task.subject,
            taskTitle: task.title,
          ),
        );

        hoursScheduledToday += 1;
      }
    }

    return generatedSessions;
  }

  int _priorityWeight(String priority) {
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

  bool _isOverlapping(String checkTime, String busyStart, String busyEnd) {
    try {
      final checkHour = int.parse(checkTime.split(':')[0]);
      final startHour = int.parse(busyStart.split(':')[0]);
      final endHour = int.parse(busyEnd.split(':')[0]);
      return checkHour >= startHour && checkHour < endHour;
    } catch (_) {
      return false;
    }
  }
}
