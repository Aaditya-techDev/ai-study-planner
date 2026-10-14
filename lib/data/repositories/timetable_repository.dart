import '../local/sqlite_helper.dart';
import '../models/timetable_entry_model.dart';
import '../remote/firestore_sync_service.dart';

/// Repository for Timetable entries with Offline-First architecture
class TimetableRepository {
  final SQLiteHelper _sqliteHelper;
  final FirestoreSyncService _syncService;

  TimetableRepository({
    SQLiteHelper? sqliteHelper,
    FirestoreSyncService? syncService,
  })  : _sqliteHelper = sqliteHelper ?? SQLiteHelper.instance,
        _syncService = syncService ?? FirestoreSyncService();

  Future<List<TimetableEntry>> getTimetableEntries() async {
    return await _sqliteHelper.getAllTimetableEntries();
  }

  Future<void> addTimetableEntry(TimetableEntry entry) async {
    // 1. Save locally to SQLite first
    await _sqliteHelper.insertTimetableEntry(entry);

    // 2. Sync to Cloud Firestore asynchronously
    _syncService.syncTimetableEntryToCloud(entry);
  }

  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    await _sqliteHelper.updateTimetableEntry(entry);
    _syncService.syncTimetableEntryToCloud(entry);
  }

  Future<void> deleteTimetableEntry(String entryId) async {
    await _sqliteHelper.deleteTimetableEntry(entryId);
    // In live Firestore: delete cloud doc
  }
}
