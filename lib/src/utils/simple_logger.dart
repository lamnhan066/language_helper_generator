enum LogLevel {
  error,
  warning,
  success,
  info,
  step,
  debug;

  bool shouldLog(LogLevel minLevel) => index <= minLevel.index;
}

enum LogColor {
  blue,
  yellow,
  red,
  gray,
  green,
  cyan;

  String get color => switch (this) {
    blue => '\x1B[34m',
    yellow => '\x1B[33m',
    red => '\x1B[31m',
    gray => '\x1B[90m',
    green => '\x1B[32m',
    cyan => '\x1B[36m',
  };
}

typedef LogCallback = void Function(String raw, String colored, LogLevel level);

const _defaultColors = {
  LogLevel.info: LogColor.blue,
  LogLevel.warning: LogColor.yellow,
  LogLevel.error: LogColor.red,
  LogLevel.debug: LogColor.gray,
  LogLevel.success: LogColor.green,
  LogLevel.step: LogColor.cyan,
};

const _defaultEmojis = {
  LogLevel.info: '💡',
  LogLevel.warning: '⚠️',
  LogLevel.error: '❌',
  LogLevel.debug: '🧠',
  LogLevel.success: '✅',
  LogLevel.step: '🔄',
};

const _defaultLevelTexts = {
  LogLevel.error: 'ERRR',
  LogLevel.warning: 'WARN',
  LogLevel.success: 'SUCC',
  LogLevel.info: 'INFO',
  LogLevel.step: 'STEP',
  LogLevel.debug: 'DBUG',
};

String _defaultTimestamp(DateTime date) {
  return '[${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}]';
}

class SimpleLogger {
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

  final LogLevel _minLevel;
  final LogCallback? _callback;
  final Map<LogLevel, LogColor> _colors;
  final Map<LogLevel, String> _emojis;
  final Map<LogLevel, String> _levelText;
  final String Function(DateTime) _timestamp;
  final String _format;

  void log(dynamic message, [LogLevel level = LogLevel.info]) {
    final timestamp = _timestamp(DateTime.now());
    final color = _colors[level]?.color ?? _defaultColors[level]!.color;
    final reset = '\x1B[0m';
    final icon = _emojis[level] ?? _defaultEmojis[level];
    final levelText = _levelText[level] ?? _defaultLevelTexts[level];

    if (level == LogLevel.debug && !level.shouldLog(_minLevel)) return;

    final textMessage = message is Function ? message() : '$message';
    var colored =
        _format
            .replaceAll('@{color}', color)
            .replaceAll('timestamp', timestamp)
            .replaceAll('@{icon}', icon!)
            .replaceAll('@{level}', levelText!)
            .replaceAll('@{message}', textMessage) +
        reset;

    if (_callback != null) {
      _callback(textMessage, colored + reset, level);
    } else {
      // ignore: avoid_print
      print(colored);
    }
  }
}
