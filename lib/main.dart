import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'logic/auth_controller.dart';
import 'logic/settings_controller.dart';
import 'logic/study_plan_controller.dart';
import 'logic/task_controller.dart';
import 'logic/timetable_controller.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/widgets/mobile_viewport_wrapper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications service
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    print('Notification initialization note: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => TimetableController()),
        ChangeNotifierProvider(create: (_) => TaskController()),
        ChangeNotifierProvider(create: (_) => StudyPlanController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: const AIStudyPlannerApp(),
    ),
  );
}

class AIStudyPlannerApp extends StatelessWidget {
  const AIStudyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = context.watch<SettingsController>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsCtrl.themeMode,
      builder: (context, child) =>
          MobileViewportWrapper(child: child ?? const SizedBox.shrink()),
      home: const SplashScreen(),
    );
  }
}
