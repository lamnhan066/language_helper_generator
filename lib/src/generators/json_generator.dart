import 'dart:convert';
import 'dart:io';

import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:language_helper_generator/src/models/parsed_data.dart';

void exportJson(Map<String, List<ParsedData>> data, String path) {
  print('===========================================================');
  print('Exporting Json...');
  _exportJsonCodes(data, path);
  _exportJsonLanguages(data, path);
  print('Exported Json');
  print('===========================================================');
}

void _exportJsonCodes(Map<String, List<ParsedData>> data, String path) {
  print('Creating codes.json...');

  final desFile = File('$path/language_helper/codes.json');
  desFile.createSync(recursive: true);

  JsonEncoder encoder = JsonEncoder.withIndent('  ');
  desFile.writeAsStringSync(encoder.convert(['en']));

  print('Created codes.json');
}

void _exportJsonLanguages(Map<String, List<ParsedData>> data, String path) {
  print('Creating languages json files...');

  final desPath = '$path/language_helper/languages/';
  final desFile = File('${desPath}_generated.json');
  desFile.createSync(recursive: true);
  Map<String, String> map = {};
  for (int i = 0; i < data.length; i++) {
    final path = data.keys.elementAt(i);
    final parsed = data[path]!;
    map.addEntries([MapEntry('@path_$i', path)]);
    for (final text in parsed) {
      if (text.type == DataType.normal) {
        map.addEntries([MapEntry(text.noFormatedText, text.noFormatedText)]);
      }
    }
  }

  JsonEncoder encoder = const JsonEncoder.withIndent('  ');
  desFile.writeAsStringSync(encoder.convert(map));

  print('Created languages json files');
}
