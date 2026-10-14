import 'package:flutter/material.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/study_session_model.dart';

class SessionCard extends StatelessWidget {
  final StudySession session;
  final VoidCallback onToggleStatus;

  const SessionCard({
    super.key,
    required this.session,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sessionDate = DateTimeUtils.parseDate(session.date);
    final displayDate = DateTimeUtils.formatDisplayDate(sessionDate);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onToggleStatus,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 1. Time Column
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: session.isComplete
                      ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                      : const Color(0xFF4338CA).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: session.isComplete
                        ? Colors.transparent
                        : const Color(0xFF4338CA).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      session.startTime,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: session.isComplete
                            ? (isDark ? Colors.white38 : Colors.grey)
                            : const Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.duration}m',
                      style: TextStyle(
                        fontSize: 11,
                        color: session.isComplete
                            ? (isDark ? Colors.white24 : Colors.grey)
                            : const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // 2. Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.subject != null && session.subject!.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF38BDF8).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              session.subject!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            displayDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      session.taskTitle ?? 'Focused Study Block',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration:
                            session.isComplete ? TextDecoration.lineThrough : null,
                        color: session.isComplete
                            ? (isDark ? Colors.white38 : Colors.grey)
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Status Action Button
              IconButton(
                onPressed: onToggleStatus,
                icon: Icon(
                  session.isComplete
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: session.isComplete
                      ? const Color(0xFF10B981)
                      : (isDark ? Colors.white38 : Colors.grey),
                  size: 26,
                ),
                tooltip: session.isComplete
                    ? 'Mark as Pending'
                    : 'Mark as Complete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
