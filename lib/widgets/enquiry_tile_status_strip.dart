import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/contacts/contact_launcher.dart';
import '../utils/logger.dart';

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

  @override
  ConsumerState<EnquiryTileStatusStrip> createState() => _EnquiryTileStatusStripState();
}

class _EnquiryTileStatusStripState extends ConsumerState<EnquiryTileStatusStrip> {
  bool _isHovered = false;
  bool _isLaunching = false;

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
    final neutralBg = theme.colorScheme.surfaceContainerHighest;
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(_isHovered ? 0.12 : 0.06)),
          boxShadow: [
            BoxShadow(
              color: eventColor.withOpacity(_isHovered ? 0.25 : 0.15),
              blurRadius: _isHovered ? 24 : 14,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
          backgroundBlendMode: BlendMode.overlay,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: widget.onView,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusStrip(color: statusColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HeaderRow(
                              name: widget.name,
                              eventColor: eventColor,
                              onMorePressed: () {},
                            ),
                            const SizedBox(height: 12),
                            _ChipWrap(
                              status: widget.status,
                              statusColor: statusColor,
                              eventType: widget.eventType,
                              eventColor: eventColor,
                              ageLabel: widget.ageLabel,
                              eventCountdownLabel: widget.eventCountdownLabel,
                              assignee: widget.assignee,
                              neutralBg: neutralBg,
                              neutralText: neutralText,
                            ),
                            const SizedBox(height: 16),
                            _MetaRow(
                              dateLabel: widget.dateLabel,
                              location: widget.location,
                              neutralText: neutralText,
                            ),
                            if (_hasNotes(widget.notes)) ...[
                              const SizedBox(height: 16),
                              _NotesPreview(notes: widget.notes!),
                            ],
                            const SizedBox(height: 16),
                            const Divider(color: Colors.white10, height: 1),
                            const SizedBox(height: 12),
                            _ActionsRow(
                              isLaunching: _isLaunching,
                              onWhatsApp: _buildWhatsAppHandler(context),
                              onCall: _buildCallHandler(context),
                              onView: widget.onView,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  bool _hasNotes(String? notes) => notes != null && notes.trim().isNotEmpty;

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

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 10, spreadRadius: 1)],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.name, required this.eventColor, required this.onMorePressed});

  final String name;
  final Color eventColor;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: eventColor.withOpacity(0.16),
          child: Text(
            initial,
            style: theme.textTheme.titleMedium?.copyWith(
              color: eventColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: onMorePressed ?? () {}),
      ],
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({
    required this.status,
    required this.statusColor,
    required this.eventType,
    required this.eventCountdownLabel,
    required this.eventColor,
    required this.ageLabel,
    required this.assignee,
    required this.neutralBg,
    required this.neutralText,
  });

  final String status;
  final Color statusColor;
  final String eventType;
  final String? eventCountdownLabel;
  final Color eventColor;
  final String ageLabel;
  final String? assignee;
  final Color neutralBg;
  final Color neutralText;

  String _prettify(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'Unknown';

    final normalized = trimmed.replaceAll(RegExp(r'[_-]+'), ' ');
    final words = normalized.split(RegExp(r'\\s+')).where((word) => word.isNotEmpty).toList();

    if (words.isEmpty) return 'Unknown';

    return words
        .map((word) {
          final lower = word.toLowerCase();
          if (lower == 'vip') return 'VIP';
          if (lower.length == 1) return lower.toUpperCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    Color neutralBackground(Color color) {
      return color.withOpacity(color.opacity >= 0.85 ? 0.85 : 0.65);
    }

    final chips = <Widget>[
      Chip(
        shape: StadiumBorder(side: BorderSide(color: statusColor.withOpacity(0.3))),
        backgroundColor: statusColor.withOpacity(0.18),
        label: Text(
          _prettify(status),
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
        ),
      ),
      Chip(
        shape: StadiumBorder(side: BorderSide(color: eventColor.withOpacity(0.3))),
        backgroundColor: eventColor.withOpacity(0.18),
        label: Text(
          _prettify(eventType),
          style: TextStyle(color: eventColor, fontWeight: FontWeight.w500),
        ),
      ),
      if (eventCountdownLabel != null && eventCountdownLabel!.trim().isNotEmpty)
        Chip(
          shape: StadiumBorder(side: BorderSide(color: eventColor.withOpacity(0.2))),
          backgroundColor: eventColor.withOpacity(0.12),
          avatar: Icon(Icons.calendar_today, size: 16, color: eventColor),
          label: Text(
            eventCountdownLabel!,
            style: TextStyle(color: eventColor, fontWeight: FontWeight.w500),
          ),
        ),
      Chip(
        shape: StadiumBorder(side: BorderSide(color: neutralText.withOpacity(0.2))),
        backgroundColor: neutralBackground(neutralBg),
        label: Text(
          ageLabel,
          style: TextStyle(color: neutralText, fontWeight: FontWeight.w500),
        ),
      ),
    ];

    if (assignee != null && assignee!.trim().isNotEmpty) {
      chips.add(
        Chip(
          shape: StadiumBorder(side: BorderSide(color: neutralText.withOpacity(0.2))),
          backgroundColor: neutralBackground(neutralBg),
          avatar: Icon(Icons.person, size: 18, color: neutralText),
          label: Text(
            assignee!,
            style: TextStyle(color: neutralText, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.dateLabel, this.location, required this.neutralText});

  final String dateLabel;
  final String? location;
  final Color neutralText;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _MetaItem(icon: Icons.calendar_today, label: dateLabel, color: neutralText),
        if (location != null && location!.trim().isNotEmpty)
          _MetaItem(icon: Icons.location_on, label: location!, color: neutralText),
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
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
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

class _NotesPreview extends StatelessWidget {
  const _NotesPreview({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 16, thickness: 0.5, color: Colors.white10),
        Text('Notes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          notes,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.isLaunching,
    required this.onWhatsApp,
    required this.onCall,
    required this.onView,
  });

  final bool isLaunching;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onCall;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble,
            label: isLaunching ? 'Opening…' : 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: isLaunching ? null : onWhatsApp,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.call,
            label: isLaunching ? 'Opening…' : 'Call',
            color: const Color(0xFF1E88E5),
            onTap: isLaunching ? null : onCall,
          ),
        ),
        const SizedBox(width: 12),
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
        ? baseColor.withOpacity(0.05)
        : baseColor.withOpacity(_hover ? 0.18 : 0.10);
    final foreground = disabled
        ? baseColor.withOpacity(0.45)
        : (_hover ? baseColor.withOpacity(0.95) : baseColor.withOpacity(0.85));

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
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
