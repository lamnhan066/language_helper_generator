import 'dart:convert';
import 'dart:io';

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:path/path.dart' as p;

void exportJson(
  Map<String, List<ParsedData>> data,
  String path, {
  List<String> languageCodes = const [],
}) {
  print('===========================================================');
  print('Exporting Json...');
  _exportJsonCodes(path, languageCodes);
  _exportJsonGeneratedFile(data, path);
  _exportJsonLanguageFiles(data, path, languageCodes);
  print('Exported Json');
  print('===========================================================');
}

void _exportJsonCodes(String path, List<String> languageCodes) {
  print('Creating codes.json...');

  final desFile = File('$path/language_helper/codes.json');

  desFile.parent.createSync(recursive: true);

  final existed = desFile.existsSync();

  final orderedCodes = <String>[];
  final added = <String>{};

  void addCode(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;
    if (added.add(trimmed)) orderedCodes.add(trimmed);
  }

  for (final code in languageCodes) {
    addCode(code);
  }

  if (existed) {
    try {
      final content = desFile.readAsStringSync();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is String) addCode(item);
        }
      }
    } catch (_) {
      // Ignore malformed existing file and rebuild from scratch.
    }
  }

  if (orderedCodes.isEmpty) {
    addCode('en');
  }

  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  desFile.writeAsStringSync(encoder.convert(orderedCodes));

  print(existed ? 'Updated codes.json' : 'Created codes.json');
}

void _exportJsonGeneratedFile(Map<String, List<ParsedData>> data, String path) {
  print('Creating languages json files...');

  final desPath = '$path/language_helper/languages/';
  final desFile = File('${desPath}_generated.json');
  desFile.createSync(recursive: true);
  final map = <String, dynamic>{};
  data.forEach((filePath, values) {
    final relativePath = p.relative(filePath);
    map['@path_$relativePath'] = '';
    for (final text in values) {
      if (text.type == DataType.normal) {
        map[text.noFormatedText] = '';
      }
    }
  });

  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  desFile.writeAsStringSync(encoder.convert(map));

  print('Created languages json files');
}

void _exportJsonLanguageFiles(
  Map<String, List<ParsedData>> data,
  String path,
  List<String> languageCodes,
) {
  if (languageCodes.isEmpty) return;

  final languagesDir = Directory('$path/language_helper/languages');
  languagesDir.createSync(recursive: true);

  for (final code in languageCodes) {
    if (code.isEmpty) continue;
    final file = File('${languagesDir.path}/$code.json');
    final existed = file.existsSync();
    final existing = <String, String>{};
    if (existed) {
      try {
        final content = file.readAsStringSync();
        final decoded = jsonDecode(content);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is String) {
              existing[key] = value;
            }
          });
        }
      } catch (_) {
        existing.clear();
      }
    }

    final merged = <String, String>{};
    final seenTexts = <String>{};

    data.forEach((filePath, values) {
      final relativePath = p.relative(filePath);
      final pathKey = '@path_$relativePath';
      merged[pathKey] = existing[pathKey] ?? '';

      for (final parsed in values) {
        if (parsed.type != DataType.normal) continue;
        if (!seenTexts.add(parsed.noFormatedText)) continue;
        final key = parsed.noFormatedText;
        final value = existing.containsKey(key) ? existing[key]! : '';
        merged[key] = value;
      }
    });

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(merged));
    print('${existed ? 'Updated' : 'Created'} language file: ${file.path}');
  }
}
