/// Represents the severity or importance of a log message.
///
/// The enum index determines priority for filtering:
///
/// - Lower index = higher priority.
/// - Messages are only logged if their level is **greater than or equal** to the configured minimum level.
///
/// For example:
/// ```dart
/// LogLevel.error.shouldLog(LogLevel.warning); // true (error is higher priority)
/// LogLevel.debug.shouldLog(LogLevel.info);   // false (debug is lower priority)
/// ```
enum LogLevel {
  /// Critical failures that require immediate attention and typically stop the process.
  error,

  /// Recoverable issues that may degrade the application or indicate potential problems.
  warning,

  /// Successful operations indicating that a task completed as expected.
  success,

  /// General informational messages about routine operations.
  info,

  /// Operational progress updates, often used in multi-step processes.
  step,

  /// Detailed diagnostic output, usually enabled only during development.
  debug,
}

/// Defines terminal colors using ANSI escape codes for styling log output.
///
/// Colors are typically used to visually distinguish log levels.
enum LogColor {
  /// Blue text — commonly used for informational messages.
  blue,

  /// Yellow text — commonly used for warnings.
  yellow,

  /// Red text — commonly used for errors.
  red,

  /// Gray text — commonly used for debug-level output.
  gray,

  /// Green text — commonly used for success messages.
  green,

  /// Cyan text — commonly used for progress or step messages.
  cyan;

  /// ANSI escape code representing the terminal color for this value.
  String get color => switch (this) {
    blue => '\x1B[34m',
    yellow => '\x1B[33m',
    red => '\x1B[31m',
    gray => '\x1B[90m',
    green => '\x1B[32m',
    cyan => '\x1B[36m',
  };
}

/// A function type used to intercept formatted and raw log messages.
///
/// Useful for writing logs to a file, sending to external systems,
/// or integrating with custom log handlers.
///
/// - [raw]     Unformatted, plain message string.
/// - [colored] The final formatted output including ANSI color codes.
/// - [level]   The log level that was emitted.
typedef LogCallback = void Function(String raw, String colored, LogLevel level);

/// Default color mapping for each log level when none is provided.
const _defaultColors = {
  LogLevel.info: LogColor.blue,
  LogLevel.warning: LogColor.yellow,
  LogLevel.error: LogColor.red,
  LogLevel.debug: LogColor.gray,
  LogLevel.success: LogColor.green,
  LogLevel.step: LogColor.cyan,
};

/// Default emoji/icon mapping for each log level.
///
/// Icons enhance readability and quickly convey log intent.
const _defaultEmojis = {
  LogLevel.info: '💡',
  LogLevel.warning: '⚠️',
  LogLevel.error: '❌',
  LogLevel.debug: '🧠',
  LogLevel.success: '✅',
  LogLevel.step: '🔄',
};

/// Default label text (fixed-width) for each log level.
///
/// Ensures consistent alignment in formatted output.
const _defaultLevelTexts = {
  LogLevel.error: 'ERRR',
  LogLevel.warning: 'WARN',
  LogLevel.success: 'SUCC',
  LogLevel.info: 'INFO',
  LogLevel.step: 'STEP',
  LogLevel.debug: 'DBUG',
};

/// Default timestamp formatter for log output.
///
/// Produces time in `[HH:MM:SS]` format using 24-hour clock.
String _defaultTimestamp(DateTime date) {
  return '[${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}:'
      '${date.second.toString().padLeft(2, '0')}]';
}

/// A lightweight, flexible logger designed for developers.
///
/// Supports:
/// - Customizable colors, icons, timestamps, and formatting tokens.
/// - Lazy evaluation for log messages (functions are only executed if the log is emitted).
/// - Optional callback for custom integration such as writing to file or remote service.
///
/// ### Format Placeholders
/// The `format` string supports these dynamic tokens:
/// - `@{color}`   → ANSI color code
/// - `@{timestamp}` → Formatted timestamp
/// - `@{icon}`    → Emoji or icon for the level
/// - `@{level}`   → Short text label
/// - `@{message}` → The actual log message
///
/// ### Example
/// ```dart
/// final logger = SimpleLogger(minLevel: LogLevel.warning);
/// logger.log('This is visible', LogLevel.error); // Logged
/// logger.log('This is hidden', LogLevel.info);  // Not logged
/// ```
class LightLogger {
  /// Creates an instance of [LightLogger].
  ///
  /// - [enabled]: Globally enables or disables logging without removing code.
  /// - [minLevel]: Minimum severity required to output a log.
  /// - [callback]: Optional custom handler instead of default print.
  /// - [colors], [emojis], [levelText]: Customize visual style.
  /// - [timestamp]: Function supplying a formatted timestamp string.
  /// - [format]: Template for building each formatted log line.
  const LightLogger({
    bool enabled = true,
    LogLevel minLevel = LogLevel.info,
    LogCallback? callback,
    Map<LogLevel, LogColor> colors = _defaultColors,
    Map<LogLevel, String> emojis = _defaultEmojis,
    Map<LogLevel, String> levelText = _defaultLevelTexts,
    String Function(DateTime) timestamp = _defaultTimestamp,
    String format = '@{color}@{timestamp} @{icon} [@{level}] @{message}',
  }) : _enabled = enabled,
       _callback = callback,
       _minLevel = minLevel,
       _colors = colors,
       _emojis = emojis,
       _levelText = levelText,
       _timestamp = timestamp,
       _format = format;

  /// Whether logging is globally enabled.
  ///
  /// When `false`, all calls to [log] are ignored.
  final bool _enabled;

  /// Minimum log level that will be output.
  ///
  /// Messages with lower priority are not logged.
  final LogLevel _minLevel;

  /// Optional user-defined handler for processed log output.
  final LogCallback? _callback;

  /// Mapping between log levels and terminal colors.
  final Map<LogLevel, LogColor> _colors;

  /// Mapping between log levels and icon characters.
  final Map<LogLevel, String> _emojis;

  /// Mapping between log levels and fixed-width label text.
  final Map<LogLevel, String> _levelText;

  /// A function that generates timestamp strings.
  final String Function(DateTime) _timestamp;

  /// The format template for composing each log entry.
  ///
  /// See the class documentation above for available placeholders.
  final String _format;

  /// Logs a message if logging is enabled and the severity meets the threshold.
  ///
  /// The [message] parameter may be:
  /// - A `String`, or
  /// - A function returning `String` (lazy evaluation to save computation).
  ///
  /// This allows:
  /// ```dart
  /// logger.log(() => expensiveComputation(), LogLevel.debug);
  /// ```
  void log(dynamic message, [LogLevel level = LogLevel.info]) {
    if (!_enabled) return;
    if (!_shouldLog(_minLevel)) return;

    final timestamp = _timestamp(DateTime.now());
    final color = _colors[level]?.color ?? _defaultColors[level]!.color;
    final reset = '\x1B[0m';
    final icon = _emojis[level] ?? _defaultEmojis[level];
    final levelText = _levelText[level] ?? _defaultLevelTexts[level];

    // Evaluate lazy message only when needed
    final textMessage = message is Function ? message() : '$message';

    // Build formatted output
    final colored =
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

  /// Determines whether this log level should be output when compared against `minLevel`.
  ///
  /// Returns `true` when this level's priority is **greater than or equal to**
  /// the provided `minLevel`.
  bool _shouldLog(LogLevel level) => level.index <= _minLevel.index;
}
