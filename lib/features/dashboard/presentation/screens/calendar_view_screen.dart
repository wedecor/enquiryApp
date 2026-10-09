import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../enquiries/presentation/screens/enquiry_form_screen.dart';
import '../../../enquiries/presentation/widgets/enquiry_list_item.dart';
import '../dashboard_providers.dart';
import '../widgets/calendar_day_agenda.dart';
import '../widgets/calendar_day_markers.dart';
import '../widgets/calendar_event.dart';
import '../widgets/calendar_month_panel.dart';

export '../widgets/calendar_event.dart';

/// Calendar View Screen - Shows relevant enquiries on a calendar
/// Filters out lost events (cancelled, not_interested, closed_lost)
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

  /// Months loaded either side of [_windowAnchor] (13-month event-date window).
  static const int _windowMonthsBefore = 6;
  static const int _windowMonthsAfter = 7;

  /// First day of the month the loaded event-date window is centred on.
  late DateTime _windowAnchor;

  /// Last loaded documents, shown while a re-centred window is loading.
  List<QueryDocumentSnapshot<Object?>>? _lastEnquiries;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _windowAnchor = DateTime(_focusedDay.year, _focusedDay.month);
  }

  DateTime get _windowStart =>
      DateTime(_windowAnchor.year, _windowAnchor.month - _windowMonthsBefore);

  DateTime get _windowEnd => DateTime(_windowAnchor.year, _windowAnchor.month + _windowMonthsAfter);

  /// Re-centres the loaded window once [focusedDay] gets within a month of
  /// either edge, so paging the calendar never shows an unloaded month.
  void _ensureWindowCovers(DateTime focusedDay) {
    final month = DateTime(focusedDay.year, focusedDay.month);
    final safeStart = DateTime(_windowStart.year, _windowStart.month + 1);
    final safeEnd = DateTime(_windowEnd.year, _windowEnd.month - 1);
    if (month.isBefore(safeStart) || !month.isBefore(safeEnd)) {
      setState(() => _windowAnchor = month);
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

    final enquiriesAsync = ref.watch(
      calendarEnquiriesProvider((
        isAdmin: isAdmin,
        uid: userId,
        start: _windowStart,
        end: _windowEnd,
      )),
    );
    return Builder(
      builder: (context) {
        if (enquiriesAsync.hasError) {
          return Center(child: Text('Error: ${enquiriesAsync.error}'));
        }

        final enquiries = enquiriesAsync.valueOrNull ?? _lastEnquiries;
        if (enquiries == null) {
          return const Center(child: CircularProgressIndicator());
        }
        _lastEnquiries = enquiries;
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
                      _ensureWindowCovers(focusedDay);
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
      left: 1,
      right: 1,
      bottom: 3,
      child: CalendarDayMarkers(
        colors: [
          for (final (value, _, color) in _breakdownStatuses)
            if ((statusCounts[value] ?? 0) > 0) color,
        ],
        total: events.length,
        hasConflict: _conflicts.containsKey(dayKey),
        // Approved bookings in the loaded (role-scoped) data — no extra query.
        booked: statusCounts[EnquiryStatus.approved.value] ?? 0,
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

    // One entry per FUNCTION on its own day ("Ayesha · Haldi (1/4)"); legacy
    // enquiries give one entry on their event date. The query window is wider than
    // the calendar window (see calendarEnquiriesProvider), so filter by day here.
    for (final doc in enquiries) {
      final data = doc.data() as Map<String, dynamic>;
      final entries = calendarEventsForEnquiry(
        enquiryId: doc.id,
        data: data,
        windowStart: _windowStart,
        windowEnd: _windowEnd,
        now: now,
      );
      for (final event in entries) {
        final dayKey = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
        dayEvents.putIfAbsent(dayKey, () => []).add(event);
        // Status counts per day count functions ("N booked" = approved functions).
        dayStatusCounts
            .putIfAbsent(dayKey, () => <String, int>{})
            .update(event.status, (currentCount) => currentCount + 1, ifAbsent: () => 1);
      }
    }

    // A day is a conflict only when approved functions of 2+ different bookings share it
    dayEvents.forEach((day, events) {
      _events[day] = events;
      _statusCounts[day] = dayStatusCounts[day] ?? {};
      final approved = events
          .where((e) => e.status == EnquiryStatus.approved.value)
          .toList(growable: false);
      if (approved.map((e) => e.enquiryId).toSet().length > 1) {
        _conflicts[day] = approved;
      }
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }
}
