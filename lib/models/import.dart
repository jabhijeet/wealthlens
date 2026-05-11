class ParsedHolding {
  ParsedHolding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averagePrice,
    required this.currency,
    required this.assetClass,
    required this.country,
    this.exchange,
    this.isin,
    this.folioNumber,
    this.accountNumber,
    this.maturityDate,
    this.interestRate,
    this.purchaseDate,
    this.latestPrice,
    this.notionalValue,
    this.confidence = 1.0,
  });

  factory ParsedHolding.fromJson(Map<String, dynamic> json) {
    return ParsedHolding(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
      currency: json['currency'] as String,
      assetClass: json['assetClass'] as String,
      country: json['country'] as String,
      exchange: json['exchange'] as String?,
      isin: json['isin'] as String?,
      folioNumber: json['folioNumber'] as String?,
      accountNumber: json['accountNumber'] as String?,
      maturityDate: json['maturityDate'] != null
          ? DateTime.parse(json['maturityDate'] as String)
          : null,
      interestRate: json['interestRate'] != null
          ? (json['interestRate'] as num).toDouble()
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      latestPrice: json['latestPrice'] != null
          ? (json['latestPrice'] as num).toDouble()
          : null,
      notionalValue: json['notionalValue'] != null
          ? (json['notionalValue'] as num).toDouble()
          : null,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
  final String symbol;
  final String name;
  final double quantity;
  final double averagePrice;
  final String currency;
  final String assetClass;
  final String country;
  final String? exchange;
  final String? isin;
  final String? folioNumber;
  final String? accountNumber;
  final DateTime? maturityDate;
  final double? interestRate;
  final DateTime? purchaseDate;
  final double? latestPrice;
  final double? notionalValue;
  final double confidence;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'quantity': quantity,
    'averagePrice': averagePrice,
    'currency': currency,
    'assetClass': assetClass,
    'country': country,
    'exchange': exchange,
    'isin': isin,
    'folioNumber': folioNumber,
    'accountNumber': accountNumber,
    'maturityDate': maturityDate?.toIso8601String(),
    'interestRate': interestRate,
    'purchaseDate': purchaseDate?.toIso8601String(),
    'latestPrice': latestPrice,
    'notionalValue': notionalValue,
    'confidence': confidence,
  };
}

class ParsedTransaction {
  ParsedTransaction({
    required this.type,
    this.symbol,
    required this.name,
    this.quantity,
    this.price,
    required this.amount,
    required this.currency,
    required this.date,
    this.fee,
    this.account,
    this.confidence = 1.0,
  });

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      type: json['type'] as String,
      symbol: json['symbol'] as String?,
      name: json['name'] as String,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      date: DateTime.parse(json['date'] as String),
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : null,
      account: json['account'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }
  final String type;
  final String? symbol;
  final String name;
  final double? quantity;
  final double? price;
  final double amount;
  final String currency;
  final DateTime date;
  final double? fee;
  final String? account;
  final double confidence;

  Map<String, dynamic> toJson() => {
    'type': type,
    'symbol': symbol,
    'name': name,
    'quantity': quantity,
    'price': price,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'fee': fee,
    'account': account,
    'confidence': confidence,
  };
}

class DocumentMetadata {
  DocumentMetadata({
    required this.documentType,
    required this.institution,
    this.accountHolder,
    this.accountNumber,
    this.periodStart,
    this.periodEnd,
    this.statementDate,
    this.totalValue,
    this.currency,
    required this.containsHoldings,
    required this.containsTransactions,
  });

  factory DocumentMetadata.fromJson(Map<String, dynamic> json) {
    return DocumentMetadata(
      documentType: json['documentType'] as String,
      institution: json['institution'] as String,
      accountHolder: json['accountHolder'] as String?,
      accountNumber: json['accountNumber'] as String?,
      periodStart: json['periodStart'] != null
          ? DateTime.parse(json['periodStart'] as String)
          : null,
      periodEnd: json['periodEnd'] != null
          ? DateTime.parse(json['periodEnd'] as String)
          : null,
      statementDate: json['statementDate'] != null
          ? DateTime.parse(json['statementDate'] as String)
          : null,
      totalValue: json['totalValue'] != null
          ? (json['totalValue'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      containsHoldings: json['containsHoldings'] as bool,
      containsTransactions: json['containsTransactions'] as bool,
    );
  }
  final String documentType;
  final String institution;
  final String? accountHolder;
  final String? accountNumber;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? statementDate;
  final double? totalValue;
  final String? currency;
  final bool containsHoldings;
  final bool containsTransactions;

  Map<String, dynamic> toJson() => {
    'documentType': documentType,
    'institution': institution,
    'accountHolder': accountHolder,
    'accountNumber': accountNumber,
    'periodStart': periodStart?.toIso8601String(),
    'periodEnd': periodEnd?.toIso8601String(),
    'statementDate': statementDate?.toIso8601String(),
    'totalValue': totalValue,
    'currency': currency,
    'containsHoldings': containsHoldings,
    'containsTransactions': containsTransactions,
  };
}
