import 'dart:convert';
import 'dart:io';

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';
import 'package:language_helper_generator/src/utils/list_all_files.dart';
import 'package:language_helper_generator/src/utils/parser.dart';

class LanguageHelperGenerator {
  Map<String, List<ParsedData>>? generate([String path = './lib/']) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      // ignore: avoid_print
      print(
          'The command run in the wrong directory. Please run it in your main directory of the project which containing `lib/`.');
      return null;
    }

    final List<FileSystemEntity> allFiles = listAllFiles(Directory(path), []);

    Map<String, List<ParsedData>> result = {};
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && file.path.endsWith('.dart')) {
        // get file path and remove `./lib/`
        final filePath = file.path.substring(6);

        // Avoid getting data from this folder
        if (filePath.startsWith('resources/language_helper')) continue;

        // Read and decode the file
        final data = file.readAsBytesSync();
        String text = const Utf8Codec().decode(data);

        final parsed = parse(text);
        if (parsed.isNotEmpty) result[filePath] = parsed;
      }
    }

    return result;
  }

  List<ParsedData> parse(String text) {
    List<ParsedData> result = [];
    result.addAll(parseString(text, endingTag: '.trT('));
    result.addAll(parseString(text, endingTag: '.trF('));
    result.addAll(parseString(text, endingTag: '.trP('));
    result.addAll(parseString(text, endingTag: '.tr;'));
    result.addAll(parseString(text, endingTag: '.tr}'));
    result.addAll(parseString(text, endingTag: '.tr)'));
    result.addAll(parseString(text, endingTag: '.tr,'));
    result.addAll(parseString(text, endingTag: '.tr '));
    result.addAll(parseString(text, startingTag: '.translate('));

    return result;
  }

  /// Create `_language_data_abstract,dart`
  void createLanguageDataAbstractFile(Map<String, List<ParsedData>> data) {
    final desFile =
        File('./lib/resources/language_helper/_language_data_abstract.g.dart');
    desFile.createSync(recursive: true);

    StringBuffer languageData = StringBuffer();
    final listAllUniqueText = <String>[];
    data.forEach((key, values) {
      // Comment file path when move to new file
      languageData.writeln('');
      languageData
          .writeln('  ///==============================================');
      languageData.writeln('  /// Path: $key');
      languageData
          .writeln('  ///==============================================');

      // Map should contains unique key => comment all duppicated keys
      for (final parsed in values) {
        // Check if the text is duplicate or abnormal. If yes then add comment.
        String needsComment = '';
        String needsEndComment = '';
        if (parsed.type != DataType.normal) {
          needsComment = '// ';
          needsEndComment = '  // contains ${parsed.type}';
          // ignore: avoid_print
          print(
              '>> Path: $key => Text: ${parsed.text} => Contains: ${parsed.type}');
        } else {
          if (listAllUniqueText.contains(parsed.text)) {
            needsComment = '// ';
            needsEndComment = '  // Duplicated';
          } else {
            listAllUniqueText.add(parsed.text);
          }
        }

        languageData.writeln(
          '  $needsComment${parsed.text}: ${parsed.text},$needsEndComment',
        );
      }
    });

    final result = '''
//==========================================================
// Author: Lâm Thành Nhân (2023)
//
// Generated Code - Do not modify by hand
//==========================================================

part of 'language_data.dart';

const analysisLanguageData = {$languageData};
''';

    desFile.writeAsString(result);
  }

  /// Create `language_data.dart`
  void createLanguageDataFile() {
    final desFile = File('./lib/resources/language_helper/language_data.dart');

    // Return if the file already exists
    if (desFile.existsSync()) return;

    desFile.createSync(recursive: true);

    const result = '''
import 'package:language_helper/language_helper.dart';

part '_language_data_abstract.g.dart';

LanguageData languageData = {
  // TODO: You can use this data as your main language, remember to change this code to your base language code
  LanguageCodes.en: analysisLanguageData,
};
''';

    desFile.writeAsString(result);
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

    desFile.writeAsString(data);
  }
}
