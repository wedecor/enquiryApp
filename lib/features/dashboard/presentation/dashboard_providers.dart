import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';

/// Key for [roleScopedEnquiriesProvider]: who is looking and which slice.
typedef RoleScopedEnquiriesKey = ({bool isAdmin, String? uid, EnquiryScope scope});

/// Key for [calendarEnquiriesProvider]: who is looking and the event-date window.
typedef CalendarEnquiriesKey = ({bool isAdmin, String? uid, DateTime start, DateTime end});

/// One shared Firestore listener per (role, uid, status slice).
///
/// Dashboard tabs, the Today counters and the Kanban board all watch this, so
/// switching tabs or rebuilding never opens a second listener; consumers
/// filter the documents in memory.
final roleScopedEnquiriesProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Object?>>, RoleScopedEnquiriesKey>((ref, key) {
      return ref
          .watch(firestoreServiceProvider)
          .watchEnquiriesForRoleScope(
            isAdmin: key.isAdmin,
            assignedToUid: key.uid,
            scope: key.scope,
          )
          .map((snapshot) => snapshot.docs);
    });

/// A booking's functions span days, not months: its `eventDate` (= LAST function)
/// is less than this after its first function.
const Duration calendarFunctionSpan = Duration(days: 31);

/// Calendar listener for enquiries with a function in the key's window.
///
/// `eventDate` is the booking's LAST function, so the query end is extended by
/// [calendarFunctionSpan] to also find bookings that start inside the window and
/// end after it; callers filter by each function's own day.
final calendarEnquiriesProvider = StreamProvider.autoDispose
    .family<List<QueryDocumentSnapshot<Object?>>, CalendarEnquiriesKey>((ref, key) {
      return ref
          .watch(firestoreServiceProvider)
          .watchEnquiriesForRoleByEventDate(
            isAdmin: key.isAdmin,
            assignedToUid: key.uid,
            start: key.start,
            end: key.end.add(calendarFunctionSpan),
          )
          .map((snapshot) => snapshot.docs);
    });

/// Watches [scopes] for the given viewer and merges them into one value.
///
/// Errors win over loading; the merged value is only available once every
/// slice has emitted.
AsyncValue<List<QueryDocumentSnapshot<Object?>>> watchRoleScopedEnquiries(
  WidgetRef ref, {
  required bool isAdmin,
  required String? uid,
  required List<EnquiryScope> scopes,
}) {
  // Watch every slice up front so none is dropped while another is erroring.
  final values = [
    for (final scope in scopes)
      ref.watch(roleScopedEnquiriesProvider((isAdmin: isAdmin, uid: uid, scope: scope))),
  ];
  final docs = <QueryDocumentSnapshot<Object?>>[];
  var loading = false;
  for (final value in values) {
    if (value.hasError) {
      return AsyncValue.error(value.error!, value.stackTrace ?? StackTrace.current);
    }
    final slice = value.valueOrNull;
    if (slice == null) {
      loading = true;
    } else {
      docs.addAll(slice);
    }
  }
  if (loading) return const AsyncValue.loading();
  return AsyncValue.data(docs);
}

/// Dashboard status tab → slices of enquiries it needs.
List<EnquiryScope> enquiryScopesForDashboardTab(String tab) {
  switch (tab) {
    case 'completed':
      return const [EnquiryScope.completed];
    case 'closed':
      return const [EnquiryScope.lost];
    case 'All':
      return EnquiryScope.values;
    default:
      // new, in_talks, reminders (In Talks), approved.
      return const [EnquiryScope.active];
  }
}
