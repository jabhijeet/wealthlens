import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../providers/providers.dart';

import '../../app/router.dart';
import 'package:go_router/go_router.dart';
import '../logging/error_handler.dart';
import 'background_dispatcher.dart';
import '../logging/logger_service.dart';

import '../../models/notifications.dart';

class NotificationService {
  NotificationService({
    required NotificationDao notificationDao,
    required SystematicPlanService systematicPlanService,
    required FdRdAccountDao fdDao,
    required InsurancePolicyDao insDao,
    required RealEstateHoldingDao realEstateDao,
    required HoldingDao holdingDao,
    required PriceSnapshotDao priceSnapshotDao,
    required this.newsService,
    required this.priceService,
    required this.insightsService,
    required SettingDao settingDao,
  }) : _notificationDao = notificationDao,
       _systematicPlanService = systematicPlanService,
       _fdDao = fdDao,
       _insDao = insDao,
       _realEstateDao = realEstateDao,
       _holdingDao = holdingDao,
       _priceSnapshotDao = priceSnapshotDao,
       _settingDao = settingDao;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final NotificationDao _notificationDao;
  final SystematicPlanService _systematicPlanService;
  final FdRdAccountDao _fdDao;
  final InsurancePolicyDao _insDao;
  final RealEstateHoldingDao _realEstateDao;
  final HoldingDao _holdingDao;
  final PriceSnapshotDao _priceSnapshotDao;
  final PriceService priceService;
  final NewsService newsService;
  final InsightsService insightsService;
  final SettingDao _settingDao;

  /// Price movement threshold (5%) to trigger an alert
  static const double _priceAlertThresholdPct = 0.05;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    if (kIsWeb) {
      // Local notifications and Workmanager have limited/different support on web.
      // Skipping for now to ensure app stability.
      return;
    }

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Initialize workmanager for background tasks
    await Workmanager().initialize(callbackDispatcher);

    // Schedule periodic tasks
    await _scheduleBackgroundTasks();
  }

  Future<void> _createNotificationChannels() async {
    for (final channel in NotificationChannel.values) {
      final androidChannel = AndroidNotificationChannel(
        channel.id,
        channel.name,
        importance: channel.importance,
        description: '${channel.name} notifications',
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);
    }
  }

  Future<void> _scheduleBackgroundTasks() async {
    // Schedule daily digest at 9 AM
    await Workmanager().registerPeriodicTask(
      'daily_digest',
      'dailyDigestTask',
      frequency: const Duration(hours: 24),
      initialDelay: _calculateInitialDelay(9), // 9 AM
    );

    // Schedule weekly review on Monday at 10 AM
    await Workmanager().registerPeriodicTask(
      'weekly_review',
      'weeklyReviewTask',
      frequency: const Duration(days: 7),
      initialDelay: _calculateInitialDelay(10, weekday: DateTime.monday),
    );

    // Schedule price check every 4 hours
    await Workmanager().registerPeriodicTask(
      'price_check',
      'priceCheckTask',
      frequency: const Duration(hours: 4),
    );

    // Schedule systematic plan check every hour
    await Workmanager().registerPeriodicTask(
      'systematic_plan_check',
      'systematicPlanCheckTask',
      frequency: const Duration(hours: 1),
    );

    // Schedule maturity/rent/insurance check daily at 8 AM
    await Workmanager().registerPeriodicTask(
      'daily_reminders',
      'dailyRemindersTask',
      frequency: const Duration(hours: 24),
      initialDelay: _calculateInitialDelay(8),
    );
  }

  Duration _calculateInitialDelay(int hour, {int? weekday}) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour);

    if (weekday != null) {
      final daysUntilWeekday = (weekday - now.weekday + 7) % 7;
      target = target.add(Duration(days: daysUntilWeekday));
    }

    if (target.isBefore(now)) {
      target = target.add(Duration(days: weekday != null ? 7 : 1));
    }

    return target.difference(now);
  }

  Future<void> showNotification({
    required NotificationChannel channel,
    required String title,
    required String body,
    NotificationPayload? payload,
    int? notificationId,
  }) async {
    // Check if notification is enabled for this channel
    final enabledStr = await _settingDao.getValue('notify_${channel.id}');
    // Default to true if not set (except for some noisy ones)
    final isEnabled = enabledStr != 'false';

    if (!isEnabled) {
      // Still log to database but don't show toast/system notification
      await _notificationDao.insertNotification(
        type: channel.id,
        title: title,
        body: body,
        payloadJson: payload != null ? jsonEncode(payload.toJson()) : null,
      );
      return;
    }

    // Use channel+title hash so same alert type doesn't stack; stays within Android int range
    final id =
        notificationId ??
        (channel.id.hashCode ^ title.hashCode).abs() % 0x7FFFFFFF;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: '${channel.name} notifications',
      importance: channel.importance,
      priority: Priority.high,
      ticker: 'ticker',
    );

    final iosDetails = DarwinNotificationDetails(
      categoryIdentifier: channel.id,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload != null ? jsonEncode(payload.toJson()) : null,
    );

    // Log notification to database
    await _notificationDao.insertNotification(
      type: channel.id,
      title: title,
      body: body,
      payloadJson: payload != null ? jsonEncode(payload.toJson()) : null,
    );
  }

  /// Check all holdings with price snapshots for significant price movements.
  ///
  /// Compares the PREVIOUS cached snapshot to the LATEST fetched price.
  /// If the movement exceeds [_priceAlertThresholdPct], a notification fires.
  Future<void> checkPriceAlerts() async {
    try {
      final holdings = await _holdingDao.getAllWithInstruments();

      // Only check priceable asset classes
      final priceableHoldings = holdings.where((h) {
        final ac = h.instrument.assetClass;
        return ac == AssetClass.equity ||
            ac == AssetClass.etf ||
            ac == AssetClass.mutualFund ||
            ac == AssetClass.cryptoSpot ||
            ac == AssetClass.cryptoStaked ||
            ac == AssetClass.realEstateReit;
      }).toList();

      for (final h in priceableHoldings) {
        try {
          // Get the last cached snapshot (before fetching fresh)
          final previousSnapshot = await _priceSnapshotDao.getLatest(
            h.instrument.id,
          );

          // Fetch a fresh price (PriceService updates the cache)
          final freshPrice = await priceService.getLatestPrice(h.instrument);

          if (previousSnapshot == null) {
            // No previous baseline — skip alert for first-time fetch
            continue;
          }

          final prevMinor = previousSnapshot.closeMinor;
          if (prevMinor == 0) continue; // Avoid divide-by-zero

          final changePct =
              (freshPrice.minor - prevMinor).abs() / prevMinor.abs();

          if (changePct >= _priceAlertThresholdPct) {
            final direction = freshPrice.minor > prevMinor ? '▲' : '▼';
            final changePctStr = (changePct * 100).toStringAsFixed(1);
            final symbol = h.instrument.symbol ?? h.instrument.name;

            await showNotification(
              channel: NotificationChannel.priceAlerts,
              title: 'Price Alert: $symbol $direction $changePctStr%',
              body:
                  '${h.instrument.name} moved $changePctStr% since your last check.',
              payload: NotificationPayload(
                type: 'price_alert',
                holdingId: h.holding.id,
                instrumentId: h.instrument.id,
                extra: {
                  'prevMinor': prevMinor,
                  'freshMinor': freshPrice.minor,
                  'changePct': changePct,
                },
              ),
            );
          }
        } catch (e, st) {
          // Swallow per-instrument errors so the loop continues
          logger.w(
            'Price alert check failed for ${h.instrument.symbol}',
            e,
            st,
          );
        }
      }
    } catch (e, st) {
      errorHandler.handleError(e, stackTrace: st, context: 'checkPriceAlerts');
    }
  }

  Future<void> checkSystematicPlanReminders() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Get systematic plans due tomorrow or today
    final plans = await _systematicPlanService.getPlansDueBetween(
      now,
      tomorrow,
    );

    for (final plan in plans) {
      await showNotification(
        channel: NotificationChannel.sipSwpReminders,
        title: '${plan.kind.toUpperCase()} Reminder',
        body: 'Your ${plan.kind} for ${plan.holdingId} is due tomorrow',
        payload: NotificationPayload(
          type: 'systematic_plan',
          planId: plan.id,
          holdingId: plan.holdingId,
        ),
      );
    }
  }

  Future<void> checkFdMaturityReminders() async {
    final now = DateTime.now();
    final thresholds = [30, 7, 1]; // Days before maturity

    final fds = await _fdDao.getAll();
    for (final fd in fds) {
      final daysToMaturity = fd.maturityDate.difference(now).inDays;
      if (thresholds.contains(daysToMaturity)) {
        await showNotification(
          channel: NotificationChannel.fdMaturity,
          title: 'FD Maturity Alert',
          body: 'Your FD (${fd.holdingId}) is maturing in $daysToMaturity days',
          payload: NotificationPayload(
            type: 'fd_maturity',
            holdingId: fd.holdingId,
          ),
        );
      }
    }
  }

  Future<void> checkInsurancePremiumReminders() async {
    final now = DateTime.now();
    final policies = await _insDao.getAll();
    for (final policy in policies) {
      // Estimate next premium date based on frequency and start date
      final nextPremiumDate = _nextPremiumDate(
        policy.startDate,
        policy.premiumFrequency,
        now,
      );
      if (nextPremiumDate != null) {
        final daysUntilPremium = nextPremiumDate.difference(now).inDays;
        if (daysUntilPremium == 15 ||
            daysUntilPremium == 3 ||
            daysUntilPremium == 0) {
          await showNotification(
            channel: NotificationChannel.insurancePremium,
            title: 'Insurance Premium Reminder',
            body:
                'Premium for policy ${policy.policyNumber} is due in $daysUntilPremium day${daysUntilPremium == 1 ? '' : 's'}',
            payload: NotificationPayload(
              type: 'insurance',
              holdingId: policy.holdingId,
            ),
          );
        }
      }
    }
  }

  /// Check real estate holdings for upcoming rent collection dates.
  Future<void> checkRentDueReminders() async {
    final now = DateTime.now();
    final properties = await _realEstateDao.getAll();

    for (final prop in properties) {
      // Skip if not rented / no rent day configured
      final rentDay = prop.rentDueDayOfMonth;
      if (rentDay == null || rentDay == 0) continue;
      if (prop.occupancyStatus != 'occupied') continue;

      // Calculate next rent due date
      var nextDue = DateTime(now.year, now.month, rentDay);
      if (nextDue.isBefore(now)) {
        // Already passed this month, go to next month
        nextDue = DateTime(now.year, now.month + 1, rentDay);
      }

      final daysUntilRent = nextDue.difference(now).inDays;

      if (daysUntilRent <= 2) {
        // Spec: T-2 and T-0 before rentDueDayOfMonth
        var propertyLabel = prop.holdingId;
        try {
          final holding = await _holdingDao.getById(prop.holdingId);
          if (holding != null) {
            final instrument = await _holdingDao.getInstrument(
              holding.instrumentId,
            );
            if (instrument != null) propertyLabel = instrument.name;
          }
        } catch (_) {}

        final body = daysUntilRent == 0
            ? 'Rent for $propertyLabel is due today!'
            : 'Rent for $propertyLabel is due in $daysUntilRent day${daysUntilRent == 1 ? '' : 's'}';

        await showNotification(
          channel: NotificationChannel.rentDue,
          title: daysUntilRent == 0 ? 'Rent Due Today' : 'Rent Due Soon',
          body: body,
          payload: NotificationPayload(
            type: 'rent_due',
            holdingId: prop.holdingId,
          ),
        );
      }
    }
  }

  Future<void> checkNewsAlerts() async {
    try {
      final news = await newsService.getNewsForHoldings(limitPerHolding: 1);
      final importantNews = news
          .where((n) => (n.sentimentScore ?? 0).abs() > 0.5)
          .toList();

      if (importantNews.isNotEmpty) {
        final article = importantNews.first;
        await showNotification(
          channel: NotificationChannel.newsAlerts,
          title: 'Important News: ${article.symbols.join(', ')}',
          body: article.title,
          payload: NotificationPayload(type: 'news', newsId: article.id),
        );
      }
    } catch (e, st) {
      errorHandler.handleError(e, stackTrace: st, context: 'checkNewsAlerts');
    }
  }

  Future<void> sendDailyDigest() async {
    try {
      final insights = await insightsService.generateInsights();

      if (insights.isEmpty) return;

      // Filter for most important ones for the notification body
      final topInsights = insights.take(2).toList();
      final body = topInsights.map((i) => '• ${i.title}').join('\n');

      await showNotification(
        channel: NotificationChannel.dailyDigest,
        title: 'Daily Portfolio Digest',
        body: body.isNotEmpty
            ? body
            : 'Check your portfolio performance for today',
        payload: NotificationPayload(type: 'daily_digest'),
      );
    } catch (e, st) {
      logger.e('Failed to send daily digest', e, st);
    }
  }

  Future<void> sendWeeklyReview() async {
    try {
      final insights = await insightsService.generateInsights();

      if (insights.isEmpty) return;

      final summary = await insightsService.generateDetailedAnalysis(
        insights: insights,
      );

      // Take first line or two for the notification
      final body = summary
          .split('\n')
          .firstWhere(
            (line) => line.trim().isNotEmpty && !line.startsWith('#'),
            orElse: () => 'Your weekly portfolio review is ready',
          );

      await showNotification(
        channel: NotificationChannel.weeklyReview,
        title: 'Weekly Portfolio Review',
        body: body,
        payload: NotificationPayload(type: 'weekly_review'),
      );
    } catch (e, st) {
      logger.e('Failed to send weekly review', e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await _notificationDao.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    await _notificationDao.markAllAsRead();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notificationDao.deleteNotification(notificationId);
  }

  Future<void> clearAllNotifications() async {
    await _notificationDao.clearAllNotifications();
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr != null) {
      try {
        final decoded = jsonDecode(payloadStr);
        if (decoded is Map<String, dynamic>) {
          final payload = NotificationPayload.fromJson(decoded);
          final context = rootNavigatorKey.currentContext;
          if (context != null && context.mounted) {
            switch (payload.type) {
              case 'news':
                GoRouter.of(context).push('/news');
                break;
              case 'systematic_plan':
                GoRouter.of(context).push('/systematic-plans');
                break;
              default:
                if (payload.holdingId != null) {
                  GoRouter.of(context).push('/holdings/${payload.holdingId}');
                } else {
                  GoRouter.of(context).push('/');
                }
            }
          }
        }
      } catch (e, st) {
        // Log gracefully instead of silent fail
        errorHandler.handleError(
          e,
          stackTrace: st,
          context: '_onNotificationTapped',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Calculate next premium date given frequency + start date.
  DateTime? _nextPremiumDate(
    DateTime startDate,
    String frequency,
    DateTime now,
  ) {
    if (frequency.toLowerCase() == 'single') return null;

    // Walk forward using calendar arithmetic to avoid month-length drift
    var candidate = startDate;
    while (candidate.isBefore(now)) {
      switch (frequency.toLowerCase()) {
        case 'monthly':
          candidate = DateTime(
            candidate.year,
            candidate.month + 1,
            candidate.day,
          );
          break;
        case 'quarterly':
          candidate = DateTime(
            candidate.year,
            candidate.month + 3,
            candidate.day,
          );
          break;
        case 'half-yearly':
          candidate = DateTime(
            candidate.year,
            candidate.month + 6,
            candidate.day,
          );
          break;
        case 'yearly':
          candidate = DateTime(
            candidate.year + 1,
            candidate.month,
            candidate.day,
          );
          break;
        default:
          return null;
      }
    }
    return candidate;
  }
}



// Riverpod provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    notificationDao: ref.watch(notificationDaoProvider),
    systematicPlanService: ref.watch(systematicPlanServiceProvider),
    fdDao: ref.watch(fdRdAccountDaoProvider),
    insDao: ref.watch(insurancePolicyDaoProvider),
    realEstateDao: ref.watch(realEstateHoldingDaoProvider),
    holdingDao: ref.watch(holdingDaoProvider),
    priceSnapshotDao: ref.watch(priceSnapshotDaoProvider),
    newsService: ref.watch(newsServiceProvider),
    priceService: ref.watch(priceServiceProvider),
    insightsService: ref.watch(insightsServiceProvider),
    settingDao: ref.watch(settingDaoProvider),
  );
});
