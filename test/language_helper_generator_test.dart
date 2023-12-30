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

        final tr = 'This is a "\\'" text'.tr;
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
          ]));
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
        final tr1 = "This ""is a 'test' ""text".trP();

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
            'This is a \'"\'text'
          ]));
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
            'This is a \'"\' text'
          ]));
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
            'This is a \'"\'text'
          ]));
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
              '          '
        ]),
      );
    });
  });
}
