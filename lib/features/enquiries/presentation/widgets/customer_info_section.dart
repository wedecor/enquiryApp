import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/logging/logger.dart';
import '../../../../core/theme/tokens.dart';
import 'enquiry_detail_info_row.dart';
import 'enquiry_detail_section.dart';

/// Customer contact facts. Call/WhatsApp/review actions live in the header.
class CustomerInfoSection extends StatelessWidget {
  const CustomerInfoSection({
    super.key,
    required this.customerPhone,
    required this.location,
    this.locationAddress,
    this.mapsUri,
    this.onAddEvent,
  });

  final String? customerPhone;
  final String location;

  /// Full Google address when a Maps place is attached.
  final String? locationAddress;

  /// "Open in Maps" link (see `mapsSearchUri`); null hides the action.
  final Uri? mapsUri;

  /// "Add another event" for this customer (admins only); null hides the button.
  final VoidCallback? onAddEvent;

  @override
  Widget build(BuildContext context) {
    return EnquiryDetailSection(
      eyebrow: 'Who & where',
      title: 'Basic Information',
      trailing: onAddEvent == null
          ? null
          : TextButton.icon(
              onPressed: onAddEvent,
              icon: const Icon(Icons.add_rounded, size: AppTokens.iconSmall),
              label: const Text('Add event'),
            ),
      children: [
        EnquiryInfoGrid(
          children: [
            EnquiryDetailInfoRow(label: 'Phone', value: customerPhone ?? 'N/A'),
            EnquiryDetailInfoRow(label: 'Location', value: location),
          ],
        ),
        if (locationAddress != null || mapsUri != null)
          _LocationExtras(address: locationAddress, mapsUri: mapsUri),
      ],
    );
  }
}

/// Full address under the venue plus an "Open in Maps" link (free URL, no API).
class _LocationExtras extends StatelessWidget {
  const _LocationExtras({required this.address, required this.mapsUri});

  final String? address;
  final Uri? mapsUri;

  Future<void> _open(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Log.w('CustomerInfoSection: could not open Maps', data: {'error': e.toString()});
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Couldn\'t open Google Maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uri = mapsUri;
    return Padding(
      padding: AppSpacing.bottom(AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (address != null)
            Padding(
              padding: AppSpacing.bottom(AppTokens.space2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: AppTokens.iconSmall,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: Text(
                      address!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (uri != null)
            TextButton.icon(
              onPressed: () => _open(context, uri),
              icon: const Icon(Icons.map_outlined, size: AppTokens.iconSmall),
              label: const Text('Open in Maps'),
            ),
        ],
      ),
    );
  }
}
