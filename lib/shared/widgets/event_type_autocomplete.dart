import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_decor_enquiries/core/services/firestore_service.dart';
import 'package:we_decor_enquiries/core/providers/role_provider.dart';
import 'package:we_decor_enquiries/core/services/user_firestore_sync_service.dart';

class EventTypeAutocomplete extends ConsumerStatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const EventTypeAutocomplete({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  ConsumerState<EventTypeAutocomplete> createState() => _EventTypeAutocompleteState();
}

class _EventTypeAutocompleteState extends ConsumerState<EventTypeAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _eventTypes = [];
  List<String> _filteredEventTypes = [];
  bool _isLoading = false;
  bool _showAddButton = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _loadEventTypes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEventTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .orderBy('name')
          .get();

      final eventTypes = snapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      setState(() {
        _eventTypes = eventTypes;
        _filteredEventTypes = eventTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading event types: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterEventTypes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredEventTypes = _eventTypes;
        _showAddButton = false;
      });
    } else {
      final filtered = _eventTypes
          .where((type) => type.toLowerCase().contains(query.toLowerCase()))
          .toList();

      setState(() {
        _filteredEventTypes = filtered;
        // Show add button if query doesn't match any existing type
        _showAddButton = filtered.isEmpty && query.trim().isNotEmpty;
      });
    }
  }

  Future<void> _addNewEventType(String newType) async {
    final isAdmin = ref.read(currentUserIsAdminProvider);
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can add new event types'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final trimmedType = newType.trim();
    if (trimmedType.isEmpty) return;

    // Check for case-insensitive uniqueness
    final exists = _eventTypes.any(
      (type) => type.toLowerCase() == trimmedType.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event type already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .add({
        'name': trimmedType,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
      });

      // Refresh the list
      await _loadEventTypes();

      // Set the new value
      _controller.text = trimmedType;
      widget.onChanged(trimmedType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event type "$trimmedType" added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding event type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _showAddButton = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Event Type',
                prefixIcon: const Icon(Icons.event),
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              validator: widget.validator,
              onChanged: (value) {
                _filterEventTypes(value);
                widget.onChanged(value);
              },
            );
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _eventTypes;
            }
            return _filteredEventTypes;
          },
          onSelected: (String selection) {
            _controller.text = selection;
            widget.onChanged(selection);
            setState(() {
              _showAddButton = false;
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Material(
              elevation: 4,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length + (_showAddButton ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == options.length && _showAddButton) {
                      return _buildAddNewOption();
                    }
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
        if (_showAddButton && !_isLoading) ...[
          const SizedBox(height: 8),
          _buildAddNewOption(),
        ],
      ],
    );
  }

  Widget _buildAddNewOption() {
    final isAdmin = ref.watch(currentUserIsAdminProvider);
    if (!isAdmin) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.add_circle, color: Colors.green),
        title: Text(
          'Add "${_controller.text.trim()}" as new event type',
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text('Admin only'),
        onTap: () => _addNewEventType(_controller.text),
      ),
    );
  }
} 