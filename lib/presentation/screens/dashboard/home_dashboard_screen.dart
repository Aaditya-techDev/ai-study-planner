import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/auth_controller.dart';
import '../../../logic/study_plan_controller.dart';
import '../../../logic/task_controller.dart';
import '../../../logic/timetable_controller.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/quick_nav_grid.dart';
import '../../widgets/session_card.dart';
import '../settings/settings_screen.dart';
import '../study_plan/study_plan_screen.dart';
import '../tasks/tasks_screen.dart';
import '../timetable/timetable_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeDashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final taskCtrl = context.watch<TaskController>();
    final planCtrl = context.watch<StudyPlanController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userEmail = auth.currentUser?.email ?? 'Student';
    final userDisplay = userEmail.split('@').first;

    final nextSession = planCtrl.allSessions
        .where((s) => !s.isComplete)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $userDisplay',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'AUT Tertiary Academic Dashboard',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Cloud Sync Indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Offline-First SQLite Cached & Cloud Synced',
              child: Chip(
                avatar: const Icon(Icons.cloud_done_rounded,
                    size: 16, color: Color(0xFF10B981)),
                label: const Text('Synced', style: TextStyle(fontSize: 11)),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<TaskController>().loadTasks();
          await context.read<TimetableController>().loadEntries();
          await context.read<StudyPlanController>().loadActivePlan();
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. High-Level Academic Progress Overview
                  ProgressCard(
                    completedTasks: taskCtrl.completedCount,
                    pendingTasks: taskCtrl.pendingCount,
                    totalTasks: taskCtrl.totalCount,
                    progress: taskCtrl.completionPercentage,
                  ),
              const SizedBox(height: 24),

              // 2. 1-Tap Navigation to All Primary Screens
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Navigation',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '1-Tap Access',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              QuickNavGrid(
                onTimetableTap: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(1);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                  }
                },
                onTasksTap: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(2);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
                  }
                },
                onStudyPlanTap: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(3);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyPlanScreen()));
                  }
                },
                onSettingsTap: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(4);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  }
                },
              ),
              const SizedBox(height: 24),

              // 3. Next Upcoming AI Study Session
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next AI Study Session',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(3);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StudyPlanScreen()),
                        );
                      }
                    },
                    child: const Text('View Full Plan'),
                  ),
                ],
              ),
              if (nextSession != null)
                SessionCard(
                  session: nextSession,
                  onToggleStatus: () => planCtrl.toggleSessionStatus(nextSession),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4338CA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'No Active Study Session',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Generate a personalized plan to optimize your study routine.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 4. Upcoming Deadlines Glance
              Text(
                'Upcoming Academic Deadlines',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (taskCtrl.filteredTasks.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No academic tasks recorded.'),
                  ),
                )
              else
                ...taskCtrl.tasks
                    .where((t) => t.isPending)
                    .take(3)
                    .map((task) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: task.type == 'Exam'
                                ? const Color(0xFFEF4444).withOpacity(0.12)
                                : const Color(0xFF4338CA).withOpacity(0.12),
                            child: Icon(
                              task.type == 'Exam'
                                  ? Icons.military_tech_outlined
                                  : Icons.assignment_outlined,
                              size: 18,
                              color: task.type == 'Exam'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF4338CA),
                            ),
                          ),
                          title: Text(
                            task.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${task.subject} • Due ${task.dueDate}'),
                          trailing: Chip(
                            label: Text(
                              task.priority,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}
