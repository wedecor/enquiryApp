import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../../enquiries/presentation/widgets/enquiry_list_item.dart';

/// Calendar View Screen - Shows relevant enquiries on a calendar
/// Filters out cancelled and not_interested events
/// Shows: new, in_talks, quote_sent, confirmed, and recent completed events
class CalendarViewScreen extends ConsumerStatefulWidget {
  const CalendarViewScreen({super.key, this.embeddedInShell = false});

  final bool embeddedInShell;

  @override
  ConsumerState<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends ConsumerState<CalendarViewScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<DateTime, List<CalendarEvent>> _events = {};
  final Map<DateTime, List<CalendarEvent>> _conflicts = {};
  final Map<DateTime, Map<String, int>> _statusCounts = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    // Trigger automatic cleanup when calendar view loads to mark past events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAutomaticCleanup();
    });
  }

  /// Run automatic cleanup to mark past "in_talks" events as "not_interested"
  Future<void> _runAutomaticCleanup() async {
    try {
      final cleanupService = ref.read(pastEnquiryCleanupServiceProvider);
      final currentUser = ref.read(currentUserWithFirestoreProvider);
      final userId = currentUser.value?.uid ?? 'system';

      await cleanupService.runAutomaticCleanup(
        force: false, // Only run if not already run today
        userId: userId,
      );
    } catch (e) {
      // Silently fail - cleanup is not critical for calendar view
      // Errors are logged by the cleanup service
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserWithFirestoreProvider);
    final roleAsync = ref.watch(roleProvider);

    final body = currentUser.when(
      data: (user) => roleAsync.when(
        data: (role) =>
            _buildCalendarContent(context, user, role == UserRole.admin),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildCalendarContent(context, user, false),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) =>
          Center(child: Text('Error: $error')),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
        actions: [
          if (roleAsync.valueOrNull == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (context) => const EnquiryFormScreen(),
                  ),
                );
              },
              tooltip: 'Add New Enquiry',
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildCalendarContent(
    BuildContext context,
    UserModel? user,
    bool isAdmin,
  ) {
    final userId = user?.uid;
    if (userId == null) {
      return const Center(child: Text('User not found'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getEnquiriesStream(isAdmin, userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final enquiries = snapshot.data?.docs ?? [];
        _processEnquiries(enquiries);

        return Column(
          children: [
            // Color Legend
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('Confirmed', AppColorScheme.statusConfirmed),
                  _buildLegendItem('In Talks', AppColorScheme.statusInTalks),
                  _buildLegendItem(
                    'Quote Sent',
                    AppColorScheme.statusQuoteSent,
                  ),
                  _buildLegendItem('New', AppColorScheme.statusNew),
                  _buildLegendItem('Completed', AppColorScheme.statusCompleted),
                ],
              ),
            ),
            // Calendar Widget
            TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: (day) => _getEventsForDay(day),
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;

                  final dayKey = DateTime(date.year, date.month, date.day);
                  final statusCounts = _statusCounts[dayKey];

                  if (statusCounts == null || statusCounts.isEmpty) {
                    return null;
                  }

                  final hasConflict = _conflicts.containsKey(dayKey);
                  final totalEvents = events.length;

                  // Show status breakdown with colored indicators
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show colored dots for each status type
                        if (statusCounts['confirmed'] != null &&
                            statusCounts['confirmed']! > 0)
                          _buildStatusIndicator(
                            AppColorScheme.statusConfirmed,
                            statusCounts['confirmed']!,
                            hasConflict,
                          ),
                        if (statusCounts['in_talks'] != null &&
                            statusCounts['in_talks']! > 0)
                          _buildStatusIndicator(
                            AppColorScheme.statusInTalks,
                            statusCounts['in_talks']!,
                            hasConflict,
                          ),
                        if (statusCounts['quote_sent'] != null &&
                            statusCounts['quote_sent']! > 0)
                          _buildStatusIndicator(
                            AppColorScheme.statusQuoteSent,
                            statusCounts['quote_sent']!,
                            hasConflict,
                          ),
                        if (statusCounts['new'] != null &&
                            statusCounts['new']! > 0)
                          _buildStatusIndicator(
                            AppColorScheme.statusNew,
                            statusCounts['new']!,
                            hasConflict,
                          ),
                        if (statusCounts['completed'] != null &&
                            statusCounts['completed']! > 0)
                          _buildStatusIndicator(
                            AppColorScheme.statusCompleted,
                            statusCounts['completed']!,
                            hasConflict,
                          ),
                        // Show total count badge if multiple events
                        if (totalEvents > 1)
                          Container(
                            margin: const EdgeInsets.only(left: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: hasConflict
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$totalEvents',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            // Selected Day Events List
            Expanded(child: _buildEventsList(context)),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(BuildContext context) {
    final selectedDayEvents = _getEventsForDay(_selectedDay);
    final selectedDayKey = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final hasConflict = _conflicts.containsKey(selectedDayKey);

    if (selectedDayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No events on ${DateFormat('MMM dd, yyyy').format(_selectedDay)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final statusCounts = _statusCounts[selectedDayKey] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status breakdown summary
        if (statusCounts.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Breakdown',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (statusCounts['confirmed'] != null)
                      _buildStatusChip(
                        'Confirmed',
                        AppColorScheme.statusConfirmed,
                        statusCounts['confirmed']!,
                      ),
                    if (statusCounts['in_talks'] != null)
                      _buildStatusChip(
                        'In Talks',
                        AppColorScheme.statusInTalks,
                        statusCounts['in_talks']!,
                      ),
                    if (statusCounts['quote_sent'] != null)
                      _buildStatusChip(
                        'Quote Sent',
                        AppColorScheme.statusQuoteSent,
                        statusCounts['quote_sent']!,
                      ),
                    if (statusCounts['new'] != null)
                      _buildStatusChip(
                        'New',
                        AppColorScheme.statusNew,
                        statusCounts['new']!,
                      ),
                    if (statusCounts['completed'] != null)
                      _buildStatusChip(
                        'Completed',
                        AppColorScheme.statusCompleted,
                        statusCounts['completed']!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (hasConflict)
          Builder(
            builder: (context) {
              final error = Theme.of(context).colorScheme.error;
              final errorContainer = Theme.of(
                context,
              ).colorScheme.errorContainer;
              return Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: errorContainer.withValues(alpha: 0.5),
                  border: Border.all(color: error.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Conflict: Multiple events on this date',
                        style: TextStyle(
                          color: error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ...selectedDayEvents.map(_buildEventListItem),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEventListItem(CalendarEvent event) {
    final dropdownLookup = ref
        .read(dropdownLookupProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return EnquiryListItem(
      enquiryId: event.enquiryId,
      data: {
        'customerName': event.customerName,
        'statusValue': event.status,
        'eventTypeLabel': event.eventType,
        'eventDate': Timestamp.fromDate(event.eventDate),
        'eventLocation': event.eventLocation,
        'createdAt': Timestamp.fromDate(event.createdAt),
        if (event.customerPhone != null) 'customerPhone': event.customerPhone,
      },
      dropdownLookup: dropdownLookup,
      compact: true,
    );
  }

  void _processEnquiries(List<QueryDocumentSnapshot<Object?>> enquiries) {
    _events.clear();
    _conflicts.clear();
    _statusCounts.clear();

    final Map<DateTime, List<CalendarEvent>> dayEvents = {};
    final Map<DateTime, Map<String, int>> dayStatusCounts = {};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final doc in enquiries) {
      final data = doc.data() as Map<String, dynamic>;
      final eventDate = _parseDateTime(data['eventDate']);
      // Skip enquiries without event dates
      if (eventDate == null) continue;

      // Get status - only use statusValue
      final status = ((data['statusValue'] as String?) ?? 'new').toLowerCase();

      // Filter out irrelevant statuses for calendar view
      // Only show: new, in_talks, quote_sent, confirmed, completed
      // Exclude: cancelled, not_interested
      if (status == 'cancelled' || status == 'not_interested') {
        continue;
      }

      // Normalize event date to start of day for comparison
      final eventDateStart = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
      );

      // Optional: Filter out past completed events (keep recent ones for reference)
      if (status == 'completed' && eventDateStart.isBefore(todayStart)) {
        // Only show completed events from the last 30 days
        final daysSinceEvent = todayStart.difference(eventDateStart).inDays;
        if (daysSinceEvent > 30) {
          continue;
        }
      }

      // Note: Past "in_talks", "new", and "quote_sent" events are NOT filtered here
      // They will be automatically marked as "not_interested" by the cleanup service
      // and will disappear once their status is updated

      final dayKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

      final event = CalendarEvent(
        enquiryId: doc.id,
        customerName: (data['customerName'] as String?) ?? 'Unknown',
        eventType:
            (data['eventTypeLabel'] as String?) ??
            (data['eventTypeValue'] as String?) ??
            (data['eventType'] as String?) ??
            'Unknown',
        eventDate: eventDate,
        eventLocation: data['eventLocation'] as String?,
        status: status,
        createdAt: _parseDateTime(data['createdAt']) ?? eventDate,
        customerPhone: data['customerPhone'] as String?,
      );

      dayEvents.putIfAbsent(dayKey, () => []).add(event);

      // Track status counts per day
      dayStatusCounts
          .putIfAbsent(dayKey, () => <String, int>{})
          .update(
            status,
            (currentCount) => currentCount + 1,
            ifAbsent: () => 1,
          );
    }

    // Identify conflicts (multiple events on same day) and store status counts
    dayEvents.forEach((day, events) {
      _events[day] = events;
      _statusCounts[day] = dayStatusCounts[day] ?? {};
      if (events.length > 1) {
        _conflicts[day] = events;
      }
    });
  }

  Widget _buildStatusIndicator(Color color, int count, bool hasConflict) {
    final conflictColor = Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(right: 2),
      width: hasConflict ? 8 : 6,
      height: hasConflict ? 8 : 6,
      decoration: BoxDecoration(
        color: hasConflict ? conflictColor : color,
        shape: BoxShape.circle,
        border: hasConflict
            ? Border.all(color: Theme.of(context).colorScheme.onError, width: 1)
            : null,
      ),
      child: count > 1
          ? Center(
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: hasConflict ? 7 : 6,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  Stream<QuerySnapshot> _getEnquiriesStream(bool isAdmin, String userId) {
    return ref
        .read(firestoreServiceProvider)
        .watchEnquiriesForRoleByEventDate(
          isAdmin: isAdmin,
          assignedToUid: userId,
        );
  }
}

/// Calendar Event Model
class CalendarEvent {
  final String enquiryId;
  final String customerName;
  final String eventType;
  final DateTime eventDate;
  final String? eventLocation;
  final String status;
  final DateTime createdAt;
  final String? customerPhone;

  CalendarEvent({
    required this.enquiryId,
    required this.customerName,
    required this.eventType,
    required this.eventDate,
    this.eventLocation,
    required this.status,
    required this.createdAt,
    this.customerPhone,
  });
}
