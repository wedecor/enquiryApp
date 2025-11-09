import 'package:flutter_contacts/flutter_contacts.dart';
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
}

class ContactSaveRequest {
  const ContactSaveRequest({
    required this.displayName,
    required this.phoneNumber,
  });

  final String displayName;
  final String phoneNumber;
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

    final permissionGranted = await FlutterContacts.requestPermission(readonly: false);

    if (!permissionGranted) {
      Log.w(
        'contact_save_permission_denied',
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.permissionDenied;
    }

    final existing = await _findByPhone(digitsOnly);
    if (existing) {
      Log.d(
        'contact_save_skipped_exists',
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.alreadyExists;
    }

    final nameParts = _splitName(sanitizedName);
    final contact = Contact()
      ..name = Name(
        first: nameParts.firstName,
        last: nameParts.lastName,
      )
      ..phones = [
        Phone(
          formattedPhone,
          label: PhoneLabel.mobile,
        ),
      ];

    try {
      await FlutterContacts.insertContact(contact);
      Log.i(
        'contact_save_success',
        data: {'name': sanitizedName, 'phone': formattedPhone},
      );
      return ContactSaveStatus.saved;
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

  Future<bool> _findByPhone(String phoneDigits) async {
    final candidates = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    return candidates.any(
      (contact) => contact.phones.any(
        (phoneEntry) => _digitsOnly(phoneEntry.number) == phoneDigits,
      ),
    );
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

    final segments = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
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

