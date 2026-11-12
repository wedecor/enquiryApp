import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../ui/primitives/primitives.dart';
import '../../../settings/domain/app_config.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../data/quotation_pdf.dart';
import '../../data/quotation_pdf_share.dart';
import '../../data/quotations_repository.dart';
import '../../domain/quotation.dart';
import '../quotations_providers.dart';

/// Create or edit a draft quotation for [enquiryId].
class QuotationEditorScreen extends ConsumerStatefulWidget {
  const QuotationEditorScreen({
    super.key,
    required this.enquiryId,
    required this.customerName,
    this.quoteId,
    this.customerPhone,
    this.eventLabel,
  });

  final String enquiryId;
  final String? quoteId;
  final String customerName;
  final String? customerPhone;
  final String? eventLabel;

  @override
  ConsumerState<QuotationEditorScreen> createState() => _QuotationEditorScreenState();
}

class _QuotationEditorScreenState extends ConsumerState<QuotationEditorScreen> {
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  final _lines = <_LineControllers>[];
  DateTime? _validUntil;
  bool _loading = true;
  bool _saving = false;

  /// GST is off by default; turn on to apply company VAT % on lines.
  bool _includeGst = false;
  String? _quoteId;
  String? _error;

  double get _companyGst => ref.read(appGeneralConfigProvider).valueOrNull?.vatPercent ?? 18.0;

  @override
  void initState() {
    super.initState();
    _quoteId = widget.quoteId;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_quoteId != null) {
      final existing = await ref
          .read(quotationsRepositoryProvider)
          .getQuotation(widget.enquiryId, _quoteId!);
      if (existing != null) {
        _referenceController.text = existing.reference ?? '';
        _notesController.text = existing.notes ?? '';
        _validUntil = existing.validUntil;
        for (final item in existing.items) {
          _lines.add(_LineControllers.fromItem(item));
        }
        _includeGst = existing.items.any((i) => i.gstPercent > 0);
      }
    }
    if (_lines.isEmpty) {
      _lines.add(_LineControllers(initialGst: 0));
    }
    if (mounted) setState(() => _loading = false);
  }

  void _setIncludeGst(bool on) {
    setState(() {
      _includeGst = on;
      final rate = on ? _companyGst : 0.0;
      for (final line in _lines) {
        line.gstPercent.text = rate.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _notesController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  List<QuotationLineItem> _buildItems() => _lines
      .map((l) => l.toItem())
      .where((i) => i.description.isNotEmpty)
      .map((i) => _includeGst ? i : i.copyWith(gstPercent: 0))
      .toList();

  QuotationTotals get _totals => QuotationTotals.of(_buildItems());

  Future<void> _save({bool andClose = true}) async {
    final uid = ref.read(currentUserUidProvider);
    if (uid == null) return;
    final items = _buildItems();
    if (items.isEmpty) {
      setState(() => _error = 'Add at least one line with a description.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(quotationsRepositoryProvider);
    try {
      if (_quoteId == null) {
        _quoteId = await repo.createDraft(
          enquiryId: widget.enquiryId,
          actorUid: uid,
          items: items,
          reference: _referenceController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          validUntil: _validUntil,
        );
      } else {
        await repo.updateDraft(
          enquiryId: widget.enquiryId,
          quoteId: _quoteId!,
          actorUid: uid,
          items: items,
          reference: _referenceController.text.trim().isEmpty
              ? null
              : _referenceController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          validUntil: _validUntil,
          status: Quotation.statusDraft,
        );
      }
      if (!mounted) return;
      if (andClose) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _previewPdf() async {
    await _save(andClose: false);
    if (!mounted || _quoteId == null) return;
    final quote = await ref
        .read(quotationsRepositoryProvider)
        .getQuotation(widget.enquiryId, _quoteId!);
    if (quote == null || !mounted) return;
    final company = ref.read(appGeneralConfigProvider).valueOrNull ?? const AppGeneralConfig();
    final bytes = await QuotationPdf.build(
      quotation: quote,
      company: company,
      customerName: widget.customerName,
      customerPhone: widget.customerPhone,
      eventLabel: widget.eventLabel,
    );
    if (!mounted) return;
    await shareQuotationPdf(bytes: bytes, filename: '${quote.reference ?? 'quotation'}.pdf');
  }

  Future<void> _pickCatalog() async {
    final catalog = ref.read(quoteCatalogProvider).valueOrNull ?? const <CatalogItem>[];
    final chosen = await showModalBottomSheet<CatalogItem>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        if (catalog.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppTokens.space5),
            child: Text('No catalog items yet. Add line items manually, or save one from a line.'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: catalog.length,
          itemBuilder: (_, i) {
            final item = catalog[i];
            return ListTile(
              title: Text(item.name),
              subtitle: Text('₹${item.unitPrice.toStringAsFixed(0)}'),
              onTap: () => Navigator.pop(ctx, item),
            );
          },
        );
      },
    );
    if (chosen == null) return;
    final line = chosen.toLineItem(defaultGst: _includeGst ? _companyGst : 0);
    setState(() => _lines.add(_LineControllers.fromItem(line)));
  }

  Future<void> _saveLineToCatalog(_LineControllers line) async {
    final item = line.toItem();
    if (item.description.isEmpty) return;
    await ref
        .read(quotationsRepositoryProvider)
        .upsertCatalogItem(
          CatalogItem(
            id: '',
            name: item.description,
            unitPrice: item.unitPrice,
            gstPercent: item.gstPercent,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to catalog.')));
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_quoteId == null ? 'New quotation' : 'Edit quotation'),
        actions: [
          TextButton(onPressed: _saving ? null : _pickCatalog, child: const Text('Catalog')),
          TextButton(onPressed: _saving || _loading ? null : _previewPdf, child: const Text('PDF')),
          TextButton(
            onPressed: _saving || _loading ? null : () => _save(),
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                Text(
                  widget.customerName,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (widget.eventLabel != null && widget.eventLabel!.isNotEmpty)
                  Text(
                    widget.eventLabel!,
                    style: t.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppTokens.space4),
                TextField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference',
                    hintText: 'Auto if blank',
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Valid until'),
                  subtitle: Text(
                    _validUntil == null
                        ? 'Optional'
                        : DateFormat('d MMM yyyy').format(_validUntil!),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.event),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 14)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) setState(() => _validUntil = picked);
                    },
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include GST'),
                  subtitle: Text(
                    _includeGst
                        ? 'Applying ${_companyGst.toStringAsFixed(0)}% from company settings'
                        : 'Off by default — amounts stay exclusive of tax',
                  ),
                  value: _includeGst,
                  onChanged: _setIncludeGst,
                ),
                const SizedBox(height: AppTokens.space3),
                Text('Line items', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppTokens.space2),
                for (var i = 0; i < _lines.length; i++) ...[
                  GlassPanel(
                    padding: const EdgeInsets.all(AppTokens.space3),
                    child: Column(
                      children: [
                        TextField(
                          controller: _lines[i].description,
                          decoration: const InputDecoration(labelText: 'Description'),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _lines[i].quantity,
                                decoration: const InputDecoration(labelText: 'Qty'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppTokens.space2),
                            Expanded(
                              child: TextField(
                                controller: _lines[i].unitPrice,
                                decoration: const InputDecoration(labelText: 'Rate ₹'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            if (_includeGst) ...[
                              const SizedBox(width: AppTokens.space2),
                              Expanded(
                                child: TextField(
                                  controller: _lines[i].gstPercent,
                                  decoration: const InputDecoration(labelText: 'GST %'),
                                  keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _lines[i].discount,
                                decoration: const InputDecoration(labelText: 'Discount ₹'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                ],
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: AppTokens.space2),
                            Text(
                              money.format(_lines[i].toItem().amount),
                              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              tooltip: 'Save to catalog',
                              onPressed: () => _saveLineToCatalog(_lines[i]),
                              icon: const Icon(Icons.bookmark_add_outlined),
                            ),
                            IconButton(
                              tooltip: 'Remove line',
                              onPressed: _lines.length <= 1
                                  ? null
                                  : () => setState(() {
                                      _lines.removeAt(i).dispose();
                                    }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space3),
                ],
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _lines.add(_LineControllers(initialGst: _includeGst ? _companyGst : 0));
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add line'),
                ),
                const SizedBox(height: AppTokens.space4),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true),
                  maxLines: 3,
                ),
                const SizedBox(height: AppTokens.space4),
                GlassPanel(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Column(
                    children: [
                      _totalRow(context, 'Subtotal', money.format(_totals.subtotal)),
                      if (_totals.discountTotal > 0)
                        _totalRow(context, 'Discount', '- ${money.format(_totals.discountTotal)}'),
                      if (_totals.gstTotal > 0)
                        _totalRow(context, 'GST', money.format(_totals.gstTotal)),
                      const Divider(),
                      _totalRow(context, 'Total', money.format(_totals.total), bold: true),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppTokens.space3),
                  Text(
                    _error!,
                    style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppTokens.space6),
              ],
            ),
    );
  }

  Widget _totalRow(BuildContext context, String label, String value, {bool bold = false}) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _LineControllers {
  _LineControllers({double initialGst = 0})
    : description = TextEditingController(),
      quantity = TextEditingController(text: '1'),
      unitPrice = TextEditingController(text: '0'),
      gstPercent = TextEditingController(text: initialGst.toStringAsFixed(0)),
      discount = TextEditingController(text: '0');

  factory _LineControllers.fromItem(QuotationLineItem item) {
    final c = _LineControllers();
    c.description.text = item.description;
    c.quantity.text = item.quantity % 1 == 0
        ? item.quantity.toStringAsFixed(0)
        : item.quantity.toString();
    c.unitPrice.text = item.unitPrice.toStringAsFixed(0);
    c.gstPercent.text = item.gstPercent.toStringAsFixed(0);
    c.discount.text = item.discount.toStringAsFixed(0);
    return c;
  }

  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController gstPercent;
  final TextEditingController discount;

  QuotationLineItem toItem() => QuotationLineItem(
    description: description.text.trim(),
    quantity: double.tryParse(quantity.text.trim()) ?? 1,
    unitPrice: double.tryParse(unitPrice.text.trim()) ?? 0,
    gstPercent: double.tryParse(gstPercent.text.trim()) ?? 0,
    discount: double.tryParse(discount.text.trim()) ?? 0,
  );

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
    gstPercent.dispose();
    discount.dispose();
  }
}
