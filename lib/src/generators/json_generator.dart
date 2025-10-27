import 'dart:convert';
import 'dart:io';

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:lite_logger/lite_logger.dart';
import 'package:path/path.dart' as p;

void exportJson(
  Map<String, List<ParsedData>> data,
  String output, {
  List<String> languageCodes = const [],
  LiteLogger? logger,
}) {
  logger ??= LiteLogger(minLevel: LogLevel.debug);
  logger.log('Exporting Json...', LogLevel.step);
  _exportJsonCodes(output, languageCodes, logger);
  _exportJsonLanguageFiles(data, output, languageCodes, logger);
  logger.log('Exported Json', LogLevel.success);
}

void _exportJsonCodes(
  String output,
  List<String> languageCodes,
  LiteLogger logger,
) {
  logger.log('Creating codes.json...', LogLevel.step);

  final desFile = File(p.join(output, 'codes.json'));

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

  logger.log(existed ? 'Updated codes.json' : 'Created codes.json');
}

void _exportJsonLanguageFiles(
  Map<String, List<ParsedData>> data,
  String output,
  List<String> languageCodes,
  LiteLogger logger,
) {
  if (languageCodes.isEmpty) return;

  final languagesDir = Directory(p.join(output, 'data'));
  logger.log('Ensuring directory exists: ${languagesDir.path}', LogLevel.debug);
  languagesDir.createSync(recursive: true);
  logger.log('Directory ensured.', LogLevel.debug);

  for (final code in languageCodes) {
    if (code.isEmpty) continue;
    final file = File(p.join(languagesDir.path, '$code.json'));
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
    logger.log(
      '${existed ? 'Updated' : 'Created'} language file: ${file.path}',
      LogLevel.debug,
    );
  }
  logger.log('Created language files');
}
