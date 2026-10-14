import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../logic/settings_controller.dart';
import '../../../logic/study_plan_controller.dart';
import '../../../logic/task_controller.dart';
import '../../../logic/timetable_controller.dart';
import '../../widgets/session_card.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  Future<void> _handleGeneratePlan() async {
    final taskCtrl = context.read<TaskController>();
    final timetableCtrl = context.read<TimetableController>();
    final settingsCtrl = context.read<SettingsController>();
    final planCtrl = context.read<StudyPlanController>();

    final incompleteTasks = taskCtrl.tasks.where((t) => t.isPending).toList();

    if (incompleteTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tasks are complete! Add pending tasks to generate a plan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await planCtrl.generateOrRegeneratePlan(
      incompleteTasks: incompleteTasks,
      timetableEntries: timetableCtrl.entries,
      availableDailyHours: settingsCtrl.availableStudyHours,
      apiKey: settingsCtrl.geminiApiKey,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI Study Plan generated with ${planCtrl.allSessions.length} study sessions!',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (planCtrl.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(planCtrl.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planCtrl = context.watch<StudyPlanController>();
    final settingsCtrl = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get unique dates for filter pills
    final uniqueDates = [
      'All',
      ...planCtrl.allSessions.map((s) => s.date).toSet().toList()
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Regenerate Study Plan',
            onPressed: planCtrl.isGenerating ? null : _handleGeneratePlan,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Generation Header & Constraints Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield_outlined,
                                  size: 14, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'Zero PII Transmitted to AI',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: ${settingsCtrl.availableStudyHours}h daily • Timetable blocks excluded',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: planCtrl.isGenerating ? null : _handleGeneratePlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4338CA),
                        foregroundColor: Colors.white,
                      ),
                      icon: planCtrl.isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(
                        planCtrl.activePlan == null
                            ? 'Generate Plan'
                            : 'Regenerate',
                      ),
                    ),
                  ],
                ),

                // Date Pills Bar (if sessions exist)
                if (planCtrl.allSessions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: uniqueDates.map((dateStr) {
                        final isSelected = planCtrl.selectedDateFilter == dateStr;
                        String displayLabel = dateStr;
                        if (dateStr != 'All') {
                          final parsed = DateTimeUtils.parseDate(dateStr);
                          displayLabel =
                              '${parsed.day}/${parsed.month} (${AppConstants.daysOfWeek[parsed.weekday - 1].substring(0, 3)})';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(displayLabel),
                            selected: isSelected,
                            onSelected: (_) => planCtrl.setDateFilter(dateStr),
                            selectedColor: const Color(0xFF4338CA),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Study Sessions List
          Expanded(
            child: planCtrl.isGenerating
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Gemini AI is optimizing your study schedule...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Subtracting class hours & prioritizing deadlines',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : planCtrl.filteredSessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome_motion_rounded,
                              size: 56,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No Study Sessions Generated',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Tap "Generate Plan" to automatically distribute your academic workload into conflict-free study blocks.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _handleGeneratePlan,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Generate AI Schedule'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: planCtrl.filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = planCtrl.filteredSessions[index];
                          return SessionCard(
                            session: session,
                            onToggleStatus: () {
                              planCtrl.toggleSessionStatus(session);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
