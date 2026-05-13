import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/db/daos.dart';
import '../../providers/providers.dart';
import '../../core/theme.dart';
import '../../widgets/llm_status_box.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, bool> _notificationSettings = {
    'price_alerts': false,
    'daily_digest': true,
    'weekly_review': true,
    'news_alerts': true,
    'sip_swp_reminders': true,
    'fd_maturity': true,
    'rd_installment': true,
    'ppf_deposit': true,
    'insurance_premium': true,
    'rent_due': true,
    'rent_overdue': true,
    'lease_expiry': true,
    'vacancy_alert': true,
    'property_loan_emi': true,
    'property_valuation_stale': true,
    'crypto_staking_unlock': true,
    'crypto_large_move': false,
    'stablecoin_depeg': true,
    'nft_floor_drop': false,
    'goal_milestones': true,
    'data_freshness': false,
    'llm_job_completed': false,
  };

  bool _biometricsEnabled = false;
  bool _autoGenerateInsights = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final security = ref.read(securityServiceProvider);
    final settingDao = ref.read(settingDaoProvider);

    final bio = await security.isBiometricEnabled();
    final autoInsightsStr =
        await settingDao.getValue('auto_generate_insights') ?? 'true';

    final loadedNotifications = Map<String, bool>.of(_notificationSettings);
    for (final key in loadedNotifications.keys) {
      final valStr = await settingDao.getValue('notify_$key');
      if (valStr != null) {
        loadedNotifications[key] = valStr == 'true';
      }
    }

    if (mounted) {
      setState(() {
        _biometricsEnabled = bio;
        _autoGenerateInsights = autoInsightsStr == 'true';
        _notificationSettings.addAll(loadedNotifications);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const LlmStatusBox(),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                style: GoogleFonts.sora(fontSize: 13),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildAllSections(),
              const SizedBox(height: 32),
              _buildFooter(),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAllSections() {
    final sections = [
      _buildSecuritySection(),
      _buildGeneralSection(),
      _buildNotificationsSection(),
      _buildAiSection(),
      _buildDataSection(),
    ];

    final filteredSections = sections
        .where((section) => section != null)
        .cast<Widget>()
        .toList();

    if (filteredSections.isEmpty && _searchQuery.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('No settings found matching your search'),
            ],
          ),
        ),
      );
    }

    return Column(children: filteredSections);
  }

  Widget? _buildSecuritySection() {
    return _buildFilteredSection(
      title: 'Security',
      icon: Icons.security,
      items: [
        _SettingItem(
          title: 'Biometric Lock',
          subtitle: 'Require authentication to open the app',
          icon: Icons.fingerprint,
          trailing: Switch(
            value: _biometricsEnabled,
            onChanged: (value) async {
              final security = ref.read(securityServiceProvider);
              await security.setBiometricEnabled(value);
              setState(() => _biometricsEnabled = value);
            },
          ),
        ),
        _SettingItem(
          title: 'Privacy Mode',
          subtitle: 'Mask sensitive amounts on screens',
          icon: Icons.visibility_off,
          trailing: Switch(
            value: ref.watch(privacyModeProvider),
            onChanged: (value) async {
              ref.read(privacyModeProvider.notifier).isEnabled = value;
            },
          ),
        ),
        _SettingItem(
          title: 'Backup & Restore',
          subtitle: 'Export or import your portfolio data',
          icon: Icons.backup,
          onTap: _showBackupRestoreDialog,
        ),
      ],
    );
  }

  Widget? _buildGeneralSection() {
    return _buildFilteredSection(
      title: 'General',
      icon: Icons.settings,
      items: [
        _SettingItem(
          title: 'Base Currency',
          subtitle: ref.watch(activeCurrencyProvider),
          icon: Icons.currency_exchange,
          onTap: _showCurrencyPicker,
        ),
        _SettingItem(
          title: 'Theme Mode',
          subtitle: ref.watch(themeModeProvider).name.toUpperCase(),
          icon: Icons.palette,
          onTap: _showThemePicker,
        ),
      ],
    );
  }

  Widget? _buildNotificationsSection() {
    final notificationItems = _notificationSettings.entries.map((entry) {
      return _SettingItem(
        title: _formatNotificationTitle(entry.key),
        subtitle: _formatNotificationSubtitle(entry.key),
        icon: _getNotificationIcon(entry.key),
        trailing: Switch(
          value: entry.value,
          onChanged: (value) async {
            final settingDao = ref.read(settingDaoProvider);
            await settingDao.setValue('notify_${entry.key}', value.toString());
            setState(() {
              _notificationSettings[entry.key] = value;
            });
          },
        ),
      );
    }).toList();

    return _buildFilteredSection(
      title: 'Notifications',
      icon: Icons.notifications,
      items: [...notificationItems],
    );
  }

  Widget? _buildAiSection() {
    return _buildFilteredSection(
      title: 'AI & Insights',
      icon: Icons.psychology,
      items: [
        _SettingItem(
          title: 'API Configuration',
          subtitle: 'Configure AI and Market Data keys',
          icon: Icons.api_rounded,
          onTap: () => context.push('/settings/llm-providers'),
        ),
        _SettingItem(
          title: 'Auto-generate Insights',
          subtitle: 'Automatically generate portfolio insights',
          icon: Icons.auto_graph,
          trailing: Switch(
            value: _autoGenerateInsights,
            onChanged: (value) async {
              final settingDao = ref.read(settingDaoProvider);
              await settingDao.setValue(
                'auto_generate_insights',
                value.toString(),
              );
              setState(() => _autoGenerateInsights = value);
            },
          ),
        ),
      ],
    );
  }

  Widget? _buildDataSection() {
    return _buildFilteredSection(
      title: 'Data Management',
      icon: Icons.storage,
      items: [
        _SettingItem(
          title: 'FX Rates',
          subtitle: 'Manage currency exchange rates',
          icon: Icons.currency_exchange_rounded,
          onTap: () => context.push('/settings/fx-rates'),
        ),
        _SettingItem(
          title: 'Clear Cache',
          subtitle: 'Clear cached prices and FX rates',
          icon: Icons.cleaning_services,
          onTap: _showClearCacheDialog,
        ),
      ],
    );
  }





  Widget? _buildFilteredSection({
    required String title,
    required IconData icon,
    required List<_SettingItem> items,
  }) {
    final filteredItems = items.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item.title.toLowerCase().contains(_searchQuery) ||
          (item.subtitle?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();

    if (filteredItems.isEmpty) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              for (int i = 0; i < filteredItems.length; i++) ...[
                _buildItemRow(filteredItems[i]),
                if (i < filteredItems.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(_SettingItem item) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(item.icon, size: 18),
      title: Text(
        item.title,
        style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: item.subtitle != null
          ? Text(
              item.subtitle!,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing:
          item.trailing ??
          (item.onTap != null
              ? const Icon(Icons.chevron_right, size: 18)
              : null),
      onTap: item.onTap,
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'WealthLens',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: WealthColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2026 WealthLens',
          style: GoogleFonts.sora(fontSize: 12, color: WealthColors.textMuted),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => context.push('/settings/privacy-policy'),
              child: Text(
                'Privacy Policy',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: WealthColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '·',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: WealthColors.textMuted,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/settings/terms-of-service'),
              child: Text(
                'Terms of Service',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: WealthColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Dialogs & Actions ---

  Future<void> _showBackupRestoreDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Text(
          'Would you like to backup your data or restore from an existing backup?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );

                if (result != null && result.files.single.path != null) {
                  final backupService = ref.read(backupServiceProvider);
                  // For now, assume no password or ask in a real app
                  await backupService.importBackupFromFile(
                    result.files.single.path!,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restore successful!')),
                    );
                    // Refresh data
                    ref.invalidate(holdingsWithInstrumentsProvider);
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
                }
              }
            },
            child: const Text('Restore'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final backupService = ref.read(backupServiceProvider);
                final file = await backupService.saveBackupToFile();
                final info = await backupService.getBackupInfo(file);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup successful!\n$info')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
                }
              }
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: RadioGroup<ThemeMode>(
          groupValue: ref.watch(themeModeProvider),
          onChanged: (val) {
            if (val != null) {
              ref.read(themeModeProvider.notifier).mode = val;
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(mode.name.toUpperCase()),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _showCurrencyPicker() async {
    final currencies = ['USD', 'INR', 'SGD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Base Currency'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer(
              builder: (context, ref, child) {
                final currentBase = ref.watch(activeCurrencyProvider);
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final currency = currencies[index];
                    return ListTile(
                      title: Text(currency),
                      trailing: currency == currentBase
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: WealthColors.primary,
                            )
                          : null,
                      onTap: () async {
                        ref.read(activeCurrencyProvider.notifier).currency =
                            currency;
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }



  Future<void> _showClearCacheDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached prices, FX rates, and news data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final priceDao = ref.read(priceSnapshotDaoProvider);
              final fxDao = ref.read(fxRateDaoProvider);
              await priceDao.clearAll();
              await fxDao.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared successfully')),
                );
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTitle(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }

  String _formatNotificationSubtitle(String key) {
    switch (key) {
      case 'price_alerts':
        return 'Price threshold alerts for holdings';
      case 'daily_digest':
        return 'Daily portfolio summary';
      case 'weekly_review':
        return 'Weekly performance review';
      case 'news_alerts':
        return 'Important news for your holdings';
      case 'sip_swp_reminders':
        return 'Reminders for systematic plans';
      case 'fd_maturity':
        return 'FD maturity reminders';
      case 'rd_installment':
        return 'RD installment reminders';
      case 'ppf_deposit':
        return 'PPF deposit window reminders';
      case 'insurance_premium':
        return 'Insurance premium due reminders';
      case 'rent_due':
        return 'Rent payment reminders';
      case 'rent_overdue':
        return 'Rent overdue alerts';
      case 'lease_expiry':
        return 'Lease expiry reminders';
      case 'vacancy_alert':
        return 'Vacancy alerts for properties';
      case 'property_loan_emi':
        return 'Property loan EMI reminders';
      case 'property_valuation_stale':
        return 'Property valuation update reminders';
      case 'crypto_staking_unlock':
        return 'Crypto staking unlock reminders';
      case 'crypto_large_move':
        return 'Large crypto price move alerts';
      case 'stablecoin_depeg':
        return 'Stablecoin depeg alerts';
      case 'nft_floor_drop':
        return 'NFT floor price drop alerts';
      case 'goal_milestones':
        return 'Goal progress milestone alerts';
      case 'data_freshness':
        return 'Data freshness warnings';
      case 'llm_job_completed':
        return 'LLM analysis completion alerts';
      default:
        return '';
    }
  }

  IconData _getNotificationIcon(String key) {
    switch (key) {
      case 'price_alerts':
        return Icons.trending_up;
      case 'daily_digest':
        return Icons.today;
      case 'weekly_review':
        return Icons.view_week;
      case 'news_alerts':
        return Icons.newspaper;
      case 'sip_swp_reminders':
        return Icons.event_repeat;
      case 'fd_maturity':
        return Icons.account_balance;
      case 'rd_installment':
        return Icons.savings;
      case 'ppf_deposit':
        return Icons.account_balance_wallet;
      case 'insurance_premium':
        return Icons.health_and_safety;
      case 'rent_due':
        return Icons.house;
      case 'rent_overdue':
        return Icons.warning_amber;
      case 'lease_expiry':
        return Icons.assignment_return;
      case 'vacancy_alert':
        return Icons.door_front_door;
      case 'property_loan_emi':
        return Icons.real_estate_agent;
      case 'property_valuation_stale':
        return Icons.refresh;
      case 'crypto_staking_unlock':
        return Icons.lock_open;
      case 'crypto_large_move':
        return Icons.currency_bitcoin;
      case 'stablecoin_depeg':
        return Icons.money_off;
      case 'nft_floor_drop':
        return Icons.image_not_supported;
      case 'goal_milestones':
        return Icons.flag;
      case 'data_freshness':
        return Icons.history;
      case 'llm_job_completed':
        return Icons.done_all;
      default:
        return Icons.notifications;
    }
  }
}

class _SettingItem {
  _SettingItem({
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
}
