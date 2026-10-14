import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../logic/task_controller.dart';

/// Quick Add Task Sheet
/// STRICT USABILITY CONSTRAINT (Milestone 1 Target U-01):
/// Guarantees a student can add a new academic assessment in 3 taps or fewer:
/// - Tap 1: Open sheet from the Tasks screen Floating Action Button.
/// - Tap 2: Tap a quick-preset chip (auto-fills all fields with academic defaults).
/// - Tap 3: Tap the 'Save Academic Task' button.
class QuickAddTaskSheet extends StatefulWidget {
  const QuickAddTaskSheet({super.key});

  @override
  State<QuickAddTaskSheet> createState() => _QuickAddTaskSheetState();
}

class _QuickAddTaskSheetState extends State<QuickAddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController(text: 'COMP826');
  final _workloadController = TextEditingController(text: '4');

  String _selectedType = 'Assignment';
  String _selectedPriority = 'High';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 4));
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _quickPresets = [
    {
      'label': 'COMP826 Lab Report',
      'subject': 'COMP826',
      'title': 'Lab Practical Report',
      'type': 'Assignment',
      'priority': 'High',
      'workload': 4,
      'days': 3,
    },
    {
      'label': 'COMP806 Essay',
      'subject': 'COMP806',
      'title': 'System Architecture Essay',
      'type': 'Assignment',
      'priority': 'Medium',
      'workload': 6,
      'days': 7,
    },
    {
      'label': 'COMP811 Final Exam',
      'subject': 'COMP811',
      'title': 'Final Theory Examination',
      'type': 'Exam',
      'priority': 'High',
      'workload': 10,
      'days': 12,
    },
    {
      'label': 'COMP826 Project Demo',
      'subject': 'COMP826',
      'title': 'Milestone 2 Video & Source Code',
      'type': 'Assignment',
      'priority': 'High',
      'workload': 8,
      'days': 5,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _workloadController.dispose();
    super.dispose();
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _subjectController.text = preset['subject'] as String;
      _titleController.text = preset['title'] as String;
      _workloadController.text = (preset['workload'] as int).toString();
      _selectedType = preset['type'] as String;
      _selectedPriority = preset['priority'] as String;
      _selectedDate = DateTime.now().add(Duration(days: preset['days'] as int));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workload = int.tryParse(_workloadController.text.trim()) ?? 4;
    final dateStr = _selectedDate.toIso8601String().split('T').first;

    setState(() => _isSubmitting = true);

    try {
      await context.read<TaskController>().addTask(
            subject: _subjectController.text.trim().isEmpty
                ? 'General'
                : _subjectController.text.trim(),
            title: _titleController.text.trim(),
            type: _selectedType,
            dueDate: dateStr,
            priority: _selectedPriority,
            estWorkload: workload,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Added "${_titleController.text.trim()}" successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Academic Task',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '3-Tap Rapid Input / Smart Presets',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Presets Row (Tap 2)
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF4338CA)),
                  const SizedBox(width: 4),
                  Text(
                    'Tap a preset to fill instantly (1-Tap):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickPresets.map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.bolt, size: 16, color: Color(0xFF4338CA)),
                        label: Text(preset['label'] as String),
                        onPressed: () => _applyPreset(preset),
                        backgroundColor:
                            isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Row 1: Subject Code & Assessment Type
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        hintText: 'e.g. COMP826',
                        prefixIcon: Icon(Icons.school_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter subject';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category_outlined, size: 20),
                      ),
                      items: AppConstants.taskTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Assessment Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Assignment 2 Flutter App',
                  prefixIcon: Icon(Icons.assignment_outlined, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a task title or tap a preset above';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Row 3: Priority & Workload
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag_outlined, size: 20),
                      ),
                      items: AppConstants.taskPriorities.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPriority = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _workloadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Workload (hrs)',
                        suffixText: 'hours',
                        prefixIcon: Icon(Icons.timer_outlined, size: 20),
                      ),
                      validator: (val) {
                        final parsed = int.tryParse(val ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Enter hours > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 4: Due Date Selector
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                leading: const Icon(Icons.event_available_rounded, color: Color(0xFF4338CA)),
                title: const Text('Due Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
                subtitle: Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                trailing: const Icon(Icons.edit_calendar_rounded, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Tap 3: Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_task_rounded),
                  label: Text(
                    _isSubmitting ? 'Saving Task...' : 'Save Academic Task',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
