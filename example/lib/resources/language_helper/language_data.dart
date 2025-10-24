import 'package:language_helper/language_helper.dart';

import 'languages/vi.dart';
import 'languages/en.dart';
import 'languages/zh.dart';

final LazyLanguageData languageData = {
  LanguageCodes.vi: () => viLanguageData,
  LanguageCodes.en: () => enLanguageData,
  LanguageCodes.zh: () => zhLanguageData,
};
