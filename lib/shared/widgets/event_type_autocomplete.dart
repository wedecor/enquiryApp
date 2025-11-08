import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/role_provider.dart';
import '../../utils/logger.dart';

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

  // Store both label (display) and value (id) for each option
  List<Map<String, String>> _eventTypes = [];
  List<Map<String, String>> _filteredEventTypes = [];
  bool _isLoading = false;
  bool _showAddButton = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't set initial value immediately - wait for event types to load
    _loadEventTypes();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EventTypeAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the controller when the initial value changes
    if (oldWidget.initialValue != widget.initialValue) {
      Log.d(
        'EventTypeAutocomplete initial value changed',
        data: {'from': oldWidget.initialValue, 'to': widget.initialValue},
      );
      _isInitialized = false;
      if (!_isLoading) {
        _setInitialValue();
      }
    }
  }

  Future<void> _loadEventTypes() async {
    Log.d('EventTypeAutocomplete load start');
    setState(() {
      _isLoading = true;
    });

    // TEMPORARY: Always use fallback values for testing
    Log.d('EventTypeAutocomplete using fallback values');
    final defaultEventTypes = [
      {'label': 'Wedding', 'value': 'wedding'},
      {'label': 'Birthday', 'value': 'birthday'},
      {'label': 'Corporate Event', 'value': 'corporate_event'},
      {'label': 'Haldi', 'value': 'haldi'},
      {'label': 'Anniversary', 'value': 'anniversary'},
      {'label': 'Others', 'value': 'others'},
    ];
    setState(() {
      _eventTypes = defaultEventTypes;
      _filteredEventTypes = defaultEventTypes;
      _isLoading = false;
    });

    // Set initial value after loading default event types
    _setInitialValue();

    // TODO: Re-enable Firestore loading after testing
    /*
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dropdowns')
          .doc('event_types')
          .collection('items')
          .where('active', isEqualTo: true)
          .orderBy('order')
          .get();

      final eventTypes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final label = (data['label'] as String?)?.trim();
        final value = (data['value'] as String?)?.trim();
        return {
          'label': label?.isNotEmpty == true ? label! : (value ?? ''),
          'value': value ?? '',
        };
      }).where((e) => (e['value'] ?? '').isNotEmpty).toList();

      // TODO: Log.d('EventTypeAutocomplete: loaded ${eventTypes.length} event types from Firestore');
      setState(() {
        _eventTypes = eventTypes;
        _filteredEventTypes = eventTypes;
        _isLoading = false;
      });
      
      // Set initial value after loading event types
      _setInitialValue();
    } catch (e) {
      // Fallback to default values if Firestore is not available
      // TODO: Log.w('EventTypeAutocomplete: using fallback values', data: {'error': e.toString()});
      final defaultEventTypes = [
        {'label': 'Wedding', 'value': 'wedding'},
        {'label': 'Birthday', 'value': 'birthday'},
        {'label': 'Corporate Event', 'value': 'corporate_event'},
        {'label': 'Haldi', 'value': 'haldi'},
        {'label': 'Anniversary', 'value': 'anniversary'},
        {'label': 'Others', 'value': 'others'},
      ];
      setState(() {
        _eventTypes = defaultEventTypes;
        _filteredEventTypes = defaultEventTypes;
        _isLoading = false;
      });
      
      // Set initial value after loading default event types
      _setInitialValue();
    }
    */
  }

  void _setInitialValue() {
    Log.d(
      'EventTypeAutocomplete setting initial value',
      data: {'value': widget.initialValue, 'eventCount': _eventTypes.length},
    );
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty && _eventTypes.isNotEmpty) {
      // Find the matching event type by value
      final matchingEventType = _eventTypes.firstWhere(
        (eventType) => eventType['value'] == widget.initialValue,
        orElse: () => <String, String>{},
      );

      if (matchingEventType.isNotEmpty) {
        _controller.text = matchingEventType['label'] ?? widget.initialValue!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged(widget.initialValue!);
        });
        _isInitialized = true;
      } else {
        // If no exact match found, try to find by label
        final matchingByLabel = _eventTypes.firstWhere(
          (eventType) => eventType['label']?.toLowerCase() == widget.initialValue!.toLowerCase(),
          orElse: () => <String, String>{},
        );

        if (matchingByLabel.isNotEmpty) {
          _controller.text = matchingByLabel['label'] ?? widget.initialValue!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged(matchingByLabel['value'] ?? widget.initialValue!);
          });
          _isInitialized = true;
        } else {
          // If still no match, just set the text as-is
          _controller.text = widget.initialValue!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged(widget.initialValue!);
          });
          _isInitialized = true;
        }
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
      final filtered = _eventTypes.where((type) {
        final label = type['label'] ?? '';
        final value = type['value'] ?? '';
        final q = query.toLowerCase();
        return label.toLowerCase().contains(q) || value.toLowerCase().contains(q);
      }).toList();

      setState(() {
        _filteredEventTypes = filtered;
        // Show add button if no exact match found and admin
        final isAdmin = ref.read(currentUserIsAdminProvider);
        _showAddButton = filtered.isEmpty && isAdmin;
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
      (type) =>
          (type['label'] ?? '').toLowerCase() == trimmedType.toLowerCase() ||
          (type['value'] ?? '').toLowerCase() == trimmedType.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event type "$trimmedType" already exists'),
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
            'label': trimmedType,
            'value': trimmedType.toLowerCase().replaceAll(' ', '_'),
            'active': true,
            'order': (_eventTypes.length + 1),
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
          SnackBar(content: Text('Error adding event type: $e'), backgroundColor: Colors.red),
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
        Autocomplete<Map<String, String>>(
          displayStringForOption: (opt) => opt['label'] ?? '',
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
                // Do not emit value on free-typing; emit on selection
              },
            );
          },
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _eventTypes;
            }
            return _filteredEventTypes;
          },
          onSelected: (Map<String, String> selection) {
            final label = selection['label'] ?? '';
            final value = selection['value'] ?? '';
            _controller.text = label;
            widget.onChanged(value);
            setState(() {
              _showAddButton = false;
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
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
                        title: Text(option['label'] ?? ''),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (_showAddButton && !_isLoading) ...[const SizedBox(height: 8), _buildAddNewOption()],
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
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Admin only'),
        onTap: () => _addNewEventType(_controller.text),
      ),
    );
  }
}
