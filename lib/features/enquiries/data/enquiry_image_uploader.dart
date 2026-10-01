import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/logging/logger.dart';

/// Uploads enquiry reference images to Firebase Storage under
/// `enquiries/{enquiryId}/images/` and returns their download URLs.
///
/// Moved unchanged out of `EnquiryFormScreen` so the screen is layout-only.
/// A failure on one file is reported through [onError] and the rest continue.
class EnquiryImageUploader {
  const EnquiryImageUploader();

  Future<List<String>> upload(
    String enquiryId,
    List<XFile> images, {
    void Function(XFile file, Object error)? onError,
  }) async {
    final storage = FirebaseStorage.instance;
    final List<String> downloadUrls = [];

    for (final xfile in images) {
      try {
        if (kIsWeb) {
          // For web, use Uint8List for putData
          final bytes = await xfile.readAsBytes();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
          final ref = storage
              .ref()
              .child('enquiries')
              .child(enquiryId)
              .child('images')
              .child(fileName);

          // Set content type based on file extension
          final contentType = contentTypeFor(fileName);

          // Upload with metadata - ensure bytes are Uint8List
          final metadata = SettableMetadata(contentType: contentType, cacheControl: 'max-age=3600');

          // Convert to Uint8List if needed
          final uint8List = bytes;

          final task = await ref.putData(uint8List, metadata);
          final url = await task.ref.getDownloadURL();
          downloadUrls.add(url);
          Log.d('EnquiryFormScreen image uploaded', data: {'fileName': fileName, 'url': url});
        } else {
          // For mobile, use File
          final file = File(xfile.path);
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
          final ref = storage
              .ref()
              .child('enquiries')
              .child(enquiryId)
              .child('images')
              .child(fileName);

          // Set content type
          final contentType = contentTypeFor(fileName);
          final metadata = SettableMetadata(contentType: contentType);

          final task = await ref.putFile(file, metadata);
          final url = await task.ref.getDownloadURL();
          downloadUrls.add(url);
          Log.d('EnquiryFormScreen image uploaded', data: {'fileName': fileName, 'url': url});
        }
      } catch (e) {
        Log.e('Error uploading image ${xfile.name}', error: e);
        onError?.call(xfile, e);
        // Continue with other images
      }
    }

    return downloadUrls;
  }

  @visibleForTesting
  static String contentTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }
}
