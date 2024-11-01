import 'dart:convert';
import 'dart:io';

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
    final parser = ArgParser()
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
      ..addFlag(
        'json',
        abbr: 'j',
        help: 'Export to json format',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show help',
        negatable: false,
      );
    final argResult = parser.parse(args);

    // Show helps
    if (argResult.flag('help')) {
      print(parser.usage);
      return;
    }

    final path = argResult['path'] as String;
    String? output = argResult['output'];
    final result = _generate(path);
    if (result == null) return;
    if (argResult['json']) {
      _exportJson(result, output ?? '$path/../assets/resources');
    } else {
      _createLanguageDataAbstractFile(result,
          path: output ?? '$path/resources');
      _createLanguageDataFile(output ?? '$path/resources');
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

    Map<String, List<ParsedData>> result = {};
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && file.path.endsWith('.dart')) {
        // get file path
        final filePath = file.path;

        // Avoid getting data from this folder
        if (filePath.contains('language_helper/languages')) continue;

        // Read and decode the file
        final data = file.readAsBytesSync();
        String text = const Utf8Codec().decode(data);

        final parsed = parse(text);
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
          '  ///===========================================================================');
      languageData.writeln('  /// Path: $key');
      languageData.writeln(
          '  ///===========================================================================');
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
              '>> Path: $key => Text: ${parsed.text} => Reason: ${parsed.type.text}');
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

    desFile.writeAsStringSync(DartFormatter().format(result));

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

    desFile.writeAsStringSync(DartFormatter().format(result));

    print('Created `language_data.dart`');
  }

  void _exportJson(Map<String, List<ParsedData>> data, String path) {
    j.exportJson(data, path);
  }

  /// This file should not be generated. Just add a doc to let users know
  /// how to add the `analysisLanguageData.keys` to `analysisKeys`
  /// in the `initial` of language_helper
  void createLanguageHelperFile() {
    final desFile =
        File('./lib/services/language_helper/language_helper.g.dart');

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
