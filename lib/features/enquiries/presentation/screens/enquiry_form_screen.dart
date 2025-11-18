import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/status_dropdown.dart';
import '../../../../utils/logger.dart';

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

  DateTime? _selectedDate;
  String? _selectedEventType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedPaymentStatus;
  String? _selectedAssignedTo;
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = []; // URLs from Firestore
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Log.d(
      'EnquiryFormScreen initState',
      data: {'mode': widget.mode, 'hasEnquiryId': widget.enquiryId != null},
    );
    // Set default values for dropdowns
    // Use dropdown value keys (snake_case)
    _selectedStatus = 'new';
    _selectedPriority = 'medium';
    _selectedPaymentStatus = 'pending';

    // Load existing data if in edit mode
    if (widget.mode == 'edit' && widget.enquiryId != null) {
      Log.d(
        'EnquiryFormScreen scheduled load',
        data: {'enquiryId': widget.enquiryId?.substring(0, 6)},
      );
      _loadEnquiryData();
    } else {
      Log.d('EnquiryFormScreen skip load (create mode)');
    }
  }

  Future<void> _loadEnquiryData() async {
    Log.d('EnquiryFormScreen load start', data: {'enquiryId': widget.enquiryId?.substring(0, 6)});
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
          _selectedEventType = (data['eventTypeValue'] ?? data['eventType']) as String?;
          Log.d('EnquiryFormScreen loaded event type', data: {'eventType': _selectedEventType});

          // Safely set dropdown values - ensure they exist in valid options
          final eventStatus = (data['statusValue'] ?? data['eventStatus']) as String?;
          _selectedStatus = eventStatus;

          final priority = (data['priorityValue'] ?? data['priority']) as String?;
          _selectedPriority = priority;

          final paymentStatus = (data['paymentStatusValue'] ?? data['paymentStatus']) as String?;
          _selectedPaymentStatus = paymentStatus;

          _selectedAssignedTo = data['assignedTo'] as String?;

          if (data['eventDate'] != null) {
            final timestamp = data['eventDate'] as Timestamp;
            _selectedDate = timestamp.toDate();
          }

          // Load existing images
          _existingImageUrls.clear();
          if (data['images'] != null) {
            final images = data['images'] as List<dynamic>?;
            if (images != null && images.isNotEmpty) {
              final imageUrls = images
                  .map((e) => e.toString())
                  .where((url) => url.isNotEmpty)
                  .toList();
              _existingImageUrls.addAll(imageUrls);
              Log.d(
                'EnquiryFormScreen loaded images',
                data: {'count': imageUrls.length, 'urls': imageUrls},
              );
            } else {
              Log.d('EnquiryFormScreen images field is empty or null');
            }
          } else {
            Log.d('EnquiryFormScreen no images field found in document');
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
    final dropdownLookup = await ref.read(dropdownLookupProvider.future);

    const statusValue = 'new';
    final statusLabel = dropdownLookup.labelForStatus(statusValue);

    final eventTypeValue = _selectedEventType!;
    final eventTypeLabel = dropdownLookup.labelForEventType(eventTypeValue);

    final priorityValue = _selectedPriority ?? 'medium';
    final priorityLabel = dropdownLookup.labelForPriority(priorityValue);

    final paymentStatusValue = _selectedPaymentStatus ?? 'unpaid';
    final paymentStatusLabel = dropdownLookup.labelForPaymentStatus(paymentStatusValue);

    const sourceValue = 'app';
    final sourceLabel = dropdownLookup.labelForSource(sourceValue);

    final enquiryId = await firestoreService.createEnquiry(
      customerName: _nameController.text.trim(),
      customerEmail: '', // TODO: Add email field if needed
      customerPhone: _phoneController.text.trim(),
      eventType: eventTypeValue,
      eventDate: _selectedDate!,
      eventLocation: _locationController.text.trim(),
      guestCount: 0, // TODO: Add guest count field
      budgetRange: '', // TODO: Add budget field
      description: _notesController.text.trim(),
      createdBy: currentUser.uid,
      priority: priorityValue,
      source: sourceValue,
      totalCost: _parseDouble(_totalCostController.text),
      advancePaid: _parseDouble(_advancePaidController.text),
      paymentStatus: paymentStatusValue,
      assignedTo: _selectedAssignedTo,
      statusValue: statusValue,
      statusLabel: statusLabel,
      eventTypeLabel: eventTypeLabel,
      priorityLabel: priorityLabel,
      sourceLabel: sourceLabel,
      paymentStatusLabel: paymentStatusLabel,
    );

    // Upload reference images if any and save URLs
    if (_selectedImages.isNotEmpty) {
      try {
        final urls = await _uploadImages(enquiryId);
        if (urls.isNotEmpty) {
          await FirebaseFirestore.instance.collection('enquiries').doc(enquiryId).update({
            'images': FieldValue.arrayUnion(urls),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': currentUser.uid,
          });
          // Clear selected images after successful upload
          setState(() {
            _selectedImages.clear();
          });
        }
      } catch (e) {
        Log.e('Error uploading images', error: e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
        }
      }
    }

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
    final dropdownLookup = await ref.read(dropdownLookupProvider.future);

    // Fetch old enquiry data to compare changes
    final oldEnquiryDoc = await FirebaseFirestore.instance
        .collection('enquiries')
        .doc(widget.enquiryId!)
        .get();
    final oldEnquiryData = oldEnquiryDoc.data() as Map<String, dynamic>? ?? {};

    final statusValue = _selectedStatus ?? 'new';
    final statusLabel = dropdownLookup.labelForStatus(statusValue);

    final eventTypeValue = _selectedEventType ?? 'event';
    final eventTypeLabel = dropdownLookup.labelForEventType(eventTypeValue);

    final priorityValue = _selectedPriority;
    final priorityLabel = priorityValue != null
        ? dropdownLookup.labelForPriority(priorityValue)
        : null;

    final paymentStatusValue = _selectedPaymentStatus;
    final paymentStatusLabel = paymentStatusValue != null
        ? dropdownLookup.labelForPaymentStatus(paymentStatusValue)
        : null;

    final newCustomerName = _nameController.text.trim();
    final newCustomerPhone = _phoneController.text.trim();
    final newEventLocation = _locationController.text.trim();
    final newDescription = _notesController.text.trim();
    final newTotalCost = _parseDouble(_totalCostController.text);
    final newAdvancePaid = _parseDouble(_advancePaidController.text);

    // Update the enquiry document directly
    await FirebaseFirestore.instance.collection('enquiries').doc(widget.enquiryId!).update({
      'customerName': newCustomerName,
      'customerPhone': newCustomerPhone,
      'eventLocation': newEventLocation,
      'description': newDescription,
      'eventType': eventTypeValue,
      'eventTypeValue': eventTypeValue,
      'eventTypeLabel': eventTypeLabel,
      'eventDate': Timestamp.fromDate(_selectedDate!),
      'priority': priorityValue,
      'priorityValue': priorityValue,
      'priorityLabel': priorityLabel,
      'eventStatus': statusValue,
      'status': statusValue,
      'statusValue': statusValue,
      'statusLabel': statusLabel,
      'paymentStatus': paymentStatusValue,
      'paymentStatusValue': paymentStatusValue,
      'paymentStatusLabel': paymentStatusLabel,
      'assignedTo': _selectedAssignedTo,
      'totalCost': newTotalCost,
      'advancePaid': newAdvancePaid,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUser.uid,
    });

    // Upload reference images if any and save URLs
    if (_selectedImages.isNotEmpty) {
      try {
        final urls = await _uploadImages(widget.enquiryId!);
        if (urls.isNotEmpty) {
          Log.d(
            'EnquiryFormScreen updating images',
            data: {'enquiryId': widget.enquiryId, 'urlCount': urls.length, 'urls': urls},
          );
          await FirebaseFirestore.instance.collection('enquiries').doc(widget.enquiryId!).update({
            'images': FieldValue.arrayUnion(urls),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': currentUser.uid,
          });
          Log.d('EnquiryFormScreen images updated successfully');
          // Add to existing images list for display
          setState(() {
            _existingImageUrls.addAll(urls);
            _selectedImages.clear(); // Clear after upload
          });
        }
      } catch (e) {
        Log.e('Error uploading images', error: e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
        }
      }
    }

    // Record audit trail for individual field changes
    final auditService = AuditService();
    final changes = <String, Map<String, dynamic>>{};

    // Track status change (store VALUES, not labels)
    final oldStatusValue = (oldEnquiryData['statusValue'] ?? oldEnquiryData['eventStatus'] ?? oldEnquiryData['status']) as String? ?? 'new';
    if (oldStatusValue != statusValue) {
      changes['eventStatus'] = {
        'old_value': oldStatusValue,
        'new_value': statusValue,
      };
    }

    // Track assignment change
    final oldAssignedTo = oldEnquiryData['assignedTo'] as String?;
    if (oldAssignedTo != _selectedAssignedTo) {
      changes['assignedTo'] = {
        'old_value': oldAssignedTo ?? 'Unassigned',
        'new_value': _selectedAssignedTo ?? 'Unassigned',
      };
    }

    // Track priority change
    final oldPriorityValue = oldEnquiryData['priorityValue'] ?? oldEnquiryData['priority'];
    if (oldPriorityValue != priorityValue) {
      changes['priority'] = {
        'old_value': oldPriorityValue ?? 'Not Set',
        'new_value': priorityValue ?? 'Not Set',
      };
    }

    // Track payment status change
    final oldPaymentStatusValue = oldEnquiryData['paymentStatusValue'] ?? oldEnquiryData['paymentStatus'];
    if (oldPaymentStatusValue != paymentStatusValue) {
      changes['paymentStatus'] = {
        'old_value': oldPaymentStatusValue ?? 'Not Set',
        'new_value': paymentStatusValue ?? 'Not Set',
      };
    }

    // Track customer name change
    final oldCustomerName = oldEnquiryData['customerName'] as String? ?? '';
    if (oldCustomerName != newCustomerName) {
      changes['customerName'] = {
        'old_value': oldCustomerName.isEmpty ? 'Not Set' : oldCustomerName,
        'new_value': newCustomerName.isEmpty ? 'Not Set' : newCustomerName,
      };
    }

    // Track customer phone change
    final oldCustomerPhone = oldEnquiryData['customerPhone'] as String? ?? '';
    if (oldCustomerPhone != newCustomerPhone) {
      changes['customerPhone'] = {
        'old_value': oldCustomerPhone.isEmpty ? 'Not Set' : oldCustomerPhone,
        'new_value': newCustomerPhone.isEmpty ? 'Not Set' : newCustomerPhone,
      };
    }

    // Track event location change
    final oldEventLocation = oldEnquiryData['eventLocation'] as String? ?? '';
    if (oldEventLocation != newEventLocation) {
      changes['eventLocation'] = {
        'old_value': oldEventLocation.isEmpty ? 'Not Set' : oldEventLocation,
        'new_value': newEventLocation.isEmpty ? 'Not Set' : newEventLocation,
      };
    }

    // Track total cost change
    final oldTotalCost = oldEnquiryData['totalCost'];
    if (oldTotalCost != newTotalCost) {
      changes['totalCost'] = {
        'old_value': oldTotalCost ?? 0,
        'new_value': newTotalCost ?? 0,
      };
    }

    // Track advance paid change
    final oldAdvancePaid = oldEnquiryData['advancePaid'];
    if (oldAdvancePaid != newAdvancePaid) {
      changes['advancePaid'] = {
        'old_value': oldAdvancePaid ?? 0,
        'new_value': newAdvancePaid ?? 0,
      };
    }

    // Record all changes at once
    if (changes.isNotEmpty) {
      await auditService.recordMultipleChanges(
        enquiryId: widget.enquiryId!,
        changes: changes,
      );
    }

    // Send notification for enquiry update
    final notificationService = NotificationService();
    await notificationService.notifyEnquiryUpdated(
      enquiryId: widget.enquiryId!,
      customerName: _nameController.text.trim(),
      eventType: eventTypeValue,
      updatedBy: currentUser.uid,
      assignedTo: _selectedAssignedTo,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enquiry updated successfully!')));
      Navigator.of(context).pop();
    }
  }

  Future<List<String>> _uploadImages(String enquiryId) async {
    final storage = FirebaseStorage.instance;
    final List<String> downloadUrls = [];

    for (final xfile in _selectedImages) {
      try {
        if (kIsWeb) {
          // For web, read bytes from XFile
          final bytes = await xfile.readAsBytes();
          final fileName = xfile.name;
          final ref = storage
              .ref()
              .child('enquiries')
              .child(enquiryId)
              .child('images')
              .child(fileName);

          // Set content type based on file extension
          final contentType = _getContentType(fileName);

          // Upload with metadata
          final metadata = SettableMetadata(contentType: contentType, cacheControl: 'max-age=3600');

          final task = await ref.putData(bytes, metadata);
          final url = await task.ref.getDownloadURL();
          downloadUrls.add(url);
          Log.d('EnquiryFormScreen image uploaded', data: {'fileName': fileName, 'url': url});
        } else {
          // For mobile, use File
          final file = File(xfile.path);
          final fileName = xfile.name;
          final ref = storage
              .ref()
              .child('enquiries')
              .child(enquiryId)
              .child('images')
              .child(fileName);

          // Set content type
          final contentType = _getContentType(fileName);
          final metadata = SettableMetadata(contentType: contentType);

          final task = await ref.putFile(file, metadata);
          final url = await task.ref.getDownloadURL();
          downloadUrls.add(url);
          Log.d('EnquiryFormScreen image uploaded', data: {'fileName': fileName, 'url': url});
        }
      } catch (e) {
        Log.e('Error uploading image ${xfile.name}', error: e);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading ${xfile.name}: $e')));
        }
        // Continue with other images
      }
    }

    return downloadUrls;
  }

  String _getContentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
    // TODO: Optionally delete from Firestore and Storage
  }

  @override
  Widget build(BuildContext context) {
    // Watch role provider directly to handle loading state properly
    final roleAsync = ref.watch(roleProvider);

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

              // Event Type Field - Firestore-backed via StatusDropdown
              StatusDropdown(
                collectionName: 'event_types',
                value: _selectedEventType,
                label: 'Event Type',
                required: true,
                onChanged: (value) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedEventType = value;
                    });
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please select an event type';
                  }
                  return null;
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
              // Show loading state while checking admin status
              roleAsync.when(
                data: (role) {
                  if (role != UserRole.admin) {
                    return const SizedBox.shrink();
                  }

                  // User is admin, use Consumer to watch activeUsersProvider
                  return Consumer(
                    builder: (context, ref, child) {
                      final activeUsers = ref.watch(activeUsersProvider);

                      return activeUsers.when(
                        data: (users) {
                          return DropdownButtonFormField<String>(
                            value: _selectedAssignedTo,
                            decoration: const InputDecoration(
                              labelText: 'Assign To',
                              prefixIcon: Icon(Icons.person_add),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select user to assign'),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Unassigned'),
                              ),
                              ...users.docs.map((doc) {
                                final user = doc.data() as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: doc.id,
                                  child: Text(
                                    (user['name'] as String?) ??
                                        (user['email'] as String?) ??
                                        'Unknown',
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
                          decoration: const InputDecoration(
                            labelText: 'Assign To',
                            prefixIcon: Icon(Icons.person_add),
                            border: OutlineInputBorder(),
                            hintText: 'Loading users...',
                          ),
                          enabled: false,
                        ),
                        error: (error, stack) {
                          Log.e('Error loading users for assignment', error: error);
                          return TextFormField(
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
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Assign To',
                    prefixIcon: Icon(Icons.person_add),
                    border: OutlineInputBorder(),
                    hintText: 'Checking permissions...',
                  ),
                  enabled: false,
                ),
                error: (error, stack) {
                  Log.e('Error checking admin status', error: error);
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),

              // Financial Information Section (Admin Only)
              roleAsync.when(
                data: (role) {
                  if (role != UserRole.admin) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

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

              // Selected Images (new uploads)
              if (_selectedImages.isNotEmpty) ...[
                Text(
                  'New Images (${_selectedImages.length})',
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
                                child: kIsWeb
                                    ? FutureBuilder<Uint8List>(
                                        future: _selectedImages[index].readAsBytes(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          if (snapshot.hasData) {
                                            return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                          }
                                          return const Icon(Icons.error);
                                        },
                                      )
                                    : Image.file(
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

              // Existing Images (from Firestore)
              // Debug: Always show section header to verify images are loaded
              Text(
                'Existing Images (${_existingImageUrls.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_existingImageUrls.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No existing images found',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      final url = _existingImageUrls[index];
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
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
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
                    : Text(
                        widget.mode == 'edit' ? 'Update Enquiry' : 'Create Enquiry',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
