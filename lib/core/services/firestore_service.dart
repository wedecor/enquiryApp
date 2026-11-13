import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/enquiries/domain/event_functions.dart';
import '../constants/firestore_schema.dart';
import '../constants/status_vocabulary.dart';
import '../logging/logger.dart';
import '../utils/enquiry_fields.dart';
import '../utils/phone_normalizer.dart';
import 'enquiry_financials.dart';

/// Status slice of the enquiries collection loaded by a role-scoped listener.
enum EnquiryScope {
  /// New, In Talks and Approved — the open pipeline (unbounded).
  active,

  /// Completed enquiries (most recent only).
  completed,

  /// Not Interested, Closed Lost and Cancelled (most recent only).
  lost,
}

/// Service class for handling all Firestore database operations.
///
/// This service provides a clean abstraction over Firebase Firestore,
/// handling CRUD operations for users, enquiries, and dropdown data.
/// It manages the application's data layer and provides streams for
/// real-time data synchronization.
///
/// The service is organized around the main entities:
/// - **Users**: User management and authentication data
/// - **Enquiries**: Customer enquiry management
/// - **Dropdowns**: Event types, statuses, and payment statuses
///
/// Example usage:
/// ```dart
/// final firestoreService = FirestoreService();
///
/// // Create a new enquiry
/// final enquiryId = await firestoreService.createEnquiry(
///   customerName: 'John Doe',
///   customerEmail: 'john@example.com',
///   // ... other parameters
/// );
///
/// // Real-time, role-scoped enquiries for a viewer
/// final enquiriesStream = firestoreService.watchEnquiriesForRole(isAdmin: true);
/// ```
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// The underlying Firebase Firestore instance.
  final FirebaseFirestore _firestore;

  /// Shared client for specialized repositories. Prefer typed helpers when available.
  FirebaseFirestore get firestore => _firestore;

  // Collection references
  /// Reference to the users collection in Firestore.
  CollectionReference get _usersCollection => _firestore.collection(FirestoreCollections.users);

  /// Reference to the enquiries collection in Firestore.
  CollectionReference get _enquiriesCollection =>
      _firestore.collection(FirestoreCollections.enquiries);

  /// Reference to the soft-deleted enquiries trash collection in Firestore.
  CollectionReference<Map<String, dynamic>> get _enquiriesTrashCollection =>
      _firestore.collection('enquiries_trash');

  /// Enquiries collection for feature repositories (single Firestore access path).
  CollectionReference<Map<String, dynamic>> get enquiriesCollection =>
      _enquiriesCollection as CollectionReference<Map<String, dynamic>>;

  /// Customer identity key (last 10 digits) — see [normalizePhone].
  static String _normalizePhone(String? phone) => normalizePhone(phone);

  static String _makeTextIndex({
    required String name,
    String? phone,
    String? email,
    String? notes,
    List<String> eventTypes = const [],
  }) => [
    name,
    phone ?? '',
    email ?? '',
    notes ?? '',
    ...eventTypes.map((t) => t.trim()).where((t) => t.isNotEmpty),
  ].join(' ').toLowerCase();

  /// Search fields for an enquiry. [eventTypes] = every function's event type label
  /// (multi-function bookings) so searching "haldi" finds the booking.
  static Map<String, dynamic> searchIndexFieldsFor({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
    String? notes,
    List<String> eventTypes = const [],
  }) => _searchIndexFields(
    customerName: customerName,
    customerPhone: customerPhone,
    customerEmail: customerEmail,
    description: description,
    notes: notes,
    eventTypes: eventTypes,
  );

  static Map<String, dynamic> _searchIndexFields({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
    String? notes,
    List<String> eventTypes = const [],
  }) {
    final email = customerEmail?.toLowerCase();
    return {
      'customerNameLower': customerName.toLowerCase(),
      'phoneNormalized': _normalizePhone(customerPhone),
      if (email != null) 'customerEmail': email,
      'textIndex': _makeTextIndex(
        name: customerName,
        phone: customerPhone,
        email: email,
        notes: notes ?? description,
        eventTypes: eventTypes,
      ),
    };
  }

  /// Retrieves a user document by UID.
  ///
  /// This method fetches the user data from Firestore using the provided UID.
  ///
  /// Parameters:
  /// - [uid]: The unique identifier of the user to retrieve
  ///
  /// Returns a [Future<Map<String, dynamic>?>] containing the user data,
  /// or `null` if no user is found with the given UID.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// final userData = await firestoreService.getUser('user123');
  /// if (userData != null) {
  ///   print('User name: ${userData['name']}');
  /// }
  /// ```
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  /// Real-time stream for a single user profile document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) {
    return (_usersCollection.doc(uid) as DocumentReference<Map<String, dynamic>>).snapshots();
  }

  /// Per-user saved enquiry filter views (`users/{uid}/savedViews`).
  CollectionReference<Map<String, dynamic>> savedViewsCollection(String userId) {
    return _usersCollection.doc(userId).collection('savedViews');
  }

  /// Starts a Firestore write batch (for multi-document updates).
  WriteBatch startBatch() => _firestore.batch();

  /// All enquiry documents (admin cleanup / export).
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAllEnquiries() {
    return enquiriesCollection.get();
  }

  /// FCM device tokens (`users/{uid}/private/notifications/tokens`).
  CollectionReference<Map<String, dynamic>> fcmTokensCollection(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('private')
        .doc('notifications')
        .collection('tokens');
  }

  Future<void> saveFcmToken(String uid, String token, {bool refreshed = false}) async {
    await fcmTokensCollection(uid).doc(token).set({
      'token': token,
      if (refreshed)
        'updatedAt': FieldValue.serverTimestamp()
      else
        'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteFcmToken(String uid, String token) async {
    await fcmTokensCollection(uid).doc(token).delete();
  }

  /// Creates a new enquiry document in Firestore.
  ///
  /// This method creates a comprehensive enquiry record with all the
  /// provided customer and event information. The enquiry is automatically
  /// assigned a default status and payment status.
  ///
  /// Parameters:
  /// - [customerName]: Name of the customer making the enquiry
  /// - [customerEmail]: Customer's email address
  /// - [customerPhone]: Customer's phone number
  /// - [eventType]: Type of event (e.g., Wedding, Birthday, Corporate)
  /// - [eventDate]: Date when the event will take place
  /// - [eventLocation]: Location where the event will be held
  /// - [guestCount]: Number of expected guests
  /// - [budgetRange]: Customer's budget range
  /// - [description]: Detailed description of the event requirements
  /// - [createdBy]: UID of the user who created the enquiry
  /// - [priority]: Priority level of the enquiry (High, Medium, Low)
  /// - [source]: Source of the enquiry (Website, Phone, Walk-in, etc.)
  /// - [totalCost]: Total estimated cost (optional, admin only)
  /// - [advancePaid]: Amount of advance payment received (optional, admin only)
  /// - [paymentStatus]: Current payment status (optional, defaults to "Pending")
  /// - [assignedTo]: UID of the user assigned to handle the enquiry (optional)
  ///
  /// Returns a [Future<String>] containing the ID of the created enquiry.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// final enquiryId = await firestoreService.createEnquiry(
  ///   customerName: 'John Doe',
  ///   customerEmail: 'john@example.com',
  ///   customerPhone: '+1234567890',
  ///   eventType: 'Wedding',
  ///   eventDate: DateTime.now().add(Duration(days: 30)),
  ///   eventLocation: 'Grand Hotel',
  ///   guestCount: 150,
  ///   budgetRange: '5000-10000',
  ///   description: 'Traditional wedding with modern decor',
  ///   createdBy: 'admin123',
  ///   priority: 'High',
  ///   source: 'Website',
  /// );
  /// ```
  Future<String> createEnquiry({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String eventType,
    required DateTime eventDate,
    required String eventLocation,
    required int guestCount,
    required String budgetRange,
    required String description,
    required String createdBy,
    required String priority,
    required String source,
    double? totalCost,
    double? advancePaid,
    String? paymentStatus,
    String? assignedTo,
    String statusValue = 'new',
    String? statusLabel,
    String? eventTypeLabel,
    String? priorityLabel,
    String? sourceLabel,
    String? paymentStatusLabel,
    String? whatsappNumber,
    String? locationPlaceId,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
    String? locationArea,
    String? locationCity,
    List<EventFunction>? functions,
    String? enquiryId,
    Map<String, dynamic>? extraFinancialFields,
  }) async {
    final placeId = locationPlaceId?.trim() ?? '';
    // Multi-function booking (or one function with a time / notes): write the
    // functions and their synced top-level fields over the single-event ones.
    final functionFields =
        functions != null && functions.isNotEmpty && needsFunctionArray(functions)
        ? (Map<String, Object?>.of(functionSyncFields(functions))
            ..removeWhere((key, value) => value == null))
        : const <String, Object?>{};
    final typeLabels = functions != null && functions.isNotEmpty
        ? functionTypeLabels(functions)
        : [eventTypeLabel ?? eventType];
    final enquiryData = {
      'customerName': customerName,
      if (customerEmail.trim().isNotEmpty) 'customerEmail': customerEmail.toLowerCase(),
      'customerPhone': customerPhone,
      if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty)
        'whatsappNumber': whatsappNumber.trim(),
      'eventType': eventType,
      'eventDate': eventDate,
      'eventLocation': eventLocation,
      // Optional Google Maps place picked in the Location field.
      if (placeId.isNotEmpty) ...{
        'locationPlaceId': placeId,
        if (locationAddress != null && locationAddress.trim().isNotEmpty)
          'locationAddress': locationAddress.trim(),
        if (locationLat != null && locationLng != null) ...{
          'locationLat': locationLat,
          'locationLng': locationLng,
        },
        if (locationArea != null && locationArea.trim().isNotEmpty)
          'locationArea': locationArea.trim(),
        if (locationCity != null && locationCity.trim().isNotEmpty)
          'locationCity': locationCity.trim(),
      },
      if (guestCount > 0) 'guestCount': guestCount,
      if (budgetRange.trim().isNotEmpty) 'budgetRange': budgetRange,
      ...enquiryNotesFields(description),
      // Only use statusValue - standard field
      'statusValue': statusValue,
      if (statusLabel != null) 'statusLabel': statusLabel,
      'eventTypeValue': eventType,
      if (eventTypeLabel != null) 'eventTypeLabel': eventTypeLabel,
      'paymentStatus': paymentStatus ?? 'pending',
      'paymentStatusValue': paymentStatus ?? 'pending',
      if (paymentStatusLabel != null) 'paymentStatusLabel': paymentStatusLabel,
      'totalCost': totalCost,
      'advancePaid': advancePaid,
      'assignedTo': assignedTo,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'priority': priority,
      'priorityValue': priority,
      if (priorityLabel != null) 'priorityLabel': priorityLabel,
      'source': source,
      'sourceValue': source,
      if (sourceLabel != null) 'sourceLabel': sourceLabel,
      ..._searchIndexFields(
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        description: description,
        notes: description,
        eventTypes: typeLabels,
      ),
      ...functionFields,
      if (extraFinancialFields != null) ...extraFinancialFields,
    };

    return _createWithFinancials(enquiryData, enquiryId: enquiryId);
  }

  /// Generates a new Firestore document ID under `enquiries`.
  String newEnquiryId() => _enquiriesCollection.doc().id;

  /// Writes a new enquiry (without money) and its admin-only financial summary in
  /// one batch. See [EnquiryFinancials].
  Future<String> _createWithFinancials(Map<String, dynamic> data, {String? enquiryId}) async {
    final parts = EnquiryFinancials.split(data);
    final docRef = enquiryId != null ? _enquiriesCollection.doc(enquiryId) : _enquiriesCollection.doc();
    final batch = firestore.batch()..set(docRef, parts.parent);
    if (parts.money.isNotEmpty) {
      batch.set(
        EnquiryFinancials.ref(firestore, docRef.id),
        EnquiryFinancials.summaryWrite(parts.money),
      );
    }
    await batch.commit();
    return docRef.id;
  }

  /// Creates an enquiry from a pre-built data map (used by tests/admin tooling).
  Future<String> createEnquiryFromData(Map<String, dynamic> data) async {
    final name = (data['customerName'] as String?) ?? '';
    final payload = {
      ...data,
      ..._searchIndexFields(
        customerName: name,
        customerPhone: data['customerPhone'] as String?,
        customerEmail: data['customerEmail'] as String?,
        description: data['description'] as String?,
        notes: data['notes'] as String?,
      ),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return _createWithFinancials(payload);
  }

  /// Retrieves a real-time stream of enquiries filtered by status.
  ///
  /// This method returns a stream of enquiries that match the specified
  /// status. Useful for displaying enquiries in different tabs or sections
  /// based on their current status.
  ///
  /// Parameters:
  /// - [status]: The status to filter by (e.g., "New", "In Progress", "Completed")
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits enquiries with the specified status.
  ///
  /// Example:
  /// ```dart
  /// final newEnquiriesStream = firestoreService.getEnquiriesByStatus('New');
  /// newEnquiriesStream.listen((snapshot) {
  ///   print('Found ${snapshot.docs.length} new enquiries');
  /// });
  /// ```
  Stream<QuerySnapshot> getEnquiriesByStatus(String status) {
    return _enquiriesCollection
        .where('statusValue', whereIn: EnquiryStatus.rawValuesFor(status))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Default cap for [watchEnquiriesForRole] (most recent by `createdAt`).
  static const int recentEnquiriesLimit = 500;

  /// Cap for the terminal (completed / lost) slices in [watchEnquiriesForRoleScope].
  static const int terminalEnquiriesLimit = 200;

  /// Stored `statusValue`s (canonical + legacy aliases) covered by [scope].
  ///
  /// Active work is New, In Talks and Approved (booked, not yet delivered).
  static List<String> rawStatusValuesForScope(EnquiryScope scope) {
    final statuses = switch (scope) {
      EnquiryScope.active => const [
        EnquiryStatus.newEnquiry,
        EnquiryStatus.inTalks,
        EnquiryStatus.approved,
      ],
      EnquiryScope.completed => const [EnquiryStatus.completed],
      EnquiryScope.lost => [
        for (final status in EnquiryStatus.values)
          if (status.category == StatusCategory.lost) status,
      ],
    };
    return [for (final status in statuses) ...EnquiryStatus.rawValuesFor(status.value)];
  }

  /// Real-time enquiries stream scoped by role (admin: all, staff: assigned only).
  ///
  /// Bounded to the most recent [limit] enquiries by `createdAt` (pass `null`
  /// for no cap). Dashboard / Kanban use [watchEnquiriesForRoleScope] instead.
  Stream<QuerySnapshot> watchEnquiriesForRole({
    required bool isAdmin,
    String? assignedToUid,
    int? limit = recentEnquiriesLimit,
  }) {
    Query query = _enquiriesCollection;
    if (!isAdmin) {
      query = query.where('assignedTo', isEqualTo: assignedToUid);
    }
    query = query.orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.snapshots();
  }

  /// Role-scoped stream of one status slice of the enquiries collection.
  ///
  /// [EnquiryScope.active] is unbounded (the open pipeline is small and must be
  /// complete); the terminal slices are capped at [terminalEnquiriesLimit],
  /// newest first. Uses the `statusValue + createdAt DESC` indexes (staff:
  /// `assignedTo + statusValue + createdAt DESC`).
  Stream<QuerySnapshot> watchEnquiriesForRoleScope({
    required bool isAdmin,
    String? assignedToUid,
    required EnquiryScope scope,
  }) {
    Query query = _enquiriesCollection;
    if (!isAdmin) {
      query = query.where('assignedTo', isEqualTo: assignedToUid);
    }
    query = query
        .where('statusValue', whereIn: rawStatusValuesForScope(scope))
        .orderBy('createdAt', descending: true);
    if (scope != EnquiryScope.active) {
      query = query.limit(terminalEnquiriesLimit);
    }
    return query.snapshots();
  }

  /// Approved bookings stay in the live dashboard listener while their last
  /// function day (`eventDate`) is at most this far in the past — the calendar's
  /// look-back. Older approved bookings are auto-completed, so the listener never
  /// carries the whole Approved history.
  static const Duration approvedLiveLookback = Duration(days: 31);

  /// The open pipeline is logged once per session when it grows past this.
  static const int activePipelineLogThreshold = 1500;
  static bool _activeCountLogged = false;

  /// Live documents of the active dashboard scope for a viewer:
  /// every New / In Talks enquiry (never capped — hiding open work is worse than
  /// the read cost) plus Approved bookings whose last function day is within
  /// [approvedLiveLookback] (indexes `statusValue + eventDate`, staff
  /// `assignedTo + statusValue + eventDate`). Emits once both queries have.
  Stream<List<QueryDocumentSnapshot<Object?>>> watchActiveEnquiryDocs({
    required bool isAdmin,
    String? assignedToUid,
    DateTime? now,
  }) {
    Query base = _enquiriesCollection;
    if (!isAdmin) base = base.where('assignedTo', isEqualTo: assignedToUid);
    final open = base
        .where(
          'statusValue',
          whereIn: [
            ...EnquiryStatus.rawValuesFor(EnquiryStatus.newEnquiry.value),
            ...EnquiryStatus.rawValuesFor(EnquiryStatus.inTalks.value),
          ],
        )
        .orderBy('createdAt', descending: true);
    final today = now ?? DateTime.now();
    final approvedFrom = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(approvedLiveLookback);
    final approved = base
        .where('statusValue', whereIn: EnquiryStatus.rawValuesFor(EnquiryStatus.approved.value))
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(approvedFrom))
        .orderBy('eventDate');
    _logLargeActivePipelineOnce(isAdmin: isAdmin, assignedToUid: assignedToUid);
    return combineLatestDocs(open.snapshots(), approved.snapshots());
  }

  /// Merges two query streams: emits the docs of both once each has emitted, and
  /// again whenever either changes. Errors from either are forwarded.
  static Stream<List<QueryDocumentSnapshot<Object?>>> combineLatestDocs(
    Stream<QuerySnapshot> a,
    Stream<QuerySnapshot> b,
  ) {
    late StreamController<List<QueryDocumentSnapshot<Object?>>> controller;
    StreamSubscription<QuerySnapshot>? subA;
    StreamSubscription<QuerySnapshot>? subB;
    QuerySnapshot? lastA;
    QuerySnapshot? lastB;
    void emit() {
      if (lastA != null && lastB != null) controller.add([...lastA!.docs, ...lastB!.docs]);
    }

    controller = StreamController<List<QueryDocumentSnapshot<Object?>>>(
      onListen: () {
        subA = a.listen((s) {
          lastA = s;
          emit();
        }, onError: controller.addError);
        subB = b.listen((s) {
          lastB = s;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await subA?.cancel();
        await subB?.cancel();
      },
    );
    return controller.stream;
  }

  /// One `count()` of the active scope per session; above
  /// [activePipelineLogThreshold] a single line with the count and role only.
  void _logLargeActivePipelineOnce({required bool isAdmin, String? assignedToUid}) {
    if (_activeCountLogged) return;
    _activeCountLogged = true;
    Query query = _enquiriesCollection;
    if (!isAdmin) query = query.where('assignedTo', isEqualTo: assignedToUid);
    query
        .where('statusValue', whereIn: rawStatusValuesForScope(EnquiryScope.active))
        .count()
        .get()
        .then((snap) {
          final count = snap.count ?? 0;
          if (count > activePipelineLogThreshold) {
            Log.w('dashboard_active_pipeline_large', data: {'count': count, 'admin': isAdmin});
          }
        }, onError: (Object _) {});
  }

  /// Rows per page when [fetchEnquiriesForRole] walks the collection.
  static const int exportPageSize = 500;

  /// Every enquiry the user may export, newest first (`createdAt DESC`), as pages of
  /// [pageSize] rows walked with `startAfterDocument`; no row cap. Each row carries
  /// its `id`. Admin rows include money from the financial summaries (legacy parent
  /// fields as fallback); staff rows are their assigned enquiries without money.
  Stream<List<Map<String, dynamic>>> fetchEnquiriesForRole({
    required bool isAdmin,
    String? assignedToUid,
    int pageSize = exportPageSize,
  }) async* {
    if (!isAdmin && (assignedToUid == null || assignedToUid.isEmpty)) return;
    Query<Map<String, dynamic>> query = enquiriesCollection;
    if (!isAdmin) query = query.where('assignedTo', isEqualTo: assignedToUid);
    query = query.orderBy('createdAt', descending: true).limit(pageSize);

    final summaries = isAdmin
        ? await EnquiryFinancials.readAllAvailable(firestore)
        : const <String, Map<String, dynamic>>{};
    DocumentSnapshot<Map<String, dynamic>>? last;
    while (true) {
      final page = await (last == null ? query : query.startAfterDocument(last)).get();
      if (page.docs.isEmpty) return;
      yield [
        for (final doc in page.docs)
          isAdmin
              ? EnquiryFinancials.merge({'id': doc.id, ...doc.data()}, summaries[doc.id])
              : EnquiryFinancials.strip({'id': doc.id, ...doc.data()}),
      ];
      if (page.docs.length < pageSize) return;
      last = page.docs.last;
    }
  }

  /// Retrieves a specific enquiry by its ID.
  ///
  /// This method fetches a single enquiry document from Firestore
  /// using the provided enquiry ID.
  ///
  /// Parameters:
  /// - [enquiryId]: The unique identifier of the enquiry to retrieve
  ///
  /// Returns a [Future<Map<String, dynamic>?>] containing the enquiry data,
  /// or `null` if no enquiry is found with the given ID.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// final enquiryData = await firestoreService.getEnquiry('enquiry123');
  /// if (enquiryData != null) {
  ///   print('Customer: ${enquiryData['customerName']}');
  ///   print('Event Type: ${enquiryData['eventType']}');
  /// }
  /// ```
  Future<Map<String, dynamic>?> getEnquiry(String enquiryId) async {
    final doc = await _enquiriesCollection.doc(enquiryId).get();
    return doc.data() as Map<String, dynamic>?;
  }

  /// Real-time stream for a single enquiry document.
  Stream<DocumentSnapshot> watchEnquiry(String enquiryId) {
    return _enquiriesCollection.doc(enquiryId).snapshots();
  }

  /// Dropdown items from `dropdowns/{kind}/items` (no `orderBy` — callers filter
  /// / sort client-side so a doc missing `order` or `active` cannot blank the list).
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveDropdownItems(String kind) {
    return _dropdownItemsCollection(kind).snapshots();
  }

  /// One-shot fetch of dropdown items (e.g. dashboard color priming).
  Future<QuerySnapshot<Map<String, dynamic>>> fetchActiveDropdownItems(String kind) {
    return _dropdownItemsCollection(kind).get();
  }

  /// Active dropdown options as label/value maps for form widgets.
  Future<List<Map<String, String>>> fetchActiveDropdownOptions(String kind) async {
    final snapshot = await fetchActiveDropdownItems(kind);
    return parseDropdownOptions(snapshot.docs);
  }

  /// Parses dropdown documents into active label/value maps.
  static List<Map<String, String>> parseDropdownOptions(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) => parseDropdownOptionMaps(docs.map((doc) => (doc.id, doc.data())));

  /// Missing `active` counts as active (same as website `loadEventTypes`).
  /// Missing `value` falls back to the document id. Sorted by `order` then label.
  static List<Map<String, String>> parseDropdownOptionMaps(
    Iterable<(String, Map<String, dynamic>)> docs,
  ) {
    final parsed = <({int order, String label, String value})>[];
    for (final (id, data) in docs) {
      if (data['active'] == false) continue;
      final rawValue = data['value'];
      final value = rawValue is String && rawValue.trim().isNotEmpty ? rawValue.trim() : id;
      if (value.isEmpty) continue;
      final rawLabel = data['label'];
      final label = rawLabel is String && rawLabel.trim().isNotEmpty ? rawLabel.trim() : value;
      final order = data['order'] is num ? (data['order'] as num).toInt() : 0;
      parsed.add((order: order, label: label, value: value));
    }
    parsed.sort((a, b) {
      final byOrder = a.order.compareTo(b.order);
      return byOrder != 0 ? byOrder : a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    return [
      for (final item in parsed) {'label': item.label, 'value': item.value},
    ];
  }

  /// Value→label map for a dropdown kind (includes inactive items for history display).
  Future<Map<String, String>> fetchDropdownValueLabelMap(String kind) async {
    final snapshot = await _firestore.collection('dropdowns').doc(kind).collection('items').get();
    return parseValueLabelMap(kind, snapshot.docs.map((doc) => (doc.id, doc.data())));
  }

  /// Value→label map from dropdown item docs: inactive items are skipped, and
  /// for statuses only items whose own value is canonical count, so a legacy
  /// alias (e.g. `quote_sent`) can never rename a canonical status.
  static Map<String, String> parseValueLabelMap(
    String kind,
    Iterable<(String, Map<String, dynamic>)> docs,
  ) {
    final map = <String, String>{};
    for (final (id, data) in docs) {
      if (data['active'] == false) continue;
      final value = (data['value'] ?? id).toString().trim();
      if (value.isEmpty) continue;
      if (kind == 'statuses' && !EnquiryStatus.values.any((s) => s.value == value)) continue;
      final label = (data['label'] ?? value).toString();
      map[value] = label;
    }
    return map;
  }

  CollectionReference<Map<String, dynamic>> _dropdownItemsCollection(String kind) {
    return _firestore.collection('dropdowns').doc(kind).collection('items');
  }

  /// Active status options for enquiry status dropdowns.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveStatusDropdownItems() =>
      watchActiveDropdownItems('statuses');

  /// Calendar view: enquiries with `eventDate` in [[start], [end]), ordered by
  /// event date (role-scoped). Staff uses the `assignedTo + eventDate` index.
  Stream<QuerySnapshot> watchEnquiriesForRoleByEventDate({
    required bool isAdmin,
    String? assignedToUid,
    required DateTime start,
    required DateTime end,
  }) {
    Query query = _enquiriesCollection;
    if (!isAdmin && assignedToUid != null) {
      query = query.where('assignedTo', isEqualTo: assignedToUid);
    }
    return query
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('eventDate', isLessThan: Timestamp.fromDate(end))
        .orderBy('eventDate', descending: false)
        .snapshots();
  }

  /// Updates an existing enquiry document.
  ///
  /// This method updates the specified enquiry with new data.
  /// The `updatedAt` timestamp is automatically set to the current time.
  ///
  /// Parameters:
  /// - [enquiryId]: The unique identifier of the enquiry to update
  /// - [data]: Map containing the fields to update
  ///
  /// Returns a [Future<void>] that completes when the update is finished.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails or enquiry doesn't exist
  ///
  /// Example:
  /// ```dart
  /// await firestoreService.updateEnquiry('enquiry123', {
  ///   'status': 'In Progress',
  ///   'assignedTo': 'staff456',
  /// });
  /// ```
  Future<void> updateEnquiry(String enquiryId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _enquiriesCollection.doc(enquiryId).update(data);
  }

  /// Admin read: the enquiry with its money taken from the financial summary
  /// (falling back to legacy parent fields). Non-admins can't read the summary;
  /// for them this returns the parent without money fields.
  Future<Map<String, dynamic>?> getEnquiryWithFinancials(String enquiryId) async {
    final parent = await getEnquiry(enquiryId);
    if (parent == null) return null;
    try {
      return EnquiryFinancials.merge(parent, await EnquiryFinancials.read(firestore, enquiryId));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      return EnquiryFinancials.strip(parent);
    }
  }

  /// [updateEnquiry] that sends money fields to the financial summary (admin only)
  /// in the same batch; the parent never receives them.
  Future<void> updateEnquiryWithFinancials(String enquiryId, Map<String, dynamic> data) async {
    final parts = EnquiryFinancials.split(data);
    if (parts.money.isEmpty) return updateEnquiry(enquiryId, parts.parent);
    final batch = firestore.batch()
      ..update(_enquiriesCollection.doc(enquiryId), {
        ...parts.parent,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(
        EnquiryFinancials.ref(firestore, enquiryId),
        EnquiryFinancials.summaryWrite(parts.money),
        SetOptions(merge: true),
      );
    await batch.commit();
  }

  /// Soft-deletes an enquiry by moving its data and financial summary to
  /// `enquiries_trash/{enquiryId}` in one atomic batch, leaving `history`,
  /// `contacts`, `quotations`, and Storage files intact for recovery.
  Future<void> deleteEnquiry(String enquiryId, {String? deletedBy}) async {
    final enquiryRef = _enquiriesCollection.doc(enquiryId);
    final financialRef = EnquiryFinancials.ref(firestore, enquiryId);
    final enquirySnap = await enquiryRef.get();
    if (!enquirySnap.exists) {
      throw StateError('Enquiry not found: $enquiryId');
    }
    final financialSnap = await financialRef.get();
    final enquiryData = Map<String, dynamic>.from(enquirySnap.data()! as Map<String, dynamic>);
    final financialData = financialSnap.exists ? financialSnap.data() : null;

    final batch = firestore.batch()
      ..set(_enquiriesTrashCollection.doc(enquiryId), {
        'enquiry': enquiryData,
        'financial': financialData,
        'deletedAt': FieldValue.serverTimestamp(),
        'deletedBy': deletedBy,
      })
      ..delete(enquiryRef)
      ..delete(financialRef);
    await batch.commit();
  }

  /// Restores a soft-deleted enquiry from `enquiries_trash/{enquiryId}` in one
  /// atomic batch. Refuses if `enquiries/{enquiryId}` already exists.
  Future<void> restoreEnquiry(String enquiryId) async {
    final trashRef = _enquiriesTrashCollection.doc(enquiryId);
    final enquiryRef = _enquiriesCollection.doc(enquiryId);
    final trashSnap = await trashRef.get();
    if (!trashSnap.exists) {
      throw StateError('Deleted enquiry not found: $enquiryId');
    }
    final existingSnap = await enquiryRef.get();
    if (existingSnap.exists) {
      throw StateError('Enquiry $enquiryId already exists');
    }

    final trashData = trashSnap.data()!;
    final rawEnquiry = Map<String, dynamic>.from(trashData['enquiry'] as Map);
    final split = EnquiryFinancials.split(rawEnquiry);
    final rawFinancial = trashData['financial'];
    final Map<String, dynamic>? financialToWrite = rawFinancial is Map
        ? Map<String, dynamic>.from(rawFinancial)
        : (split.money.isNotEmpty ? EnquiryFinancials.summaryWrite(split.money) : null);

    final batch = firestore.batch()..set(enquiryRef, split.parent);
    if (financialToWrite != null) {
      batch.set(EnquiryFinancials.ref(firestore, enquiryId), financialToWrite);
    }
    batch.delete(trashRef);
    await batch.commit();
  }

  /// Stream of recently deleted enquiries from `enquiries_trash`, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentlyDeletedEnquiries({int limit = 50}) {
    return _enquiriesTrashCollection
        .orderBy('deletedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Retrieves a real-time stream of all active users.
  ///
  /// This method returns a stream of users who are currently active
  /// in the system. Users are ordered alphabetically by name for
  /// consistent display in dropdowns and lists.
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits active users.
  Stream<QuerySnapshot> getActiveUsers() {
    return _usersCollection.where('isActive', isEqualTo: true).orderBy('name').snapshots();
  }
}

/// Riverpod provider that creates and provides a [FirestoreService] instance.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Riverpod provider that streams active users from Firestore.
final activeUsersProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getActiveUsers();
});
