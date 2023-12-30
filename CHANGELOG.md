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
