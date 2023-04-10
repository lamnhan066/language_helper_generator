import 'package:language_helper_generator/language_helper_generator.dart';

void main(List<String> args) {
  final generator = LanguageHelperGenerator();

  final result = generator.generate();

  generator.createLanguageDataAbstractFile(result);
  generator.createLanguageDataFile();
}
