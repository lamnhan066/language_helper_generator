# Language Helper Generator

## Features

* Create a base structure for [language_helper](https://pub.dev/packages/language_helper).

* This runner will get all the texts that using language_helper extensions (`tr`, `trP`, `trT`, `trF`) and `translate` method then creating a base structure for [LanguageData].

## Usage

Install `language_helper_generator` to your `pubspec.yaml` dev dependencies:

``` yaml
dev_dependencies:
  language_helper_generator: ^any
```

Run this command to generate the language from current project.

``` cmd
flutter pub run language_helper_generator
```

This command will generate a structure base files with this format:

``` txt
|-- .lib
|   |--- resources
|   |    |--- _language_data_abstract.g.dart  // Contains your base language from your all `.dart` files. This file will be re-generated when you run the command.
|   |    |--- language_data.dart              // Modifiable language data because it's only generated 1 time.
```

In the `language_data.dart`, data will show like below:

``` dart
LanguageData languageData = {
  // TODO: You can use this data as your main language, remember to change this code to your base language code
  LanguageCodes.en: analysisLanguageData,
};
```

You can use the `analysisLanguageData` as your main language if you feel it's detailed enough. After that, you can update your other languages by looking at the `_language_data_abstract.g.dart`. This file will contains all the texts that ending with the supported extensions of `LanguageHelper`.

If you don't want to use `analysisLanguageData` as your main language, you can use it for analysis by adding it to the `initial` like this:

``` dart
  await LanguageHelper.instance.initial(
    data: data, // <--- This is your data
    analysisKeys: analysisLanguageData.keys, // <--- This is the generated data
    initialCode: LanguageCodes.en,
    isDebug: !kReleaseMode,
  );
```

## Contributions

The package is currently in its early development stage and may have bugs. If you have any questions, please don't hesitate to file an issue. We are also open to pull requests.
