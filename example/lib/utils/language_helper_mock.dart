extension LHExtension on String {
  /// Translate the current text wih default parameters.
  String get tr => languageHelper.translate(this);

  /// Translate with only [params] parammeter
  /// ``` dart
  /// final text = 'result is @{param}'.trP({'param' : 'zero'});
  /// print(text); // -> 'result is zero'
  /// ```
  String trP([Map<String, dynamic> params = const {}]) {
    return this;
  }

  /// Translate with only [toCode] parammeter
  /// ``` dart
  /// final text = 'result is something'.trT(LanguageCodes.en);
  /// ```
  String trT([String? toCode]) {
    return this;
  }

  /// Full version of the translation, includes all parameters.
  String trF({Map<String, dynamic> params = const {}, String? toCode}) {
    return this;
  }
}

final languageHelper = LanguageHelper();

class LanguageHelper {
  LanguageHelper();

  String translate(String text, {Map params = const {}}) => text;
}

typedef LanguageData = Map<dynamic, Map<String, String>>;

enum LanguageCodes {
  en,
  vi;
}
