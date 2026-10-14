import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/timetable_entry_model.dart';
import '../../../logic/timetable_controller.dart';

class AddTimetableDialog extends StatefulWidget {
  final TimetableEntry? existingEntry;

  const AddTimetableDialog({super.key, this.existingEntry});

  @override
  State<AddTimetableDialog> createState() => _AddTimetableDialogState();
}

class _AddTimetableDialogState extends State<AddTimetableDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectController;
  late TextEditingController _locationController;

  late String _selectedDay;
  late String _startTime;
  late String _endTime;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.existingEntry?.subject ?? '');
    _locationController = TextEditingController(text: widget.existingEntry?.location ?? '');
    _selectedDay = widget.existingEntry?.day ?? 'Monday';
    _startTime = widget.existingEntry?.startTime ?? '10:00';
    _endTime = widget.existingEntry?.endTime ?? '12:00';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final currentStr = isStart ? _startTime : _endTime;
    final parts = currentStr.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 10,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class / subject title.')),
      );
      return;
    }

    final controller = context.read<TimetableController>();

    if (widget.existingEntry == null) {
      await controller.addEntry(
        subject: _subjectController.text.trim(),
        day: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim().isEmpty
            ? 'Campus Room'
            : _locationController.text.trim(),
      );
    } else {
      final updated = widget.existingEntry!.copyWith(
        subject: _subjectController.text.trim(),
        day: _selectedDay,
        startTime: _startTime,
        endTime: _endTime,
        location: _locationController.text.trim(),
      );
      await controller.updateEntry(updated);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEntry != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Timetable Entry' : 'Add Weekly Class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject / Class',
                  hintText: 'e.g. COMP826 Mobile Systems',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(labelText: 'Day of Week'),
                items: AppConstants.daysOfWeek.map((day) {
                  return DropdownMenuItem(value: day, child: Text(day));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDay = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text('Start: $_startTime'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.access_time_filled, size: 16),
                      label: Text('End: $_endTime'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location / Room',
                  hintText: 'e.g. Building WG-401 or Online Zoom',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
