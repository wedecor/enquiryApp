/// Customer identity key stored as `phoneNormalized` on every enquiry.
///
/// Rule (must match `normalizePhone` in functions/src/customers.ts and the
/// 2026_10_backfill_phone_normalized migration):
///   1. keep digits only;
///   2. if more than 10 digits remain, keep the last 10 — so `+91 98765 43210`,
///      `0091…`, `09876543210` and `9876543210` all become `9876543210`.
///
/// Shorter numbers (landlines) are kept as-is. Returns '' for null / no digits.
String normalizePhone(String? phone) {
  if (phone == null) return '';
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

/// Number of digits in [phone] (0 for null).
int phoneDigitCount(String? phone) =>
    phone == null ? 0 : phone.replaceAll(RegExp(r'[^0-9]'), '').length;
