import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/dropdown_defaults.dart';
import '../../core/constants/status_vocabulary.dart';
import '../../core/logging/logger.dart';
import '../../core/providers/role_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/models/user_model.dart';
import '../../ui/primitives/primitives.dart';

class StatusDropdown extends ConsumerStatefulWidget {
  final String? value;
  final void Function(String?) onChanged;
  final String label;
  final String collectionName;
  final String? Function(String?)? validator;
  final bool required;

  /// Type-to-search field instead of a plain dropdown. Defaults to on for
  /// event types, whose list keeps growing.
  final bool? searchable;

  const StatusDropdown({
    super.key,
    this.value,
    required this.onChanged,
    required this.label,
    required this.collectionName,
    this.validator,
    this.required = false,
    this.searchable,
  });

  bool get isSearchable => searchable ?? collectionName == 'event_types';

  @override
  ConsumerState<StatusDropdown> createState() => _StatusDropdownState();
}

class _StatusDropdownState extends ConsumerState<StatusDropdown> {
  // Each status item stores both label (display) and value (id)
  List<Map<String, String>> _statuses = [];
  bool _isLoading = false;
  final TextEditingController _addController = TextEditingController();
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  // Searchable mode only.
  static const _addSentinel = '__add_new__';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _statuses = DropdownDefaults.forCollection(widget.collectionName);
    _searchFocus.addListener(_onSearchFocusChanged);
    _syncSearchText();
    _loadStatuses();
  }

  @override
  void dispose() {
    _addController.dispose();
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StatusDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild if the value actually changed and we have data loaded
    if (oldWidget.value != widget.value && _statuses.isNotEmpty) {
      _syncSearchText();
      setState(() {});
    }
  }

  String _labelFor(String? value) {
    if (value == null) return '';
    for (final status in _statuses) {
      if (status['value'] == value) return status['label'] ?? value;
    }
    return '';
  }

  /// Shows the selected option's label in the search box (not while typing).
  void _syncSearchText() {
    if (!widget.isSearchable || _searchFocus.hasFocus) return;
    final current = _fieldKey.currentState?.value ?? _getValidValue(widget.value);
    final label = _labelFor(current);
    if (_searchController.text != label) _searchController.text = label;
  }

  /// Leaving the field without picking restores the selected label.
  void _onSearchFocusChanged() {
    if (!_searchFocus.hasFocus) _syncSearchText();
  }

  /// Prefix matches first, then other matches; the full list when the box is
  /// empty or still shows the current selection. Admins get "Add …" when
  /// nothing matches exactly.
  Iterable<Map<String, String>> _searchOptions(String rawQuery, bool isAdmin) {
    final query = rawQuery.trim().toLowerCase();
    final selectedLabel = _labelFor(_fieldKey.currentState?.value).toLowerCase();
    if (query.isEmpty || query == selectedLabel) return _statuses;

    final prefix = <Map<String, String>>[];
    final contains = <Map<String, String>>[];
    var exact = false;
    for (final status in _statuses) {
      final label = (status['label'] ?? '').toLowerCase();
      final value = (status['value'] ?? '').toLowerCase();
      if (label == query || value == query) exact = true;
      if (label.startsWith(query) || value.startsWith(query)) {
        prefix.add(status);
      } else if (label.contains(query) || value.contains(query.replaceAll(' ', '_'))) {
        contains.add(status);
      }
    }
    return [
      ...prefix,
      ...contains,
      if (isAdmin && !exact) {'value': _addSentinel, 'label': rawQuery.trim()},
    ];
  }

  void _selectSearchOption(FormFieldState<String> field, Map<String, String> option) {
    if (option['value'] == _addSentinel) {
      _addController.text = option['label'] ?? '';
      _addNewStatus();
      return;
    }
    final value = option['value'];
    field.didChange(value);
    _searchController.text = option['label'] ?? value ?? '';
    _searchFocus.unfocus();
    widget.onChanged(value);
  }

  Future<void> _loadStatuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final options = await ref
          .read(firestoreServiceProvider)
          .fetchActiveDropdownOptions(widget.collectionName);

      if (!mounted) return;
      setState(() {
        _statuses = DropdownDefaults.resolve(options, widget.collectionName);
        _isLoading = false;
      });
      _syncFieldValueAfterLoad();
      _syncSearchText();
    } catch (e, st) {
      // Fallback to default values if Firestore is not available
      Log.w(
        'StatusDropdown fallback values',
        data: {'collection': widget.collectionName, 'error': e.runtimeType.toString()},
      );
      Log.d('StatusDropdown fallback stack', data: st);
      if (!mounted) return;
      setState(() {
        _statuses = DropdownDefaults.forCollection(widget.collectionName);
        _isLoading = false;
      });
      _syncFieldValueAfterLoad();
      _syncSearchText();
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
      _syncSearchText();
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
          content: Text('Only admins can add new ${widget.label.toLowerCase()}'),
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
            createdBy: ref.read(currentUserWithFirestoreProvider).value?.uid ?? 'unknown',
          );

      // Refresh the list
      await _loadStatuses();

      // Set the new value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fieldKey.currentState?.didChange(newValue);
        if (widget.isSearchable) {
          _searchController.text = newStatus;
          _searchFocus.unfocus();
        }
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _addController.clear();
    }
  }

  void _showAddDialog() {
    final roleAsync = ref.read(roleProvider);
    final role = roleAsync.valueOrNull ?? UserRole.staff;
    if (role != UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only admins can add new ${widget.label.toLowerCase()}'),
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
              decoration: InputDecoration(labelText: widget.label),
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
            if (widget.isSearchable)
              Expanded(child: _buildSearchField(context, roleAsync.valueOrNull == UserRole.admin))
            else
            Expanded(
              child: DropdownButtonFormField<String>(
                key: _fieldKey,
                // CRITICAL: Always ensure value is valid or null
                initialValue: _getValidValue(widget.value),
                borderRadius: AppRadius.large,
                dropdownColor: AppSurfaces.of(context).glassFillStrong,
                icon: const Icon(Icons.expand_more_rounded),
                decoration: InputDecoration(
                  labelText: widget.required ? '${widget.label} *' : widget.label,
                  prefixIcon: Icon(_getIconForStatus(), size: AppTokens.iconMedium),
                  hintText:
                      widget.value != null &&
                          !_isLoading &&
                          _statuses.isNotEmpty &&
                          _getValidValue(widget.value) == null
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
                // The status workflow is fixed in code; only labels/colours are editable.
                // Searchable fields offer "Add …" inside the list instead.
                if (role != UserRole.admin ||
                    widget.collectionName == 'statuses' ||
                    widget.isSearchable) {
                  return const SizedBox.shrink();
                }
                final s = AppSurfaces.of(context);
                final tooltip = 'Add new ${widget.label.toLowerCase()}';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: AppTokens.space2),
                    // Neutral secondary action — not a coloured call-to-action.
                    Tooltip(
                      message: tooltip,
                      child: Pressable(
                        onTap: _showAddDialog,
                        borderRadius: AppRadius.medium,
                        pressedScale: 0.9,
                        semanticLabel: tooltip,
                        child: Container(
                          width: AppTokens.minTapTarget + 4,
                          height: AppTokens.minTapTarget + 4,
                          decoration: BoxDecoration(
                            color: s.glassFillStrong,
                            borderRadius: AppRadius.medium,
                            border: Border.all(color: s.microBorderStrong),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: AppTokens.iconMedium,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, bool isAdmin) {
    final s = AppSurfaces.of(context);
    return FormField<String>(
      key: _fieldKey,
      initialValue: _getValidValue(widget.value),
      validator: widget.validator,
      builder: (field) {
        return RawAutocomplete<Map<String, String>>(
          textEditingController: _searchController,
          focusNode: _searchFocus,
          displayStringForOption: (option) => option['value'] == _addSentinel
              ? (option['label'] ?? '')
              : (option['label'] ?? option['value'] ?? ''),
          optionsBuilder: (textValue) => _searchOptions(textValue.text, isAdmin),
          onSelected: (option) => _selectSearchOption(field, option),
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.required ? '${widget.label} *' : widget.label,
                hintText:
                    widget.value != null &&
                        !_isLoading &&
                        _statuses.isNotEmpty &&
                        _getValidValue(widget.value) == null
                    ? 'Current: ${widget.value} — type to search'
                    : 'Type to search',
                prefixIcon: Icon(_getIconForStatus(), size: AppTokens.iconMedium),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                errorText: field.errorText,
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                color: s.glassFillStrong,
                borderRadius: AppRadius.large,
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280, maxWidth: 520),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isAdd = option['value'] == _addSentinel;
                      return ListTile(
                        dense: true,
                        leading: isAdd ? const Icon(Icons.add_rounded) : null,
                        title: Text(
                          isAdd
                              ? 'Add "${option['label']}" as a new ${widget.label.toLowerCase()}'
                              : (option['label'] ?? option['value'] ?? ''),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
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
