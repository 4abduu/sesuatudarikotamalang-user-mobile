import 'dart:io';

const forbidden = <String, List<String>>{
  'view': [
    'data/repositories',
    'data/services',
    'core/network/api_service',
    'core/network/api_client',
    'core/network/upload_api',
    'shared_preferences',
    'package:http/',
  ],
  'viewmodel': [
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    'package:go_router',
    '/view/',
    'shared_preferences',
    'package:http/',
  ],
  'repository': [
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    '/viewmodel/',
    '/view/',
  ],
  'model': [
    'package:flutter/material.dart',
    'package:flutter/widgets.dart',
    '/viewmodel/',
    '/view/',
    'data/repositories',
  ],
};

String? layerOf(String path) {
  if (path.contains('/viewmodel/')) {
    return 'viewmodel';
  }
  if (path.contains('/view/') ||
      path.startsWith('lib/core/widgets/') ||
      path.startsWith('lib/shared/')) {
    return 'view';
  }
  if (path.startsWith('lib/data/repositories/')) {
    return 'repository';
  }
  if (path.startsWith('lib/data/models/')) {
    return 'model';
  }
  return null;
}

void main(List<String> args) {
  final strict = args.contains('--strict');
  final prefixes = args
      .where((arg) => !arg.startsWith('--'))
      .map((arg) => arg.replaceAll('\\', '/'))
      .toList();
  final violations = <String>[];
  for (final entity
      in Directory('lib').listSync(recursive: true).whereType<File>()) {
    final path = entity.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart') ||
        (prefixes.isNotEmpty && !prefixes.any(path.startsWith))) {
      continue;
    }
    final layer = layerOf(path);
    if (layer == null) {
      continue;
    }
    final rules = forbidden[layer]!;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('import ') && !line.startsWith('export ')) {
        continue;
      }
      for (final bad in rules) {
        // PagedState adalah state generik, bukan ViewModel fitur. Repository
        // boleh memakai hasil halaman bertipe ini.
        if (layer == 'repository' &&
            bad == '/viewmodel/' &&
            line.contains('core/viewmodel/paged_state')) {
          continue;
        }
        if (line.contains(bad)) {
          violations.add('$path:${i + 1} [$layer] dilarang "$bad"');
        }
      }
      if (strict &&
          layer == 'view' &&
          line.contains('core/network/api_exception')) {
        violations.add('$path:${i + 1} [view] dilarang memakai ApiException');
      }
    }
  }
  if (violations.isEmpty) {
    stdout.writeln('OK: 0 pelanggaran batas lapisan.');
  } else {
    violations.forEach(stdout.writeln);
    exitCode = 1;
  }
}
