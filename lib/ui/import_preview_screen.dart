import 'package:flutter/material.dart';
import '../models/schedule_event.dart';
import 'package:intl/intl.dart';
import '../utils/color_utils.dart';
import '../services/time_helpers.dart';

class ImportPreviewScreen extends StatefulWidget {
  final List<ScheduleEvent> events;
  final String initialSection;
  final Function(
          List<ScheduleEvent> events, bool showInstructors, String sectionLabel)
      onConfirm;

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
  Widget build(BuildContext context) {
    // Filter events based on selected section
    final filteredEvents = _localEvents.where((e) {
      if (_deselectedSubjects.contains(e.title)) return false;

      if (_currentSection.trim().isEmpty) return true;

      final query = _currentSection.trim().toLowerCase();
      final originalSec = (e.section ?? "").trim().toLowerCase();
      return originalSec == query;
    }).toList();

    final List<String> allSheets = widget.events
        .map((e) => e.section ?? "General")
        .toSet()
        .toList()
      ..sort();

    final List<String> allSubjects =
        _localEvents.map((e) => e.title).toSet().toList()..sort();

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
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () => widget.onConfirm(
                  filteredEvents, _showInstructors, _currentSection.trim()),
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
      body: CustomScrollView(
        slivers: [
          // Configuration Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_motion_outlined,
                          color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: allSheets.contains(_currentSection)
                              ? _currentSection
                              : (allSheets.isNotEmpty ? allSheets.first : null),
                          decoration: InputDecoration(
                            labelText: 'Select Your Sheet / Section',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                          ),
                          items: allSheets
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _currentSection = val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.psychology_outlined, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Subjects Found:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: allSubjects.map((subject) {
                      final isSelected = !_deselectedSubjects.contains(subject);
                      return FilterChip(
                        label:
                            Text(subject, style: const TextStyle(fontSize: 12)),
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
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show Professor Names',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle:
                        const Text('Include instructor info in schedule cards'),
                    value: _showInstructors,
                    onChanged: (val) => setState(() => _showInstructors = val),
                    secondary: const Icon(Icons.person_search_outlined),
                  ),
                ],
              ),
            ),
          ),
          if (filteredEvents.isEmpty && _currentSection.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('No classes found for "$_currentSection"'),
                    const Text('Try typing just the letter (e.g., "B")',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
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
                        // Check for conflicts
                        final hasConflict = dayEvents.any((other) {
                          if (other == e ||
                              other.startTime.isEmpty ||
                              e.startTime.isEmpty) {
                            return false;
                          }
                          final eStart = TimeHelpers.getMinutes(e.startTime);
                          final eEnd = e.endTime.isNotEmpty
                              ? TimeHelpers.getMinutes(e.endTime)
                              : eStart + 60;
                          final oStart =
                              TimeHelpers.getMinutes(other.startTime);
                          final oEnd = other.endTime.isNotEmpty
                              ? TimeHelpers.getMinutes(other.endTime)
                              : oStart + 60;
                          return eStart < oEnd && oStart < eEnd;
                        });
                        final subjectColor =
                            ColorUtils.getSubjectColor(e.title);
                        final theme = Theme.of(context);

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasConflict
                                  ? Colors.orangeAccent.withValues(alpha: 0.5)
                                  : theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
                              width: hasConflict ? 1.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Container(width: 6, color: subjectColor),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6, horizontal: 10),
                                            decoration: BoxDecoration(
                                              color: hasConflict
                                                  ? Colors.orangeAccent
                                                      .withValues(alpha: 0.15)
                                                  : theme.colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: hasConflict
                                                    ? Colors.orangeAccent
                                                        .withValues(alpha: 0.3)
                                                    : theme.colorScheme.primary
                                                        .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Text(
                                              e.startTime,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: hasConflict
                                                    ? Colors.orangeAccent
                                                    : theme.colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        e.title,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            fontSize: 16),
                                                      ),
                                                    ),
                                                    if (hasConflict)
                                                      const Tooltip(
                                                        message:
                                                            'Time Conflict',
                                                        child: Icon(
                                                            Icons
                                                                .warning_amber_rounded,
                                                            color: Colors
                                                                .orangeAccent,
                                                            size: 18),
                                                      ),
                                                    const SizedBox(width: 4),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          _localEvents
                                                              .remove(e);
                                                        });
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(4.0),
                                                        child: Icon(Icons.close,
                                                            size: 18,
                                                            color: Colors.grey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${e.endTime} • Section: ${e.section ?? "General"}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: theme.textTheme
                                                        .bodyMedium?.color
                                                        ?.withValues(
                                                            alpha: 0.6),
                                                  ),
                                                ),
                                                if (_showInstructors &&
                                                    e.professor != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4),
                                                    child: Text(
                                                      '👤 ${e.professor}',
                                                      style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 12,
                                                        color: theme.textTheme
                                                            .bodyMedium?.color
                                                            ?.withValues(
                                                                alpha: 0.5),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                },
                childCount: sortedDates.length,
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
