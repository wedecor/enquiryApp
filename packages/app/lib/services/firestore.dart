import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Collections
  static CollectionReference get users => _db.collection('users');
  static CollectionReference get enquiries => _db.collection('enquiries');
  static CollectionReference get eventTypeOptions => _db.collection('EventTypeOptions');
  static CollectionReference get statusOptions => _db.collection('StatusOptions');
  static CollectionReference get systemSettings => _db.collection('SystemSettings');
  
  // Document references
  static DocumentReference userDoc(String uid) => users.doc(uid);
  static DocumentReference enquiryDoc(String id) => enquiries.doc(id);
  static DocumentReference appSettingsDoc() => systemSettings.doc('app');
  
  // Subcollections
  static CollectionReference enquiryHistory(String enquiryId) => 
      enquiries.doc(enquiryId).collection('EnquiryHistory');
}

