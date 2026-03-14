import 'package:flutter/material.dart';
import '../models/schedule_event.dart';
import '../services/schedule_import.dart';
import '../services/preferences_service.dart';
import '../services/widget_data_service.dart';
import '../services/log_service.dart';
import 'import_preview_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final scheduleImport = ScheduleImport();
  String? _selectedSection;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final section = await PreferencesService.getSelectedSection();
    setState(() => _selectedSection = section);
  }

  Future<void> _handleFilePick() async {
    try {
      setState(() => _isLoading = true);
      final events = await scheduleImport.pickAndParse();
      setState(() => _isLoading = false);

      if (events == null || events.isEmpty) return;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImportPreviewScreen(
              events: events,
              initialSection: _selectedSection ?? "",
              onConfirm: (filteredEvents, showInstructors, sectionLabel) async {
                Navigator.pop(context); // Close preview
                setState(() => _isLoading = true);
                
                final result = await scheduleImport.commitImport(filteredEvents);
                
                if (result.success) {
                  if (sectionLabel.isNotEmpty) {
                    await PreferencesService.setSelectedSection(sectionLabel);
                  }
                  await PreferencesService.setShowProfessorNames(showInstructors);
                }

                setState(() => _isLoading = false);
                if (result.success && mounted) {
                  _showSuccessDialog(result, sectionLabel);
                  WidgetDataService.refreshWidget();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message), backgroundColor: Colors.red),
                  );
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to parse file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(ImportResult result, [String? userSection]) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✅ Classes Added: ${result.classesAdded}'),
            if (userSection != null && userSection.isNotEmpty)
              Text('📍 Section Assigned: $userSection')
            else if (result.section != null) 
              Text('📍 Section Detected: ${result.section}'),
            const SizedBox(height: 12),
            const Text('Your home screen widget has been updated.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('AWESOME'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Schedule')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.file_upload_outlined, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            Text(
              'Update Your Timetable',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an Excel (.xlsx) or CSV file provided by your institute.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _handleFilePick,
                icon: const Icon(Icons.file_open),
                label: const Text('SELECT FILE'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ),
            const SizedBox(height: 12),
            if (!_isLoading)
              OutlinedButton.icon(
                onPressed: () async {
                   final confirm = await showDialog<bool>(
                     context: context,
                     builder: (context) => AlertDialog(
                       title: const Text('Clear Schedule?'),
                       content: const Text('This will delete all imported classes. Manually added tasks and events will be saved.'),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                         TextButton(
                           onPressed: () => Navigator.pop(context, true), 
                           child: const Text('CLEAR ALL', style: TextStyle(color: Colors.red))
                         ),
                       ],
                     ),
                   );
                   if (confirm == true) {
                     await scheduleImport.dbHelper.deleteImportedEvents();
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported schedule cleared!')));
                     WidgetDataService.refreshWidget();
                   }
                },
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
                label: const Text('CLEAR IMPORTED DATA', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            const SizedBox(height: 16),
            const Text(
              'Note: Importing a new file will replace your previously imported schedule, but manually added events will stay.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
