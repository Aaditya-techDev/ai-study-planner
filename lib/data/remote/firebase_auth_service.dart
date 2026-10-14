import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../local/sqlite_helper.dart';

/// Firebase Authentication Service with Offline & Simulated Fallback.
/// Designed for clean separation: presentation never talks directly to auth SDK.
class FirebaseAuthService {
  final SQLiteHelper _sqliteHelper = SQLiteHelper.instance;

  // Stream controller to broadcast auth state changes
  final _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;
  bool _isInitialized = false;

  FirebaseAuthService() {
    _initializeUser();
  }

  Stream<User?> get authStateChanges => _authStateController.stream;
  User? get currentUser => _currentUser;
  bool get isInitialized => _isInitialized;

  Future<User?> restorePersistedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.keyActiveUserId);
      if (userJson != null && userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson);
        _currentUser = User.fromMap(Map<String, dynamic>.from(decoded));
        _authStateController.add(_currentUser);
        _isInitialized = true;
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
    }

    _currentUser = null;
    _authStateController.add(null);
    _isInitialized = true;
    return null;
  }

  Future<void> _initializeUser() async {
    await restorePersistedUser();
  }

  /// Sign In with Email & Password
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Invalid email address format.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    // In a live Firebase deployment, this calls:
    // final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
    final userId = 'user_${email.hashCode.abs()}';
    var user = await _sqliteHelper.getUser(userId);

    if (user == null) {
      user = User(
        userId: userId,
        email: email,
        availableStudyHours: 4,
        preferences: {'darkMode': false, 'notifications': true},
      );
      await _sqliteHelper.insertUser(user);
    }

    _currentUser = user;
    _authStateController.add(_currentUser);

    // Persist login session across app/browser reloads
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyActiveUserId, jsonEncode(user.toMap()));
    } catch (_) {}

    return user;
  }

  /// Register with Email & Password
  Future<User> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (email.isEmpty || !email.contains('@')) {
      throw Exception('Please provide a valid student email.');
    }
    if (password.length < 6) {
      throw Exception('Password must contain at least 6 characters.');
    }

    final userId = 'user_${email.hashCode.abs()}';
    final user = User(
      userId: userId,
      email: email,
      availableStudyHours: 4,
      preferences: {'notifications': true},
    );

    await _sqliteHelper.insertUser(user);
    _currentUser = user;
    _authStateController.add(_currentUser);

    // Persist session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyActiveUserId, jsonEncode(user.toMap()));
    } catch (_) {}

    return user;
  }

  /// Sign Out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _authStateController.add(null);

    // Clear active session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyActiveUserId);
    } catch (_) {}
  }

  void dispose() {
    _authStateController.close();
  }
}
