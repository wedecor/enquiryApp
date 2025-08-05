import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/services/user_firestore_sync_service.dart';
import 'package:we_decor_enquiries/shared/widgets/event_type_autocomplete.dart';
import 'package:we_decor_enquiries/shared/widgets/status_dropdown.dart';
import 'package:we_decor_enquiries/core/services/notification_service.dart';
import 'package:we_decor_enquiries/core/services/audit_service.dart';

/// Screen for creating and editing enquiries
class EnquiryFormScreen extends ConsumerStatefulWidget {
  /// Creates an EnquiryFormScreen
  const EnquiryFormScreen({super.key});

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _advancePaidController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedEventType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedPaymentStatus;
  String? _selectedAssignedTo;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Set default values for dropdowns
    _selectedStatus = 'Enquired';
    _selectedPriority = 'medium';
    _selectedPaymentStatus = 'No Payment';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _totalCostController.dispose();
    _advancePaidController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event date')),
      );
      return;
    }
    if (_selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an event type')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserWithFirestoreProvider).value;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final firestoreService = ref.read(firestoreServiceProvider);
      
      // TODO: Upload images to Firebase Storage and get URLs
      // For now, we'll skip image upload
      
      final enquiryId = await firestoreService.createEnquiry(
        customerName: _nameController.text.trim(),
        customerEmail: '', // TODO: Add email field if needed
        customerPhone: _phoneController.text.trim(),
        eventType: _selectedEventType!,
        eventDate: _selectedDate!,
        eventLocation: _locationController.text.trim(),
        guestCount: 0, // TODO: Add guest count field
        budgetRange: '', // TODO: Add budget field
        description: _notesController.text.trim(),
        createdBy: currentUser.uid,
        priority: _selectedPriority ?? 'medium',
        source: 'app',
        totalCost: _parseDouble(_totalCostController.text),
        advancePaid: _parseDouble(_advancePaidController.text),
        paymentStatus: _selectedPaymentStatus,
        assignedTo: _selectedAssignedTo,
      );

      // Send notification for new enquiry creation
      final notificationService = NotificationService();
      await notificationService.notifyEnquiryCreated(
        enquiryId: enquiryId,
        customerName: _nameController.text.trim(),
        eventType: _selectedEventType!,
        createdBy: currentUser.uid,
      );

      // Record audit trail for assignment if assigned
      if (_selectedAssignedTo != null) {
        final auditService = AuditService();
        await auditService.recordChange(
          enquiryId: enquiryId,
          fieldChanged: 'assignedTo',
          oldValue: null,
          newValue: _selectedAssignedTo!,
        );

        // Send notification for assignment
        await notificationService.notifyEnquiryAssigned(
          enquiryId: enquiryId,
          customerName: _nameController.text.trim(),
          eventType: _selectedEventType!,
          assignedTo: _selectedAssignedTo!,
          assignedBy: currentUser.uid,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating enquiry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = ref.watch(activeUsersProvider);
    final isAdmin = ref.watch(currentUserIsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Enquiry'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Information Section
              _buildSectionHeader('Customer Information'),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameController,
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
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
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
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
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
              const SizedBox(height: 24),

              // Event Details Section
              _buildSectionHeader('Event Details'),
              const SizedBox(height: 16),

              // Event Date
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 16),
                      Text(
                        _selectedDate == null
                            ? 'Select Event Date *'
                            : 'Event Date: ${_selectedDate!.toString().split(' ')[0]}',
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Type Auto-complete
              EventTypeAutocomplete(
                initialValue: _selectedEventType,
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an event type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              StatusDropdown(
                value: _selectedStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                label: 'Status',
                collectionName: 'statuses',
              ),
              const SizedBox(height: 16),

              // Priority Dropdown
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.priority_high),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Assignment Dropdown (Admin Only)
              if (isAdmin) ...[
                activeUsers.when(
                  data: (snapshot) {
                    final userList = snapshot.docs
                        .map((doc) => doc.data() as Map<String, dynamic>)
                        .toList();

                    return DropdownButtonFormField<String>(
                      value: _selectedAssignedTo,
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        prefixIcon: Icon(Icons.person_add),
                        border: OutlineInputBorder(),
                        hintText: 'Select staff member',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Unassigned'),
                        ),
                        ...userList.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['uid'] as String? ?? user['id'] as String?,
                            child: Text(user['name'] as String? ?? 'Unknown User'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAssignedTo = value;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error loading users: $error'),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),

              // Financial Information Section (Admin Only)
              if (isAdmin) ...[
                _buildSectionHeader('Financial Information (Admin Only)'),
                const SizedBox(height: 16),

                // Total Cost Field
                TextFormField(
                  controller: _totalCostController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Cost',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                    hintText: 'Enter total cost',
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final cost = _parseDouble(value);
                      if (cost == null || cost < 0) {
                        return 'Please enter a valid amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Advance Paid Field
                TextFormField(
                  controller: _advancePaidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Advance Paid',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                    hintText: 'Enter advance amount',
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final advance = _parseDouble(value);
                      if (advance == null || advance < 0) {
                        return 'Please enter a valid amount';
                      }
                      
                      // Check if advance is more than total cost
                      final totalCost = _parseDouble(_totalCostController.text);
                      if (totalCost != null && advance > totalCost) {
                        return 'Advance cannot be more than total cost';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Status Dropdown
                StatusDropdown(
                  value: _selectedPaymentStatus,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentStatus = value;
                    });
                  },
                  label: 'Payment Status',
                  collectionName: 'payment_statuses',
                ),
                const SizedBox(height: 24),
              ],

              // Notes Section
              _buildSectionHeader('Additional Information'),
              const SizedBox(height: 16),

              // Notes Field
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Images Section
              _buildSectionHeader('Reference Images'),
              const SizedBox(height: 16),

              // Image Upload Button
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.upload),
                label: const Text('Upload Images'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Selected Images
              if (_selectedImages.isNotEmpty) ...[
                Text(
                  'Selected Images (${_selectedImages.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImages[index].path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Create Enquiry',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB), // Blue
        ),
      ),
    );
  }
} 
