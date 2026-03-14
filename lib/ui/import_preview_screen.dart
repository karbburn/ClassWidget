import 'package:flutter/material.dart';
import '../models/schedule_event.dart';
import 'package:intl/intl.dart';

class ImportPreviewScreen extends StatefulWidget {
  final List<ScheduleEvent> events;
  final String initialSection;
  final Function(List<ScheduleEvent> events, bool showInstructors, String sectionLabel) onConfirm;

  const ImportPreviewScreen({
    super.key,
    required this.events,
    this.initialSection = "",
    required this.onConfirm,
  });

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late List<ScheduleEvent> _localEvents;
  final Set<String> _deselectedSubjects = {};
  String _currentSection = "";
  bool _showInstructors = true;

  @override
  void initState() {
    super.initState();
    _localEvents = List.from(widget.events);
    _currentSection = widget.initialSection;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter events based on selected section
    final filteredEvents = _localEvents.where((e) {
      if (_deselectedSubjects.contains(e.title)) return false;
      
      if (_currentSection.trim().isEmpty) return true;
      
      final query = _currentSection.trim().toLowerCase();
      final terms = query.split(RegExp(r'\s+')); 
      
      final originalSec = (e.section ?? "").toLowerCase();
      return originalSec == _currentSection.toLowerCase();
    }).toList();

    final List<String> allSheets = widget.events
        .map((e) => e.section ?? "General")
        .toSet()
        .toList()
      ..sort();

    final List<String> allSubjects = _localEvents
        .map((e) => e.title)
        .toSet()
        .toList()
      ..sort();

    // Group filtered events by date
    final Map<String, List<ScheduleEvent>> groupedEvents = {};
    for (var event in filteredEvents) {
      final date = event.date;
      groupedEvents.putIfAbsent(date, () => []).add(event);
    }

    final sortedDates = groupedEvents.keys.toList()..sort();
    
    // Calculate date range for preview
    String dateRange = "Calculating...";
    if (sortedDates.isNotEmpty) {
      final first = sortedDates.first;
      final last = sortedDates.last;
      dateRange = "${_formatShortDate(first)} – ${_formatShortDate(last)}";
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview Schedule'),
            Text(
              '${filteredEvents.length} classes • $dateRange',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => widget.onConfirm(filteredEvents, _showInstructors, _currentSection.trim()),
              icon: const Icon(Icons.check),
              label: const Text('IMPORT'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Configuration Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_motion_outlined, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: allSheets.contains(_currentSection) ? _currentSection : (allSheets.isNotEmpty ? allSheets.first : null),
                        decoration: InputDecoration(
                          labelText: 'Select Your Sheet / Section',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        items: allSheets.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _currentSection = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.psychology_outlined, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text('Subjects Found:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: allSubjects.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final subject = allSubjects[idx];
                      final isSelected = !_deselectedSubjects.contains(subject);
                      return FilterChip(
                        label: Text(subject, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _deselectedSubjects.remove(subject);
                            } else {
                              _deselectedSubjects.add(subject);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show Professor Names', style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: const Text('Include instructor info in schedule cards'),
                  value: _showInstructors,
                  onChanged: (val) => setState(() => _showInstructors = val),
                  secondary: const Icon(Icons.person_search_outlined),
                ),
              ],
            ),
          ),
          if (filteredEvents.isEmpty && _currentSection.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No classes found for "$_currentSection"'),
                    const Text('Try typing just the letter (e.g., "B")', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final dayEvents = groupedEvents[date]!;
                  dayEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          _formatDisplayDate(date),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...dayEvents.map((e) {
                        // Check for conflicts (other events on same day with same start time)
                        final hasConflict = dayEvents.where((other) => other != e && other.startTime == e.startTime).isNotEmpty;
                        
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: hasConflict ? Colors.orange.withOpacity(0.5) : Theme.of(context).dividerColor,
                              width: hasConflict ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: hasConflict 
                                  ? Colors.orangeAccent.withOpacity(0.2)
                                  : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                e.startTime,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                  color: hasConflict ? Colors.orange[900] : null,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (hasConflict)
                                  const Tooltip(
                                    message: 'Time Conflict',
                                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _localEvents.remove(e);
                                    });
                                  },
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${e.endTime} • Source: ${e.section ?? "General"}'),
                                if (_showInstructors && e.professor != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('👤 ${e.professor}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatShortDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
