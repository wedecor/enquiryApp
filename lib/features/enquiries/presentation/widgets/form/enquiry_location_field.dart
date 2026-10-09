import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../data/places_service.dart';
import '../../../domain/enquiry_location.dart';
import '../enquiry_form_section.dart';

/// A row in the venue dropdown: a Google place, or "keep what I typed".
class _LocationOption {
  const _LocationOption.place(PlaceSuggestion this.suggestion) : typed = null;
  const _LocationOption.typed(String this.typed) : suggestion = null;

  final PlaceSuggestion? suggestion;
  final String? typed;
}

/// Event Location with Google Maps search for areas ("JP Nagar") and venues. Free text is always allowed:
/// suggestions only appear while typing and nothing forces a pick.
///
/// Picking a venue fetches its details and attaches an [EnquiryPlace] through
/// [onPlaceChanged]; editing the text afterwards detaches it (reports null).
class EnquiryLocationField extends ConsumerStatefulWidget {
  const EnquiryLocationField({
    super.key,
    required this.controller,
    required this.place,
    required this.onPlaceChanged,
    this.requireKnownLocation = false,
    this.autofocus = false,
  });

  /// Shown by the validator when [requireKnownLocation] and the location is only
  /// the city (see [isLocationKnown]).
  static const String approvalRequiredMessage = 'Location is required to approve — add the area';

  final TextEditingController controller;

  /// The enquiry is (or will be) approved: validation also rejects a city-only
  /// location such as "Bangalore".
  final bool requireKnownLocation;
  final bool autofocus;

  /// The place attached to the current text, if any.
  final EnquiryPlace? place;
  final ValueChanged<EnquiryPlace?> onPlaceChanged;

  @override
  ConsumerState<EnquiryLocationField> createState() => _EnquiryLocationFieldState();
}

class _EnquiryLocationFieldState extends ConsumerState<EnquiryLocationField> {
  static const Duration _debounce = Duration(milliseconds: 350);

  /// Google ends idle sessions after a few minutes; start a fresh one before then.
  static const Duration _sessionMaxAge = Duration(minutes: 3);

  final FocusNode _focusNode = FocusNode();

  String _sessionToken = newPlacesSessionToken();
  DateTime _sessionStarted = DateTime.now();

  /// Text the attached (or resolving) place belongs to.
  String? _pickedText;
  int _querySeq = 0;
  int _pickSeq = 0;
  bool _resolving = false;
  Iterable<_LocationOption> _latest = const [];

  @override
  void initState() {
    super.initState();
    if (widget.place != null) _pickedText = widget.controller.text.trim();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant EnquiryLocationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
    if (widget.place != null && oldWidget.place == null && _pickedText == null) {
      _pickedText = widget.controller.text.trim();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _renewSession() {
    _sessionToken = newPlacesSessionToken();
    _sessionStarted = DateTime.now();
  }

  /// The user changed the text after picking: the place no longer matches it.
  void _onTextChanged() {
    final picked = _pickedText;
    if (picked == null || widget.controller.text.trim() == picked) return;
    _pickedText = null;
    _pickSeq++; // drop a details call still in flight
    if (_resolving) setState(() => _resolving = false);
    if (widget.place != null) widget.onPlaceChanged(null);
  }

  Future<Iterable<_LocationOption>> _optionsFor(TextEditingValue value) async {
    final query = value.text.trim();
    final seq = ++_querySeq;
    if (query.length < PlacesService.minQueryLength || query == _pickedText) {
      _latest = const [];
      return _latest;
    }
    await Future<void>.delayed(_debounce);
    if (!mounted || seq != _querySeq) return _latest; // superseded by newer typing
    if (DateTime.now().difference(_sessionStarted) > _sessionMaxAge) _renewSession();
    final results = await ref
        .read(placesServiceProvider)
        .autocomplete(query, sessionToken: _sessionToken);
    if (!mounted || seq != _querySeq) return _latest;
    _latest = results.isEmpty
        ? const <_LocationOption>[]
        : [for (final s in results) _LocationOption.place(s), _LocationOption.typed(query)];
    return _latest;
  }

  Future<void> _onSelected(_LocationOption option) async {
    // Cancel the lookup RawAutocomplete started for the text it just filled in.
    _querySeq++;
    _latest = const [];
    final suggestion = option.suggestion;
    if (suggestion == null) return; // "Use as typed": the text is already there

    final pickSeq = ++_pickSeq;
    _pickedText = suggestion.mainText.trim();
    setState(() => _resolving = true);
    final details = await ref
        .read(placesServiceProvider)
        .details(suggestion.placeId, sessionToken: _sessionToken);
    if (!mounted || pickSeq != _pickSeq) return; // user kept typing meanwhile
    _renewSession(); // the details call closed this session
    if (details == null) {
      // Keep the venue name as plain text.
      _pickedText = null;
      setState(() => _resolving = false);
      return;
    }
    final text = pickedLocationText(suggestion.mainText, details.area, isArea: details.isArea);
    _pickedText = text;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() => _resolving = false);
    widget.onPlaceChanged(details.toEnquiryPlace());
  }

  String _display(_LocationOption option) =>
      option.suggestion?.mainText ?? option.typed ?? widget.controller.text;

  Widget? _suffix(BuildContext context) {
    if (_resolving) {
      return const Padding(
        padding: EdgeInsets.all(AppTokens.space3 + 2),
        child: SizedBox(
          width: AppTokens.iconSmall,
          height: AppTokens.iconSmall,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (widget.place == null) return null;
    return Tooltip(
      message: 'Pinned on Google Maps',
      child: Icon(Icons.place_rounded, color: AppSurfaces.of(context).accent),
    );
  }

  String? _helper() {
    final place = widget.place;
    if (place == null) return 'Search an area or venue, or type any location';
    final address = place.address;
    return address == null ? 'Pinned on Maps' : 'Pinned on Maps · $address';
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<_LocationOption>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: _display,
      optionsBuilder: _optionsFor,
      onSelected: _onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Enter/Done keeps the typed text (no forced pick), so onFieldSubmitted
        // is deliberately not wired up.
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          autofocus: widget.autofocus,
          scrollPadding: kEnquiryFieldScrollPadding,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Event Location *',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _suffix(context),
            helperText: _helper(),
            helperMaxLines: 2,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter event location';
            }
            if (widget.requireKnownLocation &&
                !isLocationKnown(area: widget.place?.area, eventLocation: value)) {
              return EnquiryLocationField.approvalRequiredMessage;
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) =>
          _LocationOptionsView(options: options.toList(), onSelected: onSelected),
    );
  }
}

class _LocationOptionsView extends StatelessWidget {
  const _LocationOptionsView({required this.options, required this.onSelected});

  final List<_LocationOption> options;
  final AutocompleteOnSelected<_LocationOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppSurfaces.of(context);
    final highlighted = AutocompleteHighlightedOption.of(context);

    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: AppTokens.space1),
        child: Material(
          color: cs.surfaceContainerHigh,
          elevation: AppTokens.elevation4,
          shadowColor: s.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.medium,
            side: BorderSide(color: s.microBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space1),
              shrinkWrap: true,
              children: [
                for (var i = 0; i < options.length; i++)
                  _OptionTile(
                    option: options[i],
                    highlighted: i == highlighted,
                    onTap: () => onSelected(options[i]),
                  ),
                // Google requires attribution for Places results shown off a Google map.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space4,
                    AppTokens.space1,
                    AppTokens.space4,
                    AppTokens.space2,
                  ),
                  child: Text(
                    'Powered by Google',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, required this.highlighted, required this.onTap});

  final _LocationOption option;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final suggestion = option.suggestion;
    final leading = Icon(
      suggestion == null ? Icons.edit_location_alt_outlined : Icons.place_outlined,
      size: AppTokens.iconMedium,
      color: cs.onSurfaceVariant,
    );
    if (suggestion == null) {
      return ListTile(
        dense: true,
        selected: highlighted,
        selectedTileColor: cs.primary.withValues(alpha: 0.08),
        leading: leading,
        title: Text(
          'Use “${option.typed ?? ''}” as typed',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        onTap: onTap,
      );
    }
    return ListTile(
      dense: true,
      selected: highlighted,
      selectedTileColor: cs.primary.withValues(alpha: 0.08),
      leading: leading,
      title: Text(suggestion.mainText, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: suggestion.secondaryText.isEmpty
          ? null
          : Text(suggestion.secondaryText, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
