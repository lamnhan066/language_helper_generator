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
            defaultsTo: 'en',
            valueHelp: 'en,vi',
          )
          ..addFlag(
            'ignore-invalid',
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
    final ignoreCommented = argResult['ignore-invalid'] as bool;
    final result = _generate(path);
    if (result == null) return;
    if (argResult['json']) {
      _exportJson(result, output ?? '$path/../assets/resources', languageCodes);
    } else {
      _createLanguageDataFile(languageCodes, path: output ?? '$path/resources');
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
  /// Create `language_data.dart`
  void _createLanguageDataFile(
    List<String> languageCodes, {
    String path = './lib/resources',
  }) {
    print('Creating `language_data.dart`...');

    final desFile = File('$path/language_helper/language_data.dart');

    // Return if the file already exists
    if (desFile.existsSync()) {
      print('Recreating `language_data.dart`...');
    } else {
      print('Creating `language_data.dart`...');
    }

    desFile.createSync(recursive: true);

    final entriesBuffer = StringBuffer();
    final dedupedCodes = <String>{
      for (final raw in languageCodes)
        if (raw.trim().isNotEmpty) raw.trim(),
    };
    final normalizedCodes = dedupedCodes.toList(growable: false);
    final activeCodes =
        normalizedCodes.isEmpty ? <String>['en'] : normalizedCodes;
    final languageImportList = <String>[];
    final languageImportSet = <String>{};
    final seenEnumNames = <String>{};

    for (final code in activeCodes) {
      final enumName = _languageEnumName(code);
      if (enumName == null || !seenEnumNames.add(enumName)) continue;
      final constName = _languageConstName(code);
      if (constName == 'languageData') continue;
      entriesBuffer.writeln('  LanguageCodes.$enumName: () => $constName,');
      if (languageImportSet.add(code)) {
        languageImportList.add(code);
      }
    }

    if (entriesBuffer.isEmpty) {
      final constName = _languageConstName('en');
      entriesBuffer.writeln('  LanguageCodes.en: () => $constName,');
      if (languageImportSet.add('en')) {
        languageImportList.add('en');
      }
    }

    final fileBuffer =
        StringBuffer()
          ..writeln("import 'package:language_helper/language_helper.dart';")
          ..writeln();

    for (final code in languageImportList) {
      fileBuffer.writeln("import 'languages/$code.dart';");
    }

    fileBuffer
      ..writeln()
      ..writeln('LazyLanguageData languageData = {')
      ..write(entriesBuffer.toString())
      ..writeln('};');

    desFile.writeAsStringSync(
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(fileBuffer.toString()),
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
    if (raw == null || raw.trim().isEmpty) {
      return <String>['en'];
    }
    final codes = <String>{};
    for (final segment in raw.split(',')) {
      final code = segment.trim();
      if (code.isNotEmpty) {
        codes.add(code);
      }
    }
    if (codes.isEmpty) return <String>['en'];
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
          '// Generated by language_helper. Only the values will persist across regenerations.\n'
          '// Valid value types are limited to `String` or `LanguageCodes`.',
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
              existingEntry?.expression ?? _stringLiteral('');
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

  String? _languageEnumName(String code) {
    final sanitized = code.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final parts = sanitized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part.toLowerCase());
    final enumName = parts.join('_');
    if (enumName.isEmpty) return null;
    if (RegExp(r'^[0-9]').hasMatch(enumName)) return null;
    return enumName;
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
