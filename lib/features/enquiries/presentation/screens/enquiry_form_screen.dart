import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/status_vocabulary.dart';
import '../../../../core/logging/logger.dart';
import '../../../../core/providers/audit_provider.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/enquiry_fields.dart';
import '../../../../core/utils/phone_normalizer.dart';
import '../../../../services/dropdown_lookup.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../dashboard/presentation/widgets/dashboard_enquiry_utils.dart';
import '../../data/customer_lookup_service.dart';
import '../../data/enquiry_image_uploader.dart';
import '../../domain/enquiry_change_set.dart';
import '../../domain/enquiry_lifecycle.dart';
import '../../domain/enquiry_prefill.dart';
import '../widgets/approved_date_clash_prompt.dart';
import '../widgets/enquiry_form_customer_fields.dart';
import '../widgets/enquiry_form_event_fields.dart';
import '../widgets/enquiry_form_financial_fields.dart';
import '../widgets/enquiry_form_images_section.dart';
import '../widgets/enquiry_form_section.dart';
import '../widgets/enquiry_glass_bar.dart';
import '../widgets/enquiry_sheet_header.dart';
import '../widgets/form/enquiry_customer_match_cards.dart';
import '../widgets/form/enquiry_form_pipeline_fields.dart';
import '../widgets/lost_reason_sheet.dart';
import 'enquiry_details_screen.dart';

part '../widgets/form/enquiry_form_persistence.dart';

/// Screen for creating and editing enquiries
class EnquiryFormScreen extends ConsumerStatefulWidget {
  /// Creates an EnquiryFormScreen
  /// [enquiryId] is required for editing mode
  /// [mode] can be 'create' or 'edit'
  /// [prefill] seeds the customer fields in create mode (ignored when editing)
  const EnquiryFormScreen({super.key, this.enquiryId, this.mode = 'create', this.prefill});

  final String? enquiryId;
  final String mode;
  final EnquiryPrefill? prefill;

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen>
    with _EnquiryFormPersistence {
  final ImagePicker _picker = ImagePicker();

  static const double _maxContentWidth = 720;

  Future<void> _selectDate() async {
    // In edit mode, allow past dates so staff can correct wrong entries.
    final isEdit = widget.mode == 'edit';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final defaultLast = today.add(const Duration(days: 730));
    var initialDate = _selectedDate ?? today;
    if (!isEdit && initialDate.isBefore(today)) initialDate = today;
    // showDatePicker asserts firstDate <= initialDate <= lastDate.
    final earliest = DateTime(2020, 1, 1);
    final firstDate = isEdit
        ? (initialDate.isBefore(earliest) ? initialDate : earliest)
        : today;
    final lastDate = initialDate.isAfter(defaultLast) ? initialDate : defaultLast;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      final status = EnquiryStatus.fromValue(_selectedStatus);
      final isActive =
          !EnquiryStatus.isLost(_selectedStatus) && status != EnquiryStatus.completed;
      if (isEdit && isActive && picked.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This event date is in the past — an active enquiry with a past date is '
              'auto-closed overnight.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (!mounted) return;
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

  bool get _isEdit => widget.mode == 'edit';

  Widget _header() {
    final id = widget.enquiryId;
    return EnquirySheetHeader(
      eyebrow: _isEdit && id != null
          ? 'Editing · #${id.length > 8 ? id.substring(0, 8) : id}'
          : 'Pipeline · New lead',
      lightLead: _isEdit ? 'Edit' : 'New',
      title: 'Enquiry',
      subtitle: 'Fields marked * are required',
    );
  }

  /// Header + centred content for the gated and loading states.
  Widget _stateFrame(Widget child) {
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            _header(),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(padding: AppSpacing.space6, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch role provider directly to handle loading state properly
    final isAdmin = ref.watch(isAdminProvider);

    if (widget.mode == 'create' && !isAdmin) {
      return _stateFrame(
        Text(
          'Only admins can create enquiries',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final isEditLoading = widget.mode == 'edit' && !_hydrated;
    if (isEditLoading) {
      return _stateFrame(const CircularProgressIndicator());
    }

    final width = MediaQuery.sizeOf(context).width;
    final side = ((width - _maxContentWidth) / 2).clamp(AppTokens.space4, double.infinity);

    final sections = <Widget>[
      EnquiryFormCustomerFields(
        nameController: _nameController,
        phoneController: _phoneController,
        emailController: _emailController,
        locationController: _locationController,
        phoneFooter: _customerMatchCards(),
      ),
      EnquiryFormEventFields(
        selectedDate: _selectedDate,
        onSelectDate: _selectDate,
        selectedEventType: _selectedEventType,
        onEventTypeChanged: (value) => setState(() => _selectedEventType = value),
        guestCountController: _guestCountController,
        budgetController: _budgetController,
      ),
      EnquiryFormPipelineFields(
        selectedStatus: _selectedStatus,
        onStatusChanged: (value) => setState(() => _selectedStatus = value),
        selectedPriority: _selectedPriority,
        onPriorityChanged: (value) => setState(() => _selectedPriority = value),
        selectedAssignedTo: _selectedAssignedTo,
        onAssignedToChanged: (value) => setState(() => _selectedAssignedTo = value),
        selectedSource: _selectedSource,
        onSourceChanged: (value) {
          if (value != null) setState(() => _selectedSource = value);
        },
        showLeadSource: true,
        // New enquiries are always created as 'new' (see _createEnquiry),
        // so the status picker only appears when editing.
        showStatus: widget.mode == 'edit',
      ),
      EnquiryFormFinancialFields(
        totalCostController: _totalCostController,
        advancePaidController: _advancePaidController,
        selectedPaymentStatus: _selectedPaymentStatus,
        onPaymentStatusChanged: (value) => setState(() => _selectedPaymentStatus = value),
        parseDouble: _parseDouble,
        quotedAmountController: _quotedAmountController,
        quotedAt: _quotedAt,
        onQuotedAtChanged: (value) => setState(() => _quotedAt = value),
      ),
      EnquiryFormSection(
        eyebrow: 'Notes',
        title: 'Additional Information',
        children: [
          TextFormField(
            controller: _notesController,
            scrollPadding: kEnquiryFieldScrollPadding,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.notes_rounded),
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
    ];

    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _header(),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      AppTokens.space5,
                      side,
                      enquiryGlassBarClearance(context) + AppTokens.space4,
                    ),
                    // A single box keeps every field built so the Form validates all of them.
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < sections.length; i++)
                            StaggerIn(index: i, child: sections[i]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: EnquiryGlassBar(child: _submitButton(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final s = AppSurfaces.of(context);
    final enabled = !_isLoading && _hydrated;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.full,
        boxShadow: enabled ? AppShadows.glow(s.shadow, strength: 0.18) : null,
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          minimumSize: const Size.fromHeight(AppTokens.minTapTarget + 6),
        ),
        onPressed: enabled ? _submitForm : null,
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.quick),
          child: _isLoading
              ? SizedBox(
                  height: AppTokens.space5,
                  width: AppTokens.space5,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        widget.mode == 'edit' ? 'Update enquiry' : 'Create enquiry',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTokens.space2),
                    Icon(Icons.arrow_forward_rounded, size: AppTokens.iconMedium, color: s.accent),
                  ],
                ),
        ),
      ),
    );
  }
}
