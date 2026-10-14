import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/task_controller.dart';
import '../../widgets/task_card.dart';
import 'quick_add_task_sheet.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  void _openAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QuickAddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskCtrl = context.watch<TaskController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Examinations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded),
            tooltip: 'Add Task (3-tap constraint)',
            onPressed: () => _openAddTaskSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Filter Chips Bar (Type & Status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                // Type Filter: All / Assignment / Exam
                Row(
                  children: [
                    _buildFilterChip(
                      label: 'All (${taskCtrl.tasks.length})',
                      isSelected: taskCtrl.selectedFilter == 'All',
                      onSelected: () => taskCtrl.setFilter('All'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Assignments',
                      isSelected: taskCtrl.selectedFilter == 'Assignment',
                      onSelected: () => taskCtrl.setFilter('Assignment'),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: 'Exams',
                      isSelected: taskCtrl.selectedFilter == 'Exam',
                      onSelected: () => taskCtrl.setFilter('Exam'),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Status Filter: Pending vs Complete
                Row(
                  children: [
                    _buildStatusChip(
                      label: 'Pending (${taskCtrl.pendingCount})',
                      isSelected: taskCtrl.statusFilter == 'Pending',
                      color: const Color(0xFFF59E0B),
                      onSelected: () => taskCtrl.setStatusFilter(
                        taskCtrl.statusFilter == 'Pending' ? 'All' : 'Pending',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(
                      label: 'Completed (${taskCtrl.completedCount})',
                      isSelected: taskCtrl.statusFilter == 'Complete',
                      color: const Color(0xFF10B981),
                      onSelected: () => taskCtrl.setStatusFilter(
                        taskCtrl.statusFilter == 'Complete' ? 'All' : 'Complete',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Tasks List View
          Expanded(
            child: taskCtrl.isLoading
                ? const Center(child: CircularProgressIndicator())
                : taskCtrl.filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt_rounded,
                              size: 56,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No tasks match this filter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton.icon(
                              onPressed: () => _openAddTaskSheet(context),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Task Now (3 Taps)'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: taskCtrl.filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = taskCtrl.filteredTasks[index];
                          return TaskCard(
                            task: task,
                            onToggle: () => taskCtrl.toggleTaskStatus(task),
                            onDelete: () => taskCtrl.deleteTask(task.taskId),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
        tooltip: 'Add Task in 3 Taps or Fewer',
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: const Color(0xFF4338CA),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : const Color(0xFF334155)),
      ),
      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? color : Colors.grey,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.transparent,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
