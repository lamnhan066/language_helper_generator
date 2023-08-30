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

      expect(
          result.map((e) => e.text),
          containsAll([
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "\\'" text'""",
            '''"This is a '\\"' text"''',
          ]));
    });

    test('Parse multiple lines', () {
      const text = '''
        final tr = 'This is ' 'a "test" '
            'text'.tr;
        final tr1 = "This is ' 'a 'test' '
            'text".tr;

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

      expect(
          result.map((e) => e.text),
          containsAll([
            """'This is a "test" '            'text'""",
            '''"This "            "is a 'test' text"''',
            """'This is ' 'a "test" text'""",
            '''"This is a "            "'test' text"''',
            """'This ' 'is a "test" ' 'text'""",
            '''"This ""is a 'test' ""text"''',
            """'This is ' 'a "test" '            'text'""",
            '''"This is ' 'a 'test' '            'text"''',
            """'This ' 'is a "\\'"' 'text'""",
            '''"This " "is a '\\"'" "text"''',
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

      expect(
          result.map((e) => e.text),
          containsAll([
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "test" text'""",
            '''"This is a 'test' text"''',
            """'This is a "\\'" text'""",
            '''"This is a '\\"' text"''',
          ]));
    });

    test('Parse `translate` method multiple lines', () {
      const text = '''
        final tr = languageHelper.translate('This is ' 'a "test" '
            'text');
        final tr1 = languageHelper.translate("This is ' 'a 'test' '
            'text");

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

      expect(
          result.map((e) => e.text),
          containsAll([
            """'This is a "test" '            'text'""",
            '''"This "            "is a 'test' text"''',
            """'This is ' 'a "test" text'""",
            '''"This is a "            "'test' text"''',
            """'This ' 'is a "test" ' 'text'""",
            '''"This ""is a 'test' ""text"''',
            """'This is ' 'a "test" '            'text'""",
            '''"This is ' 'a 'test' '            'text"''',
            """'This ' 'is a "\\'"' 'text'""",
            '''"This " "is a '\\"'" "text"''',
          ]));
    });

    test('Parse ignoring variable', () {
      const text = '''
        final tr = languageHelper.translate('This is ' 'a "test" '
            'text with \$variable');
        final tr1 = languageHelper.translate('This is ' 'a "test" '
            'text with \${variable.1}');
        final tr2 = languageHelper.translate(\$variable);
        
        final tr3 = 'This is ' 'a "test" '
            'text with \$variable'.tr;
        final tr4 = 'This is ' 'a "test" '
            'text with \${variable.1}'.tr;
        final tr5 = variable.tr;
      ''';
      final result = generator.parse(text);

      for (final parsed in result) {
        expect(
          parsed.type,
          equals(DataType.containsVariable),
        );
      }
    });
  });
}
