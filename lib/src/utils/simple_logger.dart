// ANSI escape codes for colors
const String _reset = '\x1B[0m';
const String _blue = '\x1B[34m';
const String _yellow = '\x1B[33m';
const String _red = '\x1B[31m';
const String _gray = '\x1B[90m';
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';

// Emoji/character icons
const String _warningIcon = '⚠️';
const String _errorIcon = '❌';
const String _successIcon = '✅';
const String _infoIcon = 'ℹ️';
const String _debugIcon = '🐛';
const String _stepIcon = '⚙️';

enum LogLevel { info, warning, error, debug, success, step }

class SimpleLogger {
  const SimpleLogger({this.verbose = false});

  final bool verbose;

  void log(String message, [LogLevel level = LogLevel.info]) {
    final timestamp = _getTimestamp();
    String color = _reset;
    String icon = '';

    switch (level) {
      case LogLevel.info:
        color = _blue;
        icon = _infoIcon;
        break;
      case LogLevel.warning:
        color = _yellow;
        icon = _warningIcon;
        break;
      case LogLevel.error:
        color = _red;
        icon = _errorIcon;
        break;
      case LogLevel.debug:
        color = _gray;
        icon = _debugIcon;
        break;
      case LogLevel.success:
        color = _green;
        icon = _successIcon;
        break;
      case LogLevel.step:
        color = _cyan;
        icon = _stepIcon;
        break;
    }

    if (level == LogLevel.debug && !verbose) return;

    // ignore: avoid_print
    print(
      '$color$timestamp $icon [${level.name.toUpperCase()}] $message$_reset',
    );
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '[${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}]';
  }
}
