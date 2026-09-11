import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Structured, SAFE logger.
///
/// Rules (docs/security-plan.md):
/// - Never log passwords, tokens, keys, authorization headers, media bytes.
/// - Never log raw request bodies that could contain sensitive fields.
/// - Redact anything that looks like a credential before it reaches output.
class AppLogger {
  AppLogger._() : _console = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 6,
            colors: false,
            printEmojis: false,
          ),
          filter: ProductionFilter(),
        );

  static final AppLogger _instance = AppLogger._();

  factory AppLogger() => _instance;

  final Logger _console;

  static AppLogger get instance => _instance;

  void debug(String message) {
    if (kDebugMode) _console.d(message);
  }

  void info(String message) => _console.i(message);

  void warn(String message) => _console.w(message);

  void error(String message, [Object? error, StackTrace? stack]) {
    _console.e(message, error: error, stackTrace: stack);
  }

  /// Redact credential-like values from a string before logging.
  static String redact(String input) {
    var out = input;
    out = out.replaceAll(
      RegExp(r'(authorization\s*[:=]\s*)([^\s,]+)', caseSensitive: false),
      r'$1[REDACTED]',
    );
    out = out.replaceAll(
      RegExp(r'(password\s*[:=]\s*)([^\s,]+)', caseSensitive: false),
      r'$1[REDACTED]',
    );
    out = out.replaceAll(
      RegExp(r'(api[_-]?key\s*[:=]\s*)([^\s,]+)', caseSensitive: false),
      r'$1[REDACTED]',
    );
    out = out.replaceAll(
      RegExp(r'(service[_-]?role[_-]?key\s*[:=]\s*)([^\s,]+)', caseSensitive: false),
      r'$1[REDACTED]',
    );
    return out;
  }
}

/// Filters out verbose debug in release.
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      return event.level.index >= Level.info.index;
    }
    return true;
  }
}