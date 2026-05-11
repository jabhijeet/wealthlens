import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationChannel {
  priceAlerts('price_alerts', 'Price Alerts', Importance.high),
  dailyDigest('daily_digest', 'Daily Digest', Importance.defaultImportance),
  weeklyReview('weekly_review', 'Weekly Review', Importance.defaultImportance),
  newsAlerts('news_alerts', 'News Alerts', Importance.high),
  sipSwpReminders('sip_swp_reminders', 'SIP/SWP Reminders', Importance.high),
  fdMaturity('fd_maturity', 'FD Maturity', Importance.high),
  rdInstallment('rd_installment', 'RD Installment', Importance.high),
  ppfDeposit('ppf_deposit', 'PPF Deposit', Importance.defaultImportance),
  insurancePremium('insurance_premium', 'Insurance Premium', Importance.high),
  rentDue('rent_due', 'Rent Due', Importance.defaultImportance),
  rentOverdue('rent_overdue', 'Rent Overdue', Importance.high),
  leaseExpiry('lease_expiry', 'Lease Expiry', Importance.defaultImportance),
  vacancyAlert('vacancy_alert', 'Vacancy Alert', Importance.low),
  propertyLoanEmi('property_loan_emi', 'Property Loan EMI', Importance.high),
  propertyValuationStale(
    'property_valuation_stale',
    'Property Valuation Stale',
    Importance.low,
  ),
  cryptoStakingUnlock(
    'crypto_staking_unlock',
    'Crypto Staking Unlock',
    Importance.defaultImportance,
  ),
  cryptoLargeMove('crypto_large_move', 'Crypto Large Move', Importance.high),
  stablecoinDepeg('stablecoin_depeg', 'Stablecoin Depeg', Importance.high),
  nftFloorDrop(
    'nft_floor_drop',
    'NFT Floor Drop',
    Importance.defaultImportance,
  ),
  goalMilestones(
    'goal_milestones',
    'Goal Milestones',
    Importance.defaultImportance,
  ),
  dataFreshness('data_freshness', 'Data Freshness', Importance.low),
  llmJobCompleted('llm_job_completed', 'LLM Job Completed', Importance.low);

  const NotificationChannel(this.id, this.name, this.importance);

  final String id;
  final String name;
  final Importance importance;
}

class NotificationPayload {
  NotificationPayload({
    required this.type,
    this.holdingId,
    this.instrumentId,
    this.planId,
    this.newsId,
    this.extra,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      type: json['type']?.toString() ?? 'unknown',
      holdingId: json['holdingId']?.toString(),
      instrumentId: json['instrumentId']?.toString(),
      planId: json['planId']?.toString(),
      newsId: json['newsId']?.toString(),
      extra: json['extra'] is Map<String, dynamic>
          ? json['extra'] as Map<String, dynamic>
          : null,
    );
  }
  final String type;
  final String? holdingId;
  final String? instrumentId;
  final String? planId;
  final String? newsId;
  final Map<String, dynamic>? extra;

  Map<String, dynamic> toJson() => {
    'type': type,
    'holdingId': holdingId,
    'instrumentId': instrumentId,
    'planId': planId,
    'newsId': newsId,
    'extra': extra,
  };
}
