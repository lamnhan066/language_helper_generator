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

| Option              | Description                                            | Example                  |
| ------------------- | ------------------------------------------------------ | ------------------------ |
| `--languages`       | Language codes to generate                             | `--languages=en,vi,es`   |
| `--ignore-todo`     | Skip TODO markers for specific languages               | `--ignore-todo=en`       |
| `--path`            | Custom output directory                                | `--path=./lib/resources` |
| `--json`            | Generate JSON files instead of Dart                    | `--json`                 |
| `--no-lazy`         | Generate `LanguageData` instead of `LazyLanguageData`  | `--no-lazy`              |
| `--keep-deprecated` | Keep deprecated translations that are no longer in use | `--keep-deprecated`      |

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

**Keep deprecated translations:**

```bash
dart run language_helper_generator --languages=en,vi --keep-deprecated
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
- **Clean**: Removes unused translation keys automatically (can be disabled with `--keep-deprecated`)

## Config via `pubspec.yaml`

You can configure `language_helper_generator` using a top-level `language_helper`
node in your project's `pubspec.yaml`. CLI arguments take precedence over
values in `pubspec.yaml` (CLI > pubspec > defaults). The generator reads
`pubspec.yaml` from the current working directory when you run
`dart run language_helper_generator`.

Example `pubspec.yaml` snippet:

```yaml
language_helper:
  # Path to scan for source files (defaults to "./lib")
  path: ./lib

  # Output folder for generated files (Dart default: ./lib/languages)
  output: ./lib/languages

  # Languages to generate (can be string or list)
  languages:
    - en
    - vi

  # Languages to skip TODO comments for
  ignore-todo:
    - en

  # Export JSON instead of Dart files
  json: false

  # Enable lazy loading (true by default)
  lazy: true

  # Run dart format on generated files
  dart-format: true

  # Run dart fix on generated files
  dart-fix: true

  # Use fvm when running dart commands
  fvm: false

  # Include commented invalid/duplicate entries in outputs
  include-invalid: false

  # Keep deprecated translations instead of removing them
  keep-deprecated: false
```

Notes:
- Keys may use either hyphen or underscore forms for `ignore-todo` (example: `ignore_todo`).
- For `languages` and `ignore-todo`, you may supply a comma-separated string instead of a list.
- If `pubspec.yaml` contains invalid types for any key, the generator will print a warning and fall back to defaults or CLI-provided values.

## Contributing

Questions or suggestions? Please file an issue or submit a pull request!
