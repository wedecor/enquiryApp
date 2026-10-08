import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'enquiry_form_section.dart';

/// Customer name, phone, email, and location fields for the enquiry form.
class EnquiryFormCustomerFields extends StatelessWidget {
  const EnquiryFormCustomerFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.locationController,
    this.phoneFooter,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController locationController;

  /// Shown under the phone / email row (e.g. existing-customer and duplicate cards).
  final Widget? phoneFooter;

  @override
  Widget build(BuildContext context) {
    return EnquiryFormSection(
      eyebrow: 'The customer',
      title: 'Customer Information',
      children: [
        TextFormField(
          controller: nameController,
          scrollPadding: kEnquiryFieldScrollPadding,
          decoration: const InputDecoration(
            labelText: 'Customer Name *',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter customer name';
            }
            return null;
          },
        ),
        const SizedBox(height: kEnquiryFieldGap),
        EnquiryFieldPair(
          first: TextFormField(
            controller: phoneController,
            scrollPadding: kEnquiryFieldScrollPadding,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length < 7) {
                return 'Enter a valid phone number (at least 7 digits)';
              }
              if (digits.length > 15) {
                return 'Phone number is too long';
              }
              return null;
            },
          ),
          second: TextFormField(
            controller: emailController,
            scrollPadding: kEnquiryFieldScrollPadding,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (optional)',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return null;
              if (!trimmed.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
        ),
        if (phoneFooter != null) ...[const SizedBox(height: AppTokens.space3), phoneFooter!],
        const SizedBox(height: kEnquiryFieldGap),
        TextFormField(
          controller: locationController,
          scrollPadding: kEnquiryFieldScrollPadding,
          decoration: const InputDecoration(
            labelText: 'Event Location *',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter event location';
            }
            return null;
          },
        ),
      ],
    );
  }
}
