import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:classwidget/ui/tasks_screen.dart';
import 'package:classwidget/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper to wrap TasksScreen in required providers and MaterialApp.
Widget createTestableTasksScreen() {
  return const ProviderScope(
    child: MaterialApp(
      home: TasksScreen(),
    ),
  );
}

void main() {
  late DatabaseHelper dbHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbHelper = DatabaseHelper();
    await dbHelper.clearAllData();
  });

  group('TasksScreen Widget Tests', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestableTasksScreen());
      // On first frame, _isLoading = true → show spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('widget structure is correct', (tester) async {
      await tester.pumpWidget(createTestableTasksScreen());
      await tester.pump(const Duration(milliseconds: 600));

      // Verify key UI elements exist
      expect(find.text('My Tasks'), findsOneWidget); // AppBar title
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tapping FAB opens bottom sheet dialog', (tester) async {
      await tester.pumpWidget(createTestableTasksScreen());
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 600));

      // Bottom sheet should show "New Task" heading and "CREATE TASK" button
      expect(find.text('New Task'), findsWidgets); // FAB + dialog title
      expect(find.text('CREATE TASK'), findsOneWidget);
    });

    testWidgets('bottom sheet has title and course fields', (tester) async {
      await tester.pumpWidget(createTestableTasksScreen());
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Task Title'), findsOneWidget);
      expect(find.text('Related Course (Optional)'), findsOneWidget);
    });

    testWidgets('error state does not show when no error', (tester) async {
      await tester.pumpWidget(createTestableTasksScreen());
      await tester.pump(const Duration(milliseconds: 600));
      // If no error, we should NOT see the error state
      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
