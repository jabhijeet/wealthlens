import 'package:logger/logger.dart';

/// Centralized logging service for the WealthLens application
///
/// This service provides consistent logging across the app with different log levels
/// and supports both console and file logging in production.
class LoggerService {
  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal()
    : _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0, // Number of method calls to be displayed
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );
  static final LoggerService _instance = LoggerService._internal();
  final Logger _logger;

  /// Log verbose messages for debugging
  void v(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(
      '$message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  /// Log debug messages
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(
      '$message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  /// Log informational messages
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(
      '$message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  /// Log warning messages
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(
      '$message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  /// Log error messages
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(
      '$message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  /// Log fatal/critical error messages
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(
      '$message${error != null ? ' - Error: $error' : ''}${stackTrace != null ? '\n$stackTrace' : ''}',
    );
  }

  /// Log network requests/responses
  void network(String method, String url, {int? statusCode, dynamic data}) {
    final message = '$method $url ${statusCode != null ? '($statusCode)' : ''}';
    if (statusCode != null && statusCode >= 400) {
      e('Network Error: $message', data);
    } else {
      i('Network: $message', data);
    }
  }

  /// Log database operations
  void database(String operation, {dynamic data, dynamic error}) {
    if (error != null) {
      e('Database $operation failed', error);
    } else {
      d('Database $operation', data);
    }
  }

  /// Log user actions for analytics
  void userAction(String action, {Map<String, dynamic>? parameters}) {
    i('User Action: $action', parameters);
  }

  /// Log app lifecycle events
  void lifecycle(String event, {dynamic data}) {
    i('App Lifecycle: $event', data);
  }

  /// Log performance metrics
  void performance(String metric, Duration duration, {String? context}) {
    final message = '$metric took ${duration.inMilliseconds}ms';
    if (duration.inMilliseconds > 1000) {
      w('Slow Performance: $message', context);
    } else {
      d('Performance: $message', context);
    }
  }
}

/// Global logger instance for easy access
final logger = LoggerService();
