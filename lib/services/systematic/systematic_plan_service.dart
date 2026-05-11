import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:workmanager/workmanager.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../domain/money.dart';
import '../logging/logger_service.dart';
import '../pricing/price_service.dart';
import '../notifications/notification_service.dart';
import '../../models/notifications.dart';

class SystematicPlanService {
  SystematicPlanService({
    required SystematicPlanDao planDao,
    required HoldingDao holdingDao,
    required TransactionDao transactionDao,
    required Ref ref,
  }) : _planDao = planDao,
       _holdingDao = holdingDao,
       _transactionDao = transactionDao,
       _ref = ref;
  final SystematicPlanDao _planDao;
  final HoldingDao _holdingDao;
  final TransactionDao _transactionDao;
  final Ref _ref;
  Timer? _checkTimer;

  /// Start background checking for due systematic plans
  void startBackgroundChecking() {
    // Check immediately
    _checkDuePlans();

    // Then check every hour
    _checkTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _checkDuePlans();
    });

    // Also schedule with workmanager for more reliable background execution
    Workmanager().registerPeriodicTask(
      'systematic_plan_check',
      'checkSystematicPlans',
      frequency: const Duration(hours: 1),
      initialDelay: const Duration(minutes: 5),
    );
  }

  /// Stop background checking
  void stopBackgroundChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check for due plans and execute them
  Future<void> _checkDuePlans() async {
    final now = DateTime.now();
    final activePlans = await _planDao.getActivePlans();

    for (final plan in activePlans) {
      if (_isPlanDue(plan, now)) {
        await _executePlan(plan);
      }
    }
  }

  /// Determine if a plan is due for execution
  bool _isPlanDue(SystematicPlan plan, DateTime now) {
    if (plan.endDate != null && now.isAfter(plan.endDate!)) {
      return false;
    }

    if (now.isBefore(plan.startDate)) {
      return false;
    }

    final lastExecution = _getLastExecutionDate(plan);
    final nextDue = _calculateNextDueDate(
      plan,
      lastExecution ?? plan.startDate,
    );

    return now.isAfter(nextDue) || now.isAtSameMomentAs(nextDue);
  }

  DateTime? _getLastExecutionDate(SystematicPlan plan) {
    return plan.lastExecutedAt;
  }

  DateTime _calculateNextDueDate(SystematicPlan plan, DateTime fromDate) {
    final frequency = plan.frequency;
    final dayOfMonth = plan.dayOfMonth;

    switch (frequency) {
      case 'daily':
        return fromDate.add(const Duration(days: 1));
      case 'weekly':
        return fromDate.add(const Duration(days: 7));
      case 'monthly':
        if (dayOfMonth != null) {
          // Dart DateTime overflows month/day correctly (e.g. month 13 → Jan next year)
          return DateTime(fromDate.year, fromDate.month + 1, dayOfMonth);
        } else {
          return DateTime(fromDate.year, fromDate.month + 1, fromDate.day);
        }
      case 'quarterly':
        return DateTime(fromDate.year, fromDate.month + 3, fromDate.day);
      case 'yearly':
        return DateTime(fromDate.year + 1, fromDate.month, fromDate.day);
      default:
        // For custom cron expressions, would need cron parser
        return fromDate.add(const Duration(days: 30));
    }
  }

  /// Execute a systematic plan (create transaction and update holding)
  Future<void> _executePlan(SystematicPlan plan) async {
    try {
      // Get the holding
      final holding = await _holdingDao.getById(plan.holdingId);
      if (holding == null) {
        await _planDao.cancelPlan(plan.id);
        return;
      }

      // Get instrument for price if needed
      // For SIP (buy), we need current price
      // For SWP (sell), we need current price and calculate quantity
      // For STP (transfer), we need source and destination holdings

      final instrument = await _holdingDao.getInstrument(holding.instrumentId);
      if (instrument == null) return;

      final amount = Money(
        minor: plan.amountMinor,
        currency: instrument.currency,
      );
      final now = DateTime.now();

      switch (plan.kind) {
        case 'sip':
          await _executeSip(plan, holding, amount, now);
          break;
        case 'swp':
          await _executeSwp(plan, holding, amount, now);
          break;
        case 'stp':
          await _executeStp(plan, holding, amount, now);
          break;
      }

      // Update last execution date
      await _planDao.updateLastExecutedAt(plan.id, now);

      try {
        final notificationService = _ref.read(notificationServiceProvider);
        await notificationService.showNotification(
          channel: NotificationChannel.sipSwpReminders,
          title: 'Plan Executed',
          body:
              'Your ${plan.kind.toUpperCase()} plan was executed successfully.',
          payload: NotificationPayload(
            type: 'plan_execution',
            planId: plan.id,
            holdingId: plan.holdingId,
          ),
        );
      } catch (e, stackTrace) {
        logger.e('Failed to send execution notification', e, stackTrace);
      }
    } catch (e, stackTrace) {
      // Log error but don't crash
      logger.e('Error executing plan ${plan.id}', e, stackTrace);
    }
  }

  Future<void> _executeSip(
    SystematicPlan plan,
    Holding holding,
    Money amount,
    DateTime executionDate,
  ) async {
    // For SIP, we're buying more of the same holding

    // Get current price from price service
    final instrument = await _holdingDao.getInstrument(holding.instrumentId);
    if (instrument == null) return;

    final priceService = _ref.read(priceServiceProvider);
    final price = await priceService.getLatestPrice(instrument);

    final quantity = amount.minor / price.minor;

    // Create transaction
    await _transactionDao.createTransaction(
      instrumentId: holding.instrumentId,
      type: 'buy',
      quantity: quantity,
      price: price,
      amount: amount.copyWith(minor: -amount.minor), // Negative for outflow
      currency: instrument.currency,
      date: executionDate,
      description: 'SIP execution for ${plan.id}',
      account: plan.fundingAccount,
    );

    // Update holding
    final currentQuantity = double.parse(holding.quantity);
    final newQuantity = currentQuantity + quantity;
    final newAvgPrice =
        ((currentQuantity * (holding.avgCostMinor / 100)) +
            (quantity * (price.minor / 100))) /
        newQuantity;

    await _holdingDao.updateQuantityAndAvgPrice(
      holding.id,
      newQuantity,
      Money(minor: (newAvgPrice * 100).round(), currency: instrument.currency),
    );
  }

  Future<void> _executeSwp(
    SystematicPlan plan,
    Holding holding,
    Money amount,
    DateTime executionDate,
  ) async {
    // For SWP, we're selling from the holding

    // Get current price from price service
    final instrument = await _holdingDao.getInstrument(holding.instrumentId);
    if (instrument == null) return;

    final priceService = _ref.read(priceServiceProvider);
    final price = await priceService.getLatestPrice(instrument);

    final currentQuantity = double.parse(holding.quantity);
    final quantity = amount.minor / price.minor;

    if (quantity > currentQuantity) {
      // Not enough holdings, pause plan and notify
      await _planDao.pausePlan(plan.id);
      return;
    }

    // Create transaction
    await _transactionDao.createTransaction(
      instrumentId: holding.instrumentId,
      type: 'sell',
      quantity: quantity,
      price: price,
      amount: amount, // Positive for inflow
      currency: instrument.currency,
      date: executionDate,
      description: 'SWP execution for ${plan.id}',
      account: plan.fundingAccount,
    );

    // Update holding
    final newQuantity = currentQuantity - quantity;
    await _holdingDao.updateQuantity(holding.id, newQuantity);
  }

  Future<void> _executeStp(
    SystematicPlan plan,
    Holding sourceHolding,
    Money amount,
    DateTime executionDate,
  ) async {
    // STP (Systematic Transfer Plan) transfers from one fund to another
    if (plan.destinationHoldingId == null) return;

    final destHolding = await _holdingDao.getById(plan.destinationHoldingId!);
    if (destHolding == null) return;

    // 1. Sell from source
    final sourceInstrument = await _holdingDao.getInstrument(
      sourceHolding.instrumentId,
    );
    if (sourceInstrument == null) return;

    final priceService = _ref.read(priceServiceProvider);
    final sourcePrice = await priceService.getLatestPrice(sourceInstrument);
    final sourceQuantity = amount.minor / sourcePrice.minor;

    final sourceQuantityValue = double.parse(sourceHolding.quantity);
    if (sourceQuantity > sourceQuantityValue) {
      await _planDao.pausePlan(plan.id);
      return;
    }

    await _transactionDao.createTransaction(
      instrumentId: sourceHolding.instrumentId,
      type: 'sell',
      quantity: sourceQuantity,
      price: sourcePrice,
      amount: amount,
      currency: sourceInstrument.currency,
      date: executionDate,
      description:
          'STP transfer from ${sourceInstrument.name} to ${destHolding.id}',
    );

    await _holdingDao.updateQuantity(
      sourceHolding.id,
      sourceQuantityValue - sourceQuantity,
    );

    // 2. Buy in destination
    final destInstrument = await _holdingDao.getInstrument(
      destHolding.instrumentId,
    );
    if (destInstrument == null) return;

    final destPrice = await priceService.getLatestPrice(destInstrument);
    final destQuantity = amount.minor / destPrice.minor;

    await _transactionDao.createTransaction(
      instrumentId: destHolding.instrumentId,
      type: 'buy',
      quantity: destQuantity,
      price: destPrice,
      amount: amount.copyWith(minor: -amount.minor),
      currency: destInstrument.currency,
      date: executionDate,
      description:
          'STP transfer from ${sourceHolding.id} to ${destInstrument.name}',
    );

    final destQuantityValue = double.parse(destHolding.quantity);
    final newQuantity = destQuantityValue + destQuantity;
    final newAvgPrice =
        ((destQuantityValue * (destHolding.avgCostMinor / 100)) +
            (destQuantity * (destPrice.minor / 100))) /
        newQuantity;

    await _holdingDao.updateQuantityAndAvgPrice(
      destHolding.id,
      newQuantity,
      Money(
        minor: (newAvgPrice * 100).round(),
        currency: destInstrument.currency,
      ),
    );
  }

  /// Create a new systematic plan
  Future<SystematicPlan> createPlan({
    required String holdingId,
    required String kind, // sip/swp/stp
    required Money amount,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
    int? dayOfMonth,
    String? fundingAccount,
    String? destinationHoldingId,
    String? notes,
  }) async {
    final plan = SystematicPlansCompanion(
      holdingId: Value(holdingId),
      kind: Value(kind),
      amountMinor: Value(amount.minor),
      frequency: Value(frequency),
      dayOfMonth: Value(dayOfMonth),
      startDate: Value(startDate),
      endDate: Value(endDate),
      status: const Value('active'),
      fundingAccount: Value(fundingAccount),
      destinationHoldingId: Value(destinationHoldingId),
      notes: Value(notes),
    );

    final id = await _planDao.insert(plan);
    return (await _planDao.getById(id))!;
  }

  /// Get all plans for a holding
  Future<List<SystematicPlan>> getPlansForHolding(String holdingId) {
    return _planDao.getByHoldingId(holdingId);
  }

  /// Get all active plans
  Future<List<SystematicPlan>> getActivePlans() {
    return _planDao.getActivePlans();
  }

  /// Update plan status
  Future<void> updatePlanStatus(String planId, String status) {
    switch (status) {
      case 'active':
        return _planDao.resumePlan(planId);
      case 'paused':
        return _planDao.pausePlan(planId);
      case 'cancelled':
        return _planDao.cancelPlan(planId);
      case 'completed':
        return _planDao.completePlan(planId);
      default:
        throw ArgumentError('Invalid status: $status');
    }
  }

  /// Delete a plan
  Future<void> deletePlan(String planId) {
    return _planDao.delete(planId);
  }

  /// Get plans due between two dates
  Future<List<SystematicPlan>> getPlansDueBetween(
    DateTime start,
    DateTime end,
  ) async {
    final allPlans = await _planDao.getActivePlans();
    return allPlans.where((plan) {
      final lastExec = _getLastExecutionDate(plan);
      final nextDue = _calculateNextDueDate(plan, lastExec ?? plan.startDate);
      return nextDue.isAfter(start.subtract(const Duration(seconds: 1))) &&
          nextDue.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }
}

final systematicPlanServiceProvider = Provider<SystematicPlanService>((ref) {
  return SystematicPlanService(
    planDao: ref.watch(systematicPlanDaoProvider),
    holdingDao: ref.watch(holdingDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    ref: ref,
  );
});

final systematicPlansProvider = StreamProvider<List<SystematicPlan>>((ref) {
  return ref.watch(systematicPlanDaoProvider).watchActivePlans();
});

final holdingSystematicPlansProvider =
    StreamProvider.family<List<SystematicPlan>, String>((ref, holdingId) {
      return ref.watch(systematicPlanDaoProvider).watchByHoldingId(holdingId);
    });
