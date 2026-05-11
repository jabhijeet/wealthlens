import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../services/logging/logger_service.dart';
import '../../llm/llm_service.dart';
import '../../llm/llm_provider.dart';
import '../../data/db/daos.dart';
import '../../widgets/loading_indicator.dart';
import '../../core/theme.dart';
import '../../widgets/llm_status_box.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    'Analyze my portfolio',
    'Show asset allocation',
    'Any risky holdings?',
    'Dividend forecast',
    'Tax optimization tips',
    'Suggest rebalancing',
  ];

  Future<void> _sendMessage([String? overrideText]) async {
    final text = overrideText ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final provider = ref.read(activeLlmProvider);

      if (provider == null || !provider.isConfigured) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'LLM not configured. Please set up an API key in Settings.',
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => context.push('/settings/llm-providers'),
              ),
            ),
          );
        }
        setState(() {
          _messages
              .removeLast(); // Remove the user message since we won't process it
          _isLoading = false;
        });
        return;
      }

      final llmService = ref.read(llmServiceProvider);

      final holdingDao = ref.read(holdingDaoProvider);
      final holdings = await holdingDao.getAll();
      final portfolioContext = holdings
          .map((h) => '${h.id} (${h.instrumentId}): ${h.quantity} units')
          .join(', ');

      final prompt =
          'Context: Portfolio contains $portfolioContext\n\nUser Question: $text';

      final response = await llmService.chatCompletion(
        provider: provider,
        prompt: prompt,
        task: LlmTask.insights,
      );

      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e, stack) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '$e'.replaceFirst('Exception: ', ''),
          'isError': 'true',
        });
      });
      logger.e('AI Chat Error', e, stack);
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(100.ms, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: WealthColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: WealthColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI Assistant',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: LlmStatusBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: WealthColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            size: 40,
                            color: WealthColors.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Ask me about your portfolio',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'I can analyze your holdings, suggest\nimprovements, and answer questions.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return _ChatBubble(
                        content: msg['content']!,
                        isUser: isUser,
                        isDark: isDark,
                        isError: msg['isError'] == 'true',
                      )
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.1, end: 0);
                    },
                  ),
          ),

          // Typing indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  WealthLoadingIndicator(size: 20),
                  SizedBox(width: 12),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: WealthColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Suggested Prompts
          if (_messages.isEmpty && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _suggestedPrompts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final prompt = _suggestedPrompts[index];
                    return ActionChip(
                      label: Text(
                        prompt,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WealthColors.primary,
                        ),
                      ),
                      onPressed: () => _sendMessage(prompt),
                      backgroundColor: WealthColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            ),

          if (_messages.isNotEmpty && !_isLoading) const SizedBox(height: 8),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? WealthColors.cardDark : WealthColors.cardLight,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? WealthColors.borderDark
                      : WealthColors.borderLight,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? WealthColors.cardDarkElevated
                            : const Color(0xFFF0F1F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ask about your portfolio...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: WealthColors.textMuted,
                          ),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                        onSubmitted: (_) => _sendMessage(),
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: WealthColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _isLoading ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.content,
    required this.isUser,
    required this.isDark,
    this.isError = false,
  });
  final String content;
  final bool isUser;
  final bool isDark;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    Color bubbleColor;
    if (isUser) {
      bubbleColor = WealthColors.primary;
    } else if (isError) {
      bubbleColor = WealthColors.error.withValues(alpha: 0.1);
    } else {
      bubbleColor =
          isDark ? WealthColors.cardDarkElevated : const Color(0xFFF0F1F5);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isError
                    ? WealthColors.error.withValues(alpha: 0.1)
                    : WealthColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isError ? Icons.error_outline_rounded : Icons.smart_toy_rounded,
                size: 16,
                color: isError ? WealthColors.error : WealthColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                border: isError
                    ? Border.all(
                        color: WealthColors.error.withValues(alpha: 0.3),
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser
                          ? Colors.white
                          : isError
                              ? WealthColors.error
                              : null,
                    ),
                  ),
                  if (isError && (content.contains('API key') || content.contains('Settings')))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () => context.push('/settings/llm-providers'),
                        icon: const Icon(Icons.settings_rounded, size: 16),
                        label: const Text('Go to Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: WealthColors.error,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: WealthColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 16,
                color: WealthColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
