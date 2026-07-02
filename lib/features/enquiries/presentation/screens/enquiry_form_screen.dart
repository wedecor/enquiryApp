import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/enquiry_fields.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/providers/audit_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../ui/components/sticky_bottom_bar.dart';
import '../widgets/enquiry_form_customer_fields.dart';
import '../widgets/enquiry_form_event_fields.dart';
import '../widgets/enquiry_form_financial_fields.dart';
import '../widgets/enquiry_form_images_section.dart';
import '../widgets/enquiry_form_section.dart';

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
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _guestCountController = TextEditingController();
  final _budgetController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _advancePaidController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedEventType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedPaymentStatus;
  String? _selectedAssignedTo;
  String _selectedSource = 'instagram'; // default — user changes at creation
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
    Log.d(
      'EnquiryFormScreen load start',
      data: {'enquiryId': widget.enquiryId?.substring(0, 6)},
    );
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final data = await firestoreService.getEnquiry(widget.enquiryId!);

      if (data != null) {
        setState(() {
          _nameController.text = (data['customerName'] as String?) ?? '';
          _phoneController.text = (data['customerPhone'] as String?) ?? '';
          _emailController.text = (data['customerEmail'] as String?) ?? '';
          _locationController.text = (data['eventLocation'] as String?) ?? '';
          _notesController.text = enquiryNotesFrom(data) ?? '';

          if (data['totalCost'] != null) {
            _totalCostController.text = data['totalCost'].toString();
          }
          if (data['advancePaid'] != null) {
            _advancePaidController.text = data['advancePaid'].toString();
          }

          // Set dropdown values from database
          _selectedEventType =
              (data['eventTypeValue'] ?? data['eventType']) as String?;
          Log.d(
            'EnquiryFormScreen loaded event type',
            data: {'eventType': _selectedEventType},
          );

          // Safely set dropdown values - ensure they exist in valid options
          // Only use statusValue - standard field
          final statusValue = data['statusValue'] as String?;
          _selectedStatus = statusValue;

          final priority =
              (data['priorityValue'] ?? data['priority']) as String?;
          _selectedPriority = priority;

          final paymentStatus =
              (data['paymentStatusValue'] ?? data['paymentStatus']) as String?;
          _selectedPaymentStatus = paymentStatus;

          _selectedAssignedTo = data['assignedTo'] as String?;

          final sourceValue =
              (data['sourceValue'] ?? data['source']) as String?;
          if (sourceValue != null && sourceValue.trim().isNotEmpty) {
            _selectedSource = sourceValue.trim();
          }

          final guestCount = data['guestCount'];
          if (guestCount != null) {
            _guestCountController.text = guestCount.toString();
          }
          final budget = data['budgetRange'] as String?;
          if (budget != null && budget.trim().isNotEmpty) {
            _budgetController.text = budget;
          }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enquiry data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _guestCountController.dispose();
    _budgetController.dispose();
    _totalCostController.dispose();
    _advancePaidController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    // In edit mode, allow past dates so staff can correct wrong entries.
    final isEdit = widget.mode == 'edit';
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: isEdit ? DateTime(2020, 1, 1) : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
            content: Text(
              'Error ${widget.mode == 'edit' ? 'updating' : 'creating'} enquiry: $e',
            ),
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

    final paymentStatusValue = _selectedPaymentStatus ?? 'pending';
    final paymentStatusLabel = dropdownLookup.labelForPaymentStatus(
      paymentStatusValue,
    );

    final sourceValue = _selectedSource;
    final sourceLabel = dropdownLookup.labelForSource(sourceValue);

    final enquiryId = await firestoreService.createEnquiry(
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      eventType: eventTypeValue,
      eventDate: _selectedDate!,
      eventLocation: _locationController.text.trim(),
      guestCount: int.tryParse(_guestCountController.text.trim()) ?? 0,
      budgetRange: _budgetController.text.trim(),
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
          await firestoreService.updateEnquiry(enquiryId, {
            'images': FieldValue.arrayUnion(urls),
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
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.notifyEnquiryCreated(
      enquiryId: enquiryId,
      customerName: _nameController.text.trim(),
      eventType: _selectedEventType!,
      createdBy: currentUser.uid,
    );

    // Record audit trail for assignment if assigned
    if (_selectedAssignedTo != null) {
      final auditService = ref.read(auditServiceProvider);
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
  }

  Future<void> _updateEnquiry(UserModel currentUser) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final dropdownLookup = await ref.read(dropdownLookupProvider.future);

    // Fetch old enquiry data to compare changes
    final oldEnquiryData =
        await firestoreService.getEnquiry(widget.enquiryId!) ?? {};

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

    final sourceValue = _selectedSource;
    final sourceLabel = dropdownLookup.labelForSource(sourceValue);

    final newCustomerName = _nameController.text.trim();
    final newCustomerEmail = _emailController.text.trim();
    final newGuestCount = int.tryParse(_guestCountController.text.trim());
    final newBudgetRange = _budgetController.text.trim();
    final newCustomerPhone = _phoneController.text.trim();
    final newEventLocation = _locationController.text.trim();
    final newDescription = _notesController.text.trim();
    final newTotalCost = _parseDouble(_totalCostController.text);
    final newAdvancePaid = _parseDouble(_advancePaidController.text);

    // Check if financial fields are being changed (admin only)
    final oldTotalCost = oldEnquiryData['totalCost'] as num?;
    final oldAdvancePaid = oldEnquiryData['advancePaid'] as num?;
    final isFinancialChange =
        (oldTotalCost != newTotalCost) || (oldAdvancePaid != newAdvancePaid);

    // Show confirmation for financial changes (admin only)
    if (isFinancialChange) {
      final roleAsync = ref.read(roleProvider);
      final isAdmin = roleAsync.valueOrNull == UserRole.admin;

      if (isAdmin) {
        final costChanged = oldTotalCost != newTotalCost;
        final advanceChanged = oldAdvancePaid != newAdvancePaid;

        String message = 'You are about to update financial information:\n\n';
        if (costChanged) {
          final oldCostStr = oldTotalCost != null
              ? '₹${oldTotalCost.toStringAsFixed(0)}'
              : 'Not set';
          final newCostStr = newTotalCost != null
              ? '₹${newTotalCost.toStringAsFixed(0)}'
              : 'Not set';
          message += '• Total Cost: $oldCostStr → $newCostStr\n';
        }
        if (advanceChanged) {
          final oldAdvanceStr = oldAdvancePaid != null
              ? '₹${oldAdvancePaid.toStringAsFixed(0)}'
              : 'Not set';
          final newAdvanceStr = newAdvancePaid != null
              ? '₹${newAdvancePaid.toStringAsFixed(0)}'
              : 'Not set';
          message += '• Advance Paid: $oldAdvanceStr → $newAdvanceStr\n';
        }
        message += '\nContinue with this change?';

        final confirmed = await ConfirmationDialog.show(
          context: context,
          title: 'Update Financial Information',
          message: message,
          confirmText: 'Update',
          cancelText: 'Cancel',
          isDestructive: false,
          icon: Icons.attach_money,
        );

        if (!confirmed || !mounted) {
          return; // User cancelled, don't save
        }
      }
    }

    // Upload reference images if any and get URLs
    List<String> newImageUrls = [];
    if (_selectedImages.isNotEmpty) {
      try {
        final urls = await _uploadImages(widget.enquiryId!);
        if (urls.isNotEmpty) {
          Log.d(
            'EnquiryFormScreen uploaded new images',
            data: {
              'enquiryId': widget.enquiryId,
              'urlCount': urls.length,
              'urls': urls,
            },
          );
          newImageUrls = urls;
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
        // Continue with update even if image upload fails
      }
    }

    // Combine existing images (which may have been modified/removed) with newly uploaded ones
    // _existingImageUrls contains the current state (may have removed some)
    final allImageUrls = <String>[..._existingImageUrls, ...newImageUrls];

    // Update UI state to include new images for immediate display
    if (newImageUrls.isNotEmpty) {
      setState(() {
        _existingImageUrls.addAll(newImageUrls);
      });
    }

    Log.d(
      'EnquiryFormScreen updating images field',
      data: {
        'enquiryId': widget.enquiryId,
        'existingCount': _existingImageUrls.length,
        'newCount': newImageUrls.length,
        'totalCount': allImageUrls.length,
        'allUrls': allImageUrls,
      },
    );

    // Determine if status changed (needed for statusUpdatedAt below)
    final oldStatusValueForUpdate =
        (oldEnquiryData['statusValue'] as String?) ?? 'new';
    final statusDidChange = oldStatusValueForUpdate != statusValue;

    // Update the enquiry document — include images field with complete list
    await firestoreService.updateEnquiry(widget.enquiryId!, {
      'customerName': newCustomerName,
      'customerPhone': newCustomerPhone,
      if (newCustomerEmail.isNotEmpty)
        'customerEmail': newCustomerEmail.toLowerCase(),
      'eventLocation': newEventLocation,
      ...enquiryNotesFields(newDescription),
      'eventType': eventTypeValue,
      'eventTypeValue': eventTypeValue,
      'eventTypeLabel': eventTypeLabel,
      'eventDate': Timestamp.fromDate(_selectedDate!),
      if (newGuestCount != null && newGuestCount >= 0)
        'guestCount': newGuestCount,
      if (newBudgetRange.isNotEmpty) 'budgetRange': newBudgetRange,
      'source': sourceValue,
      'sourceValue': sourceValue,
      'sourceLabel': sourceLabel,
      'priority': priorityValue,
      'priorityValue': priorityValue,
      'priorityLabel': priorityLabel,
      'statusValue': statusValue,
      'statusLabel': statusLabel,
      // Keep statusUpdatedAt / statusUpdatedBy in sync when status changes via form
      if (statusDidChange) ...{
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': currentUser.uid,
      },
      'paymentStatus': paymentStatusValue,
      'paymentStatusValue': paymentStatusValue,
      'paymentStatusLabel': paymentStatusLabel,
      'assignedTo': _selectedAssignedTo,
      'totalCost': newTotalCost,
      'advancePaid': newAdvancePaid,
      'images': allImageUrls,
      'updatedBy': currentUser.uid,
      ...FirestoreService.searchIndexFieldsFor(
        customerName: newCustomerName,
        customerPhone: newCustomerPhone,
        customerEmail: newCustomerEmail.isNotEmpty ? newCustomerEmail : null,
        description: newDescription,
        notes: newDescription,
      ),
    });

    Log.d('EnquiryFormScreen enquiry updated successfully with images');

    // Record audit trail for individual field changes
    final auditService = ref.read(auditServiceProvider);
    final changes = <String, Map<String, dynamic>>{};

    // Track status change (store VALUES, not labels)
    // Only use statusValue - standard field
    final oldStatusValue = (oldEnquiryData['statusValue'] as String?) ?? 'new';
    if (oldStatusValue != statusValue) {
      changes['statusValue'] = {
        'old_value': oldStatusValue,
        'new_value': statusValue,
      };
    }

    // Track assignment change
    final oldAssignedTo = oldEnquiryData['assignedTo'] as String?;
    if (oldAssignedTo != _selectedAssignedTo) {
      changes['assignedTo'] = {
        'old_value':
            oldAssignedTo, // null = previously unassigned; display layer shows "Unassigned"
        'new_value': _selectedAssignedTo, // null = clearing the assignment
      };
    }

    // Track priority change
    final oldPriorityValue =
        oldEnquiryData['priorityValue'] ?? oldEnquiryData['priority'];
    if (oldPriorityValue != priorityValue) {
      changes['priority'] = {
        'old_value': oldPriorityValue ?? 'Not Set',
        'new_value': priorityValue ?? 'Not Set',
      };
    }

    // Track payment status change
    final oldPaymentStatusValue =
        oldEnquiryData['paymentStatusValue'] ?? oldEnquiryData['paymentStatus'];
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

    // Track total cost change (oldTotalCost already declared above)
    if (oldTotalCost != newTotalCost) {
      changes['totalCost'] = {
        'old_value': oldTotalCost ?? 0,
        'new_value': newTotalCost ?? 0,
      };
    }

    // Track advance paid change (oldAdvancePaid already declared above)
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

    // Send notifications
    final notificationService = ref.read(notificationServiceProvider);

    // If status changed, send specific status update notification to admins
    if (oldStatusValue != statusValue) {
      if (kDebugMode) {
        debugPrint('📝 EDIT FORM: Status changed via edit form');
        debugPrint('   OldStatus: $oldStatusValue → NewStatus: $statusValue');
        debugPrint('   EnquiryId: ${widget.enquiryId}');
      }

      final lookup = await ref.read(dropdownLookupProvider.future);
      final oldStatusLabel = lookup.labelForStatus(oldStatusValue);
      await notificationService.notifyStatusUpdated(
        enquiryId: widget.enquiryId!,
        customerName: _nameController.text.trim(),
        oldStatus: oldStatusLabel,
        newStatus: statusLabel,
        updatedBy: currentUser.uid,
        assignedTo: _selectedAssignedTo,
      );
    } else {
      // Only send generic enquiry update notification if status didn't change
      // (to avoid duplicate notifications when status changes)
      if (kDebugMode) {
        debugPrint('📝 EDIT FORM: Enquiry updated (status unchanged)');
        debugPrint('   EnquiryId: ${widget.enquiryId}');
        debugPrint('   UpdatedBy: ${currentUser.uid}');
      }

      await notificationService.notifyEnquiryUpdated(
        enquiryId: widget.enquiryId!,
        customerName: _nameController.text.trim(),
        eventType: eventTypeValue,
        updatedBy: currentUser.uid,
        assignedTo: _selectedAssignedTo,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry updated successfully!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<List<String>> _uploadImages(String enquiryId) async {
    final storage = FirebaseStorage.instance;
    final List<String> downloadUrls = [];

    for (final xfile in _selectedImages) {
      try {
        if (kIsWeb) {
          // For web, use Uint8List for putData
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

          // Upload with metadata - ensure bytes are Uint8List
          final metadata = SettableMetadata(
            contentType: contentType,
            cacheControl: 'max-age=3600',
          );

          // Convert to Uint8List if needed
          final uint8List = bytes;

          final task = await ref.putData(uint8List, metadata);
          final url = await task.ref.getDownloadURL();
          downloadUrls.add(url);
          Log.d(
            'EnquiryFormScreen image uploaded',
            data: {'fileName': fileName, 'url': url},
          );
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
          Log.d(
            'EnquiryFormScreen image uploaded',
            data: {'fileName': fileName, 'url': url},
          );
        }
      } catch (e) {
        Log.e('Error uploading image ${xfile.name}', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading ${xfile.name}: $e')),
          );
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

  Future<void> _removeExistingImage(int index) async {
    if (index < 0 || index >= _existingImageUrls.length) return;
    final removedUrl = _existingImageUrls[index];
    setState(() {
      _existingImageUrls.removeAt(index);
    });

    if (widget.mode != 'edit' || widget.enquiryId == null) return;

    try {
      final storageRef = FirebaseStorage.instance.refFromURL(removedUrl);
      await storageRef.delete();
    } catch (e) {
      Log.w(
        'Could not delete image from storage',
        data: {'url': removedUrl, 'error': e.toString()},
      );
    }

    try {
      await ref.read(firestoreServiceProvider).updateEnquiry(
        widget.enquiryId!,
        {'images': _existingImageUrls},
      );
    } catch (e) {
      Log.e('Failed to update enquiry images after removal', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image removed locally but failed to save — try saving the form',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch role provider directly to handle loading state properly
    final colorScheme = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(isAdminProvider);

    if (widget.mode == 'create' && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Enquiry')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only admins can create enquiries',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == 'edit' ? 'Edit Enquiry' : 'New Enquiry'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.space4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.mode == 'create') ...[
                      _FormSectionProgress(
                        sections: const [
                          'Customer',
                          'Event',
                          'Financial',
                          'Notes & Images',
                        ],
                      ),
                      const SizedBox(height: AppTokens.space4),
                    ],
                    EnquiryFormCustomerFields(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      emailController: _emailController,
                      locationController: _locationController,
                    ),

                    EnquiryFormEventFields(
                      selectedDate: _selectedDate,
                      onSelectDate: _selectDate,
                      selectedEventType: _selectedEventType,
                      onEventTypeChanged: (value) =>
                          setState(() => _selectedEventType = value),
                      selectedStatus: _selectedStatus,
                      onStatusChanged: (value) =>
                          setState(() => _selectedStatus = value),
                      selectedPriority: _selectedPriority,
                      onPriorityChanged: (value) =>
                          setState(() => _selectedPriority = value),
                      selectedAssignedTo: _selectedAssignedTo,
                      onAssignedToChanged: (value) =>
                          setState(() => _selectedAssignedTo = value),
                      selectedSource: _selectedSource,
                      onSourceChanged: (value) {
                        if (value != null)
                          setState(() => _selectedSource = value);
                      },
                      guestCountController: _guestCountController,
                      budgetController: _budgetController,
                      showLeadSource: true,
                    ),

                    EnquiryFormFinancialFields(
                      totalCostController: _totalCostController,
                      advancePaidController: _advancePaidController,
                      selectedPaymentStatus: _selectedPaymentStatus,
                      onPaymentStatusChanged: (value) =>
                          setState(() => _selectedPaymentStatus = value),
                      parseDouble: _parseDouble,
                    ),

                    EnquiryFormSection(
                      title: 'Additional Information',
                      children: [
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
                      ],
                    ),

                    EnquiryFormImagesSection(
                      selectedImages: _selectedImages,
                      existingImageUrls: _existingImageUrls,
                      onPickImages: _pickImages,
                      onRemoveImage: _removeImage,
                      onRemoveExistingImage: _removeExistingImage,
                    ),

                    const SizedBox(height: AppTokens.space4),
                  ],
                ),
              ),
            ),
            StickyBottomBar(
              child: FilledButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        widget.mode == 'edit'
                            ? 'Update enquiry'
                            : 'Create enquiry',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form section progress indicator ──────────────────────────────────────────

class _FormSectionProgress extends StatelessWidget {
  const _FormSectionProgress({required this.sections});

  final List<String> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (int i = 0; i < sections.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sections[i],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (i < sections.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}
