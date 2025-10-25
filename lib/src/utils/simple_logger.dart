/// Represents the severity or type of a log message.
///
/// The enum index determines priority for filtering:
/// lower index = higher priority.
enum LogLevel {
  /// Critical failures that should stop execution or require immediate attention.
  error,

  /// Issues that may lead to errors or unexpected behavior.
  warning,

  /// Indicates successful operations or positive outcomes.
  success,

  /// General runtime information useful for users or developers.
  info,

  /// Represents a transitional or progress step in a sequence of operations.
  step,

  /// Detailed diagnostic output intended for debugging.
  debug;

  /// Returns `true` if this level should be logged when compared
  /// to a specified [minLevel].
  ///
  /// Example:
  /// ```dart
  /// LogLevel.debug.shouldLog(LogLevel.info); // false
  /// LogLevel.error.shouldLog(LogLevel.info); // true
  /// ```
  bool shouldLog(LogLevel minLevel) => index <= minLevel.index;
}

/// Defines ANSI terminal colors for formatting log output.
enum LogColor {
  /// Blue text (typically used for info).
  blue,

  /// Yellow text (typically used for warnings).
  yellow,

  /// Red text (typically used for errors).
  red,

  /// Gray text (typically used for debug messages).
  gray,

  /// Green text (typically used for success messages).
  green,

  /// Cyan text (typically used for steps or progress).
  cyan;

  /// Returns the corresponding ANSI escape color code.
  String get color => switch (this) {
    blue => '\x1B[34m',
    yellow => '\x1B[33m',
    red => '\x1B[31m',
    gray => '\x1B[90m',
    green => '\x1B[32m',
    cyan => '\x1B[36m',
  };
}

/// Callback signature for custom log handling.
///
/// - [raw] is the plain log message without formatting.
/// - [colored] is the formatted message with ANSI colors applied.
/// - [level] indicates the log severity.
typedef LogCallback = void Function(String raw, String colored, LogLevel level);

/// Default mapping of log levels to colors.
const _defaultColors = {
  LogLevel.info: LogColor.blue,
  LogLevel.warning: LogColor.yellow,
  LogLevel.error: LogColor.red,
  LogLevel.debug: LogColor.gray,
  LogLevel.success: LogColor.green,
  LogLevel.step: LogColor.cyan,
};

/// Default mapping of log levels to emojis/icons.
const _defaultEmojis = {
  LogLevel.info: '💡',
  LogLevel.warning: '⚠️',
  LogLevel.error: '❌',
  LogLevel.debug: '🧠',
  LogLevel.success: '✅',
  LogLevel.step: '🔄',
};

/// Default mapping of log levels to 4-character text labels.
const _defaultLevelTexts = {
  LogLevel.error: 'ERRR',
  LogLevel.warning: 'WARN',
  LogLevel.success: 'SUCC',
  LogLevel.info: 'INFO',
  LogLevel.step: 'STEP',
  LogLevel.debug: 'DBUG',
};

/// Default timestamp formatter.
///
/// Produces output in the format `[HH:MM:SS]`.
String _defaultTimestamp(DateTime date) {
  return '[${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}]';
}

/// A lightweight, customizable logger with coloring, icons,
/// and flexible formatting.
class SimpleLogger {
  /// Creates an instance of [SimpleLogger].
  ///
  /// - [minLevel] sets the minimum severity that will be output.
  /// - [callback] allows capturing logs instead of printing.
  /// - [colors], [emojis], and [levelText] customize appearance.
  /// - [timestamp] customizes timestamp formatting.
  /// - [format] defines how a log line is constructed.
  ///
  /// Available placeholders in [format]:
  /// - `@{color}`: ANSI color code
  /// - `@{timestamp}`: formatted timestamp
  /// - `@{icon}`: emoji or symbol
  /// - `@{level}`: level text
  /// - `@{message}`: the log message
  const SimpleLogger({
    LogLevel minLevel = LogLevel.info,
    LogCallback? callback,
    Map<LogLevel, LogColor> colors = _defaultColors,
    Map<LogLevel, String> emojis = _defaultEmojis,
    Map<LogLevel, String> levelText = _defaultLevelTexts,
    String Function(DateTime) timestamp = _defaultTimestamp,
    String format = '@{color}@{timestamp} @{icon} [@{level}] @{message}',
  }) : _callback = callback,
       _minLevel = minLevel,
       _colors = colors,
       _emojis = emojis,
       _levelText = levelText,
       _timestamp = timestamp,
       _format = format;

  /// Minimum log level required for output.
  final LogLevel _minLevel;

  /// Optional user-defined callback for handling logs.
  final LogCallback? _callback;

  /// Mapping between levels and colors.
  final Map<LogLevel, LogColor> _colors;

  /// Mapping between levels and icons.
  final Map<LogLevel, String> _emojis;

  /// Mapping between levels and display text.
  final Map<LogLevel, String> _levelText;

  /// Function that generates timestamps.
  final String Function(DateTime) _timestamp;

  /// Log line format template.
  final String _format;

  /// Logs a message if the level is permitted by [_minLevel].
  ///
  /// The [message] can be a `String` or a function returning `String`
  /// (useful for lazy evaluation).
  void log(dynamic message, [LogLevel level = LogLevel.info]) {
    final timestamp = _timestamp(DateTime.now());
    final color = _colors[level]?.color ?? _defaultColors[level]!.color;
    final reset = '\x1B[0m';
    final icon = _emojis[level] ?? _defaultEmojis[level];
    final levelText = _levelText[level] ?? _defaultLevelTexts[level];

    // Respect minimum log level
    if (!level.shouldLog(_minLevel)) return;

    // Evaluate lazy message if it's a function
    final textMessage = message is Function ? message() : '$message';

    // Apply formatting
    var colored =
        _format
            .replaceAll('@{color}', color)
            .replaceAll('@{timestamp}', timestamp)
            .replaceAll('@{icon}', icon!)
            .replaceAll('@{level}', levelText!)
            .replaceAll('@{message}', textMessage) +
        reset;

    if (_callback != null) {
      _callback(textMessage, colored, level);
    } else {
      // ignore: avoid_print
      print(colored);
    }
  }
}
