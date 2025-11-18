import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart'
    show Contact, Name, Phone, PhoneLabel, FlutterContacts;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/logger.dart';

final contactServiceProvider = Provider<ContactService>((ref) {
  return const ContactService();
});

enum ContactSaveStatus {
  saved,
  alreadyExists,
  permissionDenied,
  invalidInput,
  failed,
  notSupportedOnWeb,
  copiedToClipboard,
}

class ContactSaveRequest {
  const ContactSaveRequest({
    required this.displayName,
    required this.phoneNumber,
    this.eventType,
    this.eventDate,
  });

  final String displayName;
  final String phoneNumber;
  final String? eventType;
  final String? eventDate;
}

class ContactService {
  const ContactService();

  Future<ContactSaveStatus> saveContact(ContactSaveRequest request) async {
    final sanitizedName = request.displayName.trim();
    final digitsOnly = _digitsOnly(request.phoneNumber);
    final formattedPhone = request.phoneNumber.trim();

    if (digitsOnly == null || formattedPhone.isEmpty) {
      Log.w('contact_save_invalid_input', data: {'phone': request.phoneNumber});
      return ContactSaveStatus.invalidInput;
    }

    // Web platform: Copy contact info to clipboard instead
    if (kIsWeb) {
      return await _saveContactForWeb(request, sanitizedName, formattedPhone);
    }

    // Mobile platform: Use flutter_contacts
    final permissionGranted = await FlutterContacts.requestPermission(readonly: false);

    if (!permissionGranted) {
      Log.w(
        'contact_save_permission_denied',
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.permissionDenied;
    }

    // Check if contact already exists (with error handling for OnePlus devices)
    bool existing = false;
    try {
      existing = await _findByPhone(digitsOnly);
    } catch (error, stack) {
      // On some devices (like OnePlus), getContacts might fail
      // Log the error but continue with saving
      Log.e(
        'contact_save_check_failed',
        error: error,
        stackTrace: stack,
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      // Continue with save attempt even if check failed
      existing = false;
    }

    if (existing) {
      Log.d('contact_save_skipped_exists', data: {'name': sanitizedName, 'phone': formattedPhone});
      return ContactSaveStatus.alreadyExists;
    }

    // Build display name with event information
    String displayNameWithEvent = sanitizedName;
    final eventParts = <String>[];

    if (request.eventType != null && request.eventType!.isNotEmpty) {
      eventParts.add(request.eventType!);
    }
    if (request.eventDate != null && request.eventDate!.isNotEmpty) {
      eventParts.add(request.eventDate!);
    }

    if (eventParts.isNotEmpty) {
      displayNameWithEvent = '$sanitizedName - ${eventParts.join(' - ')}';
    }

    final nameParts = _splitName(displayNameWithEvent);

    // Validate name parts to prevent crashes
    final firstName = nameParts.firstName.trim();
    final lastName = nameParts.lastName.trim();

    if (firstName.isEmpty && lastName.isEmpty) {
      Log.w('contact_save_invalid_name', data: {'name': sanitizedName, 'phone': formattedPhone});
      return ContactSaveStatus.invalidInput;
    }

    try {
      // Create contact with defensive checks
      final contact = Contact()
        ..name = Name(first: firstName.isEmpty ? 'Customer' : firstName, last: lastName)
        ..phones = [Phone(formattedPhone, label: PhoneLabel.mobile)];

      // Add timeout to prevent hanging on OnePlus devices
      await FlutterContacts.insertContact(contact).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Contact insertion timed out', const Duration(seconds: 15));
        },
      );

      Log.i('contact_save_success', data: {'name': sanitizedName, 'phone': formattedPhone});
      return ContactSaveStatus.saved;
    } on TimeoutException catch (error, stack) {
      Log.e(
        'contact_save_timeout',
        error: error,
        stackTrace: stack,
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.failed;
    } catch (error, stack) {
      Log.e(
        'contact_save_failed',
        error: error,
        stackTrace: stack,
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.failed;
    }
  }

  /// Save contact for web platform by copying to clipboard
  Future<ContactSaveStatus> _saveContactForWeb(
    ContactSaveRequest request,
    String sanitizedName,
    String formattedPhone,
  ) async {
    try {
      // Build display name with event information
      String displayNameWithEvent = sanitizedName;
      final eventParts = <String>[];

      if (request.eventType != null && request.eventType!.isNotEmpty) {
        eventParts.add(request.eventType!);
      }
      if (request.eventDate != null && request.eventDate!.isNotEmpty) {
        eventParts.add(request.eventDate!);
      }

      if (eventParts.isNotEmpty) {
        displayNameWithEvent = '$sanitizedName - ${eventParts.join(' - ')}';
      }

      // Create vCard format for clipboard
      final vCard = StringBuffer();
      vCard.writeln('BEGIN:VCARD');
      vCard.writeln('VERSION:3.0');
      vCard.writeln('FN:$displayNameWithEvent');
      vCard.writeln('TEL;TYPE=CELL:$formattedPhone');
      if (request.eventType != null && request.eventType!.isNotEmpty) {
        vCard.writeln('NOTE:Event Type: ${request.eventType}');
      }
      if (request.eventDate != null && request.eventDate!.isNotEmpty) {
        vCard.writeln('NOTE:Event Date: ${request.eventDate}');
      }
      vCard.writeln('END:VCARD');

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: vCard.toString()));

      Log.i('contact_save_web_clipboard', data: {'name': sanitizedName, 'phone': formattedPhone});
      return ContactSaveStatus.copiedToClipboard;
    } catch (error, stack) {
      Log.e(
        'contact_save_web_failed',
        error: error,
        stackTrace: stack,
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.failed;
    }
  }

  Future<bool> _findByPhone(String phoneDigits) async {
    if (kIsWeb) {
      // On web, we can't check existing contacts
      return false;
    }

    try {
      // Request permission again to ensure we have it
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      if (!hasPermission) {
        Log.w('contact_check_permission_denied', data: {'phone': phoneDigits});
        return false; // Assume doesn't exist if we can't check
      }

      // Get contacts with error handling for OnePlus and other custom Android skins
      final candidates = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      ).timeout(const Duration(seconds: 10));

      return candidates.any((contact) {
        try {
          return contact.phones.any((phoneEntry) => _digitsOnly(phoneEntry.number) == phoneDigits);
        } catch (e) {
          // Skip contacts with invalid phone data
          Log.w(
            'contact_check_phone_parse_error',
            data: {'contactId': contact.id, 'error': e.toString()},
          );
          return false;
        }
      });
    } on TimeoutException catch (error, stack) {
      // Handle timeout specifically (common on OnePlus devices)
      Log.e('contact_check_timeout', error: error, stackTrace: stack, data: {'phone': phoneDigits});
      // Return false to allow save attempt even if check times out
      return false;
    } catch (error, stack) {
      // Catch any other exceptions from getContacts (common on OnePlus devices)
      Log.e('contact_check_failed', error: error, stackTrace: stack, data: {'phone': phoneDigits});
      // Return false to allow save attempt even if check fails
      return false;
    }
  }

  String? _digitsOnly(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return null;
    return cleaned;
  }

  _NameParts _splitName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return const _NameParts(firstName: 'Customer', lastName: '');
    }

    // Split by ' - ' first to separate customer name from event info
    final parts = trimmed.split(' - ');
    final customerName = parts.first.trim();

    // If there's event info, put it in the last name
    if (parts.length > 1) {
      final eventInfo = parts.sublist(1).join(' - ');
      // Split customer name into first and last
      final nameSegments = customerName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (nameSegments.isEmpty) {
        return const _NameParts(firstName: 'Customer', lastName: '');
      } else if (nameSegments.length == 1) {
        return _NameParts(firstName: nameSegments.first, lastName: eventInfo);
      } else {
        final firstName = nameSegments.first;
        final lastName = '${nameSegments.sublist(1).join(' ')} - $eventInfo';
        return _NameParts(firstName: firstName, lastName: lastName);
      }
    }

    // No event info, just split the name normally
    final segments = customerName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (segments.length == 1) {
      return _NameParts(firstName: segments.first, lastName: '');
    }

    final firstName = segments.first;
    final lastName = segments.sublist(1).join(' ');

    return _NameParts(firstName: firstName, lastName: lastName);
  }
}

class _NameParts {
  const _NameParts({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;
}
