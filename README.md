# Language Helper Generator

A fast and reliable generator for [language_helper](https://pub.dev/packages/language_helper) that automatically creates translation files from your Dart code.

## What it does

Scans your project for text using language_helper extensions (`tr`, `trP`, `trT`, `trF`) and `translate` method, then generates organized translation files with your existing translations preserved.

## Quick Start

1. **Add to your project:**

```yaml
dev_dependencies:
  language_helper_generator: ^0.7.0
```

1. **Generate translations:**

```bash
dart run language_helper_generator --languages=en,vi --ignore-todo=en
```

This creates:

- `lib/languages/codes.dart` - Language mapping
- `lib/languages/data/en.dart` - English translations  
- `lib/languages/data/vi.dart` - Vietnamese translations (with TODO markers for missing translations)

## Common Options

| Option | Description | Example |
|--------|-------------|---------|
| `--languages` | Language codes to generate | `--languages=en,vi,es` |
| `--ignore-todo` | Skip TODO markers for specific languages | `--ignore-todo=en` |
| `--path` | Custom output directory | `--path=./lib/resources` |
| `--json` | Generate JSON files instead of Dart | `--json` |
| `--no-lazy` | Generate `LanguageData` instead of `LazyLanguageData` | `--no-lazy` |

## Examples

**Basic usage:**

```bash
dart run language_helper_generator --languages=en,vi
```

**Skip TODOs in English (your base language):**

```bash
dart run language_helper_generator --languages=en,vi --ignore-todo=en
```

**Generate JSON files for assets:**

```bash
dart run language_helper_generator --languages=en,vi --json
```

**Custom output path:**

```bash
dart run language_helper_generator --path=./assets/languages --languages=en,vi
```

**Generate non-lazy LanguageData (eager loading):**

```bash
dart run language_helper_generator --languages=en,vi --no-lazy
```

## Generated Files

**Dart format (default):**

```txt
lib/languages/
├── codes.dart          # Language mapping
└── data/
    ├── en.dart         # English translations
    └── vi.dart         # Vietnamese translations
```

**JSON format (with --json flag):**

```txt
assets/languages/
├── codes.json          # Language mapping
└── data/
    ├── en.json         # English translations
    └── vi.json         # Vietnamese translations
```

## Usage in your app

**Dart Generated Data (Lazy Loading - default):**

```dart
await LanguageHelper.instance.initial(
  data: [LanguageDataProvider.lazyData(languageData)],
  initialCode: LanguageCodes.en,
  isDebug: !kReleaseMode,
);
```

**Dart Generated Data (Eager Loading - with --no-lazy):**

```dart
await LanguageHelper.instance.initial(
  data: [LanguageDataProvider.data(languageData)],
  initialCode: LanguageCodes.en,
  isDebug: !kReleaseMode,
);
```

**JSON Generated Data:**

```dart
await LanguageHelper.instance.initial(
  data: [
    LanguageDataProvider.asset('assets/languages'),
    LanguageDataProvider.network('https://example.com/languages'),
  ],
  initialCode: LanguageCodes.en,
  isDebug: !kReleaseMode,
);
```

## Features

- **Fast**: Uses Dart Analyzer, no build_runner dependency
- **Smart**: Preserves existing translations
- **Organized**: Groups translations by file path
- **Helpful**: Adds TODO markers for missing translations
- **Clean**: Removes unused translation keys automatically

## Contributing

Questions or suggestions? Please file an issue or submit a pull request!
