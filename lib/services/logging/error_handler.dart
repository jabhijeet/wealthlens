import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'logger_service.dart';
import '../../app/router.dart';

/// Base exception for WealthLens application
class WealthLensException implements Exception {
  WealthLensException(this.message, {this.isSilent = false, this.code});

  final String message;
  final bool isSilent;
  final String? code;

  @override
  String toString() => message;
}

/// Exception thrown when application is not properly configured
class ConfigurationException extends WealthLensException {
  ConfigurationException(super.message, {super.code}) : super(isSilent: true);
}

/// Centralized error handler for the WealthLens application
///
/// Provides consistent error handling patterns and logging across the app.
class ErrorHandler {
  factory ErrorHandler() {
    return _instance;
  }

  ErrorHandler._internal();
  static final ErrorHandler _instance = ErrorHandler._internal();
  final LoggerService _logger = logger;

  /// Handle synchronous errors with logging and optional recovery
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    bool showToUser = false,
    void Function()? onRecovery,
  }) {
    final errorContext = context ?? 'Unhandled error';
    final errorMessage = error?.toString() ?? 'Unknown error';

    // Check if this is a silent exception or a common recoverable error
    final isSilent =
        (error is WealthLensException && error.isSilent) ||
        error is TimeoutException ||
        error is http.ClientException ||
        errorMessage.contains('TimeoutException') ||
        errorMessage.contains('timed out');

    if (isSilent) {
      _logger.i('$errorContext: $errorMessage');
    } else {
      // Log the error
      _logger.e('$errorContext: $errorMessage', error, stackTrace);
    }

    // In debug mode, print to console for immediate visibility
    if (kDebugMode && !isSilent) {
      debugPrint('⛔ $errorContext: $errorMessage');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    } else if (kDebugMode && isSilent) {
      debugPrint('⚠️ $errorContext: $errorMessage');
    }

    // Attempt recovery if provided
    if (onRecovery != null) {
      try {
        onRecovery();
        _logger.i('Recovery action executed for: $errorContext');
      } catch (recoveryError) {
        _logger.e('Recovery failed for $errorContext', recoveryError);
      }
    }

    // Send to crash reporting service in release mode
    if (!kDebugMode) {
      // Crash reporting (e.g. Sentry/Firebase) can be integrated here
    }

    if (showToUser) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: isSilent
              ? const Color(0xFF616161)
              : const Color(
                  0xFFD32F2F,
                ), // Gray 700 for warnings, Red 700 for errors
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Log a warning that doesn't require a stack trace
  void handleWarning(
    String message, {
    String? context,
    bool showToUser = false,
  }) {
    final warningContext = context ?? 'Warning';
    _logger.w('$warningContext: $message');

    if (showToUser) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF616161),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handle asynchronous errors in Futures
  Future<T> handleFutureError<T>(
    Future<T> future, {
    String? context,
    T? defaultValue,
    bool logError = true,
  }) async {
    try {
      return await future;
    } catch (error, stackTrace) {
      if (logError) {
        handleError(error, stackTrace: stackTrace, context: context);
      }

      // Return default value if provided
      if (defaultValue != null) {
        return defaultValue;
      }

      // Re-throw if no default value
      rethrow;
    }
  }

  /// Wrap a function with error handling
  T wrapWithErrorHandling<T>(
    T Function() fn, {
    String? context,
    T? defaultValue,
  }) {
    try {
      return fn();
    } catch (error, stackTrace) {
      handleError(error, stackTrace: stackTrace, context: context);

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }

  /// Wrap an async function with error handling
  Future<T> wrapAsyncWithErrorHandling<T>(
    Future<T> Function() fn, {
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await fn();
    } catch (error, stackTrace) {
      handleError(error, stackTrace: stackTrace, context: context);

      if (defaultValue != null) {
        return defaultValue;
      }

      rethrow;
    }
  }

  /// Handle network errors specifically
  void handleNetworkError(
    dynamic error, {
    String? url,
    String? method,
    int? statusCode,
    StackTrace? stackTrace,
  }) {
    final context =
        'Network error${url != null ? ' for $method $url' : ''}${statusCode != null ? ' ($statusCode)' : ''}';
    handleError(error, stackTrace: stackTrace, context: context);

    // Log network-specific details
    _logger.network(
      method ?? 'UNKNOWN',
      url ?? 'unknown',
      statusCode: statusCode,
      data: error,
    );
  }

  /// Handle database errors specifically
  void handleDatabaseError(
    dynamic error, {
    String? operation,
    StackTrace? stackTrace,
  }) {
    final context =
        'Database error${operation != null ? ' during $operation' : ''}';
    handleError(error, stackTrace: stackTrace, context: context);

    _logger.database(operation ?? 'unknown operation', error: error);
  }

  /// Handle UI/rendering errors
  void handleUIError(
    dynamic error, {
    String? widgetName,
    StackTrace? stackTrace,
  }) {
    final context = 'UI error${widgetName != null ? ' in $widgetName' : ''}';
    handleError(error, stackTrace: stackTrace, context: context);
  }

  /// Handle authentication/security errors
  void handleSecurityError(
    dynamic error, {
    String? operation,
    StackTrace? stackTrace,
  }) {
    final context =
        'Security error${operation != null ? ' during $operation' : ''}';
    handleError(error, stackTrace: stackTrace, context: context);

    // Security errors are critical - log as fatal
    _logger.f('Security violation: $context', error, stackTrace);
  }

  /// Initialize global error handlers
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance.handleError(
        details.exception,
        stackTrace: details.stack,
        context: 'Flutter framework error',
      );
    };

    // Handle asynchronous errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      _instance.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Platform error',
      );
      return true; // Error handled
    };
  }
}

/// Global error handler instance for easy access
final errorHandler = ErrorHandler();
