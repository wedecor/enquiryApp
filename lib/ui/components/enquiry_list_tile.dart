import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contacts/contact_launcher.dart';
import '../../core/logging/logger.dart';
import '../../core/services/contact_service.dart';
import '../../core/theme/app_theme.dart';

enum _TileAction { viewDetails, updateStatus, share, notes, saveContact, requestReview }

/// Formats a status/event-type string into Title Case, handling common
/// abbreviations and underscore/hyphen separators.
String _prettifyLabel(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';
  final normalized = trimmed.replaceAll(RegExp(r'[_-]+'), ' ');
  final words = normalized.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  return words
      .map((word) {
        final lower = word.toLowerCase();
        if (lower == 'vip') return 'VIP';
        if (lower.length == 1) return lower.toUpperCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

class EnquiryTileStatusStrip extends ConsumerStatefulWidget {
  const EnquiryTileStatusStrip({
    super.key,
    required this.name,
    required this.status,
    required this.eventType,
    this.eventCountdownLabel,
    required this.ageLabel,
    this.assignee,
    required this.dateLabel,
    this.location,
    this.notes,
    this.phoneNumber,
    this.whatsappNumber,
    this.statusColorHex,
    this.eventColorHex,
    this.statusColorOverride,
    this.eventColorOverride,
    this.whatsappPrefill,
    required this.onView,
    this.enquiryId,
    this.onCall,
    this.onWhatsApp,
    this.onUpdateStatus,
    this.onShare,
    this.onAddNote,
    this.onRequestReview,
    this.reminderCount,
    this.isPastEvent = false,
    this.onMarkNotInterested,
  });

  final String name;
  final String status;
  final String eventType;
  final String? eventCountdownLabel;
  final String ageLabel;
  final String? assignee;
  final String dateLabel;
  final String? location;
  final String? notes;
  final String? phoneNumber;
  final String? whatsappNumber;
  final String? statusColorHex;
  final String? eventColorHex;
  final Color? statusColorOverride;
  final Color? eventColorOverride;
  final String? whatsappPrefill;
  final VoidCallback onView;
  final String? enquiryId;
  final Future<void> Function()? onCall;
  final Future<void> Function()? onWhatsApp;
  final Future<void> Function()? onUpdateStatus;
  final Future<void> Function()? onShare;
  final Future<void> Function()? onAddNote;
  final Future<void> Function()? onRequestReview;
  final int? reminderCount;
  final bool isPastEvent;
  final Future<void> Function()? onMarkNotInterested;

  @override
  ConsumerState<EnquiryTileStatusStrip> createState() => _EnquiryTileStatusStripState();
}

class _EnquiryTileStatusStripState extends ConsumerState<EnquiryTileStatusStrip> {
  bool _isLaunching = false;

  void _handleAction(_TileAction action) {
    switch (action) {
      case _TileAction.viewDetails:
        widget.onView();
        break;
      case _TileAction.updateStatus:
        widget.onUpdateStatus?.call();
        break;
      case _TileAction.share:
        widget.onShare?.call();
        break;
      case _TileAction.notes:
        widget.onAddNote?.call();
        break;
      case _TileAction.saveContact:
        unawaited(_handleSaveContact());
        break;
      case _TileAction.requestReview:
        widget.onRequestReview?.call();
        break;
    }
  }

  List<_TileAction> _availableActions() {
    final actions = <_TileAction>[_TileAction.viewDetails];
    if (widget.onUpdateStatus != null) {
      actions.add(_TileAction.updateStatus);
    }
    if (widget.onShare != null) {
      actions.add(_TileAction.share);
    }
    if (widget.onAddNote != null) {
      actions.add(_TileAction.notes);
    }
    if (_hasPhoneNumber()) {
      actions.add(_TileAction.saveContact);
    }
    if (widget.onRequestReview != null && widget.status.toLowerCase() == 'completed') {
      actions.add(_TileAction.requestReview);
    }
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        widget.statusColorOverride ??
        _parseColor(widget.statusColorHex) ??
        theme.colorScheme.primary;
    final eventColor =
        widget.eventColorOverride ??
        _parseColor(widget.eventColorHex) ??
        theme.colorScheme.secondary;
    final neutralText = theme.colorScheme.onSurfaceVariant;

    if (kDebugMode) {
      Log.d(
        'Tile color debug',
        data: {
          'hasStatusHex': widget.statusColorHex != null,
          'hasEventHex': widget.eventColorHex != null,
          'statusColor': statusColor.value.toRadixString(16),
          'eventColor': eventColor.value.toRadixString(16),
        },
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onView,
        // Status strip is flush with the card's left edge.
        // IntrinsicHeight bounds the row when the tile is in a sliver list.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusStrip(color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HeaderRow(
                        name: widget.name,
                        eventType: widget.eventType,
                        eventColor: eventColor,
                        actions: _availableActions(),
                        onActionSelected: _handleAction,
                      ),
                      const SizedBox(height: 10),
                      _ChipWrap(
                        status: widget.status,
                        statusColor: statusColor,
                        eventCountdownLabel: widget.eventCountdownLabel,
                        eventColor: eventColor,
                        reminderCount: widget.reminderCount,
                        isPastEvent: widget.isPastEvent,
                      ),
                      const SizedBox(height: 12),
                      _MetaRow(
                        dateLabel: widget.dateLabel,
                        location: widget.location,
                        ageLabel: widget.ageLabel,
                        assignee: widget.assignee,
                        neutralText: neutralText,
                      ),
                      if (_hasNotes(widget.notes)) ...[
                        const SizedBox(height: 12),
                        _NotesPreview(notes: widget.notes!),
                      ],
                      const SizedBox(height: 14),
                      Divider(color: theme.colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 10),
                      _ActionsRow(
                        isLaunching: _isLaunching,
                        onWhatsApp: _buildWhatsAppHandler(context),
                        onCall: _buildCallHandler(context),
                        onView: widget.onView,
                        reminderCount: widget.reminderCount,
                        isPastEvent: widget.isPastEvent,
                        onMarkNotInterested: widget.onMarkNotInterested,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  VoidCallback? _buildWhatsAppHandler(BuildContext context) {
    final phone = _sanitizeContact(widget.whatsappNumber) ?? _sanitizeContact(widget.phoneNumber);
    if (phone == null) return null;

    return () async {
      if (_isLaunching) return;
      setState(() => _isLaunching = true);

      try {
        if (widget.onWhatsApp != null) {
          await widget.onWhatsApp!();
        } else {
          final launcher = ref.read(contactLauncherProvider);
          final status = await launcher.openWhatsAppWithAudit(
            phone,
            enquiryId: widget.enquiryId,
            prefillText: widget.whatsappPrefill,
          );
          if (!mounted) return;
          _showContactFeedback(
            context,
            status,
            successMessage: 'WhatsApp opened for ${widget.name}.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLaunching = false);
        }
      }
    };
  }

  VoidCallback? _buildCallHandler(BuildContext context) {
    final phone = _sanitizeContact(widget.phoneNumber);
    if (phone == null) return null;

    return () async {
      if (_isLaunching) return;
      setState(() => _isLaunching = true);

      try {
        if (widget.onCall != null) {
          await widget.onCall!();
        } else {
          final launcher = ref.read(contactLauncherProvider);
          final status = await launcher.callNumberWithAudit(phone, enquiryId: widget.enquiryId);
          if (!mounted) return;
          _showContactFeedback(
            context,
            status,
            successMessage: 'Dialer opened for ${widget.name}.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLaunching = false);
        }
      }
    };
  }

  void _showContactFeedback(
    BuildContext context,
    ContactLaunchStatus status, {
    required String successMessage,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    String message;
    switch (status) {
      case ContactLaunchStatus.opened:
        message = successMessage;
        break;
      case ContactLaunchStatus.notInstalled:
        message = 'Required app is not installed on this device.';
        break;
      case ContactLaunchStatus.invalidNumber:
        message = 'The provided phone number appears to be invalid.';
        break;
      case ContactLaunchStatus.failed:
        message = 'Something went wrong. Please try again.';
        break;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _sanitizeContact(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _handleSaveContact() async {
    final rawPhone = widget.phoneNumber?.trim();
    if (rawPhone == null || rawPhone.isEmpty) {
      _showContactSaveFeedback(context, ContactSaveStatus.invalidInput);
      return;
    }

    final launcher = ref.read(contactLauncherProvider);
    final formattedPhone = launcher.normalize(rawPhone);
    if (formattedPhone.isEmpty) {
      _showContactSaveFeedback(context, ContactSaveStatus.invalidInput);
      return;
    }

    final service = ref.read(contactServiceProvider);
    final status = await service.saveContact(
      ContactSaveRequest(
        displayName: widget.name,
        phoneNumber: formattedPhone,
        eventType: widget.eventType,
        eventDate: widget.dateLabel,
      ),
    );

    if (!mounted) return;
    _showContactSaveFeedback(context, status);
  }

  void _showContactSaveFeedback(BuildContext context, ContactSaveStatus status) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    String message;
    Color backgroundColor;

    switch (status) {
      case ContactSaveStatus.saved:
        message = 'Contact saved successfully';
        backgroundColor = AppColorScheme.snackSuccess;
        break;
      case ContactSaveStatus.copiedToClipboard:
        message = 'Contact info copied to clipboard. You can paste it into your contacts app.';
        backgroundColor = AppColorScheme.info;
        break;
      case ContactSaveStatus.alreadyExists:
        message = 'Contact already exists';
        backgroundColor = AppColorScheme.snackWarning;
        break;
      case ContactSaveStatus.permissionDenied:
        message = 'Permission denied. Please enable contacts permission in settings.';
        backgroundColor = AppColorScheme.snackError;
        break;
      case ContactSaveStatus.invalidInput:
        message = 'Invalid contact information';
        backgroundColor = AppColorScheme.snackError;
        break;
      case ContactSaveStatus.notSupportedOnWeb:
        message = 'Saving contacts is not supported on web. Contact info copied to clipboard.';
        backgroundColor = AppColorScheme.info;
        break;
      case ContactSaveStatus.failed:
        message = 'Failed to save contact';
        backgroundColor = AppColorScheme.snackError;
        break;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  bool _hasNotes(String? notes) => notes != null && notes.trim().isNotEmpty;

  bool _hasPhoneNumber() => widget.phoneNumber != null && widget.phoneNumber!.trim().isNotEmpty;

  Color? _parseColor(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // rgb/rgba formats
    final rgbRe = RegExp(
      r'^rgba?\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*([0-1]?\.?\d*))?\s*\)$',
      caseSensitive: false,
    );
    final rgbMatch = rgbRe.firstMatch(trimmed);
    if (rgbMatch != null) {
      int parseChannel(String value) {
        final parsed = int.parse(value);
        if (parsed < 0) return 0;
        if (parsed > 255) return 255;
        return parsed;
      }

      final r = parseChannel(rgbMatch.group(1)!);
      final g = parseChannel(rgbMatch.group(2)!);
      final b = parseChannel(rgbMatch.group(3)!);
      final alphaRaw = rgbMatch.group(4);
      double alpha = 1;
      if (alphaRaw != null) {
        final parsedAlpha = double.tryParse(alphaRaw);
        if (parsedAlpha != null) {
          alpha = parsedAlpha.clamp(0.0, 1.0);
        }
      }
      return Color.fromRGBO(r, g, b, alpha);
    }

    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), '');
    final lower = collapsed.toLowerCase();
    final hasHexPrefix = lower.startsWith('#') || lower.startsWith('0x');
    final hasHexLetters = RegExp(r'[a-f]').hasMatch(lower);

    String? hexBody;
    if (hasHexPrefix || hasHexLetters) {
      var candidate = lower;
      if (candidate.startsWith('#')) {
        candidate = candidate.substring(1);
      }
      if (candidate.startsWith('0x')) {
        candidate = candidate.substring(2);
      }
      if (candidate.length == 6 || candidate.length == 8) {
        final isHex = RegExp(r'^[0-9a-f]{6}([0-9a-f]{2})?$').hasMatch(candidate);
        if (isHex) {
          hexBody = candidate.toUpperCase();
        }
      }
    }

    if (hexBody != null) {
      final value = int.parse(hexBody, radix: 16);
      if (hexBody.length == 6) {
        return Color(0xFF000000 | value);
      }
      return Color(value);
    }

    final digitsOnly = collapsed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isNotEmpty && RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      try {
        final value = int.parse(digitsOnly);
        if (value <= 0xFFFFFF) {
          return Color(0xFF000000 | value);
        }
        return Color(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}

// ─── Status strip ────────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // 5px wide, flush at card edge. Card's Clip.antiAlias rounds the corners.
    return Container(width: 5, color: color);
  }
}

// ─── Header row ──────────────────────────────────────────────────────────────

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.name,
    required this.eventType,
    required this.eventColor,
    required this.actions,
    required this.onActionSelected,
  });

  final String name;
  final String eventType;
  final Color eventColor;
  final List<_TileAction> actions;
  final ValueChanged<_TileAction>? onActionSelected;

  String _labelForAction(_TileAction action) {
    switch (action) {
      case _TileAction.viewDetails:
        return 'View details';
      case _TileAction.updateStatus:
        return 'Update status';
      case _TileAction.share:
        return 'Share / export';
      case _TileAction.notes:
        return 'Follow-up notes';
      case _TileAction.saveContact:
        return 'Save contact';
      case _TileAction.requestReview:
        return 'Request review';
    }
  }

  IconData _iconForAction(_TileAction action) {
    switch (action) {
      case _TileAction.viewDetails:
        return Icons.visibility_outlined;
      case _TileAction.updateStatus:
        return Icons.swap_horiz_outlined;
      case _TileAction.share:
        return Icons.ios_share_outlined;
      case _TileAction.notes:
        return Icons.note_alt_outlined;
      case _TileAction.saveContact:
        return Icons.person_add_alt_1_outlined;
      case _TileAction.requestReview:
        return Icons.star_rate_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventLabel = _prettifyLabel(eventType);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (eventLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                // Compact inline badge — replaces the event type chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: eventColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: eventColor.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    eventLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: eventColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty)
          PopupMenuButton<_TileAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More actions',
            onSelected: onActionSelected ?? (_) {},
            itemBuilder: (context) => actions
                .map(
                  (action) => PopupMenuItem<_TileAction>(
                    value: action,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconForAction(action), size: 20),
                        const SizedBox(width: 12),
                        Text(_labelForAction(action)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

// ─── Chip wrap ───────────────────────────────────────────────────────────────
//
// Only shows the most actionable chips: status, countdown, past-event warning,
// and reminder count. Age and assignee have moved to the meta row.

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.status,
    required this.statusColor,
    this.eventCountdownLabel,
    required this.eventColor,
    this.reminderCount,
    this.isPastEvent = false,
  });

  final String status;
  final Color statusColor;
  final String? eventCountdownLabel;
  final Color eventColor;
  final int? reminderCount;
  final bool isPastEvent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warningColor = AppColorScheme.warning;
    final errorColor = colorScheme.error;

    final chips = <Widget>[
      // Status — always shown, most prominent
      Chip(
        shape: StadiumBorder(side: BorderSide(color: statusColor.withValues(alpha: 0.3))),
        backgroundColor: statusColor.withValues(alpha: 0.14),
        label: Text(
          _prettifyLabel(status),
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
      ),

      // Countdown to event date
      if (eventCountdownLabel != null && eventCountdownLabel!.trim().isNotEmpty)
        Chip(
          shape: StadiumBorder(side: BorderSide(color: eventColor.withValues(alpha: 0.25))),
          backgroundColor: eventColor.withValues(alpha: 0.10),
          avatar: Icon(Icons.calendar_today_outlined, size: 14, color: eventColor),
          label: Text(
            eventCountdownLabel!,
            style: TextStyle(color: eventColor, fontWeight: FontWeight.w500),
          ),
        ),

      // Past event warning
      if (isPastEvent)
        Chip(
          shape: StadiumBorder(side: BorderSide(color: errorColor.withValues(alpha: 0.3))),
          backgroundColor: errorColor.withValues(alpha: 0.12),
          avatar: Icon(Icons.warning_amber_rounded, size: 15, color: errorColor),
          label: Text(
            'Past Event',
            style: TextStyle(color: errorColor, fontWeight: FontWeight.w600),
          ),
        ),

      // Reminder count
      if (reminderCount != null && reminderCount! > 0)
        Chip(
          shape: StadiumBorder(side: BorderSide(color: warningColor.withValues(alpha: 0.3))),
          backgroundColor: warningColor.withValues(alpha: 0.12),
          avatar: Icon(Icons.notifications_active, size: 14, color: warningColor),
          label: Text(
            '$reminderCount reminder${reminderCount == 1 ? '' : 's'}',
            style: TextStyle(color: warningColor, fontWeight: FontWeight.w500),
          ),
        ),
    ];

    return Wrap(spacing: 6, runSpacing: 4, children: chips);
  }
}

// ─── Meta row ────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.dateLabel,
    this.location,
    required this.ageLabel,
    this.assignee,
    required this.neutralText,
  });

  final String dateLabel;
  final String? location;
  final String ageLabel;
  final String? assignee;
  final Color neutralText;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        _MetaItem(icon: Icons.calendar_today_outlined, label: dateLabel, color: neutralText),
        _MetaItem(icon: Icons.access_time_outlined, label: ageLabel, color: neutralText),
        if (location != null && location!.trim().isNotEmpty)
          _MetaItem(icon: Icons.location_on_outlined, label: location!, color: neutralText),
        if (assignee != null && assignee!.trim().isNotEmpty)
          _MetaItem(icon: Icons.person_outline, label: assignee!, color: neutralText),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notes preview ───────────────────────────────────────────────────────────

class _NotesPreview extends StatelessWidget {
  const _NotesPreview({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notes',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            notes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions row ─────────────────────────────────────────────────────────────

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.isLaunching,
    required this.onWhatsApp,
    required this.onCall,
    required this.onView,
    this.reminderCount,
    this.isPastEvent = false,
    this.onMarkNotInterested,
  });

  final bool isLaunching;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback onView;
  final int? reminderCount;
  final bool isPastEvent;
  final Future<void> Function()? onMarkNotInterested;

  @override
  Widget build(BuildContext context) {
    if (isPastEvent && onMarkNotInterested != null) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble,
                  label: isLaunching ? 'Opening…' : 'WhatsApp',
                  color: AppColorScheme.whatsApp,
                  onTap: isLaunching ? null : onWhatsApp,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.call,
                  label: isLaunching ? 'Opening…' : 'Call',
                  color: AppColorScheme.phoneCall,
                  onTap: isLaunching ? null : onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.visibility,
                  label: 'View',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: onView,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _ActionButton(
              icon: Icons.block,
              label: 'Mark as Not Interested',
              color: Theme.of(context).colorScheme.error,
              onTap: () async {
                await onMarkNotInterested?.call();
              },
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble,
            label: isLaunching ? 'Opening…' : 'WhatsApp',
            color: AppColorScheme.whatsApp,
            onTap: isLaunching ? null : onWhatsApp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.call,
            label: isLaunching ? 'Opening…' : 'Call',
            color: AppColorScheme.phoneCall,
            onTap: isLaunching ? null : onCall,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.visibility,
            label: 'View',
            color: Theme.of(context).colorScheme.primary,
            onTap: onView,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final disabled = widget.onTap == null;
    final baseColor = widget.color;
    final background = disabled
        ? baseColor.withValues(alpha: 0.05)
        : baseColor.withValues(alpha: _hover ? 0.18 : 0.10);
    final foreground = disabled
        ? baseColor.withValues(alpha: 0.45)
        : (_hover ? baseColor.withValues(alpha: 0.95) : baseColor.withValues(alpha: 0.85));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: background,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ) ??
                        TextStyle(fontWeight: FontWeight.w600, color: foreground),
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
