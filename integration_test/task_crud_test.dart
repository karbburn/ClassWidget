import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:classwidget/ui/tasks_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Task CRUD Integration Tests', () {
    testWidgets('Create task → appears in list → delete → removed',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: TasksScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Create a task via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in task title
      await tester.enterText(
          find.byType(TextField).first, 'Integration Test Task');
      await tester.pumpAndSettle();

      // Tap CREATE TASK
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      // Step 2: Verify task appears in list
      expect(find.text('Integration Test Task'), findsOneWidget);

      // Step 3: Delete via the delete icon button
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      // Confirm deletion in the dialog
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      // Step 4: Verify task is removed
      expect(find.text('Integration Test Task'), findsNothing);
    });

    testWidgets('Edit task → changes persist', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: TasksScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Create a task first
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Original Title');
      await tester.tap(find.text('CREATE TASK'));
      await tester.pumpAndSettle();

      expect(find.text('Original Title'), findsOneWidget);

      // Tap the task card to edit
      await tester.tap(find.text('Original Title'));
      await tester.pumpAndSettle();

      // Clear and edit the title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Updated Title');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      // Verify updated title
      expect(find.text('Updated Title'), findsOneWidget);
      expect(find.text('Original Title'), findsNothing);
    });
  });
}
