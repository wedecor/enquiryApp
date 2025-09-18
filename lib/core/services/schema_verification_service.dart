import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:we_decor_enquiries/core/constants/firestore_schema.dart';

/// Schema validation result
class SchemaValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic> details;

  const SchemaValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.details,
  });
}

/// Service for automated schema verification and validation
class SchemaVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verify all collections and documents against schema
  Future<Map<String, SchemaValidationResult>> verifyAllSchemas() async {
    final results = <String, SchemaValidationResult>{};

    try {
      // Verify users collection
      results['users'] = await _verifyUsersSchema();

      // Verify enquiries collection
      results['enquiries'] = await _verifyEnquiriesSchema();

      // Verify dropdowns collection
      results['dropdowns'] = await _verifyDropdownsSchema();

      // Verify financial subcollections
      results['financial'] = await _verifyFinancialSchema();

      // Verify history subcollections
      results['history'] = await _verifyHistorySchema();

    } catch (e) {
      print('SchemaVerificationService: Error during schema verification: $e');
    }

    return results;
  }

  /// Verify users collection schema
  Future<SchemaValidationResult> _verifyUsersSchema() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final usersSnapshot = await _firestore.collection('users').limit(100).get();
      int validCount = 0;
      int invalidCount = 0;

      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final validation = _validateUserDocument(data);
        
        if (validation.isValid) {
          validCount++;
        } else {
          invalidCount++;
          errors.add('User ${doc.id}: ${validation.errors.join(', ')}');
        }
      }

      details['totalDocuments'] = usersSnapshot.docs.length;
      details['validDocuments'] = validCount;
      details['invalidDocuments'] = invalidCount;

      if (usersSnapshot.docs.isEmpty) {
        warnings.add('No users found in collection');
      }

    } catch (e) {
      errors.add('Error accessing users collection: $e');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Verify enquiries collection schema
  Future<SchemaValidationResult> _verifyEnquiriesSchema() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final enquiriesSnapshot = await _firestore.collection('enquiries').limit(100).get();
      int validCount = 0;
      int invalidCount = 0;

      for (final doc in enquiriesSnapshot.docs) {
        final data = doc.data();
        final validation = _validateEnquiryDocument(data);
        
        if (validation.isValid) {
          validCount++;
        } else {
          invalidCount++;
          errors.add('Enquiry ${doc.id}: ${validation.errors.join(', ')}');
        }
      }

      details['totalDocuments'] = enquiriesSnapshot.docs.length;
      details['validDocuments'] = validCount;
      details['invalidDocuments'] = invalidCount;

      if (enquiriesSnapshot.docs.isEmpty) {
        warnings.add('No enquiries found in collection');
      }

    } catch (e) {
      errors.add('Error accessing enquiries collection: $e');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Verify dropdowns collection schema
  Future<SchemaValidationResult> _verifyDropdownsSchema() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final dropdownTypes = ['event_types', 'statuses', 'payment_statuses'];
      int totalValid = 0;
      int totalInvalid = 0;

      for (final dropdownType in dropdownTypes) {
        final itemsSnapshot = await _firestore
            .collection('dropdowns')
            .doc(dropdownType)
            .collection('items')
            .limit(50)
            .get();

        for (final doc in itemsSnapshot.docs) {
          final data = doc.data();
          final validation = _validateDropdownDocument(data);
          
          if (validation.isValid) {
            totalValid++;
          } else {
            totalInvalid++;
            errors.add('Dropdown $dropdownType/${doc.id}: ${validation.errors.join(', ')}');
          }
        }
      }

      details['totalDocuments'] = totalValid + totalInvalid;
      details['validDocuments'] = totalValid;
      details['invalidDocuments'] = totalInvalid;

      if (totalValid + totalInvalid == 0) {
        warnings.add('No dropdown items found');
      }

    } catch (e) {
      errors.add('Error accessing dropdowns collection: $e');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Verify financial subcollections schema
  Future<SchemaValidationResult> _verifyFinancialSchema() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final enquiriesSnapshot = await _firestore.collection('enquiries').limit(20).get();
      int totalValid = 0;
      int totalInvalid = 0;

      for (final enquiryDoc in enquiriesSnapshot.docs) {
        final financialSnapshot = await enquiryDoc.reference
            .collection('financial')
            .limit(10)
            .get();

        for (final doc in financialSnapshot.docs) {
          final data = doc.data();
          final validation = _validateFinancialDocument(data);
          
          if (validation.isValid) {
            totalValid++;
          } else {
            totalInvalid++;
            errors.add('Financial ${enquiryDoc.id}/${doc.id}: ${validation.errors.join(', ')}');
          }
        }
      }

      details['totalDocuments'] = totalValid + totalInvalid;
      details['validDocuments'] = totalValid;
      details['invalidDocuments'] = totalInvalid;

      if (totalValid + totalInvalid == 0) {
        warnings.add('No financial documents found');
      }

    } catch (e) {
      errors.add('Error accessing financial subcollections: $e');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Verify history subcollections schema
  Future<SchemaValidationResult> _verifyHistorySchema() async {
    final errors = <String>[];
    final warnings = <String>[];
    final details = <String, dynamic>{};

    try {
      final enquiriesSnapshot = await _firestore.collection('enquiries').limit(20).get();
      int totalValid = 0;
      int totalInvalid = 0;

      for (final enquiryDoc in enquiriesSnapshot.docs) {
        final historySnapshot = await enquiryDoc.reference
            .collection('history')
            .limit(10)
            .get();

        for (final doc in historySnapshot.docs) {
          final data = doc.data();
          final validation = _validateHistoryDocument(data);
          
          if (validation.isValid) {
            totalValid++;
          } else {
            totalInvalid++;
            errors.add('History ${enquiryDoc.id}/${doc.id}: ${validation.errors.join(', ')}');
          }
        }
      }

      details['totalDocuments'] = totalValid + totalInvalid;
      details['validDocuments'] = totalValid;
      details['invalidDocuments'] = totalInvalid;

      if (totalValid + totalInvalid == 0) {
        warnings.add('No history documents found');
      }

    } catch (e) {
      errors.add('Error accessing history subcollections: $e');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: details,
    );
  }

  /// Validate user document
  SchemaValidationResult _validateUserDocument(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required fields
    final requiredFields = ['name', 'email', 'phone', 'role'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }

    // Field type validation
    if (data.containsKey('name') && data['name'] is! String) {
      errors.add('name must be a string');
    }
    if (data.containsKey('email') && data['email'] is! String) {
      errors.add('email must be a string');
    }
    if (data.containsKey('phone') && data['phone'] is! String) {
      errors.add('phone must be a string');
    }
    if (data.containsKey('role') && data['role'] is! String) {
      errors.add('role must be a string');
    }

    // Field value validation
    if (data.containsKey('name') && data['name'] is String && (data['name'] as String).isEmpty) {
      errors.add('name cannot be empty');
    }
    if (data.containsKey('email') && data['email'] is String && !(data['email'] as String).contains('@')) {
      errors.add('email must be a valid email address');
    }
    if (data.containsKey('phone') && data['phone'] is String && (data['phone'] as String).isEmpty) {
      errors.add('phone cannot be empty');
    }
    if (data.containsKey('role') && data['role'] is String && !['admin', 'staff'].contains(data['role'] as String)) {
      errors.add('role must be either "admin" or "staff"');
    }

    // Optional field validation
    // fcmToken field removed for security - tokens now stored in private subcollection
    // if (data.containsKey('fcmToken') && data['fcmToken'] != null && data['fcmToken'] is! String) {
    //   errors.add('fcmToken must be a string or null');
    // }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: {},
    );
  }

  /// Validate enquiry document
  SchemaValidationResult _validateEnquiryDocument(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required fields
    final requiredFields = ['customerName', 'customerPhone', 'location', 'eventDate', 'eventType', 'eventStatus', 'notes', 'referenceImages', 'createdBy', 'createdAt'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }

    // Field type validation
    if (data.containsKey('customerName') && data['customerName'] is! String) {
      errors.add('customerName must be a string');
    }
    if (data.containsKey('customerPhone') && data['customerPhone'] is! String) {
      errors.add('customerPhone must be a string');
    }
    if (data.containsKey('location') && data['location'] is! String) {
      errors.add('location must be a string');
    }
    if (data.containsKey('eventDate') && data['eventDate'] is! Timestamp) {
      errors.add('eventDate must be a timestamp');
    }
    if (data.containsKey('eventType') && data['eventType'] is! String) {
      errors.add('eventType must be a string');
    }
    if (data.containsKey('eventStatus') && data['eventStatus'] is! String) {
      errors.add('eventStatus must be a string');
    }
    if (data.containsKey('notes') && data['notes'] is! String) {
      errors.add('notes must be a string');
    }
    if (data.containsKey('referenceImages') && data['referenceImages'] is! List) {
      errors.add('referenceImages must be a list');
    }
    if (data.containsKey('createdBy') && data['createdBy'] is! String) {
      errors.add('createdBy must be a string');
    }
    if (data.containsKey('createdAt') && data['createdAt'] is! Timestamp) {
      errors.add('createdAt must be a timestamp');
    }

    // Field value validation
    if (data.containsKey('customerName') && data['customerName'] is String && (data['customerName'] as String).isEmpty) {
      errors.add('customerName cannot be empty');
    }
    if (data.containsKey('customerPhone') && data['customerPhone'] is String && (data['customerPhone'] as String).isEmpty) {
      errors.add('customerPhone cannot be empty');
    }
    if (data.containsKey('location') && data['location'] is String && (data['location'] as String).isEmpty) {
      errors.add('location cannot be empty');
    }
    if (data.containsKey('eventType') && data['eventType'] is String && (data['eventType'] as String).isEmpty) {
      errors.add('eventType cannot be empty');
    }
    if (data.containsKey('eventStatus') && data['eventStatus'] is String && (data['eventStatus'] as String).isEmpty) {
      errors.add('eventStatus cannot be empty');
    }
    if (data.containsKey('createdBy') && data['createdBy'] is String && (data['createdBy'] as String).isEmpty) {
      errors.add('createdBy cannot be empty');
    }

    // Optional field validation
    if (data.containsKey('assignedTo') && data['assignedTo'] != null && data['assignedTo'] is! String) {
      errors.add('assignedTo must be a string or null');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: {},
    );
  }

  /// Validate dropdown document
  SchemaValidationResult _validateDropdownDocument(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required fields
    if (!data.containsKey('value')) {
      errors.add('Missing required field: value');
    }

    // Field type validation
    if (data.containsKey('value') && data['value'] is! String) {
      errors.add('value must be a string');
    }

    // Field value validation
    if (data.containsKey('value') && data['value'] is String && (data['value'] as String).isEmpty) {
      errors.add('value cannot be empty');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: {},
    );
  }

  /// Validate financial document
  SchemaValidationResult _validateFinancialDocument(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required fields
    final requiredFields = ['totalCost', 'advancePaid', 'paymentStatus'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }

    // Field type validation
    if (data.containsKey('totalCost') && data['totalCost'] is! num) {
      errors.add('totalCost must be a number');
    }
    if (data.containsKey('advancePaid') && data['advancePaid'] is! num) {
      errors.add('advancePaid must be a number');
    }
    if (data.containsKey('paymentStatus') && data['paymentStatus'] is! String) {
      errors.add('paymentStatus must be a string');
    }

    // Field value validation
    if (data.containsKey('totalCost') && data['totalCost'] is num && (data['totalCost'] as num) < 0) {
      errors.add('totalCost cannot be negative');
    }
    if (data.containsKey('advancePaid') && data['advancePaid'] is num && (data['advancePaid'] as num) < 0) {
      errors.add('advancePaid cannot be negative');
    }
    if (data.containsKey('paymentStatus') && data['paymentStatus'] is String && (data['paymentStatus'] as String).isEmpty) {
      errors.add('paymentStatus cannot be empty');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: {},
    );
  }

  /// Validate history document
  SchemaValidationResult _validateHistoryDocument(Map<String, dynamic> data) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required fields
    final requiredFields = ['fieldChanged', 'oldValue', 'newValue', 'changedBy', 'timestamp'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        errors.add('Missing required field: $field');
      }
    }

    // Field type validation
    if (data.containsKey('fieldChanged') && data['fieldChanged'] is! String) {
      errors.add('fieldChanged must be a string');
    }
    if (data.containsKey('oldValue') && data['oldValue'] is! String) {
      errors.add('oldValue must be a string');
    }
    if (data.containsKey('newValue') && data['newValue'] is! String) {
      errors.add('newValue must be a string');
    }
    if (data.containsKey('changedBy') && data['changedBy'] is! String) {
      errors.add('changedBy must be a string');
    }
    if (data.containsKey('timestamp') && data['timestamp'] is! Timestamp) {
      errors.add('timestamp must be a timestamp');
    }

    // Field value validation
    if (data.containsKey('fieldChanged') && data['fieldChanged'] is String && (data['fieldChanged'] as String).isEmpty) {
      errors.add('fieldChanged cannot be empty');
    }
    if (data.containsKey('changedBy') && data['changedBy'] is String && (data['changedBy'] as String).isEmpty) {
      errors.add('changedBy cannot be empty');
    }

    return SchemaValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      details: {},
    );
  }

  /// Generate schema verification report
  Future<String> generateSchemaReport() async {
    final results = await verifyAllSchemas();
    final report = StringBuffer();

    report.writeln('🔍 Firestore Schema Verification Report');
    report.writeln('Generated: ${DateTime.now().toIso8601String()}');
    report.writeln('');

    for (final entry in results.entries) {
      final collectionName = entry.key;
      final result = entry.value;

      report.writeln('📋 Collection: $collectionName');
      report.writeln('   Status: ${result.isValid ? '✅ Valid' : '❌ Invalid'}');
      report.writeln('   Details: ${result.details}');

      if (result.errors.isNotEmpty) {
        report.writeln('   Errors:');
        for (final error in result.errors.take(5)) {
          report.writeln('     • $error');
        }
        if (result.errors.length > 5) {
          report.writeln('     ... and ${result.errors.length - 5} more errors');
        }
      }

      if (result.warnings.isNotEmpty) {
        report.writeln('   Warnings:');
        for (final warning in result.warnings) {
          report.writeln('     • $warning');
        }
      }

      report.writeln('');
    }

    return report.toString();
  }
} 