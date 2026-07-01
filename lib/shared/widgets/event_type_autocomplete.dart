import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/role_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../shared/models/user_model.dart';

class EventTypeAutocomplete extends ConsumerStatefulWidget {
  final String? initialValue;
  final void Function(String) onChanged;
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

  List<Map<String, String>> _eventTypes = [];
  List<Map<String, String>> _filteredEventTypes = [];
  bool _isLoading = false;
  bool _showAddButton = false;

  static List<Map<String, String>> _defaultEventTypes() => [
    {'label': 'Wedding', 'value': 'wedding'},
    {'label': 'Birthday', 'value': 'birthday'},
    {'label': 'Corporate Event', 'value': 'corporate_event'},
    {'label': 'Haldi', 'value': 'haldi'},
    {'label': 'Anniversary', 'value': 'anniversary'},
    {'label': 'Others', 'value': 'others'},
  ];

  @override
  void initState() {
    super.initState();
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
    if (oldWidget.initialValue != widget.initialValue) {
      Log.d(
        'EventTypeAutocomplete initial value changed',
        data: {'from': oldWidget.initialValue, 'to': widget.initialValue},
      );
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

    try {
      final eventTypes = await ref
          .read(firestoreServiceProvider)
          .fetchActiveDropdownOptions('event_types');

      if (eventTypes.isEmpty) {
        throw StateError('No active event types in Firestore');
      }

      Log.d('EventTypeAutocomplete loaded from Firestore', data: {'count': eventTypes.length});
      setState(() {
        _eventTypes = eventTypes;
        _filteredEventTypes = eventTypes;
        _isLoading = false;
      });
      _setInitialValue();
    } catch (e, st) {
      Log.w(
        'EventTypeAutocomplete using fallback values',
        data: {'error': e.runtimeType.toString()},
      );
      Log.d('EventTypeAutocomplete fallback stack', data: st);
      final defaults = _defaultEventTypes();
      setState(() {
        _eventTypes = defaults;
        _filteredEventTypes = defaults;
        _isLoading = false;
      });
      _setInitialValue();
    }
  }

  void _setInitialValue() {
    Log.d(
      'EventTypeAutocomplete setting initial value',
      data: {'value': widget.initialValue, 'eventCount': _eventTypes.length},
    );
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty && _eventTypes.isNotEmpty) {
      final matchingEventType = _eventTypes.firstWhere(
        (eventType) => eventType['value'] == widget.initialValue,
        orElse: () => <String, String>{},
      );

      if (matchingEventType.isNotEmpty) {
        _controller.text = matchingEventType['label'] ?? widget.initialValue!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onChanged(widget.initialValue!);
        });
      } else {
        final matchingByLabel = _eventTypes.firstWhere(
          (eventType) => eventType['label']?.toLowerCase() == widget.initialValue!.toLowerCase(),
          orElse: () => <String, String>{},
        );

        if (matchingByLabel.isNotEmpty) {
          _controller.text = matchingByLabel['label'] ?? widget.initialValue!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged(matchingByLabel['value'] ?? widget.initialValue!);
          });
        } else {
          _controller.text = widget.initialValue!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged(widget.initialValue!);
          });
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
        final roleAsync = ref.read(roleProvider);
        final role = roleAsync.valueOrNull ?? UserRole.staff;
        _showAddButton = filtered.isEmpty && role == UserRole.admin;
      });
    }
  }

  Future<void> _addNewEventType(String newType) async {
    final roleAsync = ref.read(roleProvider);
    final role = roleAsync.valueOrNull ?? UserRole.staff;
    if (role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can add new event types'),
          backgroundColor: AppColorScheme.snackError,
        ),
      );
      return;
    }

    final trimmedType = newType.trim();
    if (trimmedType.isEmpty) return;

    final exists = _eventTypes.any(
      (type) =>
          (type['label'] ?? '').toLowerCase() == trimmedType.toLowerCase() ||
          (type['value'] ?? '').toLowerCase() == trimmedType.toLowerCase(),
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event type "$trimmedType" already exists'),
          backgroundColor: AppColorScheme.snackWarning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newValue = trimmedType.toLowerCase().replaceAll(' ', '_');
      await ref
          .read(firestoreServiceProvider)
          .addDropdownItem(
            kind: 'event_types',
            label: trimmedType,
            value: newValue,
            order: _eventTypes.length + 1,
            createdBy: ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
          );

      await _loadEventTypes();

      _controller.text = trimmedType;
      widget.onChanged(newValue);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event type "$trimmedType" added successfully'),
            backgroundColor: AppColorScheme.snackSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding event type: $e'),
            backgroundColor: AppColorScheme.snackError,
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
    final roleAsync = ref.watch(roleProvider);
    return roleAsync.when(
      data: (role) {
        if (role != UserRole.admin) {
          return const SizedBox.shrink();
        }
        return _buildAddOptionCard();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAddOptionCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.add_circle, color: AppColorScheme.snackSuccess),
        title: Text(
          'Add "${_controller.text.trim()}" as new event type',
          style: const TextStyle(color: AppColorScheme.snackSuccess, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Admin only'),
        onTap: () => _addNewEventType(_controller.text),
      ),
    );
  }
}
