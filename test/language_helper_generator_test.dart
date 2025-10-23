import 'dart:io';

import 'package:language_helper_generator/language_helper_generator.dart';
import 'package:language_helper_generator/src/models/data_type.dart';
import 'package:test/test.dart';

void main() {
  final generator = LanguageHelperGenerator();

  group('Test parser', () {
    test('Parse single line', () {
      const text = '''
        final tr = 'This is a "test" text'.tr;
        final tr1 = "This is a 'test' text".tr;

        final tr = 'This is a "test" text'.trF();
        final tr1 = "This is a 'test' text".trF();

        final tr = 'This is a "test" text'.trT();
        final tr1 = "This is a 'test' text".trT();

        final tr = 'This is a "test" text'.trP();
        final tr1 = "This is a 'test' text".trP();

        final tr = 'This is a "\\'" text'.trC();
        final tr = "This is a '\\"' text".tr;
      ''';
      final result = generator.parse(text);

      expect(result.length, equals(10));
      expect(
        result.map((e) => e.noFormatedText).toList(),
        equals([
          """This is a "test" text""",
          '''This is a 'test' text''',
          """This is a "test" text""",
          '''This is a 'test' text''',
          """This is a "test" text""",
          '''This is a 'test' text''',
          """This is a "test" text""",
          '''This is a 'test' text''',
          """This is a "'" text""",
          '''This is a '"' text''',
        ]),
      );
    });

    test('Parse multiple lines', () {
      const text = '''
        final tr = 'This is ' 'a "test" '
            'text'.tr;
        final tr1 = "This is ' 'a 'test' "
          "text".tr;

        final tr = 'This is ' 'a "test" text'
            .trF();
        final tr1 = "This is a "
            "'test' text"
            .trF();

        final tr = 'This is a "test" '
            'text'.trT();
        final tr1 = "This "
            "is a 'test' text".trT();

        final tr = 'This ' 'is a "test" ' 'text'.trP();
        final tr1 = "This ""is a 'test' ""text".trC();

        final tr = 'This ' 'is a "\\'"' 'text'.tr;
        final tr = "This " "is a '\\"'" "text".tr;
      ''';
      final result = generator.parse(text);

      expect(result.length, equals(10));
      expect(
        result.map((e) => e.noFormatedText).toList(),
        equals([
          'This is a "test" text',
          'This is \' \'a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "\'"text',
          'This is a \'"\'text',
        ]),
      );
    });

    test('Parse `translate` method single line', () {
      const text = '''
        final tr = languageHelper.translate('This is a "test" text');
        final tr1 = languageHelper.translate("This is a 'test' text");

        final tr = languageHelper.translate('This is a "test" text');
        final tr1 = languageHelper.translate("This is a 'test' text");

        final tr = languageHelper.translate('This is a "test" text');
        final tr1 = languageHelper.translate("This is a 'test' text");

        final tr = languageHelper.translate('This is a "test" text');
        final tr1 = languageHelper.translate("This is a 'test' text");

        final tr = languageHelper.translate('This is a "\\'" text');
        final tr = languageHelper.translate("This is a '\\"' text");
      ''';
      final result = generator.parse(text);

      expect(result.length, equals(10));
      expect(
        result.map((e) => e.noFormatedText).toList(),
        equals([
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "\'" text',
          'This is a \'"\' text',
        ]),
      );
    });

    test('Parse `translate` method multiple lines', () {
      const text = '''
        final tr = languageHelper.translate('This is ' 'a "test" '
            'text');
        final tr1 = languageHelper.translate("This is ' 'a 'test' 'text");

        final tr = languageHelper.translate('This is ' 'a "test" text'
            );
        final tr1 = languageHelper.translate("This is a "
            "'test' text"
            );

        final tr = languageHelper.translate('This is a "test" '
            'text');
        final tr1 = languageHelper.translate("This "
            "is a 'test' text");

        final tr = languageHelper.translate('This ' 'is a "test" ' 'text');
        final tr1 = languageHelper.translate("This ""is a 'test' ""text");

        final tr = languageHelper.translate('This ' 'is a "\\'"' 'text');
        final tr = languageHelper.translate("This " "is a '\\"'" "text");
      ''';
      final result = generator.parse(text);

      expect(result.length, equals(10));
      expect(
        result.map((e) => e.noFormatedText).toList(),
        equals([
          'This is a "test" text',
          'This is \' \'a \'test\' \'text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "test" text',
          'This is a \'test\' text',
          'This is a "\'"text',
          'This is a \'"\'text',
        ]),
      );
    });

    test('Parse ignoring variable', () {
      const text = '''
        final tr = languageHelper.translate('This is ' 'a "test" '
            'text with \$variable');
        final tr1 = languageHelper.translate('This is ' 'a "test" '
            'text with \${variable}');
        final tr2 = languageHelper.translate(\$variable);
        
        final tr3 = 'This is ' 'a "test" '
            'text with \$variable'.tr;
        final tr4 = 'This is ' 'a "test" '
            'text with \${variable.a}'.tr;
        final tr5 = variable.tr;
      ''';
      final result = generator.parse(text);

      expect(result.length, equals(4));
      expect(result[0].type, equals(DataType.containsVariable));
      expect(result[1].type, equals(DataType.containsVariable));
      expect(result[2].type, equals(DataType.containsVariable));
      expect(result[3].type, equals(DataType.containsVariable));
    });

    test('Parse dupplicated text with different quote', () {
      const text = '''
        final tr = 'This is a dupplicated text'.tr;
        final tr1 = "This is a dupplicated text".tr;
      ''';

      final result = generator.parse(text);

      expect(result.length, 2);
      expect(result.first, equals(result.last));
    });

    test('Parse raw text', () {
      const text = '''
        final tr = r'This is a raw text'.tr;
        final tr1 = r"This is another raw text".tr;
      ''';

      final result = generator.parse(text);

      expect(result.length, 2);
      for (var element in result) {
        expect(element.text, startsWith('r'));
      }
    });

    test('Multiple kind of one text', () {
      const text = '''
        final tr = r"This is the same text".tr;
        final tr1 = r'This is the same text'.tr;
        final tr2 = r"This is the " "same text".tr;
        final tr3 = r"This is " "the "
          "same text".tr;
      ''';

      final result = generator.parse(text);
      expect(result.toSet().length, equals(1));
    });

    test('Triple-quoted', () {
      const text = '''
        final tr = r"""This is the same text""".tr;
        final tr1 = """
        This is the same text
        """.tr;
        final tr2 = """This is a \$variable text""".tr;
        final tr3 = r"""This is a
          multi-lines text
          """.tr;
      ''';

      final result = generator.parse(text);
      expect(result.toSet().length, equals(4));
      print(result[2]);
      expect(result[2].type, equals(DataType.containsVariable));
      expect(
        result.map((e) => e.noFormatedText).toList(),
        equals([
          'This is the same text',
          '        This is the same text\n'
              '        ',
          '"""This is a \$variable text"""',
          'This is a\n'
              '          multi-lines text\n'
              '          ',
        ]),
      );
    });
  });

  test(
      'Language boilerplate preserves translated entries and marks only new keys',
      () {
    final tempDir = Directory.systemTemp.createTempSync('lang_helper_test_');
    try {
      final generator = LanguageHelperGenerator();
      final sourceFile = File('${tempDir.path}/page.dart');
      sourceFile.writeAsStringSync(
        '''
import 'package:language_helper/language_helper.dart';

void main() {
  'Hello'.tr;
  'World'.tr;
}
''',
      );

      final languagesDir = Directory(
        '${tempDir.path}/resources/language_helper/languages',
      )..createSync(recursive: true);
      final enFile = File('${languagesDir.path}/en.dart');
      enFile.writeAsStringSync(
        '''
const enLanguageData = <String, String>{
  "World": "Monde",
  "Hello": "Bonjour",
};
''',
      );

      generator.generate([
        '--path=${tempDir.path}',
        '--output=${tempDir.path}/resources',
        '--lang=en',
      ]);

      final firstRun = enFile.readAsStringSync();
      expect(firstRun.contains('// TODO: Translate text'), isFalse);
      expect(firstRun.contains('"Hello": "Bonjour"'), isTrue);
      expect(firstRun.contains('"World": "Monde"'), isTrue);

      sourceFile.writeAsStringSync(
        '''
import 'package:language_helper/language_helper.dart';

void main() {
  'World'.tr;
  'Hello'.tr;
  'New key'.tr;
}
''',
      );

      generator.generate([
        '--path=${tempDir.path}',
        '--output=${tempDir.path}/resources',
        '--lang=en',
      ]);

      final fileContent = enFile.readAsStringSync();
      final secondRunLines = fileContent.split('\n');
      final helloIndex = secondRunLines.indexWhere(
        (line) => line.contains('Bonjour'),
      );
      final worldIndex = secondRunLines.indexWhere(
        (line) => line.contains('Monde'),
      );
      expect(helloIndex, isNonNegative);
      expect(worldIndex, isNonNegative);
      expect(secondRunLines[helloIndex - 1].contains('// TODO'), isFalse);
      expect(secondRunLines[worldIndex - 1].contains('// TODO'), isFalse);

      final newKeyIndex = secondRunLines.indexWhere(
        (line) => line.contains('"New key"'),
      );
      expect(newKeyIndex, isNonNegative);
      expect(
        secondRunLines[newKeyIndex - 1].trim(),
        equals('// TODO: Translate text'),
      );
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
