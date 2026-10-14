import 'package:flutter/material.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/academic_task_model.dart';

class TaskCard extends StatelessWidget {
  final AcademicTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'high':
        priorityColor = const Color(0xFFEF4444);
        break;
      case 'medium':
        priorityColor = const Color(0xFFF59E0B);
        break;
      case 'low':
      default:
        priorityColor = const Color(0xFF10B981);
    }

    final dueDateParsed = DateTimeUtils.parseDate(task.dueDate);
    final daysRemaining = DateTimeUtils.daysRemaining(dueDateParsed);
    final remainingLabel = DateTimeUtils.formatRemainingLabel(dueDateParsed);

    return Dismissible(
      key: Key(task.taskId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Checkbox for completion
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: task.isComplete,
                  activeColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (_) => onToggle(),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Main Task Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Subject Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.subject,
                            style: const TextStyle(
                              color: Color(0xFF4338CA),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Type Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Priority Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 3,
                                backgroundColor: priorityColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.priority,
                                style: TextStyle(
                                  color: priorityColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Title
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration:
                            task.isComplete ? TextDecoration.lineThrough : null,
                        color: task.isComplete
                            ? (isDark ? Colors.white38 : Colors.grey)
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Metadata footer: Due date + Workload
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: daysRemaining < 0
                              ? const Color(0xFFEF4444)
                              : (daysRemaining <= 1
                                  ? const Color(0xFFF59E0B)
                                  : (isDark ? Colors.white60 : Colors.black54)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          remainingLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: daysRemaining < 0
                                ? const Color(0xFFEF4444)
                                : (daysRemaining <= 1
                                    ? const Color(0xFFF59E0B)
                                    : (isDark ? Colors.white60 : Colors.black54)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(
                          Icons.hourglass_empty_rounded,
                          size: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.estWorkload}h workload',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
