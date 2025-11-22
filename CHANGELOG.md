## 0.8.0

* Bump dart sdk to ^3.9.0.
* Bump analyzer to ^9.0.0.

## 0.7.6

* Add `--lazy` arg to generate `LazyLanguageDat`a (lazy loading) instead of `LanguageData` which default is set to `true`.
* Update docs.

## 0.7.5

* Enable usePrint option for LiteLogger in LanguageHelperGenerator.

## 0.7.4

* Bump `lite_logger` to v0.2.0.

## 0.7.3

* Remove the `language_helper` from the dependencies.

## 0.7.2

* Able to generate `--languages=zh_CN,zh_TW` with correct language code.
* Ignore `file_names` lint.

## 0.7.1

* Ignore `lines_longer_than_80_chars` in the generated files.

## 0.7.0

* Updated the structure of generated paths and files:

  **Dart output** (default: `./lib/languages/`):

  ```txt
  $output/
  ├── codes.dart         # Language codes mapping
  └── data/
      ├── en.dart        # English translations
      └── vi.dart        # Vietnamese translations
  ```

  **JSON output** (default: `./assets/languages/`):

  ```txt
  $output/
  ├── codes.json         # Language codes mapping
  └── data/
      ├── en.json        # English translations
      └── vi.json        # Vietnamese translations
  ```

* Added `--languages` flag to generate and update language files, preserving existing translations. New entries will include a `TODO` comment (when generating Dart files). Unused translations are automatically removed when regenerating.
* Introduced `--ignore-todo` option to omit TODO markers for specific language codes.
* Added `--include-invalid` (Dart only): includes commented-out duplicated or invalid entries in the output.
* Switched to using `LazyLanguageData` for generation, allowing for lazy loading of translation data.
* Removed auto-generated aggregate files (`_generated.dart` and `_generated.json`); each language file is now standalone with only necessary keys and imports.
* Improved documentation in the README.

## 0.6.0

* Bump dart min sdk to 3.7.0.

## 0.5.3

* Add `--help` flag to the generator to show help.

## 0.5.2

* Use `DartFormatter` instead of `dart format`.

## 0.5.1

* Change the generated path in Map from `'@path_1': '.lib/to/file.dart'` to `"@path_.lib/to/file.dart": ''`.

## 0.5.0

* Release to stable.

## 0.5.0-rc.4

* Bump min sdk to `3.0.0`.
* Add `trC` to the parser.
* Change the generated type from `<String, String>` to `<String, dynamic>`.

## 0.5.0-rc.3

* Change the default path of the Dart Map generator:
  * Before:

  ```txt
  |-- .lib
  |   |--- resources
  |   |    |--- language_helper
  |   |    |    |--- _language_data_abstract.g.dart   ; This file will be overwritten when generating
  |   |    |    |--- language_data.dart
  ```

  * Now:

  ```txt
  |-- .lib
  |   |--- resources
  |   |    |--- language_helper
  |   |    |    |--- language_data.dart
  |   |    |    |--- languages
  |   |    |    |    |--- _generated.dart   ; This will be overwritten when re-generating
  ```

* Change the default path of the Dart Map generator:
  * Before:

  ```txt
  |-- assets
  |   |--- language_helper
  |   |    |--- codes.json   ; List of supported language code
  |   |    |--- languages
  |   |    |    |--- _generated.json ; Each language will be stored in 1 files
  ```

  * Now:

  ```txt
  |-- assets
  |   |--- resources
  |   |    |--- language_helper
  |   |    |    |--- codes.json
  |   |    |    |--- languages
  |   |    |    |   |--- _generated.json ; This file will be overwritten when re-generating
  ```

* JSON generator will not overwrite the `codes.json` when re-generating.

## 0.5.0-rc.2

* Change the default generated path of JSON to `assets/language_helper`.
* Change the default generated language file to `_generated.json`

## 0.5.0-rc.1

* Add the export as JSON feature.

## 0.4.2

* Update the `analyzer` version in the dependencies to support the current `flutter_test`.

## 0.4.1

* Completely rewritten using Dart Analyzer to improve reliability.
* Update tests.

## 0.3.0

* Fix issue with the same text but has different quote.
* Add: parse text that has a `r` raw text tag.
* Add: convert to single quote when possible.
* Update tests.

## 0.2.3

* Fixes: Parser will returns an incorrect result if there is a variable using .tr.
* Update tests.
* Update homepage URL.

## 0.2.2

* Support generating the text that containing the backslashed quote (`'This\'s'` and `"This\"s"`).

## 0.2.1

* Update `dart format` parameter.

## 0.2.0

* Automatically run `dart format` for the created files.

## 0.1.6

* Support changing the generated path when generating.
* Add more logs.
* Improve the commented text.

## 0.1.2

* Improve the commented text.
* Improve TODO text.

## 0.1.1

* Ignore prefer_single_quotes to the generated file.
* Improve the commented reason.
* Update the generated files in the example.

## 0.1.0

* Bump dart sdk version to `>=2.18.0 <4.0.0`.

## 0.0.1+2

* Use mock in example instead of using `language_helper`.
* Update base data path in README.

## 0.0.1

* Bring to the first stable release.
* Change command to `dart run language_helper_generator`.
* Remove Flutter dependencies.

## 0.0.1-rc.5

* Able to run with command: `flutter pub run language_helper_generator`.
* Add a warning message for the wrong working directory.

## 0.0.1-rc.4

* Improves parser to be able to parse `'test'.tr,`.

## 0.0.1-rc.3

* Print text in the console if it contains $variable.
* Add comments to the generated text if it contains invalid information (like $variable, duplicated).
* Add mutiple tests.

## 0.0.1-rc.2

* User new parser to parse string which supports multiple lines.

## 0.0.1-rc.1

* Initial release.
