import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:args/args.dart';
import 'package:dart_style/dart_style.dart';
import 'package:language_helper_generator/src/generators/json_generator.dart'
    as j;
import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:language_helper_generator/src/parser/parser.dart';
import 'package:language_helper_generator/src/utils/list_all_files.dart';
import 'package:language_helper_generator/src/utils/todo_comment.dart';
import 'package:path/path.dart' as p;

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
          ..addFlag(
            'ignore-commented',
            help:
                'Ignore commented-out duplicated or invalid entries in outputs.',
            defaultsTo: false,
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
    final ignoreCommented = argResult['ignore-commented'] as bool;
    final result = _generate(path);
    if (result == null) return;
    if (argResult['json']) {
      _exportJson(result, output ?? '$path/../assets/resources', languageCodes);
    } else {
      _createLanguageDataAbstractFile(
        result,
        path: output ?? '$path/resources',
        ignoreCommented: ignoreCommented,
      );
      _createLanguageDataFile(output ?? '$path/resources');
      _createLanguageBoilerplateFiles(
        result,
        languageCodes,
        path: output ?? '$path/resources',
        ignoreCommented: ignoreCommented,
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

    final List<FileSystemEntity> allFiles = listAllFiles(dir, []);
    AnalysisContextCollection? contextCollection;
    try {
      contextCollection = AnalysisContextCollection(
        includedPaths: [p.normalize(dir.absolute.path)],
      );
    } catch (error) {
      // ignore: avoid_print
      print(
        'Warning: Could not create analysis context. Falling back to raw parsing. $error',
      );
    }

    Map<String, List<ParsedData>> result = {};
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && file.path.endsWith('.dart')) {
        final normalizedPath = p.normalize(file.absolute.path);

        // Avoid getting data from this folder
        if (normalizedPath.contains('language_helper/languages')) continue;

        final parsed = _parseFile(normalizedPath, contextCollection);
        if (parsed.isEmpty) continue;

        final relativePath = p.relative(
          normalizedPath,
          from: dir.absolute.path,
        );

        result[relativePath] = parsed;
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
    bool ignoreCommented = false,
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

        if (needsComment.isNotEmpty && ignoreCommented) continue;

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
    j.exportJson(data, path, languageCodes: languageCodes);
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
    bool ignoreCommented = false,
  }) {
    if (languageCodes.isEmpty) return;

    final languagesDir = Directory('$path/language_helper/languages');
    languagesDir.createSync(recursive: true);

    for (final code in languageCodes) {
      if (code.isEmpty) continue;
      final file = File('${languagesDir.path}/$code.dart');
      final existing = _readExistingDartLanguageFile(file);
      final date = DateTime.now().toIso8601String();
      final seenTexts = <ParsedData>{};
      final buffer = StringBuffer();

      buffer
        ..writeln(
          '//==============================================================================',
        )
        ..writeln('// Generated Date: $date')
        ..writeln('//')
        ..writeln(
          '// Generated By language_helper - You can freely edit this file',
        )
        ..writeln(
          '//==============================================================================',
        )
        ..writeln()
        ..writeln('// ignore_for_file: prefer_single_quotes');

      if (existing.imports.isNotEmpty) {
        for (final import in existing.imports) {
          buffer.writeln(import);
        }
        buffer.writeln();
      }

      buffer
        ..writeln()
        ..writeln(
          '${existing.declarationKeyword} ${_languageConstName(code)} = <String, dynamic>{',
        );

      data.forEach((filePath, values) {
        final pathKey = '@path_$filePath';
        final pathKeyLiteral = _stringLiteral(pathKey);
        final pathEntry = existing.entries[pathKey];
        final pathValueExpression = pathEntry?.expression ?? _stringLiteral('');

        buffer
          ..writeln()
          ..writeln(
            '  ///===========================================================================',
          )
          ..writeln('  /// Path: $filePath')
          ..writeln(
            '  ///===========================================================================',
          );

        buffer.writeln('  $pathKeyLiteral: $pathValueExpression,');

        for (final parsed in values) {
          final key = parsed.noFormatedText;
          final keyLiteral = _stringLiteral(key);
          final existingEntry = existing.entries[key];
          final valueExpression =
              existingEntry?.expression ?? _stringLiteral(key);
          final existingStringValue = existingEntry?.stringValue;

          String commentPrefix = '';
          String commentSuffix = '';
          bool commentOut = false;

          if (parsed.type != DataType.normal) {
            commentOut = true;
            commentPrefix = '// ';
            commentSuffix = '  // ${parsed.type.text}';
          } else if (!seenTexts.add(parsed)) {
            commentOut = true;
            commentPrefix = '// ';
            commentSuffix = '  // Duplicated';
          }

          if (commentOut) {
            if (ignoreCommented) {
              continue;
            }
            buffer.writeln(
              '  $commentPrefix$keyLiteral: $valueExpression,$commentSuffix',
            );
            continue;
          }

          final hasExistingTodo = existing.todoKeys.contains(key);
          final isPlaceholder =
              existingEntry == null ||
              (existingStringValue != null &&
                  (existingStringValue.isEmpty || existingStringValue == key));
          final needsTodo =
              (existingEntry == null || (hasExistingTodo && isPlaceholder)) &&
              !key.startsWith('@path_');

          if (needsTodo) {
            buffer.writeln('  ${todoComment(code)}');
          }
          buffer.writeln('  $keyLiteral: $valueExpression,');
        }
      });

      buffer.writeln('};');

      final fileContent = DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(buffer.toString());

      file.writeAsStringSync(fileContent);
    }
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
        print(
          'Warning: Analyzer failed for $filePath. Falling back to raw parsing. $error',
        );
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

    final content = file.readAsStringSync();
    final parseResult = parseString(content: content);
    final unit = parseResult.unit;

    final imports =
        unit.directives
            .whereType<ImportDirective>()
            .map((directive) => directive.toSource())
            .toList();

    final entries = <String, _ExistingEntry>{};
    String declarationKeyword = 'const';

    for (final declaration in unit.declarations) {
      if (declaration is! TopLevelVariableDeclaration) continue;
      final variableList = declaration.variables;
      final keyword = variableList.keyword?.lexeme;

      for (final variable in variableList.variables) {
        final initializer = variable.initializer;
        if (initializer is! SetOrMapLiteral) continue;
        final hasMapEntry = initializer.elements.any(
          (element) => element is MapLiteralEntry,
        );
        if (!hasMapEntry) continue;

        if (keyword == 'final') {
          declarationKeyword = 'final';
        } else if (keyword == 'const') {
          declarationKeyword = 'const';
        }

        for (final element in initializer.elements) {
          if (element is! MapLiteralEntry) continue;
          final keyLiteral = element.key;
          if (keyLiteral is! StringLiteral) continue;
          final key = keyLiteral.stringValue;
          if (key == null) continue;

          final value = element.value;
          final expression = value.toSource();
          String? stringValue;
          if (value is StringLiteral) {
            stringValue = value.stringValue;
          }

          entries[key] = _ExistingEntry(
            expression: expression,
            stringValue: stringValue,
          );
        }

        break;
      }
    }

    final todoKeys = <String>{};
    final keyRegex = RegExp(r'"((?:[^"\\]|\\.)*)"\s*:');
    bool pendingTodoComment = false;

    for (final rawLine in content.split('\n')) {
      final trimmed = rawLine.trim();
      if (trimmed.isEmpty) continue;

      final containsTodo = containsTodoComment(trimmed);
      final isCommentLine = trimmed.startsWith('//');

      if (isCommentLine) {
        if (containsTodo) pendingTodoComment = true;
        continue;
      }

      var line = trimmed;
      if (containsTodo) {
        line = line.split('//').first.trimRight();
      }

      final match = keyRegex.firstMatch(line);
      if (match == null) continue;

      final key = json.decode('"${match.group(1)!}"') as String;
      if (containsTodo || pendingTodoComment) {
        todoKeys.add(key);
        pendingTodoComment = false;
      } else {
        pendingTodoComment = false;
      }
    }

    return _ExistingLanguageFile(
      entries: entries,
      todoKeys: todoKeys,
      declarationKeyword: declarationKeyword,
      imports: imports,
    );
  }

  String _stringLiteral(String value) => json.encode(value);

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
  final Map<String, _ExistingEntry> entries;
  final Set<String> todoKeys;
  final String declarationKeyword;
  final List<String> imports;

  _ExistingLanguageFile({
    Map<String, _ExistingEntry>? entries,
    Set<String>? todoKeys,
    String? declarationKeyword,
    List<String>? imports,
  }) : entries = entries ?? <String, _ExistingEntry>{},
       todoKeys = todoKeys ?? <String>{},
       declarationKeyword = declarationKeyword ?? 'const',
       imports = imports ?? <String>[];
}

class _ExistingEntry {
  final String expression;
  final String? stringValue;

  _ExistingEntry({required this.expression, this.stringValue});
}
