import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/firestore_schema.dart';

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
/// // Get real-time stream of enquiries
/// final enquiriesStream = firestoreService.getEnquiries();
/// ```
class FirestoreService {
  /// The underlying Firebase Firestore instance.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Shared client for specialized repositories. Prefer typed helpers when available.
  FirebaseFirestore get firestore => _firestore;

  // Collection references
  /// Reference to the users collection in Firestore.
  CollectionReference get _usersCollection => _firestore.collection(FirestoreCollections.users);

  /// Reference to the enquiries collection in Firestore.
  CollectionReference get _enquiriesCollection =>
      _firestore.collection(FirestoreCollections.enquiries);

  /// Enquiries collection for feature repositories (single Firestore access path).
  CollectionReference<Map<String, dynamic>> get enquiriesCollection =>
      _enquiriesCollection as CollectionReference<Map<String, dynamic>>;

  static String _normalizePhone(String? phone) =>
      phone == null ? '' : phone.replaceAll(RegExp(r'[^0-9]'), '');

  static String _makeTextIndex({
    required String name,
    String? phone,
    String? email,
    String? notes,
  }) => [name, phone ?? '', email ?? '', notes ?? ''].join(' ').toLowerCase();

  static Map<String, dynamic> searchIndexFieldsFor({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
    String? notes,
  }) => _searchIndexFields(
    customerName: customerName,
    customerPhone: customerPhone,
    customerEmail: customerEmail,
    description: description,
    notes: notes,
  );

  static Map<String, dynamic> _searchIndexFields({
    required String customerName,
    String? customerPhone,
    String? customerEmail,
    String? description,
    String? notes,
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
      ),
    };
  }

  /// Reference to the event types collection in Firestore.
  CollectionReference get _eventTypesCollection =>
      _firestore.collection(FirestoreCollections.eventTypes);

  /// Reference to the statuses collection in Firestore.
  CollectionReference get _statusesCollection =>
      _firestore.collection(FirestoreCollections.statuses);

  /// Reference to the payment statuses collection in Firestore.
  CollectionReference get _paymentStatusesCollection =>
      _firestore.collection(FirestoreCollections.paymentStatuses);

  /// Creates a new user document in Firestore.
  ///
  /// This method creates a user record with the provided information
  /// and stores it in the users collection. The document ID is set to
  /// the user's UID for easy retrieval and updates.
  ///
  /// Parameters:
  /// - [uid]: Unique identifier for the user (typically from Firebase Auth)
  /// - [name]: User's full name
  /// - [email]: User's email address
  /// - [phone]: User's phone number
  /// - [role]: User's role in the system (admin/staff)
  ///
  /// Returns a [Future<void>] that completes when the user document is created.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await firestoreService.createUser(
  ///   uid: 'user123',
  ///   name: 'John Doe',
  ///   email: 'john@example.com',
  ///   phone: '+1234567890',
  ///   role: 'admin',
  /// );
  /// ```
  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) async {
    final userData = {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': true, // Standardized field name
    };

    await _usersCollection.doc(uid).set(userData);
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

  /// Updates an existing user document.
  ///
  /// This method updates the specified user document with new data.
  /// The `updatedAt` timestamp is automatically set to the current time.
  ///
  /// Parameters:
  /// - [uid]: The unique identifier of the user to update
  /// - [data]: Map containing the fields to update
  ///
  /// Returns a [Future<void>] that completes when the update is finished.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails or user doesn't exist
  ///
  /// Example:
  /// ```dart
  /// await firestoreService.updateUser('user123', {
  ///   'name': 'Jane Doe',
  ///   'phone': '+0987654321',
  /// });
  /// ```
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _usersCollection.doc(uid).update(data);
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
  }) async {
    final enquiryData = {
      'customerName': customerName,
      'customerEmail': customerEmail.toLowerCase(),
      'customerPhone': customerPhone,
      'eventType': eventType,
      'eventDate': eventDate,
      'eventLocation': eventLocation,
      'guestCount': guestCount,
      'budgetRange': budgetRange,
      'description': description,
      // Only use statusValue - standard field
      'statusValue': statusValue,
      if (statusLabel != null) 'statusLabel': statusLabel,
      'eventTypeValue': eventType,
      if (eventTypeLabel != null) 'eventTypeLabel': eventTypeLabel,
      'paymentStatus': paymentStatus ?? 'unpaid',
      'paymentStatusValue': paymentStatus ?? 'unpaid',
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
      ),
    };

    final docRef = await _enquiriesCollection.add(enquiryData);
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

    final docRef = await _enquiriesCollection.add(payload);
    return docRef.id;
  }

  /// Retrieves a real-time stream of all enquiries.
  ///
  /// This method returns a stream that emits the latest enquiry data
  /// whenever there are changes in the enquiries collection. The enquiries
  /// are ordered by creation date (newest first).
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits:
  /// - Current enquiry data on subscription
  /// - Updated data whenever enquiries are added, modified, or deleted
  ///
  /// Example:
  /// ```dart
  /// final enquiriesStream = firestoreService.getEnquiries();
  /// enquiriesStream.listen((snapshot) {
  ///   for (final doc in snapshot.docs) {
  ///     final data = doc.data() as Map<String, dynamic>;
  ///     print('Enquiry: ${data['customerName']}');
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot> getEnquiries() {
    return _enquiriesCollection.orderBy('createdAt', descending: true).snapshots();
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
        .where('statusValue', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Real-time enquiries stream scoped by role (admin: all, staff: assigned only).
  Stream<QuerySnapshot> watchEnquiriesForRole({required bool isAdmin, String? assignedToUid}) {
    if (isAdmin) {
      return getEnquiries();
    }
    return _enquiriesCollection
        .where('assignedTo', isEqualTo: assignedToUid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// One-shot enquiry fetch for export (same visibility as [watchEnquiriesForRole]).
  Future<QuerySnapshot> fetchEnquiriesForRole({required bool isAdmin, String? assignedToUid}) {
    Query query = _enquiriesCollection.orderBy('createdAt', descending: true);
    if (!isAdmin && assignedToUid != null) {
      query = _enquiriesCollection
          .where('assignedTo', isEqualTo: assignedToUid)
          .orderBy('createdAt', descending: true);
    }
    return query.get();
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

  /// Active dropdown items from `dropdowns/{kind}/items`.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveDropdownItems(String kind) {
    return _activeDropdownItemsQuery(kind).snapshots();
  }

  /// One-shot fetch of active dropdown items (e.g. dashboard color priming).
  Future<QuerySnapshot<Map<String, dynamic>>> fetchActiveDropdownItems(String kind) {
    return _activeDropdownItemsQuery(kind).get();
  }

  /// Active dropdown options as label/value maps for form widgets.
  Future<List<Map<String, String>>> fetchActiveDropdownOptions(String kind) async {
    final snapshot = await fetchActiveDropdownItems(kind);
    return parseDropdownOptions(snapshot.docs);
  }

  /// Parses active dropdown documents into label/value maps.
  static List<Map<String, String>> parseDropdownOptions(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) {
          final data = doc.data();
          final label = (data['label'] as String?)?.trim();
          final value = (data['value'] as String?)?.trim();
          return {
            'label': label?.isNotEmpty == true ? label! : (value ?? ''),
            'value': value ?? '',
          };
        })
        .where((entry) => entry['value']!.isNotEmpty)
        .toList();
  }

  /// Adds a new item under `dropdowns/{kind}/items` (admin UI quick-add).
  Future<void> addDropdownItem({
    required String kind,
    required String label,
    required String value,
    required int order,
    required String createdBy,
  }) async {
    await _firestore.collection('dropdowns').doc(kind).collection('items').add({
      'label': label,
      'value': value,
      'active': true,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    });
  }

  /// Value→label map for a dropdown kind (includes inactive items for history display).
  Future<Map<String, String>> fetchDropdownValueLabelMap(String kind) async {
    final snapshot = await _firestore.collection('dropdowns').doc(kind).collection('items').get();
    final map = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = (data['value'] ?? doc.id).toString();
      final label = (data['label'] ?? value).toString();
      map[value] = label;
    }
    return map;
  }

  Query<Map<String, dynamic>> _activeDropdownItemsQuery(String kind) {
    return _firestore
        .collection('dropdowns')
        .doc(kind)
        .collection('items')
        .where('active', isEqualTo: true)
        .orderBy('order');
  }

  /// Active status options for enquiry status dropdowns.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchActiveStatusDropdownItems() =>
      watchActiveDropdownItems('statuses');

  /// Calendar view: enquiries ordered by event date (role-scoped).
  Stream<QuerySnapshot> watchEnquiriesForRoleByEventDate({
    required bool isAdmin,
    String? assignedToUid,
  }) {
    Query query = _enquiriesCollection;
    if (!isAdmin && assignedToUid != null) {
      query = query.where('assignedTo', isEqualTo: assignedToUid);
    }
    return query.orderBy('eventDate', descending: false).snapshots();
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

  /// Deletes an enquiry document from Firestore.
  ///
  /// This method permanently removes the specified enquiry from the database.
  /// Use with caution as this operation cannot be undone.
  ///
  /// Parameters:
  /// - [enquiryId]: The unique identifier of the enquiry to delete
  ///
  /// Returns a [Future<void>] that completes when the deletion is finished.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await firestoreService.deleteEnquiry('enquiry123');
  /// ```
  Future<void> deleteEnquiry(String enquiryId) async {
    await _enquiriesCollection.doc(enquiryId).delete();
  }

  /// Retrieves a real-time stream of all active event types.
  ///
  /// This method returns a stream of event types that are currently active
  /// in the system. Event types are ordered by their sort order for
  /// consistent display in dropdowns and forms.
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits active event types.
  ///
  /// Example:
  /// ```dart
  /// final eventTypesStream = firestoreService.getEventTypes();
  /// eventTypesStream.listen((snapshot) {
  ///   for (final doc in snapshot.docs) {
  ///     final data = doc.data() as Map<String, dynamic>;
  ///     print('Event Type: ${data['name']}');
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot> getEventTypes() {
    return _eventTypesCollection.orderBy('value').snapshots();
  }

  /// Retrieves a real-time stream of all active statuses.
  ///
  /// This method returns a stream of enquiry statuses that are currently
  /// active in the system. Statuses are ordered by their sort order for
  /// consistent display in dropdowns and forms.
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits active statuses.
  ///
  /// Example:
  /// ```dart
  /// final statusesStream = firestoreService.getStatuses();
  /// statusesStream.listen((snapshot) {
  ///   for (final doc in snapshot.docs) {
  ///     final data = doc.data() as Map<String, dynamic>;
  ///     print('Status: ${data['value']}');
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot> getStatuses() {
    return _statusesCollection.orderBy('value').snapshots();
  }

  /// Retrieves a real-time stream of all active payment statuses.
  ///
  /// This method returns a stream of payment statuses that are currently
  /// active in the system. Payment statuses are ordered by their sort order
  /// for consistent display in dropdowns and forms.
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits active payment statuses.
  ///
  /// Example:
  /// ```dart
  /// final paymentStatusesStream = firestoreService.getPaymentStatuses();
  /// paymentStatusesStream.listen((snapshot) {
  ///   for (final doc in snapshot.docs) {
  ///     final data = doc.data() as Map<String, dynamic>;
  ///     print('Payment Status: ${data['value']}');
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot> getPaymentStatuses() {
    return _paymentStatusesCollection.orderBy('value').snapshots();
  }

  /// Initializes the default dropdown values in Firestore.
  ///
  /// This method populates the dropdown collections (event types, statuses,
  /// payment statuses) with default values if they don't already exist.
  /// This ensures the application has the necessary data for forms and
  /// filtering functionality.
  ///
  /// The method creates documents for:
  /// - Event types (Wedding, Birthday, Corporate, etc.)
  /// - Enquiry statuses (New, In Progress, Completed, etc.)
  /// - Payment statuses (Pending, Partial, Paid, etc.)
  ///
  /// Returns a [Future<void>] that completes when all dropdowns are initialized.
  ///
  /// Throws:
  /// - [FirebaseException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await firestoreService.initializeDropdowns();
  /// ```
  Future<void> initializeDropdowns() async {
    // Initialize event types
    for (final eventType in DefaultDropdownValues.eventTypes) {
      final data = {
        'value': eventType,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _eventTypesCollection.add(data);
    }

    // Initialize statuses
    for (final status in DefaultDropdownValues.statuses) {
      final data = {
        'value': status,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _statusesCollection.add(data);
    }

    // Initialize payment statuses
    for (final paymentStatus in DefaultDropdownValues.paymentStatuses) {
      final data = {
        'value': paymentStatus,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _paymentStatusesCollection.add(data);
    }
  }

  /// Checks if the dropdown collections have been initialized.
  ///
  /// This method verifies whether the default dropdown values have been
  /// created in Firestore by checking if each collection has at least
  /// one document.
  ///
  /// Returns a [Future<bool>] that resolves to:
  /// - `true` if all dropdown collections have data
  /// - `false` if any collection is empty
  ///
  /// Example:
  /// ```dart
  /// final isInitialized = await firestoreService.areDropdownsInitialized();
  /// if (!isInitialized) {
  ///   await firestoreService.initializeDropdowns();
  /// }
  /// ```
  Future<bool> areDropdownsInitialized() async {
    final eventTypesSnapshot = await _eventTypesCollection.limit(1).get();
    final statusesSnapshot = await _statusesCollection.limit(1).get();
    final paymentStatusesSnapshot = await _paymentStatusesCollection.limit(1).get();

    return eventTypesSnapshot.docs.isNotEmpty &&
        statusesSnapshot.docs.isNotEmpty &&
        paymentStatusesSnapshot.docs.isNotEmpty;
  }

  /// Retrieves statistics about enquiries grouped by status.
  ///
  /// This method analyzes all enquiries in the database and returns
  /// a count of enquiries for each status. Useful for dashboard
  /// analytics and reporting.
  ///
  /// Returns a [Future<Map<String, int>>] where:
  /// - Keys are status names (e.g., "New", "In Progress", "Completed")
  /// - Values are the count of enquiries with that status
  ///
  /// Example:
  /// ```dart
  /// final stats = await firestoreService.getEnquiryStatistics();
  /// print('New enquiries: ${stats['New'] ?? 0}');
  /// print('Completed enquiries: ${stats['Completed'] ?? 0}');
  /// ```
  Future<Map<String, int>> getEnquiryStatistics() async {
    final snapshot = await _enquiriesCollection.get();
    final enquiries = snapshot.docs;

    final stats = <String, int>{};
    for (final doc in enquiries) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['statusValue'] as String? ?? 'Unknown'; // Use statusValue only
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }

  /// Searches enquiries by customer name.
  ///
  /// This method performs a prefix search on customer names to find
  /// enquiries that match the provided search term. The search is
  /// case-sensitive and uses Firestore's string comparison operators.
  ///
  /// Parameters:
  /// - [searchTerm]: The search term to match against customer names
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits matching enquiries.
  ///
  /// Example:
  /// ```dart
  /// final searchResults = firestoreService.searchEnquiries('John');
  /// searchResults.listen((snapshot) {
  ///   for (final doc in snapshot.docs) {
  ///     final data = doc.data() as Map<String, dynamic>;
  ///     print('Found: ${data['customerName']}');
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot> searchEnquiries(String searchTerm) {
    return _enquiriesCollection
        .where('customerName', isGreaterThanOrEqualTo: searchTerm)
        .where('customerName', isLessThan: '$searchTerm\uf8ff')
        .orderBy('customerName')
        .snapshots();
  }

  /// Retrieves a real-time stream of all active users.
  ///
  /// This method returns a stream of users who are currently active
  /// in the system. Users are ordered alphabetically by name for
  /// consistent display in dropdowns and lists.
  ///
  /// Returns a [Stream<QuerySnapshot>] that emits active users.
  ///
  /// Example:
  /// ```dart
  /// final usersStream = firestoreService.getActiveUsers();
  /// usersStream.listen((snapshot) {
  ///   for (final doc in snapshot.docs) {
  ///     final data = doc.data() as Map<String, dynamic>;
  ///     print('User: ${data['name']} (${data['role']})');
  ///   }
  /// });
  /// ```
  Stream<QuerySnapshot> getActiveUsers() {
    return _usersCollection.orderBy('name').snapshots();
  }
}

/// Riverpod provider that creates and provides a [FirestoreService] instance.
///
/// This provider ensures that the Firestore service is properly
/// initialized and can be accessed throughout the app using Riverpod.
///
/// Usage:
/// ```dart
/// final firestoreService = ref.read(firestoreServiceProvider);
/// ```
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Riverpod provider that checks if dropdown collections are initialized.
///
/// This provider returns a [Future<bool>] indicating whether the default
/// dropdown values have been created in Firestore.
///
/// Usage:
/// ```dart
/// final isInitialized = ref.watch(dropdownsInitializedProvider);
/// isInitialized.when(
///   data: (initialized) {
///     if (!initialized) {
///       // Initialize dropdowns
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final dropdownsInitializedProvider = FutureProvider<bool>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.areDropdownsInitialized();
});

/// Riverpod provider that streams event types from Firestore.
///
/// This provider provides real-time access to the event types collection,
/// automatically updating when the data changes in Firestore.
///
/// Usage:
/// ```dart
/// final eventTypes = ref.watch(eventTypesProvider);
/// eventTypes.when(
///   data: (snapshot) {
///     for (final doc in snapshot.docs) {
///       final data = doc.data() as Map<String, dynamic>;
///       // Use event type data
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final eventTypesProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getEventTypes();
});

/// Riverpod provider that streams statuses from Firestore.
///
/// This provider provides real-time access to the statuses collection,
/// automatically updating when the data changes in Firestore.
///
/// Usage:
/// ```dart
/// final statuses = ref.watch(statusesProvider);
/// statuses.when(
///   data: (snapshot) {
///     for (final doc in snapshot.docs) {
///       final data = doc.data() as Map<String, dynamic>;
///       // Use status data
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final statusesProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStatuses();
});

/// Riverpod provider that streams payment statuses from Firestore.
///
/// This provider provides real-time access to the payment statuses collection,
/// automatically updating when the data changes in Firestore.
///
/// Usage:
/// ```dart
/// final paymentStatuses = ref.watch(paymentStatusesProvider);
/// paymentStatuses.when(
///   data: (snapshot) {
///     for (final doc in snapshot.docs) {
///       final data = doc.data() as Map<String, dynamic>;
///       // Use payment status data
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final paymentStatusesProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getPaymentStatuses();
});

/// Riverpod provider that streams all enquiries from Firestore.
///
/// This provider provides real-time access to the enquiries collection,
/// automatically updating when enquiries are added, modified, or deleted.
///
/// Usage:
/// ```dart
/// final enquiries = ref.watch(enquiriesProvider);
/// enquiries.when(
///   data: (snapshot) {
///     for (final doc in snapshot.docs) {
///       final data = doc.data() as Map<String, dynamic>;
///       // Use enquiry data
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final enquiriesProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getEnquiries();
});

/// Riverpod provider that streams active users from Firestore.
///
/// This provider provides real-time access to the active users collection,
/// automatically updating when user data changes in Firestore.
///
/// Usage:
/// ```dart
/// final users = ref.watch(activeUsersProvider);
/// users.when(
///   data: (snapshot) {
///     for (final doc in snapshot.docs) {
///       final data = doc.data() as Map<String, dynamic>;
///       // Use user data
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final activeUsersProvider = StreamProvider<QuerySnapshot>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getActiveUsers();
});
