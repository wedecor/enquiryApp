import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/past_enquiry_cleanup_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../../enquiries/presentation/widgets/enquiry_list_item.dart';
import '../widgets/calendar_day_agenda.dart';
import '../widgets/calendar_day_markers.dart';
import '../widgets/calendar_event.dart';
import '../widgets/calendar_month_panel.dart';

export '../widgets/calendar_event.dart';

/// Calendar View Screen - Shows relevant enquiries on a calendar
/// Filters out cancelled and not_interested events
/// Shows: new, in_talks, approved, and recent completed events
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
        data: (role) => _buildCalendarContent(context, user, role == UserRole.admin),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _buildCalendarContent(context, user, false),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) => Center(child: Text('Error: $error')),
    );

    if (widget.embeddedInShell) {
      return body;
    }

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Calendar View'),
          actions: [
            if (roleAsync.valueOrNull == UserRole.admin)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(builder: (context) => const EnquiryFormScreen()),
                  );
                },
                tooltip: 'Add New Enquiry',
              ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _buildCalendarContent(BuildContext context, UserModel? user, bool isAdmin) {
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

        final selectedDayKey = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space3,
                AppTokens.space4,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 0,
                  child: CalendarMonthPanel(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    legend: const [
                      ('Approved', AppColorScheme.statusConfirmed),
                      ('In Talks', AppColorScheme.statusInTalks),
                      ('New', AppColorScheme.statusNew),
                      ('Completed', AppColorScheme.statusCompleted),
                    ],
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
                    markerBuilder: _buildDayMarkers,
                  ),
                ),
              ),
            ),
            CalendarDayAgenda(
              day: _selectedDay,
              events: _getEventsForDay(_selectedDay),
              statusCounts: _statusCounts[selectedDayKey] ?? const {},
              hasConflict: _conflicts.containsKey(selectedDayKey),
              statuses: _breakdownStatuses,
              itemBuilder: _buildEventListItem,
            ),
          ],
        );
      },
    );
  }

  /// Statuses shown as day markers and in the agenda breakdown, in order.
  static const List<(String, String, Color)> _breakdownStatuses = [
    ('approved', 'Approved', AppColorScheme.statusConfirmed),
    ('in_talks', 'In Talks', AppColorScheme.statusInTalks),
    ('new', 'New', AppColorScheme.statusNew),
    ('completed', 'Completed', AppColorScheme.statusCompleted),
  ];

  Widget? _buildDayMarkers(BuildContext context, DateTime date, List<CalendarEvent> events) {
    if (events.isEmpty) return null;

    final dayKey = DateTime(date.year, date.month, date.day);
    final statusCounts = _statusCounts[dayKey];

    if (statusCounts == null || statusCounts.isEmpty) {
      return null;
    }

    return Positioned(
      bottom: 3,
      child: CalendarDayMarkers(
        colors: [
          for (final (value, _, color) in _breakdownStatuses)
            if ((statusCounts[value] ?? 0) > 0) color,
        ],
        total: events.length,
        hasConflict: _conflicts.containsKey(dayKey),
      ),
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

      // Get canonical status from statusValue (maps legacy confirmed → approved, etc.)
      final rawStatus = ((data['statusValue'] as String?) ?? 'new').toLowerCase();
      final status = EnquiryStatus.fromValue(rawStatus)?.value ?? rawStatus;

      // Filter out irrelevant statuses for calendar view
      // Only show: new, in_talks, approved, completed
      // Exclude: cancelled, not_interested
      if (status == 'cancelled' || status == 'not_interested') {
        continue;
      }

      // Normalize event date to start of day for comparison
      final eventDateStart = DateTime(eventDate.year, eventDate.month, eventDate.day);

      // Optional: Filter out past completed events (keep recent ones for reference)
      if (status == 'completed' && eventDateStart.isBefore(todayStart)) {
        // Only show completed events from the last 30 days
        final daysSinceEvent = todayStart.difference(eventDateStart).inDays;
        if (daysSinceEvent > 30) {
          continue;
        }
      }

      // Note: Past "in_talks" and "new" events are NOT filtered here
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
          .update(status, (currentCount) => currentCount + 1, ifAbsent: () => 1);
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
        .watchEnquiriesForRoleByEventDate(isAdmin: isAdmin, assignedToUid: userId);
  }
}
