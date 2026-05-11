import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'llm_provider.dart';
import '../services/logging/logger_service.dart';
import '../services/logging/error_handler.dart';

abstract class LlmService {
  Future<String> chatCompletion({
    required LlmProvider provider,
    required String prompt,
    required LlmTask task,
    List<String>? base64Images,
    bool stream = false,
  });

  Future<Map<String, dynamic>> testConnection(LlmProvider provider);
}

class HttpLlmService implements LlmService {
  HttpLlmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String _getModelForTask(LlmProvider provider, LlmTask task) {
    return provider.taskModelOverrides[task] ?? provider.model;
  }

  Map<String, String> _buildHeaders(LlmProvider provider) {
    final headers = {
      'Content-Type': 'application/json',
      ...provider.extraHeaders,
    };

    if (provider.apiKey != null && provider.apiKey!.isNotEmpty) {
      switch (provider.kind) {
        case LlmKind.openai:
        case LlmKind.openrouter:
          headers['Authorization'] = 'Bearer ${provider.apiKey}';
          break;
        case LlmKind.customOpenAiCompat:
          if (provider.apiKey!.isNotEmpty) {
            headers['Authorization'] = 'Bearer ${provider.apiKey}';
            headers['x-goog-api-key'] = provider.apiKey!;
          }
          break;
        case LlmKind.anthropic:
          headers['x-api-key'] = provider.apiKey!;
          headers['anthropic-version'] = '2023-06-01';
          break;
        case LlmKind.ollama:
          break;
        case LlmKind.gemini:
          // Gemini supports API key in header as well, which can help bypass some proxy issues on Web
          headers['x-goog-api-key'] = provider.apiKey!.trim();
          break;
      }
    }

    return headers;
  }

  String _buildEndpoint(LlmProvider provider, LlmTask task) {
    final base = provider.baseUrl.endsWith('/')
        ? provider.baseUrl.substring(0, provider.baseUrl.length - 1)
        : provider.baseUrl;

    switch (provider.kind) {
      case LlmKind.openai:
      case LlmKind.openrouter:
      case LlmKind.customOpenAiCompat:
        return '$base/chat/completions';
      case LlmKind.anthropic:
        return '$base/messages';
      case LlmKind.ollama:
        return '$base/api/chat';
      case LlmKind.gemini:
        final model = _getModelForTask(provider, task);
        final apiKey = provider.apiKey?.trim() ?? '';
        return '$base/models/$model:generateContent?key=$apiKey';
    }
  }

  Map<String, dynamic> _buildRequestBody({
    required LlmProvider provider,
    required String prompt,
    required LlmTask task,
    required bool stream,
    List<String>? base64Images,
  }) {
    final model = _getModelForTask(provider, task);
    final hasImages = base64Images != null && base64Images.isNotEmpty;

    switch (provider.kind) {
      case LlmKind.openai:
      case LlmKind.openrouter:
      case LlmKind.customOpenAiCompat:
        Object content;
        if (!hasImages) {
          content = prompt;
        } else {
          content = [
            {'type': 'text', 'text': prompt},
            ...base64Images.map(
              (img) => {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$img'},
              },
            ),
          ];
        }

        return {
          'model': model,
          'messages': [
            {'role': 'user', 'content': content},
          ],
          'temperature': provider.temperature,
          'max_tokens': provider.maxTokens,
          'stream': stream,
        };

      case LlmKind.anthropic:
        Object content;
        if (!hasImages) {
          content = prompt;
        } else {
          content = [
            ...base64Images.map(
              (img) => {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': img,
                },
              },
            ),
            {'type': 'text', 'text': prompt},
          ];
        }

        return {
          'model': model,
          'messages': [
            {'role': 'user', 'content': content},
          ],
          'max_tokens': provider.maxTokens,
          'temperature': provider.temperature,
        };

      case LlmKind.ollama:
        final body = {
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'stream': stream,
          'options': {
            'temperature': provider.temperature,
            'num_predict': provider.maxTokens,
          },
        };
        if (hasImages) {
          ((body['messages'] as List).first as Map<String, dynamic>)['images'] =
              base64Images;
        }
        return body;

      case LlmKind.gemini:
        final parts = <Map<String, dynamic>>[
          {'text': prompt},
        ];

        if (hasImages) {
          for (final img in base64Images) {
            parts.add({
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': img,
              },
            });
          }
        }

        return {
          'contents': [
            {
              'parts': parts,
            },
          ],
          'generationConfig': {
            'temperature': provider.temperature,
            'maxOutputTokens': provider.maxTokens,
          },
        };
    }
  }

  String _extractResponse(
    LlmProvider provider,
    Map<String, dynamic> responseBody,
  ) {
    try {
      switch (provider.kind) {
        case LlmKind.openai:
        case LlmKind.openrouter:
        case LlmKind.customOpenAiCompat:
          final choices = responseBody['choices'] as List<dynamic>?;
          if (choices == null || choices.isEmpty) {
            logger.w('LLM response has no choices: $responseBody');
            return '';
          }
          final firstChoice = choices[0] as Map<String, dynamic>?;
          final message = firstChoice?['message'] as Map<String, dynamic>?;
          final content = message?['content'];
          return content?.toString() ?? '';

        case LlmKind.anthropic:
          final contentList = responseBody['content'] as List<dynamic>?;
          if (contentList == null || contentList.isEmpty) {
            logger.w('LLM response has no content: $responseBody');
            return '';
          }
          return contentList.map((c) {
            final contentMap = c as Map<String, dynamic>;
            return contentMap['text']?.toString() ?? '';
          }).join();

        case LlmKind.ollama:
          final message = responseBody['message'] as Map<String, dynamic>?;
          final content = message?['content'];
          return content?.toString() ?? '';

        case LlmKind.gemini:
          final candidates = responseBody['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            logger.w('Gemini response has no candidates: $responseBody');
            return '';
          }
          final firstCandidate = candidates[0] as Map<String, dynamic>;
          final content = firstCandidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) {
            return '';
          }
          return parts.map((p) => (p as Map)['text']?.toString() ?? '').join();
      }
    } catch (e, stack) {
      logger.e('Error extracting LLM response content', e, stack);
      return '';
    }
  }

  @override
  Future<String> chatCompletion({
    required LlmProvider provider,
    required String prompt,
    required LlmTask task,
    List<String>? base64Images,
    bool stream = false,
  }) async {
    final body = _buildRequestBody(
      provider: provider,
      prompt: prompt,
      task: task,
      stream: stream,
      base64Images: base64Images,
    );

    final headers = _buildHeaders(provider);
    final endpoint = _buildEndpoint(provider, task);
    
    // Log a safe version of the endpoint
    final logEndpoint = provider.kind == LlmKind.gemini
        ? '${endpoint.split('?').first}?key=REDACTED'
        : endpoint;

    logger
      ..i('LLM Request: ${provider.kind.name} -> $logEndpoint')
      ..d('LLM Task: ${task.name}, Model: ${_getModelForTask(provider, task)}');

    final url = Uri.parse(endpoint);

    try {
      final timeout = (task == LlmTask.insights || task == LlmTask.parsing) 
          ? const Duration(seconds: 120) 
          : const Duration(seconds: 60);
      final response = await _client
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(timeout);

      logger.i('LLM Response: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.d('LLM Response Body: ${response.body}');
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        return _extractResponse(provider, responseBody);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ConfigurationException(
          'Authentication failed for ${provider.kind.displayName}. Please check your API key in Settings.',
          code: 'AUTH_FAILED',
        );
      } else {
        logger.e('LLM Error: ${response.statusCode}\n${response.body}');
        throw Exception(
          'LLM request failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e, stack) {
      if (e is ConfigurationException) rethrow;

      var errorMessage = 'LLM request failed';
      if (e is http.ClientException) {
        errorMessage = 'Network error: Check your internet connection.';
      } else if (e is TimeoutException) {
        errorMessage = 'Request timed out. The model took too long to respond. Please try again.';
      } else if (e is FormatException) {
        errorMessage = 'Invalid response from AI provider.';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      // Log as a warning if it's a timeout or network error, otherwise it will be logged by the caller
      if (e is TimeoutException || e is http.ClientException) {
        errorHandler.handleError(e, context: 'LLM Timeout/Network', stackTrace: stack);
      }
      
      throw Exception(errorMessage);
    }
  }

  @override
  Future<Map<String, dynamic>> testConnection(LlmProvider provider) async {
    final stopwatch = Stopwatch()..start();
    try {
      // Send a minimal test prompt
      const testPrompt = 'Respond with just the word "pong".';
      final response = await chatCompletion(
        provider: provider,
        prompt: testPrompt,
        task: LlmTask.parsing,
      );
      stopwatch.stop();

      return {
        'success': true,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'modelEcho': response.trim(),
        'error': null,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'latencyMs': stopwatch.elapsedMilliseconds,
        'modelEcho': null,
        'error': e.toString(),
      };
    }
  }
}

final llmServiceProvider = Provider<LlmService>((ref) {
  return HttpLlmService();
});
