import 'package:flutter/material.dart';
import '../../../core/utils/contact_launcher.dart';

String waTemplate({
  required String customerName,
  required String eventTypeLabel,
  required DateTime eventDate,
  required String locationText,
}) => '''
Hi $customerName 👋

This is We Decor — thanks for your enquiry!
• Event: $eventTypeLabel
• Date: ${eventDate.toLocal().toString().split(' ').first}
• Location: $locationText

Let me know a good time to discuss 😊
''';

class ContactActionsRow extends StatelessWidget {
  final String customerName;
  final String phoneE164;
  final String eventTypeLabel;
  final DateTime eventDate;
  final String locationText;
  const ContactActionsRow({
    super.key,
    required this.customerName,
    required this.phoneE164,
    required this.eventTypeLabel,
    required this.eventDate,
    required this.locationText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Call',
          icon: const Icon(Icons.call),
          onPressed: () => ContactLauncher.call(phoneE164),
        ),
        IconButton(
          tooltip: 'WhatsApp',
          icon: const Icon(Icons.chat),
          onPressed: () => ContactLauncher.whatsapp(
            phoneE164,
            message: waTemplate(
              customerName: customerName,
              eventTypeLabel: eventTypeLabel,
              eventDate: eventDate,
              locationText: locationText,
            ),
          ),
        ),
      ],
    );
  }
}
