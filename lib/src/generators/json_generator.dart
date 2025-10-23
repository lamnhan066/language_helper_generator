import 'dart:convert';
import 'dart:io';

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

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

void _exportJsonGeneratedFile(
  Map<String, List<ParsedData>> data,
  String path,
) {
  print('Creating languages json files...');

  final desPath = '$path/language_helper/languages/';
  final desFile = File('${desPath}_generated.json');
  desFile.createSync(recursive: true);
  final map = <String, String>{};
  var index = 0;
  for (final entry in data.entries) {
    map['@path_$index'] = entry.key;
    index += 1;
    for (final text in entry.value) {
      if (text.type == DataType.normal) {
        map[text.noFormatedText] = text.noFormatedText;
      }
    }
  }

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

  final keys = _collectUniqueTexts(data);
  if (keys.isEmpty) return;

  final languagesDir = Directory('$path/language_helper/languages');
  languagesDir.createSync(recursive: true);

  for (final code in languageCodes) {
    if (code.isEmpty) continue;
    final file = File('${languagesDir.path}/$code.json');
    final existed = file.existsSync();
    Map<String, String> existing = {};
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
        existing = {};
      }
    }

    final merged = <String, String>{};
    for (final key in keys) {
      final value = existing[key] ?? 'TODO: Translate text';
      merged[key] = value;
    }

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(merged));
    print(
      '${existed ? 'Updated' : 'Created'} language file: ${file.path}',
    );
  }
}

List<String> _collectUniqueTexts(
  Map<String, List<ParsedData>> data,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final entry in data.entries) {
    for (final parsed in entry.value) {
      if (parsed.type != DataType.normal) continue;
      if (seen.add(parsed.noFormatedText)) {
        result.add(parsed.noFormatedText);
      }
    }
  }
  return result;
}
