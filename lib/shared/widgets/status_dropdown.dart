import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/dropdown_defaults.dart';
import '../../core/constants/status_vocabulary.dart';
import '../../core/logging/logger.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/role_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../shared/models/user_model.dart';

class StatusDropdown extends ConsumerStatefulWidget {
  final String? value;
  final void Function(String?) onChanged;
  final String label;
  final String collectionName;
  final String? Function(String?)? validator;
  final bool required;

  const StatusDropdown({
    super.key,
    this.value,
    required this.onChanged,
    required this.label,
    required this.collectionName,
    this.validator,
    this.required = false,
  });

  @override
  ConsumerState<StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends ConsumerState<StatusDropdown> {
  // Each status item stores both label (display) and value (id)
  List<Map<String, String>> _statuses = [];
  bool _isLoading = false;
  final TextEditingController _addController = TextEditingController();
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _statuses = DropdownDefaults.forCollection(widget.collectionName);
    _loadStatuses();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild if the value actually changed and we have data loaded
    if (oldWidget.value != widget.value && _statuses.isNotEmpty) {
      setState(() {});
    }
  }

  Future<void> _loadStatuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final options = await ref
          .read(firestoreServiceProvider)
          .fetchActiveDropdownOptions(widget.collectionName);

      setState(() {
        _statuses = DropdownDefaults.resolve(options, widget.collectionName);
        _isLoading = false;
      });
      _syncFieldValueAfterLoad();
    } catch (e, st) {
      // Fallback to default values if Firestore is not available
      Log.w(
        'StatusDropdown fallback values',
        data: {
          'collection': widget.collectionName,
          'error': e.runtimeType.toString(),
        },
      );
      Log.d('StatusDropdown fallback stack', data: st);
      setState(() {
        _statuses = DropdownDefaults.forCollection(widget.collectionName);
        _isLoading = false;
      });
      _syncFieldValueAfterLoad();
    }
  }

  void _syncFieldValueAfterLoad() {
    final value = widget.value;
    if (value == null) return;
    final canonical = widget.collectionName == 'statuses'
        ? EnquiryStatus.canonicalValue(value) ?? value
        : value;
    if (!_statuses.any((status) => status['value'] == canonical)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_fieldKey.currentState?.value == null) {
        _fieldKey.currentState?.didChange(canonical);
      }
    });
  }

  // Validate if the current value exists in the statuses list
  String? _getValidValue(String? value) {
    if (value == null) return null;

    if (_statuses.isEmpty) return null;

    final canonical = widget.collectionName == 'statuses'
        ? EnquiryStatus.fromValue(value)?.value ?? value
        : value;

    final exists = _statuses.any((status) => status['value'] == canonical);
    if (exists) return canonical;

    return null;
  }

  Future<void> _addNewStatus() async {
    final roleAsync = ref.read(roleProvider);
    final role = roleAsync.valueOrNull ?? UserRole.staff;
    if (role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only admins can add new ${widget.label.toLowerCase()}',
          ),
          backgroundColor: AppColorScheme.snackError,
        ),
      );
      return;
    }

    final newStatus = _addController.text.trim();
    if (newStatus.isEmpty) return;

    // Check for case-insensitive uniqueness
    final exists = _statuses.any(
      (status) =>
          (status['label'] ?? '').toLowerCase() == newStatus.toLowerCase() ||
          (status['value'] ?? '').toLowerCase() == newStatus.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.label} already exists'),
          backgroundColor: AppColorScheme.snackWarning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newValue = newStatus.toLowerCase().replaceAll(' ', '_');
      await ref
          .read(firestoreServiceProvider)
          .addDropdownItem(
            kind: widget.collectionName,
            label: newStatus,
            value: newValue,
            order: _statuses.length + 1,
            createdBy:
                ref.read(currentUserWithFirestoreProvider).value?.uid ??
                'unknown',
          );

      // Refresh the list
      await _loadStatuses();

      // Set the new value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(newValue);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.label} "$newStatus" added successfully'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding ${widget.label.toLowerCase()}: $e'),
            backgroundColor: AppColorScheme.snackError,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
      _addController.clear();
    }
  }

  void _showAddDialog() {
    final roleAsync = ref.read(roleProvider);
    final role = roleAsync.valueOrNull ?? UserRole.staff;
    if (role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only admins can add new ${widget.label.toLowerCase()}',
          ),
          backgroundColor: AppColorScheme.snackError,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New ${widget.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addController,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) => _addNewStatus(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addController.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _addNewStatus, child: const Text('Add')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleAsync = ref.watch(roleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                key: _fieldKey,
                // CRITICAL: Always ensure value is valid or null
                initialValue: _getValidValue(widget.value),
                decoration: InputDecoration(
                  labelText: widget.required
                      ? '${widget.label} *'
                      : widget.label,
                  prefixIcon: Icon(_getIconForStatus()),
                  border: const OutlineInputBorder(),
                  hintText:
                      widget.value != null &&
                          !_isLoading &&
                          _statuses.isNotEmpty &&
                          !_statuses.any(
                            (status) => status['value'] == widget.value,
                          )
                      ? 'Current: ${widget.value}'
                      : null,
                  suffixIcon: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status['value'],
                    child: Text(status['label'] ?? status['value'] ?? ''),
                  );
                }).toList(),
                onChanged: widget.onChanged,
                validator: widget.validator,
              ),
            ),
            roleAsync.when(
              data: (role) {
                if (role != UserRole.admin) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showAddDialog,
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColorScheme.snackSuccess,
                      ),
                      tooltip: 'Add new ${widget.label.toLowerCase()}',
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getIconForStatus() {
    switch (widget.collectionName) {
      case 'statuses':
        return Icons.flag;
      case 'payment_statuses':
        return Icons.payment;
      case 'priorities':
        return Icons.priority_high;
      case 'sources':
        return Icons.campaign_outlined;
      case 'event_types':
        return Icons.celebration_outlined;
      default:
        return Icons.list;
    }
  }
}
