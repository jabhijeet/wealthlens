import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import '../services/logging/logger_service.dart';
import '../data/db/daos.dart';

part 'llm_provider.freezed.dart';
part 'llm_provider.g.dart';

enum LlmKind {
  openai,
  anthropic,
  ollama,
  openrouter,
  customOpenAiCompat,
  gemini,
}

extension LlmKindExtension on LlmKind {
  String get displayName {
    switch (this) {
      case LlmKind.openai:
        return 'OpenAI';
      case LlmKind.anthropic:
        return 'Anthropic';
      case LlmKind.ollama:
        return 'Ollama (Local)';
      case LlmKind.openrouter:
        return 'OpenRouter';
      case LlmKind.customOpenAiCompat:
        return 'Custom API (OpenAI Compatible)';
      case LlmKind.gemini:
        return 'Google Gemini';
    }
  }
}

enum LlmTask { parsing, insights, newsSummary, marketData }

@freezed
abstract class LlmProvider with _$LlmProvider {
  const factory LlmProvider({
    required String id,
    required LlmKind kind,
    required String baseUrl,
    String? apiKey,
    required String model,
    @Default({}) Map<String, String> extraHeaders,
    @Default(0.2) double temperature,
    @Default(2000) int maxTokens,
    @Default(false) bool isDefault,
    @Default({}) Map<LlmTask, String?> taskModelOverrides,
  }) = _LlmProvider;

  const LlmProvider._();

  factory LlmProvider.fromJson(Map<String, dynamic> json) =>
      _$LlmProviderFromJson(json);

  bool get isConfigured {
    if (kind == LlmKind.ollama) return true;
    if (kind == LlmKind.customOpenAiCompat) return true;
    return apiKey != null && apiKey!.trim().isNotEmpty;
  }
}

final activeLlmProvider =
    NotifierProvider<ActiveLlmProviderNotifier, LlmProvider?>(
      ActiveLlmProviderNotifier.new,
    );

class ActiveLlmProviderNotifier extends Notifier<LlmProvider?> {
  @override
  LlmProvider? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final settingDao = ref.read(settingDaoProvider);
      final providersJson = await settingDao.getValue('llm_providers');
      var providers = <LlmProvider>[];

      if (providersJson != null) {
        final decoded = jsonDecode(providersJson) as List<dynamic>;
        providers = decoded
            .map((e) => LlmProvider.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        // Provide defaults if none exist
        providers = _getDefaultProviders();
        await settingDao.setValue(
          'llm_providers',
          jsonEncode(providers.map((e) => e.toJson()).toList()),
        );
      }

      var activeId = await settingDao.getValue('active_llm_provider_id');

      if (activeId == null && providers.isNotEmpty) {
        activeId = providers
            .firstWhere((p) => p.isDefault, orElse: () => providers.first)
            .id;
        await settingDao.setValue('active_llm_provider_id', activeId);
      }

      state = providers.firstWhereOrNull((p) => p.id == activeId);
    } catch (e, stack) {
      logger.e('Error loading LLM providers', e, stack);
    }
  }

  List<LlmProvider> _getDefaultProviders() {
    const uuid = Uuid();
    return [
      LlmProvider(
        id: uuid.v4(),
        kind: LlmKind.openrouter,
        baseUrl: 'https://openrouter.ai/api/v1',
        model: 'openrouter/free',
        isDefault: true,
      ),
      LlmProvider(
        id: uuid.v4(),
        kind: LlmKind.openai,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o',
      ),
      LlmProvider(
        id: uuid.v4(),
        kind: LlmKind.anthropic,
        baseUrl: 'https://api.anthropic.com/v1',
        model: 'claude-3-5-sonnet-20241022',
      ),
      LlmProvider(
        id: uuid.v4(),
        kind: LlmKind.gemini,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        model: 'gemini-1.5-flash',
      ),
    ];
  }

  LlmProvider? get provider => state;
  set provider(LlmProvider? value) => state = value;
}
