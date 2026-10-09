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

  /// Google Maps place picked for the location text; null for free text.
  EnquiryPlace? _locationPlace;

  /// Functions editor (2+ functions: Haldi, Mehendi, Wedding…); null = single event.
  List<EventFunctionDraft>? _functionDrafts;

  /// A single function's id / time / notes, kept while the simple form shows it
  /// (stored 1-function array, or the editor collapsed back to one function).
  EventFunction? _soloFunction;

  /// The loaded enquiry had a `functions` array (cleared if the save no longer needs it).
  bool _hadFunctionArray = false;

  bool get _functionsMode => _functionDrafts != null;

  // Values as loaded when the edit form opened. Status / assignee / images are only
  // written back if the user changed them, so a save can't undo a change someone else
  // made while this form was open.
  String? _initialStatus;
  String? _initialAssignedTo;
  List<String> _initialImageUrls = const [];

  // Customer lookup (create mode): existing customer + open-enquiry duplicate warning.
  Timer? _lookupDebounce;
  String? _whatsappNumber; // from prefill / "Use details"; no form field of its own
  String? _whatsappForPhone; // normalized phone [_whatsappNumber] belongs to
  String? _lookupPhone; // normalized phone of the last lookup
  CustomerLookupResult? _customerLookup; // non-null only for a known customer
  String? _duplicateDismissedForPhone;

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
      _applyPrefill(widget.prefill);
      _hydrated = true;
      _phoneController.addListener(_onPhoneChanged);
      _onPhoneChanged();
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

      if (!mounted) return;
      if (data != null) {
        setState(() {
          _nameController.text = (data['customerName'] as String?) ?? '';
          _phoneController.text = (data['customerPhone'] as String?) ?? '';
          _emailController.text = (data['customerEmail'] as String?) ?? '';
          _locationController.text = (data['eventLocation'] as String?) ?? '';
          _locationPlace = EnquiryPlace.fromData(data);
          _notesController.text = enquiryNotesFrom(data) ?? '';

          if (data['totalCost'] != null) {
            _totalCostController.text = amountText(data['totalCost']);
          }
          if (data['advancePaid'] != null) {
            _advancePaidController.text = amountText(data['advancePaid']);
          }
          if (data['quotedAmount'] != null) {
            _quotedAmountController.text = amountText(data['quotedAmount']);
          }
          final quotedAtRaw = data['quotedAt'];
          _quotedAt = parseEnquiryDateTime(quotedAtRaw);

          // Set dropdown values from database
          _selectedEventType = (data['eventTypeValue'] ?? data['eventType']) as String?;
          Log.d('EnquiryFormScreen loaded event type', data: {'eventType': _selectedEventType});

          // Safely set dropdown values - ensure they exist in valid options
          final statusValue = data['statusValue'] as String?;
          _selectedStatus = EnquiryStatus.canonicalValue(statusValue) ?? statusValue;
          _initialStatus = _selectedStatus;

          final priority = (data['priorityValue'] ?? data['priority']) as String?;
          _selectedPriority = priority;

          final paymentStatus = (data['paymentStatusValue'] ?? data['paymentStatus']) as String?;
          _selectedPaymentStatus = paymentStatus;

          _selectedAssignedTo = data['assignedTo'] as String?;
          _initialAssignedTo = _selectedAssignedTo;

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

          _selectedDate = parseEnquiryDateTime(data['eventDate']);

          // Multi-function booking: open the Functions editor.
          final rawFunctions = data['functions'];
          _hadFunctionArray = rawFunctions is List && rawFunctions.isNotEmpty;
          final storedFunctions = _hadFunctionArray ? functionsOf(data) : const <EventFunction>[];
          if (storedFunctions.length > 1) {
            _functionDrafts = [for (final f in storedFunctions) EventFunctionDraft.fromFunction(f)];
          } else if (storedFunctions.length == 1) {
            _soloFunction = storedFunctions.first;
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
          _initialImageUrls = List.unmodifiable(_existingImageUrls);

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

  void _applyPrefill(EnquiryPrefill? prefill) {
    if (prefill == null) return;
    _nameController.text = prefill.customerName ?? '';
    _phoneController.text = prefill.customerPhone ?? '';
    _emailController.text = prefill.customerEmail ?? '';
    _locationController.text = prefill.eventLocation ?? '';
    _whatsappNumber = prefill.whatsappNumber;
    _whatsappForPhone = normalizePhone(prefill.customerPhone);
    final source = prefill.source?.trim();
    if (source != null && source.isNotEmpty) _selectedSource = source;
    // "Add another event": the user already said this is a different event.
    if (prefill.fromEnquiryId != null) {
      _duplicateDismissedForPhone = normalizePhone(prefill.customerPhone);
    }
  }

  bool get _isCreateMode => widget.mode != 'edit';

  /// WhatsApp number to save — only while the phone still belongs to that customer.
  String? get _currentWhatsapp =>
      _whatsappForPhone != null && normalizePhone(_phoneController.text) == _whatsappForPhone
      ? _whatsappNumber
      : null;

  /// Debounced lookup once the phone has enough digits (create mode only).
  void _onPhoneChanged() {
    if (!_isCreateMode) return;
    final text = _phoneController.text;
    final normalized = normalizePhone(text);
    if (phoneDigitCount(text) < CustomerLookupService.minDigits) {
      _lookupDebounce?.cancel();
      _lookupPhone = null;
      if (_customerLookup != null) setState(() => _customerLookup = null);
      return;
    }
    if (normalized == _lookupPhone) return;
    _lookupDebounce?.cancel();
    // A different number: drop the previous customer's cards straight away.
    if (_customerLookup != null) setState(() => _customerLookup = null);
    _lookupDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _runCustomerLookup(normalized),
    );
  }

  /// Never throws: a failed lookup just shows no cards.
  Future<void> _runCustomerLookup(String normalized) async {
    _lookupPhone = normalized;
    final result = await ref
        .read(customerLookupServiceProvider)
        .lookupOrNull(_phoneController.text.trim());
    if (!mounted) return;
    if (normalizePhone(_phoneController.text) != normalized) return; // phone changed meanwhile
    if (result == null) {
      // Allow a retry on the next edit.
      _lookupPhone = null;
    }
    setState(() {
      _customerLookup = (result?.isKnownCustomer ?? false) ? result : null;
    });
  }

  /// The lookup result for the phone currently typed, if any.
  CustomerLookupResult? get _currentCustomerLookup {
    final lookup = _customerLookup;
    if (lookup == null) return null;
    if (normalizePhone(_phoneController.text) != _lookupPhone) return null;
    return lookup;
  }

  bool get _duplicateWarningDismissed =>
      _duplicateDismissedForPhone != null && _duplicateDismissedForPhone == _lookupPhone;

  void _dismissDuplicateWarning() {
    setState(() => _duplicateDismissedForPhone = _lookupPhone);
  }

  /// Fields "Use details" would change: empty ones are filled, typed ones differ.
  ({bool fillsEmpty, List<String> conflicts}) _customerDetailsDiff(CustomerSummary customer) {
    var fillsEmpty = false;
    final conflicts = <String>[];
    void check(String label, String current, String? incoming) {
      final value = incoming?.trim() ?? '';
      if (value.isEmpty) return;
      if (current.trim().isEmpty) {
        fillsEmpty = true;
      } else if (current.trim().toLowerCase() != value.toLowerCase()) {
        conflicts.add(label);
      }
    }

    check('Name', _nameController.text, customer.name);
    check('Email', _emailController.text, customer.email);
    check('WhatsApp', _currentWhatsapp ?? '', customer.whatsappNumber);
    return (fillsEmpty: fillsEmpty, conflicts: conflicts);
  }

  bool _canUseCustomerDetails(CustomerSummary customer) {
    final diff = _customerDetailsDiff(customer);
    return diff.fillsEmpty || diff.conflicts.isNotEmpty;
  }

  /// Fills empty name / email / WhatsApp; asks before replacing typed values.
  Future<void> _useCustomerDetails(CustomerSummary customer) async {
    final diff = _customerDetailsDiff(customer);
    var overwrite = false;
    if (diff.conflicts.isNotEmpty) {
      overwrite = await ConfirmationDialog.show(
        context: context,
        title: 'Replace typed details?',
        message:
            '${diff.conflicts.join(', ')} already filled in differently. Replace with the '
            'details from ${customer.name}\'s earlier enquiry?',
        confirmText: 'Replace',
        cancelText: 'Keep mine',
        icon: Icons.person_search_outlined,
      );
      if (!mounted) return;
    }
    String pick(String current, String? incoming) {
      final value = incoming?.trim() ?? '';
      if (value.isEmpty) return current;
      if (current.trim().isEmpty || overwrite) return value;
      return current;
    }

    setState(() {
      _nameController.text = pick(_nameController.text, customer.name);
      _emailController.text = pick(_emailController.text, customer.email);
      final whatsapp = pick(_currentWhatsapp ?? '', customer.whatsappNumber);
      _whatsappNumber = whatsapp.isEmpty ? null : whatsapp;
      _whatsappForPhone = _lookupPhone;
    });
  }

  /// Opens an existing enquiry if the user may read it (admin or assignee).
  void _openExistingEnquiry(CustomerEvent event) {
    final isAdmin = ref.read(isAdminProvider);
    if (!event.canOpen(isAdmin: isAdmin)) {
      final who = event.assignedToName;
      final message = who == null
          ? 'Ask an admin — it\'s unassigned'
          : 'Ask an admin — it\'s assigned to $who';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => EnquiryDetailsScreen(enquiryId: event.id)),
    );
  }

  /// In create mode, confirms before saving when the customer has an open enquiry
  /// and the warning wasn't dismissed. Lookup problems never block the save.
  Future<bool> _confirmPossibleDuplicate() async {
    if (!_isCreateMode) return true;
    if (_lookupDebounce?.isActive ?? false) {
      // Saved before the debounced lookup ran: check now, but never wait long.
      _lookupDebounce!.cancel();
      try {
        await _runCustomerLookup(
          normalizePhone(_phoneController.text),
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        Log.w('EnquiryFormScreen: duplicate check skipped', data: {'error': e.toString()});
      }
      if (!mounted) return false;
    }
    final lookup = _currentCustomerLookup;
    if (lookup == null || _duplicateWarningDismissed) return true;
    final open = lookup.openEventList;
    if (open.isEmpty) return true;
    final first = open.first;
    final assignee = first.assignedToName;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Possible duplicate — create anyway?',
      message:
          '${lookup.customer?.name ?? 'This customer'} already has an open enquiry: '
          '${customerEventSummary(first)}${assignee != null ? ' (assigned to $assignee)' : ''}.',
      confirmText: 'Create anyway',
      cancelText: 'Cancel',
      icon: Icons.warning_amber_rounded,
    );
    return confirmed && mounted;
  }

  /// Existing-customer / open-enquiry cards under the phone field (create mode).
  Widget? _customerMatchCards() {
    if (!_isCreateMode) return null;
    final lookup = _currentCustomerLookup;
    final customer = lookup?.customer;
    if (lookup == null || customer == null) return null;
    final open = lookup.openEventList;
    final showWarning = open.isNotEmpty && !_duplicateWarningDismissed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExistingCustomerCard(
          result: lookup,
          onUseDetails: _canUseCustomerDetails(customer)
              ? () => _useCustomerDetails(customer)
              : null,
        ),
        if (showWarning) ...[
          const SizedBox(height: AppTokens.space2),
          OpenEnquiryWarningCard(
            customerName: customer.name,
            openEvents: open,
            onOpen: _openExistingEnquiry,
            onDismiss: _dismissDuplicateWarning,
          ),
        ],
      ],
    );
  }

  /// "+ Add another function": the first card is pre-filled from the event type /
  /// date / location already entered; later presses add an empty card.
  void _addFunction() {
    setState(() {
      final drafts = _functionDrafts;
      if (drafts == null) {
        final solo = _soloFunction;
        _functionDrafts = [
          EventFunctionDraft(
            id: solo?.id ?? newEventFunctionId(),
            eventType: _selectedEventType,
            date: _selectedDate,
            time: solo?.time,
            location: _locationController.text,
            place: _locationPlace,
            notes: solo?.notes,
          ),
          EventFunctionDraft.blank(),
        ];
      } else {
        drafts.add(EventFunctionDraft.blank());
      }
    });
  }

  /// Removes a card; down to one function the form returns to the simple fields.
  void _removeFunction(EventFunctionDraft draft) {
    final drafts = _functionDrafts;
    if (drafts == null) return;
    final retired = <EventFunctionDraft>[draft];
    setState(() {
      drafts.remove(draft);
      if (drafts.length <= 1) {
        final last = drafts.isEmpty ? null : drafts.first;
        if (last != null) {
          _selectedEventType = last.eventType;
          _selectedDate = last.date;
          _locationController.text = last.locationController.text;
          _locationPlace = last.place;
          final notes = last.notesController.text.trim();
          _soloFunction = last.isComplete
              ? EventFunction(
                  id: last.id,
                  eventType: last.eventType!,
                  date: last.date!,
                  time: last.time,
                  notes: notes.isEmpty ? null : notes,
                )
              : null;
          retired.add(last);
        }
        _functionDrafts = null;
      }
    });
    // The removed cards' fields still hold the controllers until this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final d in retired) {
        d.dispose();
      }
    });
  }

  /// A card changed: rebuild and keep the cards ordered by date.
  void _onFunctionChanged() {
    final drafts = _functionDrafts;
    if (drafts == null) return;
    setState(() => _functionDrafts = sortFunctionDrafts(drafts));
  }

  /// Functions to save, or null for a plain single event (legacy shape).
  List<EventFunction>? _functionsToSave(DropdownLookup lookup) {
    final drafts = _functionDrafts;
    if (drafts != null) {
      return [for (final d in drafts) d.toFunction(labelFor: lookup.labelForEventType)];
    }
    final solo = _soloFunction;
    final type = _selectedEventType;
    final date = _selectedDate;
    if (solo == null || type == null || date == null) return null;
    final text = _locationController.text.trim();
    final single = EventFunction(
      id: solo.id,
      eventType: type,
      eventTypeLabel: lookup.labelForEventType(type),
      date: DateTime(date.year, date.month, date.day),
      time: solo.time,
      notes: solo.notes,
      location: text.isEmpty ? null : text,
      locationArea: text.isEmpty ? null : _locationPlace?.area,
      locationPlaceId: text.isEmpty ? null : _locationPlace?.placeId,
      locationAddress: text.isEmpty ? null : _locationPlace?.address,
    );
    return needsFunctionArray([single]) ? [single] : null;
  }

  @override
  void dispose() {
    for (final d in _functionDrafts ?? const <EventFunctionDraft>[]) {
      d.dispose();
    }
    _lookupDebounce?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
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

  /// Maps place fields to write on edit: the picked place (absent parts deleted),
  /// or deletes for all of them when the place was removed. Nothing when the
  /// enquiry never had a place and still has none.
  ///
  /// Free text (no place) on an approved enquiry also stores the text as
  /// `locationArea` (same as the approve sheet) so area analytics groups it.
  Map<String, Object> _locationPlaceFields(
    Map<String, dynamic> oldData, {
    required String locationText,
    required bool approved,
  }) {
    final place = _locationPlace;
    if (place == null) {
      final typedArea = approved && !isVagueLocation(locationText) ? locationText.trim() : null;
      final hadPlace = EnquiryPlace.fieldKeys.any(oldData.containsKey);
      if (typedArea != null) {
        return {
          for (final key in EnquiryPlace.fieldKeys)
            if (key == EnquiryPlace.areaField)
              key: typedArea
            else if (oldData.containsKey(key))
              key: FieldValue.delete(),
        };
      }
      if (!hadPlace) return const {};
      // A typed area (no place id) stays while the text it came from is unchanged.
      final oldText = ((oldData['eventLocation'] as String?) ?? '').trim();
      if (!oldData.containsKey(EnquiryPlace.placeIdField) && oldText == locationText.trim()) {
        return const {};
      }
      return {for (final key in EnquiryPlace.fieldKeys) key: FieldValue.delete()};
    }
    final fields = place.toFields();
    return {for (final key in EnquiryPlace.fieldKeys) key: fields[key] ?? FieldValue.delete()};
  }

  double? _parseDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim());
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final drafts = _functionDrafts;
    if (drafts != null) {
      final incomplete = drafts.indexWhere((d) => !d.isComplete);
      if (incomplete >= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Function ${incomplete + 1} needs a type and a date')),
        );
        return;
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an event date')));
      return;
    } else if (_selectedEventType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an event type')));
      return;
    }

    if (!await _confirmPossibleDuplicate()) return;
    if (!mounted) return;

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

    // Multi-function booking: top-level type / date / location follow the functions
    // (main function, last date) — see functionSyncFields.
    final functions = _functionsToSave(dropdownLookup);
    final multi = _functionsMode && functions != null;
    final main = multi ? mainFunctionOf(functions!) : null;
    final syncLocation = multi ? functionSyncFields(functions!)['eventLocation'] as String? : null;
    final eventTypeValue = main?.eventType ?? _selectedEventType!;
    final eventTypeLabel = main?.label ?? dropdownLookup.labelForEventType(eventTypeValue);
    final eventDate = multi ? sortEventFunctions(functions!).last.day : _selectedDate!;
    final place = multi ? null : _locationPlace;

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
      eventDate: eventDate,
      eventLocation: multi ? (syncLocation ?? '') : _locationController.text.trim(),
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
      whatsappNumber: _currentWhatsapp,
      locationPlaceId: place?.placeId,
      locationAddress: place?.address,
      locationLat: place?.lat,
      locationLng: place?.lng,
      locationArea: place?.area,
      locationCity: place?.city,
      functions: functions,
    );

    final quoteFields = _quoteFields(const {});
    if (quoteFields.isNotEmpty) {
      await firestoreService.updateEnquiry(enquiryId, {
        ...quoteFields,
        'updatedBy': currentUser.uid,
      });
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
          if (mounted) {
            setState(() {
              _selectedImages.clear();
            });
          }
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
      eventType: eventTypeValue,
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

      // Admins already got "New Enquiry Created"; only the assignee hears about it here.
      // An admin assignee (other than the creator) was in that push already — don't
      // send them a second one.
      final assignee = _selectedAssignedTo!;
      final assigneeAlreadyNotified =
          assignee != currentUser.uid && await _isAdminUser(firestoreService, assignee);
      if (!assigneeAlreadyNotified) {
        await notificationService.notifyEnquiryAssigned(
          enquiryId: enquiryId,
          customerName: _nameController.text.trim(),
          eventType: eventTypeValue,
          assignedTo: assignee,
          assignedBy: currentUser.uid,
          notifyAdmins: false,
        );
      }
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

  /// Whether [uid] is an admin (admins already receive the generic admin pushes).
  static Future<bool> _isAdminUser(FirestoreService firestoreService, String uid) async {
    try {
      final data = await firestoreService.getUser(uid);
      return data?['role'] == 'admin';
    } catch (e) {
      Log.w('EnquiryFormScreen: could not look up user role', data: {'error': e.toString()});
      return false;
    }
  }

  Future<void> _updateEnquiry(UserModel currentUser) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    final dropdownLookup = await ref.read(dropdownLookupProvider.future);

    // Fetch old enquiry data to compare changes
    final oldEnquiryData = await firestoreService.getEnquiry(widget.enquiryId!) ?? {};
    if (!mounted) return;

    // Status: only the user's own change is written. If they didn't touch the status
    // control, keep whatever is stored now (it may have been changed elsewhere since the
    // form opened) and don't log history or send a status push.
    final oldStatusValue = _canonicalOldStatus(oldEnquiryData);
    final initialStatus = EnquiryStatus.canonicalValue(_initialStatus) ?? _initialStatus ?? 'new';
    final selectedStatus =
        EnquiryStatus.canonicalValue(_selectedStatus) ?? _selectedStatus ?? 'new';
    final userChangedStatus = selectedStatus != initialStatus;
    final statusValue = userChangedStatus ? selectedStatus : oldStatusValue;
    final statusDidChange = userChangedStatus && oldStatusValue != statusValue;
    final statusLabel = dropdownLookup.labelForStatus(statusValue);
    final reopening = statusDidChange && EnquiryStageFields.clearsLostFields(statusValue);

    // Assignee: same rule as status.
    final previousAssignee = oldEnquiryData['assignedTo'] as String?;
    final userChangedAssignee = _selectedAssignedTo != _initialAssignedTo;
    final assignedTo = userChangedAssignee ? _selectedAssignedTo : previousAssignee;

    // Functions: a multi-function booking writes `functions` + synced top-level
    // fields (type = main function, eventDate = last function, location = main's).
    final functions = _functionsToSave(dropdownLookup);
    final multi = _functionsMode && functions != null;
    final syncFields = functions == null
        ? null
        : functionSyncFields(functions, existing: oldEnquiryData);
    final eventTypeValue = multi
        ? syncFields!['eventTypeValue']! as String
        : (_selectedEventType ?? 'event');
    final eventTypeLabel = multi
        ? syncFields!['eventTypeLabel']! as String
        : dropdownLookup.labelForEventType(eventTypeValue);
    final newEventDate = multi ? sortEventFunctions(functions!).last.day : _selectedDate!;

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
    final guestCountText = _guestCountController.text.trim();
    final newGuestCount = int.tryParse(guestCountText);
    final newBudgetRange = _budgetController.text.trim();
    final newCustomerPhone = _phoneController.text.trim();
    final newEventLocation = multi
        ? ((syncFields!['eventLocation'] as String?) ??
              ((oldEnquiryData['eventLocation'] as String?) ?? '').trim())
        : _locationController.text.trim();
    final newLocationArea = multi && syncFields!.containsKey(EnquiryPlace.areaField)
        ? syncFields![EnquiryPlace.areaField] as String?
        : (multi ? oldEnquiryData[EnquiryPlace.areaField] as String? : _locationPlace?.area);
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

    // Approving needs a known location (area at minimum), matching the rules, which
    // only check the move into Approved. Checked before the date-clash warning.
    if (statusDidChange &&
        EnquiryStatus.isApproved(statusValue) &&
        !isLocationKnown(area: newLocationArea, eventLocation: newEventLocation)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            multi
                ? 'Location is required to approve — add the area to the main function'
                : EnquiryLocationField.approvalRequiredMessage,
          ),
        ),
      );
      return;
    }

    // Approved bookings: warn about other approved events on the booking's days when
    // this save approves it (every function day), or moves an approved booking to new
    // days (only function days that weren't there before).
    if (EnquiryStatus.isApproved(statusValue)) {
      final approving = statusDidChange;
      final newDays = distinctBookingDays(
        multi ? [for (final f in functions!) f.day] : [newEventDate],
      );
      final oldDays = functionDaysOf(oldEnquiryData).toSet();
      final daysToCheck = approving ? newDays : newDays.where((d) => !oldDays.contains(d)).toList();
      if (daysToCheck.isNotEmpty) {
        final proceed = await confirmApprovedDateClash(
          context,
          ref,
          eventDates: daysToCheck,
          excludeEnquiryId: widget.enquiryId,
          isDateChange: !approving,
        );
        if (!proceed || !mounted) return;
      }
    }

    // Moving to a lost status asks why (same rule as every other status path).
    LostReasonChoice? lostChoice;
    if (statusDidChange && EnquiryStatus.isLost(statusValue)) {
      if (!mounted) return;
      final prompt = await promptLostReasonIfNeeded(context, statusValue);
      if (!prompt.proceed || !mounted) return;
      lostChoice = prompt.choice;
    }

    // Did the user remove images in this form (vs what was loaded / last persisted)?
    final imagesEditedLocally = !listEquals(_existingImageUrls, _initialImageUrls);

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
          if (mounted) {
            setState(() {
              _selectedImages.clear();
            });
          }
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
    if (newImageUrls.isNotEmpty && mounted) {
      setState(() {
        _existingImageUrls.addAll(newImageUrls);
      });
    }

    Log.d(
      'EnquiryFormScreen updating images field',
      data: {
        'enquiryId': widget.enquiryId,
        'editedLocally': imagesEditedLocally,
        'newCount': newImageUrls.length,
        'totalCount': allImageUrls.length,
      },
    );

    final quoteFields = _quoteFields(oldEnquiryData);
    final Map<String, Object?> eventFields;
    if (multi) {
      eventFields = {for (final e in syncFields!.entries) e.key: e.value ?? FieldValue.delete()};
    } else {
      eventFields = {
        'eventLocation': newEventLocation,
        ..._locationPlaceFields(
          oldEnquiryData,
          locationText: newEventLocation,
          approved: EnquiryStatus.isApproved(statusValue),
        ),
        'eventType': eventTypeValue,
        'eventTypeValue': eventTypeValue,
        'eventTypeLabel': eventTypeLabel,
        'eventDate': Timestamp.fromDate(newEventDate),
        // One function with a time / notes keeps its array; otherwise a former
        // multi-function booking goes back to the single-event shape.
        if (syncFields != null)
          for (final key in clearFunctionFields.keys) key: syncFields[key]
        else if (_hadFunctionArray)
          for (final key in clearFunctionFields.keys) key: FieldValue.delete(),
      };
    }

    // Update the enquiry document. Status / assignee / images are written only when the
    // user changed them; cleared optional fields are deleted rather than left stale.
    await firestoreService.updateEnquiry(widget.enquiryId!, {
      'customerName': newCustomerName,
      'customerPhone': newCustomerPhone,
      if (newCustomerEmail.isNotEmpty)
        'customerEmail': newCustomerEmail.toLowerCase()
      else
        'customerEmail': FieldValue.delete(),
      ...eventFields,
      if (newDescription.isNotEmpty)
        ...enquiryNotesFields(newDescription)
      else ...{
        'notes': FieldValue.delete(),
        'description': FieldValue.delete(),
      },
      if (guestCountText.isEmpty)
        'guestCount': FieldValue.delete()
      else if (newGuestCount != null && newGuestCount >= 0)
        'guestCount': newGuestCount,
      if (newBudgetRange.isNotEmpty)
        'budgetRange': newBudgetRange
      else
        'budgetRange': FieldValue.delete(),
      'source': sourceValue,
      'sourceValue': sourceValue,
      'sourceLabel': sourceLabel,
      'priority': priorityValue,
      'priorityValue': priorityValue,
      'priorityLabel': priorityLabel,
      // Keep statusUpdatedAt / statusUpdatedBy in sync when status changes via form
      if (statusDidChange) ...{
        'statusValue': statusValue,
        'statusLabel': statusLabel,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': currentUser.uid,
        for (final field in EnquiryStageFields.fieldsToStamp(oldEnquiryData, statusValue))
          field: FieldValue.serverTimestamp(),
      },
      if (reopening)
        for (final field in EnquiryStageFields.lostOnlyFields) field: FieldValue.delete(),
      if (lostChoice != null) ...lostChoice.toFields(),
      ...quoteFields,
      // Financial fields are admin-only in the rules: write them only when they
      // actually change, so a staff save that leaves them untouched isn't denied.
      if ((oldEnquiryData['paymentStatusValue'] ?? oldEnquiryData['paymentStatus'] ?? 'pending') !=
          paymentStatusValue) ...{
        'paymentStatus': paymentStatusValue,
        'paymentStatusValue': paymentStatusValue,
        'paymentStatusLabel': paymentStatusLabel,
      },
      if (userChangedAssignee) 'assignedTo': _selectedAssignedTo,
      if (oldTotalCost != newTotalCost) 'totalCost': newTotalCost,
      if (oldAdvancePaid != newAdvancePaid) 'advancePaid': newAdvancePaid,
      if (imagesEditedLocally)
        'images': allImageUrls
      else if (newImageUrls.isNotEmpty)
        'images': FieldValue.arrayUnion(newImageUrls),
      'updatedBy': currentUser.uid,
      ...FirestoreService.searchIndexFieldsFor(
        customerName: newCustomerName,
        customerPhone: newCustomerPhone,
        customerEmail: newCustomerEmail.isNotEmpty ? newCustomerEmail : null,
        description: newDescription,
        notes: newDescription,
        eventTypes: functions != null ? functionTypeLabels(functions) : [eventTypeLabel],
      ),
    });

    Log.d('EnquiryFormScreen enquiry updated successfully with images');

    // Record audit trail for individual field changes
    final auditService = ref.read(auditServiceProvider);
    final oldImages = oldEnquiryData['images'];
    final changes = buildEnquiryAuditChanges(
      oldEnquiryData: oldEnquiryData,
      statusValue: statusValue,
      assignedTo: assignedTo,
      priorityValue: priorityValue,
      paymentStatusValue: paymentStatusValue,
      newCustomerName: newCustomerName,
      newCustomerPhone: newCustomerPhone,
      newEventLocation: newEventLocation,
      oldTotalCost: oldTotalCost,
      newTotalCost: newTotalCost,
      oldAdvancePaid: oldAdvancePaid,
      newAdvancePaid: newAdvancePaid,
      newEventDate: newEventDate,
      eventTypeValue: eventTypeValue,
      newGuestCount: guestCountText.isEmpty ? null : newGuestCount,
      newBudgetRange: newBudgetRange,
      newCustomerEmail: newCustomerEmail.toLowerCase(),
      newNotes: newDescription,
      sourceValue: sourceValue,
      quoteFields: quoteFields,
      oldImageCount: oldImages is List ? oldImages.length : _initialImageUrls.length,
      newImageCount: imagesEditedLocally
          ? allImageUrls.length
          : (oldImages is List ? oldImages.length : 0) + newImageUrls.length,
    );

    // Functions added / changed / removed: one readable "Functions" entry.
    final oldFunctions = functionsOf(oldEnquiryData);
    final newFunctions =
        functions ??
        [
          EventFunction(
            id: EventFunction.legacyId,
            eventType: eventTypeValue,
            eventTypeLabel: eventTypeLabel,
            date: newEventDate,
          ),
        ];
    if (oldFunctions.length > 1 || newFunctions.length > 1) {
      final oldSummary = functionsSummary(oldFunctions);
      final newSummary = functionsSummary(newFunctions);
      if (oldSummary != newSummary) {
        changes['functions'] = {
          'old_value': oldSummary.isEmpty ? 'Not Set' : oldSummary,
          'new_value': newSummary,
        };
      }
    }

    if (lostChoice != null) {
      changes['lostReason'] = {
        'old_value': oldEnquiryData['lostReason'],
        'new_value': lostChoice.reason.value,
      };
    } else if (reopening && oldEnquiryData['lostReason'] != null) {
      changes['lostReason'] = {'old_value': oldEnquiryData['lostReason'], 'new_value': null};
    }

    // Record all changes at once
    if (changes.isNotEmpty) {
      await auditService.recordMultipleChanges(enquiryId: widget.enquiryId!, changes: changes);
    }

    // Send notifications: at most one push per person for this save.
    final notificationService = ref.read(notificationServiceProvider);
    final reassigned =
        userChangedAssignee &&
        assignedTo != null &&
        assignedTo.isNotEmpty &&
        assignedTo != previousAssignee;

    // If status changed, send specific status update notification to admins
    if (statusDidChange) {
      if (kDebugMode) {
        debugPrint('📝 EDIT FORM: Status changed via edit form');
        debugPrint('   OldStatus: $oldStatusValue → NewStatus: $statusValue');
        debugPrint('   EnquiryId: ${widget.enquiryId}');
      }

      final oldStatusLabel = dropdownLookup.labelForStatus(oldStatusValue);
      await notificationService.notifyStatusUpdated(
        enquiryId: widget.enquiryId!,
        customerName: newCustomerName,
        oldStatus: oldStatusLabel,
        newStatus: statusLabel,
        updatedBy: currentUser.uid,
        // A new assignee gets "Assigned to You" below instead.
        assignedTo: reassigned ? null : assignedTo,
      );
    } else if (!reassigned) {
      // Only send generic enquiry update notification if status didn't change
      // (to avoid duplicate notifications when status changes)
      if (kDebugMode) {
        debugPrint('📝 EDIT FORM: Enquiry updated (status unchanged)');
        debugPrint('   EnquiryId: ${widget.enquiryId}');
        debugPrint('   UpdatedBy: ${currentUser.uid}');
      }

      await notificationService.notifyEnquiryUpdated(
        enquiryId: widget.enquiryId!,
        customerName: newCustomerName,
        eventType: eventTypeValue,
        updatedBy: currentUser.uid,
        assignedTo: assignedTo,
      );
    }

    // Re-assignment from the edit form: tell the new assignee, and other admins unless
    // they were already told about the status change above. An admin assignee already got
    // the status push (it goes to every admin but the updater), so skip a second one.
    if (reassigned) {
      final newAssignee = assignedTo!;
      final assigneeAlreadyNotified =
          statusDidChange &&
          newAssignee != currentUser.uid &&
          await _isAdminUser(firestoreService, newAssignee);
      if (!assigneeAlreadyNotified) {
        await notificationService.notifyEnquiryAssigned(
          enquiryId: widget.enquiryId!,
          customerName: newCustomerName,
          eventType: eventTypeLabel,
          assignedTo: newAssignee,
          assignedBy: currentUser.uid,
          notifyAdmins: !statusDidChange,
        );
      }
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
    final firestoreService = ref.read(firestoreServiceProvider);
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
      await firestoreService.updateEnquiry(widget.enquiryId!, {
        'images': List<String>.of(_existingImageUrls),
      });
      // Persisted: a later form save no longer needs to rewrite the whole list.
      _initialImageUrls = List.unmodifiable(_existingImageUrls);
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
