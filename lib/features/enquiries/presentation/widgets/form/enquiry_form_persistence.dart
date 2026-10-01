part of '../../screens/enquiry_form_screen.dart';

/// Form state, hydration (edit mode) and create/update persistence for
/// [EnquiryFormScreen]. Kept apart from the layout in the screen file.
mixin _EnquiryFormPersistence on ConsumerState<EnquiryFormScreen> {
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
  final _quotedAmountController = TextEditingController();

  DateTime? _selectedDate;
  DateTime? _quotedAt;
  String? _selectedEventType;
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedPaymentStatus;
  String? _selectedAssignedTo;
  String _selectedSource = 'instagram'; // default — user changes at creation
  final List<XFile> _selectedImages = [];
  final List<String> _existingImageUrls = []; // URLs from Firestore
  bool _isLoading = false;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    Log.d(
      'EnquiryFormScreen initState',
      data: {'mode': widget.mode, 'hasEnquiryId': widget.enquiryId != null},
    );

    if (widget.mode != 'edit') {
      // Set default values for dropdowns (create mode only)
      _selectedStatus = 'new';
      _selectedPriority = 'medium';
      _selectedPaymentStatus = 'pending';
      _hydrated = true;
      Log.d('EnquiryFormScreen skip load (create mode)');
    } else if (widget.enquiryId != null) {
      Log.d(
        'EnquiryFormScreen scheduled load',
        data: {'enquiryId': widget.enquiryId?.substring(0, 6)},
      );
      _loadEnquiryData();
    }
  }

  Future<void> _loadEnquiryData() async {
    Log.d('EnquiryFormScreen load start', data: {'enquiryId': widget.enquiryId?.substring(0, 6)});
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
          if (data['quotedAmount'] != null) {
            _quotedAmountController.text = data['quotedAmount'].toString();
          }
          final quotedAtRaw = data['quotedAt'];
          if (quotedAtRaw is Timestamp) _quotedAt = quotedAtRaw.toDate();

          // Set dropdown values from database
          _selectedEventType = (data['eventTypeValue'] ?? data['eventType']) as String?;
          Log.d('EnquiryFormScreen loaded event type', data: {'eventType': _selectedEventType});

          // Safely set dropdown values - ensure they exist in valid options
          final statusValue = data['statusValue'] as String?;
          _selectedStatus = EnquiryStatus.canonicalValue(statusValue) ?? statusValue;

          final priority = (data['priorityValue'] ?? data['priority']) as String?;
          _selectedPriority = priority;

          final paymentStatus = (data['paymentStatusValue'] ?? data['paymentStatus']) as String?;
          _selectedPaymentStatus = paymentStatus;

          _selectedAssignedTo = data['assignedTo'] as String?;

          final sourceValue = (data['sourceValue'] ?? data['source']) as String?;
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

          _hydrated = true;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enquiry not found')));
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading enquiry data: $e')));
        Navigator.of(context).maybePop();
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
    _quotedAmountController.dispose();
    super.dispose();
  }

  /// `quotedAmount` / `quotedAt` to write. `quotedAt` defaults to now the first
  /// time an amount is entered. Returns only fields that differ from [oldData].
  Map<String, Object?> _quoteFields(Map<String, dynamic> oldData) {
    final amount = _parseDouble(_quotedAmountController.text);
    final oldAmount = (oldData['quotedAmount'] as num?)?.toDouble();
    final oldAtRaw = oldData['quotedAt'];
    final oldAt = oldAtRaw is Timestamp ? oldAtRaw.toDate() : null;
    if (amount == null) {
      if (oldAmount == null) return const {};
      return {'quotedAmount': null, 'quotedAt': null};
    }
    final at = _quotedAt ?? oldAt ?? DateTime.now();
    return {
      if (amount != oldAmount) 'quotedAmount': amount,
      if (oldAt == null || at != oldAt) 'quotedAt': Timestamp.fromDate(at),
    };
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

    final paymentStatusValue = _selectedPaymentStatus ?? 'pending';
    final paymentStatusLabel = dropdownLookup.labelForPaymentStatus(paymentStatusValue);

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

    final quoteFields = _quoteFields(const {});
    if (quoteFields.isNotEmpty) {
      await firestoreService.updateEnquiry(enquiryId, {...quoteFields, 'updatedBy': currentUser.uid});
    }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enquiry created successfully!')));
      Navigator.of(context).pop();
    }
  }

  static String _canonicalOldStatus(Map<String, dynamic> data) {
    final raw = data['statusValue'] as String?;
    return EnquiryStatus.canonicalValue(raw) ?? raw ?? 'new';
  }

  Future<void> _updateEnquiry(UserModel currentUser) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final dropdownLookup = await ref.read(dropdownLookupProvider.future);

    // Fetch old enquiry data to compare changes
    final oldEnquiryData = await firestoreService.getEnquiry(widget.enquiryId!) ?? {};

    final statusValue = EnquiryStatus.canonicalValue(_selectedStatus) ?? _selectedStatus ?? 'new';
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
    final isFinancialChange = (oldTotalCost != newTotalCost) || (oldAdvancePaid != newAdvancePaid);

    // Show confirmation for financial changes (admin only)
    if (isFinancialChange) {
      final roleAsync = ref.read(roleProvider);
      final isAdmin = roleAsync.valueOrNull == UserRole.admin;

      if (isAdmin) {
        final message = buildFinancialChangeMessage(
          oldTotalCost: oldTotalCost,
          newTotalCost: newTotalCost,
          oldAdvancePaid: oldAdvancePaid,
          newAdvancePaid: newAdvancePaid,
        );

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

    // Moving to a lost status asks why (same rule as every other status path).
    LostReasonChoice? lostChoice;
    final statusChanging = _canonicalOldStatus(oldEnquiryData) != statusValue;
    if (statusChanging && EnquiryStatus.isLost(statusValue)) {
      if (!mounted) return;
      final prompt = await promptLostReasonIfNeeded(context, statusValue);
      if (!prompt.proceed || !mounted) return;
      lostChoice = prompt.choice;
    }

    // Upload reference images if any and get URLs
    List<String> newImageUrls = [];
    if (_selectedImages.isNotEmpty) {
      try {
        final urls = await _uploadImages(widget.enquiryId!);
        if (urls.isNotEmpty) {
          Log.d(
            'EnquiryFormScreen uploaded new images',
            data: {'enquiryId': widget.enquiryId, 'urlCount': urls.length, 'urls': urls},
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
    final oldStatusValue = _canonicalOldStatus(oldEnquiryData);
    final statusDidChange = oldStatusValue != statusValue;

    // Update the enquiry document — include images field with complete list
    await firestoreService.updateEnquiry(widget.enquiryId!, {
      'customerName': newCustomerName,
      'customerPhone': newCustomerPhone,
      if (newCustomerEmail.isNotEmpty) 'customerEmail': newCustomerEmail.toLowerCase(),
      'eventLocation': newEventLocation,
      ...enquiryNotesFields(newDescription),
      'eventType': eventTypeValue,
      'eventTypeValue': eventTypeValue,
      'eventTypeLabel': eventTypeLabel,
      'eventDate': Timestamp.fromDate(_selectedDate!),
      if (newGuestCount != null && newGuestCount >= 0) 'guestCount': newGuestCount,
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
        for (final field in EnquiryStageFields.fieldsToStamp(oldEnquiryData, statusValue))
          field: FieldValue.serverTimestamp(),
      },
      if (lostChoice != null) ...lostChoice.toFields(),
      ..._quoteFields(oldEnquiryData),
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
    final changes = buildEnquiryAuditChanges(
      oldEnquiryData: oldEnquiryData,
      statusValue: statusValue,
      assignedTo: _selectedAssignedTo,
      priorityValue: priorityValue,
      paymentStatusValue: paymentStatusValue,
      newCustomerName: newCustomerName,
      newCustomerPhone: newCustomerPhone,
      newEventLocation: newEventLocation,
      oldTotalCost: oldTotalCost,
      newTotalCost: newTotalCost,
      oldAdvancePaid: oldAdvancePaid,
      newAdvancePaid: newAdvancePaid,
    );

    if (lostChoice != null) {
      changes['lostReason'] = {
        'old_value': oldEnquiryData['lostReason'],
        'new_value': lostChoice.reason.value,
      };
    }

    // Record all changes at once
    if (changes.isNotEmpty) {
      await auditService.recordMultipleChanges(enquiryId: widget.enquiryId!, changes: changes);
    }

    // Send notifications
    final notificationService = ref.read(notificationServiceProvider);

    // If status changed, send specific status update notification to admins
    if (statusDidChange) {
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

    // Re-assignment from the edit form: tell the new assignee (and other admins).
    final previousAssignee = oldEnquiryData['assignedTo'] as String?;
    if (_selectedAssignedTo != null &&
        _selectedAssignedTo!.isNotEmpty &&
        _selectedAssignedTo != previousAssignee) {
      await notificationService.notifyEnquiryAssigned(
        enquiryId: widget.enquiryId!,
        customerName: _nameController.text.trim(),
        eventType: eventTypeLabel,
        assignedTo: _selectedAssignedTo!,
        assignedBy: currentUser.uid,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enquiry updated successfully!')));
      Navigator.of(context).pop();
    }
  }

  Future<List<String>> _uploadImages(String enquiryId) {
    return const EnquiryImageUploader().upload(
      enquiryId,
      _selectedImages,
      onError: (xfile, e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading ${xfile.name}: $e')));
        }
      },
    );
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
      await ref.read(firestoreServiceProvider).updateEnquiry(widget.enquiryId!, {
        'images': _existingImageUrls,
      });
    } catch (e) {
      Log.e('Failed to update enquiry images after removal', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image removed locally but failed to save — try saving the form'),
          ),
        );
      }
    }
  }
}
