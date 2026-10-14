/// Represents a recurring weekly class or static commitment.
class TimetableEntry {
  final String entryId;
  final String subject;
  final String day; // Monday, Tuesday, etc.
  final String startTime; // "09:00"
  final String endTime; // "11:00"
  final String location;

  const TimetableEntry({
    required this.entryId,
    required this.subject,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  TimetableEntry copyWith({
    String? entryId,
    String? subject,
    String? day,
    String? startTime,
    String? endTime,
    String? location,
  }) {
    return TimetableEntry(
      entryId: entryId ?? this.entryId,
      subject: subject ?? this.subject,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'subject': subject,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
    };
  }

  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    return TimetableEntry(
      entryId: map['entryId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      day: map['day'] as String? ?? 'Monday',
      startTime: map['startTime'] as String? ?? '09:00',
      endTime: map['endTime'] as String? ?? '10:00',
      location: map['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory TimetableEntry.fromJson(Map<String, dynamic> json) =>
      TimetableEntry.fromMap(json);
}
