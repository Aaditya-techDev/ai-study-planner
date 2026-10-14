import 'package:flutter/material.dart';

class QuickNavGrid extends StatelessWidget {
  final VoidCallback onTimetableTap;
  final VoidCallback onTasksTap;
  final VoidCallback onStudyPlanTap;
  final VoidCallback onSettingsTap;

  const QuickNavGrid({
    super.key,
    required this.onTimetableTap,
    required this.onTasksTap,
    required this.onStudyPlanTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      children: [
        _buildNavCard(
          context: context,
          title: 'Timetable',
          subtitle: 'Weekly Classes',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF3B82F6),
          onTap: onTimetableTap,
        ),
        _buildNavCard(
          context: context,
          title: 'Tasks & Exams',
          subtitle: 'Deadlines & Priority',
          icon: Icons.assignment_turned_in_rounded,
          color: const Color(0xFF10B981),
          onTap: onTasksTap,
        ),
        _buildNavCard(
          context: context,
          title: 'AI Study Plan',
          subtitle: 'Smart Sessions',
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: onStudyPlanTap,
        ),
        _buildNavCard(
          context: context,
          title: 'Settings',
          subtitle: 'Study Hours & Alerts',
          icon: Icons.settings_rounded,
          color: const Color(0xFFF59E0B),
          onTap: onSettingsTap,
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: color.withOpacity(0.12),
        highlightColor: color.withOpacity(0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
