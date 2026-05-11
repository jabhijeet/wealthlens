import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/logger_service.dart';
import '../../llm/llm_service.dart';
import '../../llm/llm_provider.dart';
import '../../llm/prompts/document_parsing_prompts.dart';
import '../../data/db/daos.dart';
import '../../data/db/database.dart';
import '../../domain/money.dart';

import '../../models/import.dart';

class DocumentParserService {
  DocumentParserService({
    required LlmService llmService,
    required InstrumentDao instrumentDao,
    required HoldingDao holdingDao,
    required TransactionDao transactionDao,
    required FdRdAccountDao fdDao,
    required PpfAccountDao ppfDao,
    required InsurancePolicyDao insDao,
  }) : _llmService = llmService,
       _instrumentDao = instrumentDao,
       _holdingDao = holdingDao,
       _transactionDao = transactionDao,
       _fdDao = fdDao,
       _ppfDao = ppfDao,
       _insDao = insDao;

  final LlmService _llmService;
  final InstrumentDao _instrumentDao;
  final HoldingDao _holdingDao;
  final TransactionDao _transactionDao;
  final FdRdAccountDao _fdDao;
  final PpfAccountDao _ppfDao;
  final InsurancePolicyDao _insDao;

  Future<Map<String, dynamic>> parseImage(
    List<String> base64Images, {
    LlmProvider? provider,
  }) async {
    if (provider == null) {
      throw Exception('LLM provider not configured');
    }

    final response = await _llmService.chatCompletion(
      provider: provider,
      prompt: DocumentParsingPrompts.visionCombinedExtractionPrompt,
      task: LlmTask.parsing,
      base64Images: base64Images,
    );

    final jsonStr = _extractJson(response);
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      logger.w('LLM returned non-map for parseImage: $jsonStr');
      return {};
    } catch (e) {
      logger.e('Failed to parse LLM response as JSON: $jsonStr', e);
      return {};
    }
  }

  Future<DocumentMetadata> classifyDocument(
    String text, {
    LlmProvider? provider,
  }) async {
    if (provider == null) {
      throw Exception('LLM provider not configured');
    }

    final prompt = DocumentParsingPrompts.documentClassificationPrompt
        .replaceFirst('{text}', text);

    final response = await _llmService.chatCompletion(
      provider: provider,
      prompt: prompt,
      task: LlmTask.parsing,
    );

    // Clean up response if it contains markdown code blocks
    final jsonStr = _extractJson(response);
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return DocumentMetadata.fromJson(decoded);
      }
      throw Exception(
        'LLM returned non-map for document classification: $jsonStr',
      );
    } catch (e) {
      logger.e('Failed to classify document: $jsonStr', e);
      // Return a "fallback" metadata instead of crashing
      return DocumentMetadata(
        documentType: 'other',
        institution: 'Unknown',
        containsHoldings: false,
        containsTransactions: false,
      );
    }
  }

  Future<List<ParsedHolding>> extractHoldings(
    String text, {
    LlmProvider? provider,
  }) async {
    if (provider == null) {
      throw Exception('LLM provider not configured');
    }

    final prompt = DocumentParsingPrompts.holdingsExtractionPrompt.replaceFirst(
      '{text}',
      text,
    );

    final response = await _llmService.chatCompletion(
      provider: provider,
      prompt: prompt,
      task: LlmTask.parsing,
    );

    final jsonStr = _extractJson(response);
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .map((item) => ParsedHolding.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      logger.w('LLM returned non-list for holdings: $jsonStr');
      return [];
    } catch (e) {
      logger.e('Failed to parse holdings from LLM: $jsonStr', e);
      return [];
    }
  }

  Future<List<ParsedTransaction>> extractTransactions(
    String text, {
    LlmProvider? provider,
  }) async {
    if (provider == null) {
      throw Exception('LLM provider not configured');
    }

    final prompt = DocumentParsingPrompts.transactionsExtractionPrompt
        .replaceFirst('{text}', text);

    final response = await _llmService.chatCompletion(
      provider: provider,
      prompt: prompt,
      task: LlmTask.parsing,
    );

    final jsonStr = _extractJson(response);
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded
            .map(
              (item) =>
                  ParsedTransaction.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      logger.w('LLM returned non-list for transactions: $jsonStr');
      return [];
    } catch (e) {
      logger.e('Failed to parse transactions from LLM: $jsonStr', e);
      return [];
    }
  }

  String _extractJson(String text) {
    logger.d('Raw LLM Response: $text');
    var result = text.trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      logger.w('LLM returned empty or null response');
      return '[]'; // Return empty array as a safe default for parsing
    }

    // LLMs often wrap JSON in ```json ... ```
    if (text.contains('```')) {
      final startIndex = text.indexOf('```json');
      if (startIndex != -1) {
        final start = startIndex + 7;
        final end = text.indexOf('```', start);
        if (end != -1) {
          result = text.substring(start, end).trim();
        }
      } else {
        final startIndex = text.indexOf('```');
        if (startIndex != -1) {
          final start = startIndex + 3;
          final end = text.indexOf('```', start);
          if (end != -1) {
            result = text.substring(start, end).trim();
          }
        }
      }
    }

    // Final check for valid JSON start/end if result is still not empty
    if (result.isNotEmpty &&
        !result.startsWith('{') &&
        !result.startsWith('[') &&
        result.toLowerCase() != 'null') {
      // If it doesn't look like JSON, try to find the first { or [
      final firstBrace = result.indexOf('{');
      final firstBracket = result.indexOf('[');

      var start = -1;
      if (firstBrace != -1 &&
          (firstBracket == -1 || firstBrace < firstBracket)) {
        start = firstBrace;
      } else if (firstBracket != -1) {
        start = firstBracket;
      }

      if (start != -1) {
        final lastBrace = result.lastIndexOf('}');
        final lastBracket = result.lastIndexOf(']');
        final end = lastBrace > lastBracket ? lastBrace : lastBracket;

        if (end != -1 && end > start) {
          result = result.substring(start, end + 1);
        }
      }
    }

    logger.d('Extracted JSON: $result');
    return result;
  }

  Future<void> saveParsedHoldings(List<ParsedHolding> holdings) async {
    for (final parsed in holdings) {
      // Create or find instrument
      final instrument = await _instrumentDao.getOrCreateInstrument(
        symbol: parsed.symbol,
        name: parsed.name,
        assetClass: parsed.assetClass,
        currency: parsed.currency,
        country: parsed.country,
        exchange: parsed.exchange,
        isin: parsed.isin,
      );

      // Create holding
      final holdingId = await _holdingDao.createHolding(
        instrumentId: instrument.id,
        quantity: parsed.quantity,
        averagePrice: Money.fromDouble(
          parsed.averagePrice,
          currency: parsed.currency,
        ),
        openedOn: parsed.purchaseDate,
        currency: parsed.currency,
        accountNumber: parsed.accountNumber,
        folioNumber: parsed.folioNumber,
      );

      // For FD/RD/PPF/Insurance, create specific accounts
      if (parsed.assetClass == 'fixedDeposit' ||
          parsed.assetClass == 'recurringDeposit') {
        final principal = Money.fromDouble(
          parsed.quantity,
          currency: parsed.currency,
        );
        await _fdDao.insert(
          FdRdAccountsCompanion(
            holdingId: Value(holdingId),
            principalMinor: Value(principal.minor),
            annualRatePct: Value(parsed.interestRate?.toString() ?? '0.0'),
            startDate: Value(DateTime.now()),
            maturityDate: Value(parsed.maturityDate ?? DateTime.now()),
            compoundingFrequency: const Value('quarterly'),
          ),
        );
      } else if (parsed.assetClass == 'ppf') {
        await _ppfDao.insert(
          PpfAccountsCompanion(
            holdingId: Value(holdingId),
            contributionsJson: const Value('[]'),
            rateHistoryJson: const Value('[]'),
            maturityDate: Value(parsed.maturityDate ?? DateTime.now()),
          ),
        );
      } else if (parsed.assetClass.contains('insurance')) {
        final premium = Money.fromDouble(
          parsed.averagePrice,
          currency: parsed.currency,
        );
        await _insDao.insert(
          InsurancePoliciesCompanion(
            holdingId: Value(holdingId),
            policyNumber: Value(parsed.accountNumber ?? ''),
            type: Value(parsed.assetClass),
            premiumMinor: Value(premium.minor),
            sumAssuredMinor: Value(
              Money.fromDouble(
                parsed.notionalValue ?? 0.0,
                currency: parsed.currency,
              ).minor,
            ),
            startDate: Value(DateTime.now()),
            maturityDate: Value(parsed.maturityDate ?? DateTime.now()),
          ),
        );
      }
    }
  }

  Future<void> saveParsedTransactions(
    List<ParsedTransaction> transactions, {
    DocumentMetadata? metadata,
  }) async {
    for (final parsed in transactions) {
      // Ensure instrument exists
      String? instrumentId;
      if (parsed.symbol != null) {
        final instrument = await _instrumentDao.getOrCreateInstrument(
          symbol: parsed.symbol!,
          name: parsed.name,
          assetClass: _inferAssetClass(metadata?.documentType),
          currency: parsed.currency,
          country: 'india', // Default
        );
        instrumentId = instrument.id;
      }

      // Create transaction
      await _transactionDao.createTransaction(
        instrumentId: instrumentId,
        type: parsed.type,
        quantity: parsed.quantity,
        price: parsed.price != null
            ? Money.fromDouble(parsed.price!, currency: parsed.currency)
            : null,
        amount: Money.fromDouble(parsed.amount, currency: parsed.currency),
        currency: parsed.currency,
        date: parsed.date,
        fee: parsed.fee != null
            ? Money.fromDouble(parsed.fee!, currency: parsed.currency)
            : null,
        description: parsed.name,
        account: parsed.account,
      );
    }
  }

  String _inferAssetClass(String? documentType) {
    if (documentType == null) return 'equity';

    final type = documentType.toLowerCase();
    if (type.contains('mutual_fund')) return 'mutualFund';
    if (type.contains('equity')) return 'equity';
    if (type.contains('crypto')) return 'cryptoSpot';
    if (type.contains('bank')) return 'custom';
    if (type.contains('fd') || type.contains('fixed_deposit')) {
      return 'fixedDeposit';
    }

    return 'equity'; // Fallback
  }
}

final documentParserServiceProvider = Provider<DocumentParserService>((ref) {
  return DocumentParserService(
    llmService: ref.watch(llmServiceProvider),
    instrumentDao: ref.watch(instrumentDaoProvider),
    holdingDao: ref.watch(holdingDaoProvider),
    transactionDao: ref.watch(transactionDaoProvider),
    fdDao: ref.watch(fdRdAccountDaoProvider),
    ppfDao: ref.watch(ppfAccountDaoProvider),
    insDao: ref.watch(insurancePolicyDaoProvider),
  );
});
