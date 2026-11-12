import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../settings/domain/app_config.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../data/quotation_pdf.dart';
import '../../data/quotation_pdf_share.dart';
import '../../data/quotations_repository.dart';
import '../../domain/quotation.dart';
import '../quotations_providers.dart';
import '../screens/quotation_editor_screen.dart';
import 'enquiry_detail_section.dart';

/// Admin panel: list of quotations for this enquiry, with create / open / PDF / mark sent.
class QuotationSection extends ConsumerWidget {
  const QuotationSection({
    super.key,
    required this.enquiryId,
    required this.customerName,
    this.customerPhone,
    this.eventLabel,
  });

  final String enquiryId;
  final String customerName;
  final String? customerPhone;
  final String? eventLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesAsync = ref.watch(enquiryQuotationsProvider(enquiryId));

    return EnquiryDetailSection(
      eyebrow: 'Admin only',
      title: 'Quotations',
      trailing: TextButton.icon(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New'),
      ),
      children: [
        quotesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTokens.space3),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (e, _) => Text(
            'Could not load quotations.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
          data: (quotes) {
            if (quotes.isEmpty) {
              return Text(
                'No quotations yet. Build a line-item quote, share the PDF, then mark it sent to update the quoted amount.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < quotes.length; i++) ...[
                  if (i > 0) const Divider(height: AppTokens.space5),
                  _QuoteRow(
                    enquiryId: enquiryId,
                    quote: quotes[i],
                    customerName: customerName,
                    customerPhone: customerPhone,
                    eventLabel: eventLabel,
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => QuotationEditorScreen(
          enquiryId: enquiryId,
          customerName: customerName,
          customerPhone: customerPhone,
          eventLabel: eventLabel,
        ),
      ),
    );
  }
}

class _QuoteRow extends ConsumerWidget {
  const _QuoteRow({
    required this.enquiryId,
    required this.quote,
    required this.customerName,
    this.customerPhone,
    this.eventLabel,
  });

  final String enquiryId;
  final Quotation quote;
  final String customerName;
  final String? customerPhone;
  final String? eventLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final day = DateFormat('d MMM yyyy');
    final statusColor = quote.isSent ? AppSurfaces.of(context).accentInk : cs.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusDot(color: statusColor),
            const SizedBox(width: AppTokens.space2),
            Expanded(
              child: Text(
                quote.reference ?? quote.id,
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              money.format(quote.total),
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space1),
        Text(
          quote.isSent
              ? 'Sent${quote.sentAt != null ? ' · ${day.format(quote.sentAt!)}' : ''}'
              : 'Draft · ${quote.items.length} line${quote.items.length == 1 ? '' : 's'}',
          style: t.labelMedium?.copyWith(
            letterSpacing: 0.6,
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space3),
        Wrap(
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          children: [
            if (quote.isDraft)
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => QuotationEditorScreen(
                      enquiryId: enquiryId,
                      quoteId: quote.id,
                      customerName: customerName,
                      customerPhone: customerPhone,
                      eventLabel: eventLabel,
                    ),
                  ),
                ),
                child: const Text('Edit'),
              ),
            OutlinedButton(onPressed: () => _sharePdf(context, ref), child: const Text('PDF')),
            if (quote.isDraft)
              FilledButton(
                onPressed: () => _markSent(context, ref),
                child: const Text('Mark sent'),
              ),
            if (quote.isDraft)
              TextButton(
                onPressed: () => _delete(context, ref),
                child: Text('Delete', style: TextStyle(color: cs.error)),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    final company = ref.read(appGeneralConfigProvider).valueOrNull ?? const AppGeneralConfig();
    try {
      final bytes = await QuotationPdf.build(
        quotation: quote,
        company: company,
        customerName: customerName,
        customerPhone: customerPhone,
        eventLabel: eventLabel,
      );
      await shareQuotationPdf(bytes: bytes, filename: '${quote.reference ?? 'quotation'}.pdf');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not build PDF: $e')));
    }
  }

  Future<void> _markSent(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark quotation sent?'),
        content: Text('This sets the enquiry quoted amount to ₹${quote.total.toStringAsFixed(0)}.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mark sent')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(quotationsRepositoryProvider)
          .markSent(enquiryId: enquiryId, quoteId: quote.id, actorUid: uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quotation marked sent; quoted amount updated.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not mark sent: $e')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete draft?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(quotationsRepositoryProvider)
          .deleteDraft(enquiryId: enquiryId, quoteId: quote.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }
}
