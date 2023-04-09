import 'dart:convert';
import 'dart:io';

import 'package:language_helper_generator/src/utils/list_all_files.dart';

class LanguageHelperGenerator {
  Future<void> run() async {
    // ignore: avoid_print
    print('Generating language...');

    final List<FileSystemEntity> allFiles =
        listAllFiles(Directory('./lib/'), []);

    Map<String, List<String>> result = {};
    for (final file in allFiles) {
      // Only analyze the file ending with .dart
      if (file is File && file.path.endsWith('.dart')) {
        // get file path and remove `./lib/`
        final filePath = file.path.substring(6);

        // Avoid getting data from this folder
        if (filePath.startsWith('resources/language_helper')) continue;

        // Read and decode the file
        final data = file.readAsBytesSync();
        final text = const Utf8Codec().decode(data);

        // Get all available text that using the LanguageHelper extensions
        const extensionPattern =
            r'''(?<!\\)(['"])(?:(?!\1|[@{]).|(?<=\\)\1|@\{\w+\})*\1\.(?:tr|trP|trT|trF)''';
        final regex = RegExp(extensionPattern);
        final listText = regex.allMatches(text);
        for (final match in listText) {
          // Remove the `.tr`, `.trP`,..
          final list = match.group(0)!.split('.')..removeLast();

          // Add file path and contents
          if (!result.containsKey(filePath)) {
            result[filePath] = [list.join('.')];
            continue;
          } else {
            result[filePath]!.add(list.join('.'));
          }
        }

        const methodPattern = r'''\.translate\((['\"])(.+?)\1(?:,[^)]*)?\)''';
        final methodRegex = RegExp(methodPattern);
        final listMethodResult = methodRegex.allMatches(text);
        for (final match in listMethodResult) {
          final capturedQuote = match.group(1);
          final capturedText = match.group(2);
          final text = "$capturedQuote$capturedText$capturedQuote";
          // Add file path and contents
          if (!result.containsKey(filePath)) {
            result[filePath] = [text];
            continue;
          } else {
            result[filePath]!.add(text);
          }
        }
      }
    }

    createLanguageDataAbstractFile(result);
    createLanguageDataFile();

    // ignore: avoid_print
    print('All texts are generated!');
  }

  /// Create `_language_data_abstract,dart`
  void createLanguageDataAbstractFile(Map<String, List<String>> data) {
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
      for (final text in values) {
        // Check if the text is duplicate or not. If yes then add comment.
        String needsComment = '// ';
        if (!listAllUniqueText.contains(text)) {
          needsComment = '';
          listAllUniqueText.add(text);
        }
        languageData.writeln(
          '  $needsComment$text: $text,',
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
