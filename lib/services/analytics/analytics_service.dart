import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Analytics removed

/// Analytics event names used throughout the app
class AnalyticsEvents {
  // Authentication events
  static const String appLaunched = 'app_launched';
  static const String appBackgrounded = 'app_backgrounded';
  static const String appResumed = 'app_resumed';
  static const String biometricAuthEnabled = 'biometric_auth_enabled';
  static const String biometricAuthDisabled = 'biometric_auth_disabled';

  // Navigation events
  static const String screenView = 'screen_view';
  static const String navigation = 'navigation';

  // Portfolio events
  static const String holdingAdded = 'holding_added';
  static const String holdingUpdated = 'holding_updated';
  static const String holdingDeleted = 'holding_deleted';
  static const String holdingImported = 'holding_imported';

  // Transaction events
  static const String transactionAdded = 'transaction_added';
  static const String transactionUpdated = 'transaction_updated';
  static const String transactionDeleted = 'transaction_deleted';

  // Systematic plan events
  static const String systematicPlanCreated = 'systematic_plan_created';
  static const String systematicPlanUpdated = 'systematic_plan_updated';
  static const String systematicPlanDeleted = 'systematic_plan_deleted';
  static const String systematicPlanExecuted = 'systematic_plan_executed';

  // Calculator events
  static const String calculatorUsed = 'calculator_used';
  static const String xirrCalculated = 'xirr_calculated';
  static const String fdRdCalculated = 'fd_rd_calculated';
  static const String ppfCalculated = 'ppf_calculated';
  static const String loanAmortizationCalculated =
      'loan_amortization_calculated';
  static const String rentalYieldCalculated = 'rental_yield_calculated';
  static const String cryptoCostBasisCalculated =
      'crypto_cost_basis_calculated';
  static const String stakingProjected = 'staking_projected';
  static const String occupancyTracked = 'occupancy_tracked';

  // Insights events
  static const String insightGenerated = 'insight_generated';
  static const String aiChatMessage = 'ai_chat_message';
  static const String llmProviderChanged = 'llm_provider_changed';

  // News events
  static const String newsViewed = 'news_viewed';
  static const String newsSourceSelected = 'news_source_selected';

  // Settings events
  static const String notificationEnabled = 'notification_enabled';
  static const String notificationDisabled = 'notification_disabled';
  static const String currencyChanged = 'currency_changed';
  static const String themeChanged = 'theme_changed';
  static const String backupCreated = 'backup_created';
  static const String backupRestored = 'backup_restored';

  // Error events
  static const String errorOccurred = 'error_occurred';
  static const String networkError = 'network_error';
  static const String databaseError = 'database_error';
  static const String authenticationError = 'authentication_error';

  // Performance events
  static const String performanceMetric = 'performance_metric';
  static const String slowOperation = 'slow_operation';
}

/// Analytics user properties
class AnalyticsUserProperties {
  static const String hasHoldings = 'has_holdings';
  static const String holdingsCount = 'holdings_count';
  static const String totalPortfolioValue = 'total_portfolio_value';
  static const String hasSystematicPlans = 'has_systematic_plans';
  static const String systematicPlansCount = 'systematic_plans_count';
  static const String preferredCurrency = 'preferred_currency';
  static const String biometricAuthEnabled = 'biometric_auth_enabled';
  static const String privacyModeEnabled = 'privacy_mode_enabled';
  static const String notificationSettings = 'notification_settings';
  static const String appVersion = 'app_version';
}

/// Interface for analytics services
abstract class AnalyticsService {
  /// Initialize the analytics service
  Future<void> initialize();

  /// Log an event with optional parameters
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters});

  /// Set a user property
  Future<void> setUserProperty(String name, dynamic value);

  /// Set user ID for analytics
  Future<void> setUserId(String? userId);

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass});

  /// Log error with context
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  });

  /// Log performance metric
  Future<void> logPerformance(
    String metricName,
    Duration duration, {
    Map<String, dynamic>? attributes,
  });

  /// Enable/disable analytics collection
  Future<void> setAnalyticsCollectionEnabled(bool enabled);

  /// Reset analytics data (for testing or logout)
  Future<void> resetAnalyticsData();
}

/// Mock implementation for development/testing
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {
    // No-op for mock
  }

  @override
  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    // Print to console in debug mode
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $eventName, Parameters: $parameters');
    }
  }

  @override
  Future<void> setUserProperty(String name, dynamic value) async {
    if (kDebugMode) {
      debugPrint('[Analytics] User Property: $name = $value');
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    if (kDebugMode) {
      debugPrint('[Analytics] User ID: $userId');
    }
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Screen View: $screenName (class: $screenClass)');
    }
  }

  @override
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Error: $context - $error\n$stackTrace');
    }
  }

  @override
  Future<void> logPerformance(
    String metricName,
    Duration duration, {
    Map<String, dynamic>? attributes,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[Analytics] Performance: $metricName took ${duration.inMilliseconds}ms',
      );
    }
  }

  @override
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Collection enabled: $enabled');
    }
  }

  @override
  Future<void> resetAnalyticsData() async {
    if (kDebugMode) {
      debugPrint('[Analytics] Data reset');
    }
  }
}

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  // Console logging implementation
  return MockAnalyticsService();
});

/// Helper class to simplify analytics calls
class AnalyticsHelper {
  AnalyticsHelper(this._service);
  final AnalyticsService _service;

  /// Log app lifecycle events
  Future<void> logAppLaunched() async {
    await _service.logEvent(AnalyticsEvents.appLaunched);
  }

  Future<void> logAppBackgrounded() async {
    await _service.logEvent(AnalyticsEvents.appBackgrounded);
  }

  Future<void> logAppResumed() async {
    await _service.logEvent(AnalyticsEvents.appResumed);
  }

  /// Log navigation events
  Future<void> logScreenView(String screenName) async {
    await _service.logScreenView(screenName);
  }

  /// Log portfolio events
  Future<void> logHoldingAdded({
    String? instrumentType,
    String? currency,
  }) async {
    final params = <String, dynamic>{};
    if (instrumentType != null) params['instrument_type'] = instrumentType;
    if (currency != null) params['currency'] = currency;
    await _service.logEvent(AnalyticsEvents.holdingAdded, parameters: params);
  }

  Future<void> logHoldingUpdated({String? instrumentType}) async {
    final params = <String, dynamic>{};
    if (instrumentType != null) params['instrument_type'] = instrumentType;
    await _service.logEvent(AnalyticsEvents.holdingUpdated, parameters: params);
  }

  Future<void> logHoldingDeleted({String? instrumentType}) async {
    final params = <String, dynamic>{};
    if (instrumentType != null) params['instrument_type'] = instrumentType;
    await _service.logEvent(AnalyticsEvents.holdingDeleted, parameters: params);
  }

  Future<void> logHoldingImported({String? importType, int? count}) async {
    final params = <String, dynamic>{};
    if (importType != null) params['import_type'] = importType;
    if (count != null) params['count'] = count;
    await _service.logEvent(
      AnalyticsEvents.holdingImported,
      parameters: params,
    );
  }

  /// Log calculator usage
  Future<void> logCalculatorUsed(
    String calculatorName, {
    Map<String, dynamic>? parameters,
  }) async {
    final params = parameters ?? <String, dynamic>{};
    params['calculator_name'] = calculatorName;
    await _service.logEvent(AnalyticsEvents.calculatorUsed, parameters: params);
  }

  /// Log error with context
  Future<void> logErrorWithContext(
    dynamic error,
    StackTrace? stackTrace,
    String context,
  ) async {
    await _service.logError(error, stackTrace, context: context);
  }

  /// Log performance metric
  Future<void> logPerformanceMetric(
    String operation,
    Duration duration, {
    Map<String, dynamic>? additionalParams,
  }) async {
    final params = additionalParams ?? <String, dynamic>{};
    params['duration_ms'] = duration.inMilliseconds;
    params['operation'] = operation;
    await _service.logEvent(
      AnalyticsEvents.performanceMetric,
      parameters: params,
    );
  }
}

/// Provider for analytics helper
final analyticsHelperProvider = Provider<AnalyticsHelper>((ref) {
  final service = ref.watch(analyticsServiceProvider);
  return AnalyticsHelper(service);
});
