import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'enquiry_form_section.dart';

/// Customer name, phone, and location fields for the enquiry form.
class EnquiryFormCustomerFields extends StatelessWidget {
  const EnquiryFormCustomerFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.locationController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController locationController;

  @override
  Widget build(BuildContext context) {
    return EnquiryFormSection(
      title: 'Customer Information',
      children: [
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Customer Name *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter customer name';
            }
            return null;
          },
        ),
        SizedBox(height: AppTokens.space4),
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number *',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
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
        SizedBox(height: AppTokens.space4),
        TextFormField(
          controller: locationController,
          decoration: const InputDecoration(
            labelText: 'Event Location *',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
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
