import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/db/daos.dart';
import '../../llm/llm_provider.dart';
import '../../llm/llm_service.dart';
import '../../services/news/news_service.dart';
import '../../core/theme.dart';

class LlmProvidersScreen extends ConsumerStatefulWidget {
  const LlmProvidersScreen({super.key});

  @override
  ConsumerState<LlmProvidersScreen> createState() => _LlmProvidersScreenState();
}

class _LlmProvidersScreenState extends ConsumerState<LlmProvidersScreen> {
  List<LlmProvider> _providers = [];
  String? _finnhubApiKey;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingDao = ref.read(settingDaoProvider);
    final providersJson = await settingDao.getValue('llm_providers');
    final finnhubKey = await settingDao.getValue('finnhub_api_key');

    if (providersJson != null) {
      try {
        final decoded = jsonDecode(providersJson) as List<dynamic>;
        _providers = decoded
            .map((e) => LlmProvider.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _providers = [];
      }
    }

    _finnhubApiKey = finnhubKey;

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProviders() async {
    final settingDao = ref.read(settingDaoProvider);
    final providersJson = jsonEncode(
      _providers.map((e) => e.toJson()).toList(),
    );
    await settingDao.setValue('llm_providers', providersJson);

    final active =
        _providers.firstWhereOrNull((LlmProvider p) => p.isDefault) ??
        (_providers.isNotEmpty ? _providers.first : null);

    if (active != null) {
      await settingDao.setValue('active_llm_provider_id', active.id);
      ref.read(activeLlmProvider.notifier).provider = active;
    }
  }

  Future<void> _saveFinnhubKey(String key) async {
    await ref.read(finnhubApiKeyProvider.notifier).updateKey(key);
    setState(() {
      _finnhubApiKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'API Configuration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEditProviderDialog,
        label: const Text('Add Provider'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          _buildSectionHeader(
            'Market Data',
            'Required for real-time stock prices and market news.',
            Icons.show_chart_rounded,
            WealthColors.success,
          ),
          const SizedBox(height: 16),
          _buildFinnhubCard(isDark),
          const SizedBox(height: 32),
          _buildSectionHeader(
            'AI Providers',
            'Connect LLMs for document parsing and portfolio insights.',
            Icons.psychology_rounded,
            WealthColors.primary,
          ),
          const SizedBox(height: 16),
          if (_providers.isEmpty)
            _buildEmptyState()
          else
            ..._providers
                .map((p) => _buildProviderCard(p, isDark))
                .toList()
                .animate(interval: 50.ms)
                .fadeIn()
                .slideX(begin: 0.05, end: 0),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            subtitle,
            style: GoogleFonts.sora(
              fontSize: 12,
              color: WealthColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinnhubCard(bool isDark) {
    final hasKey = _finnhubApiKey?.isNotEmpty == true;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasKey
              ? WealthColors.success.withValues(alpha: 0.3)
              : (isDark ? WealthColors.borderDark : WealthColors.borderLight),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          'Finnhub API',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          hasKey ? '••••••••••••' : 'Key not configured',
          style: GoogleFonts.sora(
            color: hasKey ? WealthColors.success : WealthColors.textMuted,
            fontWeight: hasKey ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, size: 20),
              onPressed: () =>
                  _showKeyInfoDialog('Finnhub', 'https://finnhub.io/dashboard'),
              tooltip: 'How to get a key',
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: _showFinnhubKeyDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasKey ? null : WealthColors.success,
                foregroundColor: hasKey ? null : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(hasKey ? 'Edit' : 'Connect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(LlmProvider provider, bool isDark) {
    final isActive = provider.isDefault;
    final color = _getProviderColor(provider.kind);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.5)
              : (isDark ? WealthColors.borderDark : WealthColors.borderLight),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForKind(provider.kind),
                color: color,
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    provider.kind.displayName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${provider.model} • ${provider.baseUrl}',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  color: WealthColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) => _handleMenuAction(value, provider),
              itemBuilder: (context) => [
                if (!isActive)
                  const PopupMenuItem(
                    value: 'active',
                    child: Text('Set as Active'),
                  ),
                const PopupMenuItem(
                  value: 'test',
                  child: Text('Test Connection'),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit Settings'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Icon(
                  provider.apiKey != null
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  size: 14,
                  color: provider.apiKey != null
                      ? WealthColors.success
                      : WealthColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  provider.apiKey != null
                      ? 'API Key Secure'
                      : (provider.kind == LlmKind.ollama
                            ? 'No Key Required (Local)'
                            : 'Missing API Key'),
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: provider.apiKey != null
                        ? WealthColors.success
                        : WealthColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showKeyInfoDialog(
                    provider.kind.displayName,
                    _getKeyUrl(provider.kind),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: WealthColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Get Key',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: WealthColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: WealthColors.textMuted.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: WealthColors.textMuted.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.psychology_alt_rounded,
            size: 48,
            color: WealthColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No AI Providers Found',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: WealthColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a provider to enable parsing and insights',
            textAlign: TextAlign.center,
            style: GoogleFonts.sora(
              fontSize: 13,
              color: WealthColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value, LlmProvider provider) {
    if (value == 'edit') {
      _showEditProviderDialog(provider);
    } else if (value == 'delete') {
      _deleteProvider(provider.id);
    } else if (value == 'test') {
      _testConnection(provider);
    } else if (value == 'active') {
      _setDefaultProvider(provider.id);
    }
  }

  Color _getProviderColor(LlmKind kind) {
    switch (kind) {
      case LlmKind.openai:
        return const Color(0xFF10a37f);
      case LlmKind.anthropic:
        return const Color(0xFFd97757);
      case LlmKind.ollama:
        return const Color(0xFF2d3748);
      case LlmKind.openrouter:
        return const Color(0xFF6366f1);
      case LlmKind.customOpenAiCompat:
        return WealthColors.accent;
      case LlmKind.gemini:
        return const Color(0xFF4285F4);
    }
  }

  IconData _getIconForKind(LlmKind kind) {
    switch (kind) {
      case LlmKind.openai:
        return Icons.auto_awesome_rounded;
      case LlmKind.anthropic:
        return Icons.blur_on_rounded;
      case LlmKind.ollama:
        return Icons.terminal_rounded;
      case LlmKind.openrouter:
        return Icons.hub_rounded;
      case LlmKind.customOpenAiCompat:
        return Icons.settings_input_component_rounded;
      case LlmKind.gemini:
        return Icons.rocket_launch_rounded;
    }
  }

  String _getKeyUrl(LlmKind kind) {
    switch (kind) {
      case LlmKind.openai:
        return 'https://platform.openai.com/api-keys';
      case LlmKind.anthropic:
        return 'https://console.anthropic.com/settings/keys';
      case LlmKind.openrouter:
        return 'https://openrouter.ai/keys';
      case LlmKind.gemini:
        return 'https://aistudio.google.com/app/apikey';
      default:
        return '';
    }
  }

  void _showKeyInfoDialog(String provider, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Get $provider Key',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To use $provider, you need to create an API key from their official dashboard.',
              style: GoogleFonts.sora(),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                onTap: () => launchUrl(Uri.parse(url)),
                child: Text(
                  'Visit Dashboard ↗',
                  style: GoogleFonts.sora(
                    color: WealthColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _setDefaultProvider(String id) {
    setState(() {
      _providers = _providers
          .map((p) => p.copyWith(isDefault: p.id == id))
          .toList();
    });
    _saveProviders();
  }

  void _deleteProvider(String id) {
    setState(() {
      _providers.removeWhere((p) => p.id == id);
    });
    _saveProviders();
  }

  Future<void> _testConnection(LlmProvider provider) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Testing connection...')));

    final service = ref.read(llmServiceProvider);
    final result = await service.testConnection(provider);

    if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            (result['success'] as bool? ?? false)
                ? 'Connection Success'
                : 'Connection Failed',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result['success'] as bool? ?? false) ...[
                _buildTestResultRow(
                  Icons.timer_outlined,
                  'Latency',
                  '${result['latencyMs']}ms',
                ),
                _buildTestResultRow(
                  Icons.model_training_outlined,
                  'Model',
                  '${result['modelEcho']}',
                ),
              ] else ...[
                Text(
                  'Error: ${result['error']}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTestResultRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: WealthColors.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.sora(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.sora(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinnhubKeyDialog() {
    final controller = TextEditingController(text: _finnhubApiKey);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Finnhub Configuration',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Required for Indian & Global stock pricing updates.',
              style: GoogleFonts.sora(
                fontSize: 13,
                color: WealthColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter your key',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveFinnhubKey(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save Key'),
          ),
        ],
      ),
    );
  }

  void _showEditProviderDialog([LlmProvider? provider]) {
    final isEditing = provider != null;
    final id = provider?.id ?? const Uuid().v4();
    var kind = provider?.kind ?? LlmKind.openai;

    final modelController = TextEditingController(
      text: provider?.model ?? 'gpt-4o',
    );
    final baseUrlController = TextEditingController(
      text: provider?.baseUrl ?? 'https://api.openai.com/v1',
    );
    final apiKeyController = TextEditingController(
      text: provider?.apiKey ?? '',
    );

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isEditing ? 'Edit Provider' : 'New Provider',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<LlmKind>(
                  initialValue: kind,
                  decoration: const InputDecoration(labelText: 'Provider Type'),
                  items: LlmKind.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        kind = value;
                        if (value == LlmKind.openai) {
                          baseUrlController.text = 'https://api.openai.com/v1';
                        } else if (value == LlmKind.anthropic) {
                          baseUrlController.text =
                              'https://api.anthropic.com/v1';
                        } else if (value == LlmKind.ollama) {
                          baseUrlController.text = 'http://localhost:11434';
                        } else if (value == LlmKind.openrouter) {
                          baseUrlController.text =
                              'https://openrouter.ai/api/v1';
                        } else if (value == LlmKind.gemini) {
                          baseUrlController.text =
                              'https://generativelanguage.googleapis.com/v1beta';
                          modelController.text = 'gemini-1.5-flash';
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model Name (e.g. gpt-4o)',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baseUrlController,
                  decoration: const InputDecoration(labelText: 'Base URL'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: kind == LlmKind.ollama
                        ? 'Optional for local Ollama'
                        : 'Required for ${kind.displayName}',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newProvider = LlmProvider(
                  id: id,
                  kind: kind,
                  model: modelController.text.trim(),
                  baseUrl: baseUrlController.text.trim(),
                  apiKey: apiKeyController.text.trim().isEmpty
                      ? null
                      : apiKeyController.text.trim(),
                  isDefault: provider?.isDefault ?? _providers.isEmpty,
                );

                setState(() {
                  if (isEditing) {
                    final index = _providers.indexWhere((p) => p.id == id);
                    _providers[index] = newProvider;
                  } else {
                    _providers.add(newProvider);
                  }
                });
                _saveProviders();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashStyle {
  const DashStyle({required this.array});
  final List<double> array;
}
