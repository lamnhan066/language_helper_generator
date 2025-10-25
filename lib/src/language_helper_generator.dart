import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:args/args.dart';
import 'package:language_helper_generator/src/generators/json_generator.dart'
    as j;
import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:language_helper_generator/src/parser/parser.dart';
import 'package:language_helper_generator/src/utils/list_all_files.dart';
import 'package:language_helper_generator/src/utils/todo_comment.dart';
import 'package:path/path.dart' as p;

class LanguageHelperGenerator {
  void _log(String message) {
    // ignore: avoid_print
    print('[LanguageHelperGenerator] $message');
  }

  void generate(List<String> args) {
    _log('Starting language helper code generation...');
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
            'languages',
            help:
                'Generate boilerplate translation files for the provided comma separated language codes.',
            defaultsTo: 'en',
            valueHelp: 'en,vi',
          )
          ..addOption(
            'ignore-todo',
            help:
                'Comma separated language codes that should not receive TODO comments when generating boilerplate.',
            valueHelp: 'en,vi',
          )
          ..addFlag(
            'include-invalid',
            negatable: false,
            help:
                'Include commented-out duplicated or invalid entries in outputs.',
            defaultsTo: false,
          )
          ..addFlag(
            'dart-format',
            help: 'Running `dart format` for the generated files.',
            defaultsTo: true,
          )
          ..addFlag(
            'dart-fix',
            help: 'Running `dart fix --apply` for the generated files.',
            defaultsTo: true,
          )
          ..addFlag(
            'fvm',
            help: 'Should use `fvm` prefix when running the `dart` commands',
            defaultsTo: false,
          )
          ..addFlag(
            'json',
            defaultsTo: false,
            help: 'Export translations to JSON files instead of Dart files.',
          )
          ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);
    final argResult = parser.parse(args);

    // Show helps
    if (argResult.flag('help')) {
      _log('Showing help message.');
      // ignore: avoid_print
      print(parser.usage);
      return;
    }

    _log('Arguments parsed: $args');

    final path = argResult['path'] as String;
    String? output = argResult['output'];
    final languageCodes = _parseLanguageCodes(
      argResult['languages'] as String?,
    );
    final ignoreTodoCodes = _parseOptionalLanguageCodes(
      argResult['ignore-todo'] as String?,
    );
    final includeInvalid = argResult['include-invalid'] as bool;
    final dartFormat = argResult['dart-format'] as bool;
    final dartFix = argResult['dart-fix'] as bool;
    final fvm = argResult['fvm'] as bool;

    _log('Path: $path');
    _log('Output: ${output ?? 'default'}');
    _log('Languages: ${languageCodes.join(', ')}');
    _log('Ignore TODO: ${ignoreTodoCodes.join(', ')}');
    _log('Include Invalid: $includeInvalid');
    _log('Dart Format: $dartFormat');
    _log('Dart Fix: $dartFix');
    _log('FVM: $fvm');
    _log('Export to JSON: ${argResult['json']}');

    final result = _generate(path);
    if (result == null) {
      _log('Generation failed: No data parsed.');
      return;
    }
    if (argResult['json']) {
      _log('Exporting to JSON files...');
      _exportJson(result, output ?? '$path/../assets/resources', languageCodes);
      _log('JSON export complete.');
    } else {
      _log('Generating Dart language files...');
      final date = DateTime.now().toIso8601String();
      final outputPath = output ?? '$path/resources';
      _createLanguageDataFile(languageCodes, path: outputPath, date: date);
      _createLanguageBoilerplateFiles(
        result,
        languageCodes,
        path: outputPath,
        includeInvalid: includeInvalid,
        ignoreTodoCodes: ignoreTodoCodes,
        date: date,
      );

      if (dartFormat) {
        _log('Running dart format on $outputPath...');
        if (fvm) {
          Process.runSync('fvm', ['dart', 'format', outputPath]);
        } else {
          Process.runSync('dart', ['format', outputPath]);
        }
        _log('Dart format complete.');
      }
      if (dartFix) {
        _log('Running dart fix --apply on $outputPath...');
        if (fvm) {
          Process.runSync('fvm', ['dart', 'fix', outputPath, '--apply']);
        } else {
          Process.runSync('dart', ['fix', outputPath, '--apply']);
        }
        _log('Dart fix complete.');
      }
      _log('Dart language file generation complete.');
    }
    _log('Language helper code generation finished.');
  }

  Map<String, List<ParsedData>>? _generate([String path = './lib/']) {
    _log('Parsing language data from directory: $path...');

    final dir = Directory(path);
    if (!dir.existsSync()) {
      _log('Error: The specified directory "$path" does not exist.');
      return null;
    }
    _log('Directory "$path" exists.');

    final List<FileSystemEntity> allFiles = listAllFiles(dir, []);
    AnalysisContextCollection? contextCollection;
    try {
      contextCollection = AnalysisContextCollection(
        includedPaths: [p.normalize(dir.absolute.path)],
      );
      _log('Analysis context created successfully.');
    } catch (error) {
      _log(
        'Warning: Could not create analysis context. Falling back to raw parsing. Error: $error',
      );
    }

    Map<String, List<ParsedData>> result = {};
    _log('Found ${allFiles.length} files. Starting file analysis...');
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && file.path.endsWith('.dart')) {
        final normalizedPath = p.normalize(file.absolute.path);

        // Avoid getting data from this folder
        if (normalizedPath.contains('language_helper/languages')) {
          _log('Skipping language helper file: $normalizedPath');
          continue;
        }

        _log('Parsing file: $normalizedPath');
        final parsed = _parseFile(normalizedPath, contextCollection);
        if (parsed.isEmpty) {
          _log('No language data found in $normalizedPath.');
          continue;
        }

        final relativePath = p.relative(
          normalizedPath,
          from: dir.absolute.path,
        );

        result[relativePath] = parsed;
        _log('Extracted ${parsed.length} entries from $relativePath.');
      }
    }

    _log('Finished parsing. Total files with language data: ${result.length}.');

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
    required String date,
  }) {
    _log(
      'Starting creation of `language_data.dart` at $path/language_helper/language_data.dart...',
    );

    final desFile = File('$path/language_helper/language_data.dart');

    if (desFile.existsSync()) {
      _log('File `language_data.dart` already exists. Recreating...');
    } else {
      _log('File `language_data.dart` does not exist. Creating new file...');
    }

    desFile.createSync(recursive: true);
    _log('Directory for `language_data.dart` ensured.');

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
          ..writeln(
            '//==============================================================================',
          )
          ..writeln('// Generated Date: $date')
          ..writeln('//')
          ..writeln(
            '// Generated by language_helper. Please do not modify by hand',
          )
          ..writeln(
            '//==============================================================================',
          )
          ..writeln()
          ..writeln('// Keeps format for the parser')
          ..writeln('// ignore_for_file: always_use_package_imports')
          ..writeln()
          ..writeln("import 'package:language_helper/language_helper.dart';")
          ..writeln();

    for (final code in languageImportList) {
      fileBuffer.writeln("import 'languages/$code.dart';");
    }

    fileBuffer
      ..writeln()
      ..writeln('final LazyLanguageData languageData = {')
      ..write(entriesBuffer.toString())
      ..writeln('};');

    desFile.writeAsStringSync(fileBuffer.toString());

    _log('Successfully created `language_data.dart`.');
  }

  void _exportJson(
    Map<String, List<ParsedData>> data,
    String path,
    List<String> languageCodes,
  ) {
    _log('Exporting JSON with path: $path, language codes: $languageCodes');
    j.exportJson(data, path, languageCodes: languageCodes);
    _log('JSON export completed.');
  }

  List<String> _parseLanguageCodes(String? raw) {
    _log('Parsing language codes from raw input: "$raw"');
    if (raw == null || raw.trim().isEmpty) {
      _log('No language codes provided, defaulting to "en".');
      return <String>['en'];
    }
    final codes = <String>{};
    for (final segment in raw.split(',')) {
      final code = segment.trim();
      if (code.isNotEmpty) {
        codes.add(code);
      }
    }
    if (codes.isEmpty) {
      _log('Parsed language codes are empty, defaulting to "en".');
      return <String>['en'];
    }
    final parsedCodes = codes.toList()..sort((a, b) => a.compareTo(b));
    _log('Successfully parsed language codes: $parsedCodes');
    return parsedCodes;
  }

  Set<String> _parseOptionalLanguageCodes(String? raw) {
    _log(
      'Parsing optional language codes for ignore-todo from raw input: "$raw"',
    );
    if (raw == null || raw.trim().isEmpty) {
      _log('No optional language codes provided for ignore-todo.');
      return const <String>{};
    }
    final codes = <String>{};
    for (final segment in raw.split(',')) {
      final code = segment.trim();
      if (code.isNotEmpty) {
        codes.add(code);
      }
    }
    _log('Successfully parsed optional language codes: $codes');
    return codes;
  }

  void _createLanguageBoilerplateFiles(
    Map<String, List<ParsedData>> data,
    List<String> languageCodes, {
    required String path,
    bool includeInvalid = true,
    Set<String> ignoreTodoCodes = const <String>{},
    required String date,
  }) {
    _log(
      'Starting creation of language boilerplate files at $path/language_helper/languages...',
    );
    if (languageCodes.isEmpty) {
      _log(
        'No language codes provided for boilerplate file creation. Skipping.',
      );
      return;
    }

    final languagesDir = Directory('$path/language_helper/languages');
    _log('Ensuring directory exists: ${languagesDir.path}');
    languagesDir.createSync(recursive: true);
    _log('Directory ensured.');

    for (final code in languageCodes) {
      if (code.isEmpty) {
        _log('Skipping empty language code.');
        continue;
      }
      _log('Processing language code: $code');
      final file = File('${languagesDir.path}/$code.dart');
      _log('Reading existing language file for $code: ${file.path}');
      final existing = _readExistingDartLanguageFile(file);
      _log('Finished reading existing language file for $code.');
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
        ..writeln('// Keeps format for the parser')
        ..writeln('// ignore_for_file: prefer_single_quotes');

      if (existing.imports.isNotEmpty) {
        buffer.writeln();
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
          final valueExpression = existingEntry?.expression ?? keyLiteral;
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
            if (includeInvalid) {
              buffer.writeln(
                '  $commentPrefix$keyLiteral: $valueExpression,$commentSuffix',
              );
            }
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

          if (needsTodo && !ignoreTodoCodes.contains(code)) {
            buffer.writeln('  ${todoComment(code)}');
          }
          buffer.writeln('  $keyLiteral: $valueExpression,');
        }
      });

      buffer.writeln('};');

      _log('Writing content to file: ${file.path}');
      file.writeAsStringSync(buffer.toString());
      _log('Successfully created boilerplate file for language code: $code');
    }
    _log('Finished creating all language boilerplate files.');
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
        _log(
          'Warning: Analyzer failed for $filePath. Falling back to raw parsing. Error: $error',
        );
      }
    }
    _log('Attempting raw parsing for $filePath.');

    if (parsed != null) {
      return parsed;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      _log('Error: File $filePath not found for parsing.');
      return const [];
    }
    final data = file.readAsBytesSync();
    _log('Successfully read bytes from $filePath.');
    final text = const Utf8Codec().decode(data);
    return parse(text);
  }

  _ExistingLanguageFile _readExistingDartLanguageFile(File file) {
    _log('Attempting to read existing Dart language file: ${file.path}');
    if (!file.existsSync()) {
      _log(
        'File does not exist: ${file.path}. Returning empty _ExistingLanguageFile.',
      );
      return _ExistingLanguageFile();
    }

    final content = file.readAsStringSync();
    _log('File content read for: ${file.path}.');
    final parseResult = parseString(content: content);
    final unit = parseResult.unit;
    _log('File parsed into AST unit.');

    final imports =
        unit.directives
            .whereType<ImportDirective>()
            .map((directive) => directive.toSource())
            .toList();
    _log('Extracted ${imports.length} imports.');

    final entries = <String, _ExistingEntry>{};
    String declarationKeyword = 'const';
    _log('Starting to extract existing entries and declaration keyword.');

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

    _log(
      'Finished extracting existing entries. Declaration keyword: $declarationKeyword.',
    );

    final todoKeys = <String>{};
    final keyRegex = RegExp(r'"((?:[^"\\]|\\.)*)"\s*:');
    bool pendingTodoComment = false;
    _log('Starting to identify TODO comments and associated keys.');

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

    _log(
      'Finished identifying TODO comments. Found ${todoKeys.length} TODO keys.',
    );

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
