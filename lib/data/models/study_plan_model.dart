import 'dart:convert';
import 'study_session_model.dart';

/// Represents a generated AI Study Plan spanning a horizon (e.g. 7 days).
class StudyPlan {
  final String planId;
  final String createdAt; // ISO string
  final String status; // 'Active', 'Archived', 'Generating'
  final List<StudySession> sessions;

  const StudyPlan({
    required this.planId,
    required this.createdAt,
    this.status = 'Active',
    this.sessions = const [],
  });

  StudyPlan copyWith({
    String? planId,
    String? createdAt,
    String? status,
    List<StudySession>? sessions,
  }) {
    return StudyPlan(
      planId: planId ?? this.planId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'createdAt': createdAt,
      'status': status,
      'sessionsJson': jsonEncode(sessions.map((s) => s.toMap()).toList()),
    };
  }

  factory StudyPlan.fromMap(Map<String, dynamic> map, {List<StudySession>? loadedSessions}) {
    List<StudySession> parsedSessions = loadedSessions ?? [];
    if (parsedSessions.isEmpty && map['sessionsJson'] != null) {
      try {
        final decoded = jsonDecode(map['sessionsJson'] as String) as List<dynamic>;
        parsedSessions = decoded.map((item) => StudySession.fromMap(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    return StudyPlan(
      planId: map['planId'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      status: map['status'] as String? ?? 'Active',
      sessions: parsedSessions,
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'createdAt': createdAt,
        'status': status,
        'sessions': sessions.map((s) => s.toJson()).toList(),
      };

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    List<StudySession> parsedSessions = [];
    if (json['sessions'] != null && json['sessions'] is List) {
      parsedSessions = (json['sessions'] as List)
          .map((item) => StudySession.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return StudyPlan(
      planId: json['planId'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      status: json['status'] as String? ?? 'Active',
      sessions: parsedSessions,
    );
  }
}
