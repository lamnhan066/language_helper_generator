import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:args/args.dart';
import 'package:language_helper_generator/src/generators/dart_generator.dart'
    as d;
import 'package:language_helper_generator/src/generators/json_generator.dart'
    as j;
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:language_helper_generator/src/parser/parser.dart';
import 'package:language_helper_generator/src/utils/list_all_files.dart';
import 'package:lite_logger/lite_logger.dart';
import 'package:path/path.dart' as p;

class LanguageHelperGenerator {
  late LiteLogger logger;

  void _log(LogLevel level, String message) => logger.log(message, level);

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
            help: 'Path to the folder that you want to save the output.',
            valueHelp: 'Dart: ./lib/languages, JSON: ./assets/languages',
          )
          ..addOption(
            'languages',
            abbr: 'l',
            help:
                'Generate boilerplate translation files for the provided comma separated language codes.',
            defaultsTo: 'en',
            valueHelp: 'en,vi',
          )
          ..addOption(
            'ignore-todo',
            aliases: ['todo'],
            help:
                'Comma separated language codes that should not receive TODO comments when generating boilerplate.',
            valueHelp: 'en,vi',
          )
          ..addFlag(
            'include-invalid',
            aliases: ['invalid'],
            negatable: false,
            help:
                'Include commented-out duplicated or invalid entries in outputs.',
            defaultsTo: false,
          )
          ..addFlag(
            'dart-format',
            aliases: ['format'],
            help: 'Running `dart format` for the generated files.',
            negatable: false,
            defaultsTo: true,
          )
          ..addFlag(
            'dart-fix',
            aliases: ['fix'],
            negatable: false,
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
          ..addFlag(
            'verbose',
            abbr: 'v',
            help: 'Show verbose logs',
            negatable: false,
            defaultsTo: false,
          )
          ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);
    final argResult = parser.parse(args);

    if (argResult.flag('verbose')) {
      logger = LiteLogger(
        name: 'LanguageHelperGenerator',
        minLevel: LogLevel.debug,
        usePrint: true,
      );
    } else {
      logger = LiteLogger(name: 'LanguageHelperGenerator', usePrint: true);
    }

    _log(LogLevel.info, 'Starting language helper code generation...');

    // Show helps
    if (argResult.flag('help')) {
      _log(LogLevel.info, 'Showing help message.');
      // ignore: avoid_print
      print(parser.usage);
      return;
    }

    _log(LogLevel.info, 'Arguments parsed: $args');

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

    _log(LogLevel.debug, 'Path: $path');
    _log(LogLevel.debug, 'Output: ${output ?? 'default'}');
    _log(LogLevel.debug, 'Languages: ${languageCodes.join(', ')}');
    _log(LogLevel.debug, 'Ignore TODO: ${ignoreTodoCodes.join(', ')}');
    _log(LogLevel.debug, 'Include Invalid: $includeInvalid');
    _log(LogLevel.debug, 'Dart Format: $dartFormat');
    _log(LogLevel.debug, 'Dart Fix: $dartFix');
    _log(LogLevel.debug, 'FVM: $fvm');
    _log(LogLevel.debug, 'Export to JSON: ${argResult['json']}');

    final result = _generate(path, output ?? p.join('.', 'lib', 'languages'));
    if (result == null) {
      _log(LogLevel.error, 'Generation failed: No data parsed.');
      return;
    }
    if (argResult['json']) {
      _log(LogLevel.step, 'Exporting to JSON files...');
      _exportJson(
        result,
        output ?? p.join('.', 'assets', 'languages'),
        languageCodes,
      );
      _log(LogLevel.success, 'JSON export completed.');
    } else {
      _log(LogLevel.step, 'Generating Dart language files...');
      final outputPath = output ?? p.join('.', 'lib', 'languages');
      d.exportDart(
        result,
        outputPath,
        languageCodes,
        includeInvalid: includeInvalid,
        ignoreTodoCodes: ignoreTodoCodes,
        dartFormat: dartFormat,
        dartFix: dartFix,
        fvm: fvm,
        logger: logger,
      );
      _log(LogLevel.success, 'Dart language file generation complete.');
    }
    _log(LogLevel.success, 'Language helper code generation finished.');
  }

  Map<String, List<ParsedData>>? _generate(String path, String outputPath) {
    _log(LogLevel.step, 'Parsing language data from directory: $path...');

    final dir = Directory(path);
    if (!dir.existsSync()) {
      _log(
        LogLevel.error,
        'Error: The specified directory "$path" does not exist.',
      );
      return null;
    }
    _log(LogLevel.info, 'Directory "$path" exists.');

    final List<FileSystemEntity> allFiles = listAllFiles(dir, []);
    AnalysisContextCollection? contextCollection;
    try {
      contextCollection = AnalysisContextCollection(
        includedPaths: [p.normalize(dir.absolute.path)],
      );
      _log(LogLevel.info, 'Analysis context created successfully.');
    } catch (error) {
      _log(
        LogLevel.warning,
        'Warning: Could not create analysis context. Falling back to raw parsing. Error: $error',
      );
    }

    Map<String, List<ParsedData>> result = {};
    _log(
      LogLevel.step,
      'Found ${allFiles.length} files. Starting file analysis...',
    );
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && p.extension(file.path) == '.dart') {
        final normalizedPath = p.normalize(file.absolute.path);

        // Avoid getting data from this folder
        if (normalizedPath.contains(p.normalize(outputPath))) {
          _log(
            LogLevel.debug,
            'Skipping language helper file: $normalizedPath',
          );
          continue;
        }

        _log(LogLevel.debug, 'Parsing file: $normalizedPath');
        final parsed = _parseFile(normalizedPath, contextCollection);
        if (parsed.isEmpty) {
          _log(LogLevel.debug, 'No language data found in $normalizedPath.');
          continue;
        }

        final relativePath = p.relative(
          normalizedPath,
          from: dir.absolute.path,
        );

        result[relativePath] = parsed;
        _log(
          LogLevel.debug,
          'Extracted ${parsed.length} entries from $relativePath.',
        );
      }
    }

    _log(
      LogLevel.success,
      'Finished parsing. Total files with language data: ${result.length}.',
    );

    return result;
  }

  List<ParsedData> parse(String text) {
    List<ParsedData> result = [];
    result.addAll(parses(text));

    return result;
  }

  void _exportJson(
    Map<String, List<ParsedData>> data,
    String output,
    List<String> languageCodes,
  ) {
    _log(
      LogLevel.debug,
      'Exporting JSON with path: $output, language codes: $languageCodes',
    );
    j.exportJson(data, output, languageCodes: languageCodes, logger: logger);
  }

  List<String> _parseLanguageCodes(String? raw) {
    _log(LogLevel.debug, 'Parsing language codes from raw input: "$raw"');
    if (raw == null || raw.trim().isEmpty) {
      _log(LogLevel.warning, 'No language codes provided, defaulting to "en".');
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
      _log(
        LogLevel.warning,
        'Parsed language codes are empty, defaulting to "en".',
      );
      return <String>['en'];
    }
    final parsedCodes = codes.toList()..sort((a, b) => a.compareTo(b));
    _log(LogLevel.debug, 'Successfully parsed language codes: $parsedCodes');
    return parsedCodes;
  }

  Set<String> _parseOptionalLanguageCodes(String? raw) {
    _log(
      LogLevel.debug,
      'Parsing optional language codes for ignore-todo from raw input: "$raw"',
    );
    if (raw == null || raw.trim().isEmpty) {
      _log(
        LogLevel.debug,
        'No optional language codes provided for ignore-todo.',
      );
      return const <String>{};
    }
    final codes = <String>{};
    for (final segment in raw.split(',')) {
      final code = segment.trim();
      if (code.isNotEmpty) {
        codes.add(code);
      }
    }
    _log(LogLevel.debug, 'Successfully parsed optional language codes: $codes');
    return codes;
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
          LogLevel.warning,
          'Warning: Analyzer failed for $filePath. Falling back to raw parsing. Error: $error',
        );
      }
    }
    _log(LogLevel.debug, 'Attempting raw parsing for $filePath.');

    if (parsed != null) {
      return parsed;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      _log(LogLevel.error, 'Error: File $filePath not found for parsing.');
      return const [];
    }
    final data = file.readAsBytesSync();
    _log(LogLevel.debug, 'Successfully read bytes from $filePath.');
    final text = const Utf8Codec().decode(data);
    return parse(text);
  }
}
