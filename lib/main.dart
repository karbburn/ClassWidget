import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'services/widget_data_service.dart';
import 'services/log_service.dart';
import 'ui/dashboard_screen.dart';
import 'ui/import_screen.dart';
import 'ui/add_task_screen.dart';
import 'services/theme_controller.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    LogService.log('Background task $taskName started', tag: 'WorkManager');
    // Feature #3: Midnight refresh
    await WidgetDataService.syncTodaySchedule();
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeController = ThemeController();
  
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to false for release
  );

  // Register periodic task for every 3 hours (more frequent than midnight to stay updated)
  await Workmanager().registerPeriodicTask(
    "1", 
    "widget_periodic_refresh",
    frequency: const Duration(hours: 3),
    initialDelay: const Duration(minutes: 5),
  );

  runApp(ClassWidgetApp(themeController: themeController));
}

class ClassWidgetApp extends StatelessWidget {
  final ThemeController themeController;

  const ClassWidgetApp({super.key, required this.themeController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'ClassWidget',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF38BDF8), // Primary from UI-UX Skill
              brightness: Brightness.light,
              surface: const Color(0xFFF1F5F9), // Accent/Surface
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF38BDF8),
              brightness: Brightness.dark,
              surface: const Color(0xFF0F172A), // Dark Surface
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => DashboardScreen(themeController: themeController),
            '/import': (context) => const ImportScreen(),
            '/add-task': (context) => const AddTaskScreen(),
          },
        );
      },
    );
  }
}
