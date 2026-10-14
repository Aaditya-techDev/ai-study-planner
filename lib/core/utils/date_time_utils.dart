import 'package:intl/intl.dart';

class DateTimeUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormat = DateFormat('EEE, d MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _displayTimeFormat = DateFormat('h:mm a');

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String formatDisplayDate(DateTime dateTime) {
    return _displayDateFormat.format(dateTime);
  }

  static DateTime parseDate(String dateStr) {
    try {
      return _dateFormat.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  static String formatTimeOfDay(int hour, int minute) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    return _displayTimeFormat.format(dt);
  }

  static String formatTime24(int hour, int minute) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hour, minute);
    return _timeFormat.format(dt);
  }

  /// Calculates days remaining between today and target due date
  static int daysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }

  static String formatRemainingLabel(DateTime dueDate) {
    final days = daysRemaining(dueDate);
    if (days < 0) {
      return '${-days}d overdue';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else {
      return '$days days left';
    }
  }
}
