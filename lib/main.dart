import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';
import 'services/widget_data_service.dart';
import 'services/log_service.dart';
import 'ui/root_screen.dart';
import 'ui/import_screen.dart';
import 'ui/add_task_screen.dart';
import 'services/theme_controller.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    LogService.log('Background task $taskName started', tag: 'WorkManager');
    await WidgetDataService.syncSchedule();
    return Future.value(true);
  });
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'update') {
    LogService.log('HomeWidget background update triggered', tag: 'HomeWidget');
    await WidgetDataService.syncSchedule();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final themeController = ThemeController();
  
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // Set to false for release
  );

  await HomeWidget.registerBackgroundCallback(backgroundCallback);

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
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37), // Gold
              brightness: Brightness.light,
              surface: const Color(0xFFFFFFFF),
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
            cardTheme: CardThemeData(
              color: const Color(0xFFFFFFFF),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E5E5), width: 1),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
              iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFD4AF37),
              foregroundColor: Color(0xFF0D0D0D),
              elevation: 2,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFFFFFFFF),
              selectedItemColor: Color(0xFFD4AF37),
              unselectedItemColor: Color(0xFF8A8A8A),
              elevation: 8,
              type: BottomNavigationBarType.fixed,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
              ),
              labelStyle: const TextStyle(color: Color(0xFF6B6B6B)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0D0D0D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD4AF37), // Gold
              brightness: Brightness.dark,
              surface: const Color(0xFF1A1A1A),
            ),
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            cardTheme: CardThemeData(
              color: const Color(0xFF1A1A1A),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF242424), width: 1),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFFE8E8E8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
              iconTheme: IconThemeData(color: Color(0xFFE8E8E8)),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFFD4AF37),
              foregroundColor: Color(0xFF0D0D0D),
              elevation: 2,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1A1A1A),
              selectedItemColor: Color(0xFFD4AF37),
              unselectedItemColor: Color(0xFF8A8A8A),
              elevation: 8,
              type: BottomNavigationBarType.fixed,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF0D0D0D),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF242424)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF242424)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
              ),
              labelStyle: const TextStyle(color: Color(0xFF8A8A8A)),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: const Color(0xFF0D0D0D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => RootScreen(themeController: themeController),
            '/import': (context) => const ImportScreen(),
            '/add-task': (context) => const AddTaskScreen(),
          },
        );
      },
    );
  }
}
