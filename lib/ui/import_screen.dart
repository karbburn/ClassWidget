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
                  await WidgetDataService.refreshWidget(immediate: true);
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
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Import Schedule')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Your Classes',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload your timetable in Excel or CSV format.',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
              
              // Upload Zone
              Expanded(
                child: Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isLoading ? null : _handleFilePick,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: _isLoading
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Processing File...',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 48,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Tap to Select File',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supports .xlsx and .csv',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
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
                             child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent))
                           ),
                         ],
                       ),
                     );
                     if (confirm == true) {
                       await scheduleImport.dbHelper.deleteImportedEvents();
                       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported schedule cleared!')));
                       await WidgetDataService.refreshWidget(immediate: true);
                     }
                  },
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
                  label: const Text('CLEAR IMPORTED DATA', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Note: Importing a new file replaces previously imported schedules. Manually added events will remain untouched.',
                style: TextStyle(
                  fontSize: 12, 
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5), 
                  fontStyle: FontStyle.italic
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
