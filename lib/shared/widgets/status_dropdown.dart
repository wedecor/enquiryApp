import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/role_provider.dart';

class StatusDropdown extends ConsumerStatefulWidget {
  final String? value;
  final Function(String?) onChanged;
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

  @override
  void initState() {
    super.initState();
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
      final snapshot = await FirebaseFirestore.instance
          .collection('dropdowns')
          .doc(widget.collectionName)
          .collection('items')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .get();

      final statuses = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final label = (data['label'] as String?)?.trim();
            final value = (data['value'] as String?)?.trim();
            return {
              'label': label?.isNotEmpty == true ? label! : (value ?? ''),
              'value': value ?? '',
            };
          })
          .where((e) => (e['value'] ?? '').isNotEmpty)
          .toList();

      setState(() {
        _statuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to default values if Firestore is not available
      print('⚠️ Using fallback values for ${widget.collectionName}: $e');
      setState(() {
        _statuses = _getDefaultValues(widget.collectionName);
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> _getDefaultValues(String collectionName) {
    switch (collectionName) {
      case 'statuses':
        return [
          {'label': 'New', 'value': 'new'},
          {'label': 'Contacted', 'value': 'contacted'},
          {'label': 'In Talks', 'value': 'in_talks'},
          {'label': 'Quote Sent', 'value': 'quote_sent'},
          {'label': 'Approved', 'value': 'approved'},
          {'label': 'Scheduled', 'value': 'scheduled'},
          {'label': 'Completed', 'value': 'completed'},
          {'label': 'Closed - Lost', 'value': 'closed_lost'},
          {'label': 'Cancelled', 'value': 'cancelled'},
        ];
      case 'payment_statuses':
        return [
          {'label': 'Pending', 'value': 'pending'},
          {'label': 'Partial', 'value': 'partial'},
          {'label': 'Paid', 'value': 'paid'},
          {'label': 'Overdue', 'value': 'overdue'},
        ];
      case 'priorities':
        return [
          {'label': 'Low', 'value': 'low'},
          {'label': 'Medium', 'value': 'medium'},
          {'label': 'High', 'value': 'high'},
          {'label': 'Urgent', 'value': 'urgent'},
        ];
      default:
        return [];
    }
  }

  // Validate if the current value exists in the statuses list
  String? _getValidValue(String? value) {
    if (value == null) return null;

    // If still loading, return null to show hint text
    if (_isLoading) return null;

    // CRITICAL FIX: Return null if _statuses is empty (still loading)
    if (_statuses.isEmpty) return null;

    // Check if the value exists in the current statuses list
    final exists = _statuses.any((status) => status['value'] == value);
    if (exists) return value;

    // If value doesn't exist in the list, return null to show hint text
    // This prevents assertion errors while still showing the field
    return null;
  }

  Future<void> _addNewStatus() async {
    final isAdmin = ref.read(currentUserIsAdminProvider);
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only admins can add new ${widget.label.toLowerCase()}'),
          backgroundColor: Colors.red,
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
        SnackBar(content: Text('${widget.label} already exists'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('dropdowns')
          .doc(widget.collectionName)
          .collection('items')
          .add({
            'label': newStatus,
            'value': newStatus.toLowerCase().replaceAll(' ', '_'),
            'active': true,
            'order': (_statuses.length + 1),
            'createdAt': FieldValue.serverTimestamp(),
            'createdBy': ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
          });

      // Refresh the list
      await _loadStatuses();

      // Set the new value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(newStatus.toLowerCase().replaceAll(' ', '_'));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.label} "$newStatus" added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding ${widget.label.toLowerCase()}: $e'),
            backgroundColor: Colors.red,
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
    final isAdmin = ref.read(currentUserIsAdminProvider);
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only admins can add new ${widget.label.toLowerCase()}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
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
    final isAdmin = ref.watch(currentUserIsAdminProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                // CRITICAL: Always ensure value is valid or null
                initialValue: _getValidValue(widget.value),
                decoration: InputDecoration(
                  labelText: widget.required ? '${widget.label} *' : widget.label,
                  prefixIcon: Icon(_getIconForStatus()),
                  border: const OutlineInputBorder(),
                  hintText:
                      widget.value != null &&
                          !_isLoading &&
                          _statuses.isNotEmpty &&
                          !_statuses.any((status) => status['value'] == widget.value)
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
            if (isAdmin) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _showAddDialog,
                icon: const Icon(Icons.add_circle, color: Colors.green),
                tooltip: 'Add new ${widget.label.toLowerCase()}',
              ),
            ],
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
      default:
        return Icons.list;
    }
  }
}
