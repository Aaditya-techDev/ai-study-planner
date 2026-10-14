import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../data/models/timetable_entry_model.dart';
import '../data/repositories/timetable_repository.dart';

class TimetableController extends ChangeNotifier {
  final TimetableRepository _repository;
  final Uuid _uuid = const Uuid();

  List<TimetableEntry> _entries = [];
  String _selectedDay = 'Monday';
  bool _isLoading = false;

  TimetableController({TimetableRepository? repository})
      : _repository = repository ?? TimetableRepository() {
    loadEntries();
  }

  List<TimetableEntry> get entries => _entries;
  String get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;

  List<TimetableEntry> get filteredEntries {
    return _entries
        .where((e) => e.day.toLowerCase() == _selectedDay.toLowerCase())
        .toList();
  }

  void setSelectedDay(String day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _repository.getTimetableEntries();

    // If initial launch and empty, seed sample realistic university schedule once
    final prefs = await SharedPreferences.getInstance();
    final hasSeeded = prefs.getBool(AppConstants.keyTimetableSeeded) ?? false;

    if (!hasSeeded && _entries.isEmpty) {
      await _seedSampleTimetable();
      await prefs.setBool(AppConstants.keyTimetableSeeded, true);
      _entries = await _repository.getTimetableEntries();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry({
    required String subject,
    required String day,
    required String startTime,
    required String endTime,
    required String location,
  }) async {
    final newEntry = TimetableEntry(
      entryId: _uuid.v4(),
      subject: subject,
      day: day,
      startTime: startTime,
      endTime: endTime,
      location: location,
    );

    await _repository.addTimetableEntry(newEntry);
    await loadEntries();
  }

  Future<void> updateEntry(TimetableEntry entry) async {
    await _repository.updateTimetableEntry(entry);
    await loadEntries();
  }

  Future<void> deleteEntry(String entryId) async {
    await _repository.deleteTimetableEntry(entryId);
    await loadEntries();
  }

  Future<void> _seedSampleTimetable() async {
    final sample = [
      TimetableEntry(
        entryId: _uuid.v4(),
        subject: 'COMP826 Mobile Systems Dev',
        day: 'Monday',
        startTime: '10:00',
        endTime: '12:00',
        location: 'Building WG-401',
      ),
      TimetableEntry(
        entryId: _uuid.v4(),
        subject: 'COMP806 Software Architecture',
        day: 'Tuesday',
        startTime: '14:00',
        endTime: '16:00',
        location: 'Lecture Hall WZ-202',
      ),
      TimetableEntry(
        entryId: _uuid.v4(),
        subject: 'COMP826 Lab Practical',
        day: 'Wednesday',
        startTime: '11:00',
        endTime: '13:00',
        location: 'Computer Lab WE-312',
      ),
      TimetableEntry(
        entryId: _uuid.v4(),
        subject: 'COMP811 Research Methods',
        day: 'Thursday',
        startTime: '09:00',
        endTime: '11:00',
        location: 'Seminar Room WT-103',
      ),
    ];

    for (final e in sample) {
      await _repository.addTimetableEntry(e);
    }
  }
}
