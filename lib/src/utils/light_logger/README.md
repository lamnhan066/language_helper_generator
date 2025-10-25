# LightLogger

A fast, lightweight, and customizable logging utility for Dart & Flutter — with colored output, emoji icons, log filtering, and powerful formatting.

---

## Features

* **Log Level Filtering**: Control output visibility (`error`, `warning`, `success`, `info`, `step`, `debug`)
* **Colorized Output**: ANSI terminal colors for instant visual clarity
* **Emoji Indicators**: Makes reading console logs effortless
* **Lazy Message Evaluation**: Prevents unnecessary computation
* **Custom Formatting**: Fully configurable message templates
* **Callback Support**: Redirect logs to file, cloud, or analytics
* **Global Enable/Disable Switch**

---

## Getting Started

```dart
final logger = LightLogger(
  minLevel: LogLevel.info, // Only show info and above
);

logger.log('Starting application...');
logger.log('Processing request...', LogLevel.step);
logger.log('Operation completed!', LogLevel.success);
logger.log('Warning: low disk space', LogLevel.warning);
logger.log('Critical failure!', LogLevel.error);
```

---

## Advanced Configuration

```dart
final logger = LightLogger(
  enabled: true,
  minLevel: LogLevel.debug,
  timestamp: (dt) => '[${dt.toIso8601String()}]',
  format: '@{color}@{timestamp} @{icon} [@{level}] @{message}',
  callback: (raw, colored, level) {
    // Save logs to file or send to a remote endpoint
  },
);
```

### Supported Format Tokens

| Token          | Description         |
| -------------- | ------------------- |
| `@{color}`     | ANSI color escape   |
| `@{timestamp}` | Formatted timestamp |
| `@{icon}`      | Emoji per LogLevel  |
| `@{level}`     | Short log label     |
| `@{message}`   | Content of the log  |

---

## Log Filtering Example

```dart
final logger = LightLogger(minLevel: LogLevel.warning);

logger.log('This is info', LogLevel.info);     // ❌ Not logged
logger.log('This is warning', LogLevel.warning); // ✅ Logged
logger.log('This is error', LogLevel.error);     // ✅ Logged
```

---

## Using Callback for Custom Output

```dart
final logger = LightLogger(
  callback: (raw, colored, level) {
    sendToServer({'level': level.text, 'message': raw});
  },
);
```

---

## License

Licensed under the **MIT License** — free for personal and commercial use.

---

## Contributing

Contributions, bug reports, and ideas are always welcome!
Let’s make **LightLogger** the go-to logger for Dart developers.

---

### Start logging with purpose. Start with **LightLogger**
