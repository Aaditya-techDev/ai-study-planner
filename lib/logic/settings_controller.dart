import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../services/notification_service.dart';

class SettingsController extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService.instance;

  int _availableStudyHours = AppConstants.defaultAvailableHours;
  bool _notificationsEnabled = true;
  bool _deadlineAlertsEnabled = true;
  String _geminiApiKey = '';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  SettingsController() {
    loadSettings();
  }

  int get availableStudyHours => _availableStudyHours;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get deadlineAlertsEnabled => _deadlineAlertsEnabled;
  String get geminiApiKey => _geminiApiKey;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _availableStudyHours = prefs.getInt(AppConstants.keyAvailableHours) ??
        AppConstants.defaultAvailableHours;
    _notificationsEnabled =
        prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
    _deadlineAlertsEnabled =
        prefs.getBool(AppConstants.keyDeadlineAlertsEnabled) ?? true;
    _geminiApiKey = prefs.getString(AppConstants.keyGeminiApiKey) ?? '';

    final themeStr = prefs.getString(AppConstants.keyThemeMode);
    if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _notificationService.notificationsEnabled = _notificationsEnabled;
    _notificationService.deadlineAlertsEnabled = _deadlineAlertsEnabled;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setAvailableStudyHours(int hours) async {
    _availableStudyHours = hours;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyAvailableHours, hours);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    _notificationService.notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyNotificationsEnabled, value);
  }

  Future<void> setDeadlineAlertsEnabled(bool value) async {
    _deadlineAlertsEnabled = value;
    _notificationService.deadlineAlertsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyDeadlineAlertsEnabled, value);
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyGeminiApiKey, _geminiApiKey);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.keyThemeMode,
      mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system'),
    );
  }
}
