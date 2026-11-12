import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to a temp PDF and opens the platform share sheet.
Future<void> shareQuotationPdf({required Uint8List bytes, required String filename}) async {
  final safeName = filename.toLowerCase().endsWith('.pdf') ? filename : '$filename.pdf';
  if (kIsWeb) {
    await Share.shareXFiles([
      XFile.fromData(bytes, mimeType: 'application/pdf', name: safeName),
    ], text: safeName);
    return;
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$safeName');
  await file.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')], text: safeName);
}
