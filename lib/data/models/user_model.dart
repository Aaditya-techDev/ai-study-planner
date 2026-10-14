import 'dart:convert';

/// Represents an authenticated student user.
class User {
  final String userId;
  final String email;
  final Map<String, dynamic> preferences;
  final int availableStudyHours;

  const User({
    required this.userId,
    required this.email,
    this.preferences = const {},
    this.availableStudyHours = 4,
  });

  User copyWith({
    String? userId,
    String? email,
    Map<String, dynamic>? preferences,
    int? availableStudyHours,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      preferences: preferences ?? this.preferences,
      availableStudyHours: availableStudyHours ?? this.availableStudyHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'preferences': jsonEncode(preferences),
      'availableStudyHours': availableStudyHours,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> parsedPrefs = {};
    if (map['preferences'] != null) {
      if (map['preferences'] is String) {
        try {
          parsedPrefs = jsonDecode(map['preferences'] as String);
        } catch (_) {
          parsedPrefs = {};
        }
      } else if (map['preferences'] is Map) {
        parsedPrefs = Map<String, dynamic>.from(map['preferences'] as Map);
      }
    }

    return User(
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      preferences: parsedPrefs,
      availableStudyHours: (map['availableStudyHours'] as num?)?.toInt() ?? 4,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
}
