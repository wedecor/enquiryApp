import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/audit_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/user_firestore_sync_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/clamped_text.dart';
import '../../../../shared/widgets/status_dropdown.dart';

/// Screen for creating and editing enquiries
class EnquiryFormScreen extends ConsumerStatefulWidget {
  /// Creates an EnquiryFormScreen
  /// [enquiryId] is required for editing mode
  /// [mode] can be 'create' or 'edit'
  const EnquiryFormScreen({super.key, this.enquiryId, this.mode = 'create'});

  final String? enquiryId;
  final String mode;

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
  final _budgetController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedEventType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedPaymentStatus;
  String? _selectedAssignedTo;
  final List<XFile> _selectedImages = [];
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print(
      '🔍 EnquiryFormScreen: initState called - mode: ${widget.mode}, enquiryId: ${widget.enquiryId}',
    );
    // Set default values for dropdowns
    // Use dropdown value keys (snake_case)
    _selectedStatus = 'new';
    _selectedPriority = 'medium';
    _selectedPaymentStatus = 'pending';

    // Load existing data if in edit mode
    if (widget.mode == 'edit' && widget.enquiryId != null) {
      print('🔍 EnquiryFormScreen: About to call _loadEnquiryData');
      _loadEnquiryData();
    } else {
      print('🔍 EnquiryFormScreen: Not in edit mode or no enquiryId');
    }
  }

  Future<void> _loadEnquiryData() async {
    print('🔍 EnquiryFormScreen: _loadEnquiryData called for enquiryId: ${widget.enquiryId}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('enquiries')
          .doc(widget.enquiryId!)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          _nameController.text = (data['customerName'] as String?) ?? '';
          _phoneController.text = (data['customerPhone'] as String?) ?? '';
          _locationController.text = (data['eventLocation'] as String?) ?? '';
          _notesController.text = (data['description'] as String?) ?? '';

          if (data['totalCost'] != null) {
            _totalCostController.text = data['totalCost'].toString();
          }
          if (data['advancePaid'] != null) {
            _advancePaidController.text = data['advancePaid'].toString();
          }

          // Set dropdown values from database
          _selectedEventType = data['eventType'] as String?;
          print('🔍 EnquiryFormScreen: Loaded eventType from database: "$_selectedEventType"');

          // Safely set dropdown values - ensure they exist in valid options
          final eventStatus = data['eventStatus'] as String?;
          _selectedStatus = eventStatus;

          final priority = data['priority'] as String?;
          _selectedPriority = priority;

          final paymentStatus = data['paymentStatus'] as String?;
          _selectedPaymentStatus = paymentStatus;

          _selectedAssignedTo = data['assignedTo'] as String?;

          if (data['eventDate'] != null) {
            final timestamp = data['eventDate'] as Timestamp;
            _selectedDate = timestamp.toDate();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading enquiry data: $e')));
      }
    }
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
    // Check if we're already at the maximum limit
    if (_selectedImages.length >= 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Maximum 10 attachments allowed.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      final remainingSlots = 10 - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).toList();

      if (images.length > remainingSlots) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only ${remainingSlots} more images can be added.'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      }

      // Validate each image before adding
      final validImages = <XFile>[];
      for (final image in imagesToAdd) {
        if (_isValidImageFile(image)) {
          validImages.add(image);
        }
      }

      if (validImages.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(validImages);
        });
      }
    }
  }

  /// Validate image file before adding to selection
  bool _isValidImageFile(XFile image) {
    final fileName = image.name.toLowerCase();
    final fileExtension = fileName.split('.').last;
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'];

    if (!allowedExtensions.contains(fileExtension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${image.name} has unsupported format. Only images and PDFs are allowed.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }

    return true;
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadImages(String userId) async {
    if (_selectedImages.isEmpty) return [];

    final List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final maxFileSize = 5 * 1024 * 1024; // 5MB in bytes
    final allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    final allowedPdfTypes = ['application/pdf'];

    for (int i = 0; i < _selectedImages.length; i++) {
      try {
        final file = File(_selectedImages[i].path);
        final fileSize = await file.length();

        // Validate file size (AC-Intake-3)
        if (fileSize > maxFileSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image ${i + 1} is too large. Maximum size is 5MB.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          continue; // Skip this file
        }

        // Get file extension and validate type
        final fileName = _selectedImages[i].name.toLowerCase();
        final fileExtension = fileName.split('.').last;
        final mimeType = _getMimeTypeFromExtension(fileExtension);

        // Validate file type (AC-Intake-3)
        if (!allowedImageTypes.contains(mimeType) && !allowedPdfTypes.contains(mimeType)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image ${i + 1} has unsupported format. Only images and PDFs are allowed.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          continue; // Skip this file
        }

        // Validate maximum number of files (AC-Intake-3)
        if (imageUrls.length >= 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Maximum 10 attachments allowed.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          break; // Stop processing more files
        }

        final storageFileName = 'enquiry_${timestamp}_${i}_${_selectedImages[i].name}';
        final ref = storage.ref().child('enquiry_images/$userId/$storageFileName');

        // Set metadata for content type
        final metadata = SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'originalName': _selectedImages[i].name,
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );

        final uploadTask = await ref.putFile(file, metadata);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        print('Successfully uploaded image ${i + 1}: ${_selectedImages[i].name}');
      } catch (e) {
        print('Error uploading image $i: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload image ${i + 1}: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        // Continue with other images even if one fails
      }
    }

    return imageUrls;
  }

  /// Get MIME type from file extension
  String _getMimeTypeFromExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Get list of updated fields for audit logging
  List<String> _getUpdatedFields() {
    final updatedFields = <String>[];
    
    if (_nameController.text.isNotEmpty) updatedFields.add('customerName');
    if (_phoneController.text.isNotEmpty) updatedFields.add('customerPhone');
    if (_locationController.text.isNotEmpty) updatedFields.add('eventLocation');
    if (_notesController.text.isNotEmpty) updatedFields.add('description');
    if (_totalCostController.text.isNotEmpty) updatedFields.add('totalCost');
    if (_advancePaidController.text.isNotEmpty) updatedFields.add('advancePaid');
    if (_budgetController.text.isNotEmpty) updatedFields.add('budgetRange');
    if (_selectedImages.isNotEmpty) updatedFields.add('imageUrls');
    
    return updatedFields;
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an event date')));
      return;
    }
    if (_selectedEventType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an event type')));
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

      if (widget.mode == 'edit' && widget.enquiryId != null) {
        // Update existing enquiry
        await _updateEnquiry(currentUser);
      } else {
        // Create new enquiry
        await _createEnquiry(currentUser);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${widget.mode == 'edit' ? 'updating' : 'creating'} enquiry: $e'),
          ),
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

  Future<void> _createEnquiry(UserModel currentUser) async {
    final firestoreService = ref.read(firestoreServiceProvider);

    // Upload images to Firebase Storage and get URLs
    final List<String> imageUrls = await _uploadImages(currentUser.uid);

    final enquiryId = await firestoreService.createEnquiry(
      customerName: _nameController.text.trim(),
      customerEmail: '', // Email field not needed
      customerPhone: _phoneController.text.trim(),
      eventType: _selectedEventType!,
      eventDate: _selectedDate!,
      eventLocation: _locationController.text.trim(),
      guestCount: 0, // Guest count field not needed
      budgetRange: _budgetController.text.trim(),
      description: _notesController.text.trim(),
      createdBy: currentUser.uid,
      priority: _selectedPriority ?? 'medium',
      source: 'app',
      totalCost: _parseDouble(_totalCostController.text),
      advancePaid: _parseDouble(_advancePaidController.text),
      paymentStatus: _selectedPaymentStatus,
      assignedTo: _selectedAssignedTo,
      imageUrls: imageUrls,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enquiry created successfully!')));
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateEnquiry(UserModel currentUser) async {
    // Update the enquiry document directly
    await FirebaseFirestore.instance.collection('enquiries').doc(widget.enquiryId!).update({
      'customerName': _nameController.text.trim(),
      'customerPhone': _phoneController.text.trim(),
      'eventLocation': _locationController.text.trim(),
      'description': _notesController.text.trim(),
      'eventType': _selectedEventType,
      'eventDate': Timestamp.fromDate(_selectedDate!),
      'priority': _selectedPriority,
      'eventStatus': _selectedStatus,
      'paymentStatus': _selectedPaymentStatus,
      'assignedTo': _selectedAssignedTo,
      'totalCost': _parseDouble(_totalCostController.text),
      'advancePaid': _parseDouble(_advancePaidController.text),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUser.uid,
    });

    // Record audit trail for the update
    final auditService = AuditService();
    await auditService.recordChange(
      enquiryId: widget.enquiryId!,
      fieldChanged: 'general_update',
      oldValue: 'Previous values',
      newValue: 'Updated enquiry data',
      changeType: 'edit',
      notes: 'Enquiry updated via form',
      additionalContext: {
        'update_type': 'form_submission',
        'fields_updated': _getUpdatedFields(),
        'has_images': _selectedImages.isNotEmpty,
        'budget_provided': _budgetController.text.isNotEmpty,
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enquiry updated successfully!')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeUsers = ref.watch(activeUsersProvider);
    final isAdmin = ref.watch(currentUserIsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'edit' ? 'Edit Enquiry' : 'New Enquiry'),
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
              const SizedBox(height: 16),

              // Budget Field
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Budget Range',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 50k-100k, Under 25k, etc.',
                ),
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
                        style: TextStyle(color: _selectedDate == null ? Colors.grey : null),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Type Field - SIMPLIFIED FOR TESTING
              Builder(
                builder: (context) {
                  print('🔍 EnquiryFormScreen: Event type value: "$_selectedEventType"');
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedEventType,
                    decoration: const InputDecoration(
                      labelText: 'Event Type *',
                      prefixIcon: Icon(Icons.event),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'wedding', child: Text('Wedding')),
                      DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
                      DropdownMenuItem(value: 'corporate_event', child: Text('Corporate Event')),
                      DropdownMenuItem(value: 'haldi', child: Text('Haldi')),
                      DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
                      DropdownMenuItem(value: 'others', child: Text('Others')),
                    ],
                    onChanged: (value) {
                      print('🔍 EnquiryFormScreen: Event type changed to: "$value"');
                      setState(() {
                        _selectedEventType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select an event type';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Status Field
              StatusDropdown(
                collectionName: 'statuses',
                value: _selectedStatus,
                label: 'Status',
                onChanged: (value) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select a status';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Priority Field
              StatusDropdown(
                collectionName: 'priorities',
                value: _selectedPriority,
                label: 'Priority',
                onChanged: (value) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select a priority';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Assignment Field (Admin Only)
              if (isAdmin) ...[
                activeUsers.when(
                  data: (users) {
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedAssignedTo,
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        prefixIcon: Icon(Icons.person_add),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Select user to assign'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('Unassigned')),
                        ...users.docs.map((doc) {
                          final user = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(
                              (user['name'] as String?) ?? (user['email'] as String?) ?? 'Unknown',
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            _selectedAssignedTo = value;
                          });
                        });
                      },
                    );
                  },
                  loading: () => TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Assign To',
                      prefixIcon: Icon(Icons.person_add),
                      border: OutlineInputBorder(),
                      hintText: 'Loading users...',
                    ),
                    enabled: false,
                  ),
                  error: (error, stack) => TextFormField(
                    initialValue: _selectedAssignedTo ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Assign To (User ID)',
                      prefixIcon: Icon(Icons.person_add),
                      border: OutlineInputBorder(),
                      hintText: 'Enter user ID or leave empty for unassigned',
                    ),
                    onChanged: (value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedAssignedTo = value.isEmpty ? null : value;
                        });
                      });
                    },
                  ),
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

                // Payment Status Field
                StatusDropdown(
                  collectionName: 'payment_statuses',
                  value: _selectedPaymentStatus,
                  label: 'Payment Status',
                  onChanged: (value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedPaymentStatus = value;
                      });
                    });
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a payment status';
                    }
                    return null;
                  },
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
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
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
                                  child: const Icon(Icons.close, color: Colors.white, size: 16),
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                    : ClampedText(
                        widget.mode == 'edit' ? 'Update Enquiry' : 'Create Enquiry',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Builder(
        builder: (context) {
          return Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}
