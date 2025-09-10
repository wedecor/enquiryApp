String toE164India(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0') && digits.length == 11) return '+91${digits.substring(1)}';
  if (digits.length == 10) return '+91$digits';
  if (digits.startsWith('91') && digits.length == 12) return '+$digits';
  if (digits.startsWith('+')) return digits;
  return '+$digits';
}
