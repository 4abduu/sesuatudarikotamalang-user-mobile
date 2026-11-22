import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;

/// Safely provides an ImageProvider from a local file path or web blob/network URL,
/// preventing "Unsupported operation: _Namespace" crashes on Flutter Web.
ImageProvider? safeImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  if (kIsWeb) {
    return NetworkImage(path);
  }
  // URL dari Cloudinary/API tetap harus diambil lewat jaringan di Android/iOS.
  // Sebelumnya semua path non-web dipaksa menjadi FileImage, sehingga URL
  // https://... dianggap sebagai nama file lokal dan memunculkan
  // PathNotFoundException.
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  return FileImage(io.File(path));
}
