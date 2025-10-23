import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:args/args.dart';
import 'package:dart_style/dart_style.dart';
import 'package:language_helper_generator/src/generators/json_generator.dart'
    as j;
import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:language_helper_generator/src/parser/parser.dart';
import 'package:language_helper_generator/src/utils/list_all_files.dart';

class LanguageHelperGenerator {
  void generate(List<String> args) {
    final parser =
        ArgParser()
          ..addOption(
            'path',
            abbr: 'p',
            help:
                'Path to the main folder that you want to to create a base language. Default is `./lib`.',
            valueHelp: './lib',
            defaultsTo: './lib',
          )
          ..addOption(
            'output',
            abbr: 'o',
            help:
                'Path to the folder that you want to save the output. Default --no-json: `--path`; Default --json: ./assets',
            valueHelp: 'Default --no-json: `--path`; Default --json: ./assets',
          )
          ..addOption(
            'lang',
            help:
                'Generate boilerplate translation files for the provided comma separated language codes.',
            valueHelp: 'en,vi',
          )
          ..addFlag('json', abbr: 'j', help: 'Export to json format')
          ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);
    final argResult = parser.parse(args);

    // Show helps
    if (argResult.flag('help')) {
      print(parser.usage);
      return;
    }

    final path = argResult['path'] as String;
    String? output = argResult['output'];
    final languageCodes = _parseLanguageCodes(argResult['lang'] as String?);
    final result = _generate(path);
    if (result == null) return;
    if (argResult['json']) {
      _exportJson(
        result,
        output ?? '$path/../assets/resources',
        languageCodes,
      );
    } else {
      _createLanguageDataAbstractFile(
        result,
        path: output ?? '$path/resources',
      );
      _createLanguageDataFile(output ?? '$path/resources');
      _createLanguageBoilerplateFiles(
        result,
        languageCodes,
        path: output ?? '$path/resources',
      );
    }
  }

  Map<String, List<ParsedData>>? _generate([String path = './lib/']) {
    print('Parsing language data from directory: $path...');

    final dir = Directory(path);
    if (!dir.existsSync()) {
      // ignore: avoid_print
      print('The command run in the wrong directory.');
      return null;
    }

    final List<FileSystemEntity> allFiles = listAllFiles(Directory(path), []);
    AnalysisContextCollection? contextCollection;
    try {
      contextCollection = AnalysisContextCollection(
        includedPaths: [dir.absolute.path],
      );
    } catch (error) {
      // ignore: avoid_print
      print('Warning: Could not create analysis context. Falling back to raw parsing. $error');
    }

    Map<String, List<ParsedData>> result = {};
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && file.path.endsWith('.dart')) {
        // get file path
        final filePath = file.absolute.path;

        // Avoid getting data from this folder
        if (filePath.contains('language_helper/languages')) continue;

        final parsed = _parseFile(filePath, contextCollection);
        if (parsed.isNotEmpty) result[filePath] = parsed;
      }
    }

    print('Parsed.');

    return result;
  }

  List<ParsedData> parse(String text) {
    List<ParsedData> result = [];
    result.addAll(parses(text));

    return result;
  }

  /// Create `_language_data_abstract,dart`
  void _createLanguageDataAbstractFile(
    Map<String, List<ParsedData>> data, {
    String path = './lib/resources',
  }) {
    print('Creating _generated.dart...');

    final desFile = File('$path/language_helper/languages/_generated.dart');
    desFile.createSync(recursive: true);

    StringBuffer languageData = StringBuffer();
    final listAllUniqueText = <ParsedData>{};
    data.forEach((key, values) {
      // Comment file path when move to new file
      languageData.writeln('');
      languageData.writeln(
        '  ///===========================================================================',
      );
      languageData.writeln('  /// Path: $key');
      languageData.writeln(
        '  ///===========================================================================',
      );
      languageData.writeln("\"@path_$key\": '',");

      // Map should contains unique key => comment all duppicated keys
      for (final parsed in values) {
        // Check if the text is duplicate or abnormal. If yes then add comment.
        String needsComment = '';
        String needsEndComment = '';
        if (parsed.type != DataType.normal) {
          needsComment = '// ';
          needsEndComment = '  // ${parsed.type.text}';
          // ignore: avoid_print
          print(
            '>> Path: $key => Text: ${parsed.text} => Reason: ${parsed.type.text}',
          );
        } else {
          if (listAllUniqueText.contains(parsed)) {
            needsComment = '// ';
            needsEndComment = '  // Duplicated';
          } else {
            listAllUniqueText.add(parsed);
          }
        }

        languageData.writeln(
          '  $needsComment${parsed.text}: ${parsed.text},$needsEndComment',
        );
      }
    });

    final date = DateTime.now();
    final result = '''
//==============================================================================
// Generated Date: ${date.toIso8601String()}
//
// Generated By language_helper - Do Not Modify By Hand
//==============================================================================

// ignore_for_file: prefer_single_quotes

part of '../language_data.dart';

const analysisLanguageData = <String, dynamic>{$languageData};
''';

    desFile.writeAsStringSync(
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(result),
    );

    print('Created _generated.dart');
  }

  /// Create `language_data.dart`
  void _createLanguageDataFile([String path = './lib/resources']) {
    print('Creating `language_data.dart`...');

    final desFile = File('$path/language_helper/language_data.dart');

    // Return if the file already exists
    if (desFile.existsSync()) {
      print('The `language_data.dart` existed => Done');
      return;
    }

    desFile.createSync(recursive: true);

    const result = '''
import 'package:language_helper/language_helper.dart';

part 'languages/_generated.dart';

LanguageData languageData = {
  // TODO: You can use this data as your main language, remember to change [LanguageCodes.en] to your base language code
  LanguageCodes.en: analysisLanguageData,
};
''';

    desFile.writeAsStringSync(
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(result),
    );

    print('Created `language_data.dart`');
  }

  void _exportJson(
    Map<String, List<ParsedData>> data,
    String path,
    List<String> languageCodes,
  ) {
    j.exportJson(
      data,
      path,
      languageCodes: languageCodes,
    );
  }

  List<String> _parseLanguageCodes(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    final codes = <String>{};
    for (final segment in raw.split(',')) {
      final code = segment.trim();
      if (code.isNotEmpty) {
        codes.add(code);
      }
    }
    return codes.toList();
  }

  void _createLanguageBoilerplateFiles(
    Map<String, List<ParsedData>> data,
    List<String> languageCodes, {
    required String path,
  }) {
    if (languageCodes.isEmpty) return;

    final entries = _collectUniqueTexts(data);
    if (entries.isEmpty) return;

    final languagesDir = Directory('$path/language_helper/languages');
    languagesDir.createSync(recursive: true);

    for (final code in languageCodes) {
      if (code.isEmpty) continue;
      final file = File('${languagesDir.path}/$code.dart');
      final existing = _readExistingDartLanguageFile(file);
      final buffer = StringBuffer()
        ..writeln('//==============================================================================')
        ..writeln('// Generated by language_helper_generator')
        ..writeln('//==============================================================================')
        ..writeln()
        ..writeln(
          'const ${_languageConstName(code)} = <String, String>{',
        );

      for (final parsed in entries) {
        final key = parsed.noFormatedText;
        final encodedKey = json.encode(key);
        final existingValue = existing.translations[key];
        final value = existingValue ?? key;
        final encodedValue = json.encode(value);
        final hasExistingTodo = existing.todoKeys.contains(key);
        final isPlaceholder = existingValue == null || existingValue == key;
        final needsTodo =
            existingValue == null || (hasExistingTodo && isPlaceholder);
        if (needsTodo) {
          buffer.writeln('  // TODO: Translate text');
        }
        buffer.writeln('  $encodedKey: $encodedValue,');
      }

      buffer.writeln('};');

      final fileContent = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(buffer.toString());

      file.writeAsStringSync(fileContent);
    }
  }

  List<ParsedData> _collectUniqueTexts(
    Map<String, List<ParsedData>> data,
  ) {
    final seen = <String>{};
    final result = <ParsedData>[];
    for (final entry in data.entries) {
      for (final parsed in entry.value) {
        if (parsed.type != DataType.normal) continue;
        if (seen.contains(parsed.noFormatedText)) continue;
        seen.add(parsed.noFormatedText);
        result.add(parsed);
      }
    }
    return result;
  }

  List<ParsedData> _parseFile(
    String filePath,
    AnalysisContextCollection? contextCollection,
  ) {
    List<ParsedData>? parsed;
    if (contextCollection != null) {
      try {
        final context = contextCollection.contextFor(filePath);
        final session = context.currentSession;
        final unit = session.getParsedUnit(filePath);
        if (unit is ParsedUnitResult) {
          parsed = parseCompilationUnit(unit.unit);
        }
      } catch (error) {
        // ignore: avoid_print
        print('Warning: Analyzer failed for $filePath. Falling back to raw parsing. $error');
      }
    }

    if (parsed != null) {
      return parsed;
    }

    final file = File(filePath);
    if (!file.existsSync()) return const [];
    final data = file.readAsBytesSync();
    final text = const Utf8Codec().decode(data);
    return parse(text);
  }

  _ExistingLanguageFile _readExistingDartLanguageFile(File file) {
    if (!file.existsSync()) {
      return _ExistingLanguageFile();
    }

    final lines = file.readAsLinesSync();
    final translations = <String, String>{};
    final todoKeys = <String>{};
    final entryRegex =
        RegExp(r'"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"');

    bool pendingTodoComment = false;

    for (final rawLine in lines) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final isCommentLine = trimmed.startsWith('//');
      final containsTodo =
          trimmed.contains('// TODO: Translate text');
      if (isCommentLine) {
        if (containsTodo) pendingTodoComment = true;
        continue;
      }

      var line = trimmed;
      bool inlineTodo = false;
      if (containsTodo) {
        inlineTodo = true;
        line = line.split('//').first.trimRight();
      }
      if (line.endsWith(',')) {
        line = line.substring(0, line.length - 1);
      }

      final match = entryRegex.firstMatch(line);
      if (match == null) continue;

      final key = json.decode('"${match.group(1)!}"') as String;
      final value = json.decode('"${match.group(2)!}"') as String;
      translations[key] = value;
      if (inlineTodo || pendingTodoComment) todoKeys.add(key);
      pendingTodoComment = false;
    }

    return _ExistingLanguageFile(
      translations: translations,
      todoKeys: todoKeys,
    );
  }

  String _languageConstName(String code) {
    final sanitized = code.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    if (sanitized.isEmpty) return 'languageData';

    final parts = sanitized
        .split('_')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'languageData';

    final buffer = StringBuffer(parts.first.toLowerCase());
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) continue;
      buffer.write(part.substring(0, 1).toUpperCase());
      if (part.length > 1) {
        buffer.write(part.substring(1).toLowerCase());
      }
    }

    buffer.write('LanguageData');
    return buffer.toString();
  }

  /// This file should not be generated. Just add a doc to let users know
  /// how to add the `analysisLanguageData.keys` to `analysisKeys`
  /// in the `initial` of language_helper
  void createLanguageHelperFile() {
    final desFile = File(
      './lib/services/language_helper/language_helper.g.dart',
    );

    // Return if the file already exists
    if (desFile.existsSync()) return;

    desFile.createSync(recursive: true);

    const data = '''
import 'package:flutter/foundation.dart';
import 'package:language_helper/language_helper.dart';

import '../../resources/language_helper/language_data.g.dart';

final languageHelper = LanguageHelper.instance;

Future<void> languageHelperInitial() async {
  languageHelper.initial(
    data: languageData,
    analysisKeys: analysisLanguageData.keys,
    initialCode: LanguageCodes.en,
    isDebug: !kReleaseMode,
  );
}
''';

    desFile.writeAsStringSync(data);
  }
}

class _ExistingLanguageFile {
  final Map<String, String> translations;
  final Set<String> todoKeys;

  _ExistingLanguageFile({
    Map<String, String>? translations,
    Set<String>? todoKeys,
  })  : translations = translations ?? <String, String>{},
        todoKeys = todoKeys ?? <String>{};
}
