import 'package:cloud_firestore/cloud_firestore.dart';

/// One line on a quotation: description, qty, price, GST and optional discount.
class QuotationLineItem {
  const QuotationLineItem({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.gstPercent = 0,
    this.discount = 0,
    this.catalogId,
  });

  final String description;
  final double quantity;
  final double unitPrice;
  final double gstPercent;

  /// Flat rupee discount on this line (not a percent).
  final double discount;
  final String? catalogId;

  /// (qty × unitPrice) − discount, never below zero.
  double get lineSubtotal {
    final raw = quantity * unitPrice - discount;
    return raw < 0 ? 0 : raw;
  }

  double get gstAmount => lineSubtotal * gstPercent / 100;

  /// Line total including GST.
  double get amount => lineSubtotal + gstAmount;

  Map<String, dynamic> toMap() => {
    'description': description,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'gstPercent': gstPercent,
    'discount': discount,
    'amount': amount,
    if (catalogId != null && catalogId!.isNotEmpty) 'catalogId': catalogId,
  };

  factory QuotationLineItem.fromMap(Map<String, dynamic> data) {
    return QuotationLineItem(
      description: (data['description'] as String?)?.trim() ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 1,
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      gstPercent: (data['gstPercent'] as num?)?.toDouble() ?? 0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0,
      catalogId: data['catalogId'] as String?,
    );
  }

  QuotationLineItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    double? gstPercent,
    double? discount,
    String? catalogId,
  }) {
    return QuotationLineItem(
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      gstPercent: gstPercent ?? this.gstPercent,
      discount: discount ?? this.discount,
      catalogId: catalogId ?? this.catalogId,
    );
  }
}

/// Totals derived from a list of [QuotationLineItem]s.
class QuotationTotals {
  const QuotationTotals({
    required this.subtotal,
    required this.gstTotal,
    required this.discountTotal,
    required this.total,
  });

  final double subtotal;
  final double gstTotal;
  final double discountTotal;
  final double total;

  static QuotationTotals of(Iterable<QuotationLineItem> items) {
    var subtotal = 0.0;
    var gstTotal = 0.0;
    var discountTotal = 0.0;
    for (final item in items) {
      subtotal += item.quantity * item.unitPrice;
      discountTotal += item.discount;
      gstTotal += item.gstAmount;
    }
    final afterDiscount = subtotal - discountTotal;
    return QuotationTotals(
      subtotal: subtotal,
      gstTotal: gstTotal,
      discountTotal: discountTotal,
      total: (afterDiscount < 0 ? 0 : afterDiscount) + gstTotal,
    );
  }
}

/// Draft or sent quotation under `enquiries/{id}/quotations/{quoteId}`.
class Quotation {
  const Quotation({
    required this.id,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.gstTotal,
    required this.discountTotal,
    required this.total,
    this.reference,
    this.notes,
    this.validUntil,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.sentAt,
    this.sentBy,
  });

  static const String statusDraft = 'draft';
  static const String statusSent = 'sent';

  final String id;
  final String status;
  final List<QuotationLineItem> items;
  final double subtotal;
  final double gstTotal;
  final double discountTotal;
  final double total;
  final String? reference;
  final String? notes;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final DateTime? sentAt;
  final String? sentBy;

  bool get isDraft => status == statusDraft;
  bool get isSent => status == statusSent;

  factory Quotation.fromMap(String id, Map<String, dynamic> data) {
    DateTime? date(String key) {
      final v = data[key];
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    final rawItems = data['items'];
    final items = <QuotationLineItem>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map) {
          items.add(QuotationLineItem.fromMap(Map<String, dynamic>.from(row)));
        }
      }
    }

    return Quotation(
      id: id,
      status: (data['status'] as String?) ?? statusDraft,
      items: items,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      gstTotal: (data['gstTotal'] as num?)?.toDouble() ?? 0,
      discountTotal: (data['discountTotal'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      reference: data['reference'] as String?,
      notes: data['notes'] as String?,
      validUntil: date('validUntil'),
      createdAt: date('createdAt'),
      updatedAt: date('updatedAt'),
      createdBy: data['createdBy'] as String?,
      sentAt: date('sentAt'),
      sentBy: data['sentBy'] as String?,
    );
  }

  /// Firestore write body (no id). Totals are recomputed from [items].
  Map<String, dynamic> toMap({required String actorUid, bool creating = false}) {
    final totals = QuotationTotals.of(items);
    return {
      'status': status,
      'reference': reference,
      'items': items.map((e) => e.toMap()).toList(),
      'subtotal': totals.subtotal,
      'gstTotal': totals.gstTotal,
      'discountTotal': totals.discountTotal,
      'total': totals.total,
      'notes': notes,
      'validUntil': validUntil == null ? null : Timestamp.fromDate(validUntil!),
      'updatedAt': FieldValue.serverTimestamp(),
      if (creating) ...{'createdAt': FieldValue.serverTimestamp(), 'createdBy': actorUid},
      if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
      if (sentBy != null) 'sentBy': sentBy,
    };
  }
}

/// Reusable catalog row for quote line items (`catalog/{id}`).
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.description,
    this.unit,
    this.gstPercent = 0,
  });

  final String id;
  final String name;
  final double unitPrice;
  final String? description;
  final String? unit;
  final double gstPercent;

  factory CatalogItem.fromMap(String id, Map<String, dynamic> data) {
    return CatalogItem(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String?,
      unit: data['unit'] as String?,
      gstPercent: (data['gstPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'unitPrice': unitPrice,
    'description': description,
    'unit': unit,
    'gstPercent': gstPercent,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  QuotationLineItem toLineItem({double defaultGst = 0}) => QuotationLineItem(
    description: description?.trim().isNotEmpty == true ? description!.trim() : name,
    quantity: 1,
    unitPrice: unitPrice,
    gstPercent: gstPercent > 0 ? gstPercent : defaultGst,
    catalogId: id,
  );
}
