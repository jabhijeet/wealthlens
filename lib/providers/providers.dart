import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db/daos.dart';

// Export all service providers so they are available via providers.dart
export '../services/pricing/price_service.dart';
export '../services/pricing/price_feed.dart';
export '../services/news/news_service.dart';
export '../llm/llm_service.dart';
export '../llm/llm_provider.dart';
export '../services/import/document_parser_service.dart';
export '../services/fx/fx_service.dart';
export '../services/security/encryption_service.dart';
export '../services/notifications/notification_service.dart';
export '../services/systematic/systematic_plan_service.dart';
export '../services/backup/backup_service.dart';
export '../services/insights/insights_service.dart';
export '../services/fundamental/fundamental_service.dart';
export '../features/holdings/models/holding_with_instrument.dart';
export '../services/security/security_service.dart';

// --- Theme & UI Providers ---

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final settingDao = ref.read(settingDaoProvider);
    final val = await settingDao.getValue('theme_mode');
    if (val != null) {
      state = ThemeMode.values.firstWhere(
        (e) => e.name == val,
        orElse: () => ThemeMode.system,
      );
    }
  }

  ThemeMode get mode => state;
  set mode(ThemeMode value) {
    state = value;
    ref.read(settingDaoProvider).setValue('theme_mode', value.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class PrivacyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final settingDao = ref.read(settingDaoProvider);
    final val = await settingDao.getValue('privacy_mode_enabled');
    state = val == 'true';
  }

  bool get isEnabled => state;
  set isEnabled(bool value) {
    state = value;
    ref
        .read(settingDaoProvider)
        .setValue('privacy_mode_enabled', value.toString());
  }
}

final privacyModeProvider = NotifierProvider<PrivacyModeNotifier, bool>(
  PrivacyModeNotifier.new,
);

// --- Domain/Logic Providers ---

class ActiveCurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    _load();
    return 'INR';
  }

  Future<void> _load() async {
    final settingDao = ref.read(settingDaoProvider);
    final val = await settingDao.getValue('base_currency');
    if (val != null) {
      state = val;
    }
  }

  String get currency => state;
  set currency(String value) {
    state = value;
    ref.read(settingDaoProvider).setValue('base_currency', value);
  }
}

final activeCurrencyProvider = NotifierProvider<ActiveCurrencyNotifier, String>(
  ActiveCurrencyNotifier.new,
);


// Alias for activeCurrencyProvider if needed for legacy support
final selectedCurrencyProvider = activeCurrencyProvider;
