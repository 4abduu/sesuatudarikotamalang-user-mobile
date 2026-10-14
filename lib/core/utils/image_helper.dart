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
  return FileImage(io.File(path));
}
