// Version: 1.0.0
// Document parsing prompts for extracting holdings and transactions from text

class DocumentParsingPrompts {
  static const String version = '1.1.0';

  /// Prompt for extracting holdings from brokerage statements, PDFs, etc.
  /// Expects JSON array of holdings.
  static const String holdingsExtractionPrompt = '''
You are a financial data extraction assistant. Extract holdings information from the provided text.
Return ONLY a valid JSON array of objects, no other text.

Each object should have these fields:
- "symbol": string (e.g., "AAPL", "INFY.NS", "VOO")
- "name": string (full name of the security)
- "quantity": number (e.g., 10.5 for fractional shares)
- "averagePrice": number (per-unit cost in original currency)
- "currency": string (3-letter ISO code: USD, INR, SGD, etc.)
- "assetClass": string (MUST be one of: "equity", "etf", "mutualFund", "bond", "fixedDeposit", "recurringDeposit", "ppf", "epf", "nps", "insuranceTerm", "insuranceEndowment", "insuranceUlip", "cryptoSpot", "realEstateLand", "cash", "commodity", "other")
- "country": string (MUST be one of: "india", "usa", "singapore", "uk", "other")
- "exchange": optional string (e.g., "NSE", "BSE", "NASDAQ", "NYSE")
- "isin": optional string (for stocks/ETFs)
- "folioNumber": optional string (for mutual funds)
- "accountNumber": optional string (for FD/RD/insurance/PPF)
- "maturityDate": optional string (YYYY-MM-DD format for FD/RD/bonds)
- "interestRate": optional number (for FD/RD/bonds, as percentage)
- "purchaseDate": optional string (YYYY-MM-DD, when the security was bought)
- "latestPrice": optional number (current market price if shown)
- "notionalValue": optional number (current total value of position, quantity * latestPrice)

Rules:
1. If quantity is not specified but value is, infer quantity = value / price if price is known.
2. For mutual funds, use "mutualFund" assetClass.
3. For fixed deposits, use "fixedDeposit" assetClass.
4. For recurring deposits, use "recurringDeposit" assetClass.
5. For PPF, use "ppf" assetClass.
6. For crypto, use "cryptoSpot" assetClass.
7. If country is India, use "india", for USA use "usa".
8. Parse dates in DD/MM/YYYY, MM/DD/YYYY, or YYYY-MM-DD formats and return ONLY YYYY-MM-DD.
9. Ensure numeric values do not contain commas.
10. "Portfolio composition" sections tell overall portfolio assetclasses and value.
11. "Consolidated Account Statement" tells details about current account, while "Summary" gives detail of all accounts in brief.
12. Treat "latest portfolio positions" as holdings.
13. Map "no of shares" or "units" to quantity.

Example output:
[
  {
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "quantity": 25,
    "averagePrice": 175.50,
    "currency": "USD",
    "assetClass": "equity",
    "country": "usa",
    "exchange": "NASDAQ",
    "notionalValue": 4387.50
  },
  {
    "symbol": "INFY.NS",
    "name": "Infosys Limited",
    "quantity": 100,
    "averagePrice": 1500.75,
    "currency": "INR",
    "assetClass": "equity",
    "country": "india",
    "exchange": "NSE"
  }
]

Now extract holdings from this text:
{text}
''';

  /// Prompt for extracting transactions (buys, sells, dividends, etc.)
  static const String transactionsExtractionPrompt = '''
You are a financial transaction extraction assistant. Extract transactions from the provided text.
Return ONLY a valid JSON array of objects, no other text. Ensure all keys are strings in double quotes.

Each object should have these fields:
- "type": string (MUST be one of: "buy", "sell", "dividend", "interest", "fee", "contribution", "withdrawal", "bonus", "premiumPaid", "claimReceived", "surrenderPayout")
- "symbol": optional string (for equity/ETF/mutual fund transactions)
- "name": string (security name or description)
- "quantity": optional number (for buy/sell transactions)
- "price": optional number (per-unit price in original currency)
- "amount": number (total transaction amount, absolute value)
- "currency": string (3-letter ISO code)
- "date": string (YYYY-MM-DD format)
- "fee": optional number (transaction fees/taxes)
- "account": optional string (account/broker name)

Rules:
1. For dividends and interest, type should be "dividend" or "interest".
2. For mutual fund SIP purchases or investments, type is "buy".
3. For redemptions or selling, type is "sell".
4. For insurance premium payments, type is "premiumPaid".
5. For FD/RD maturity, type is "withdrawal".
6. Parse dates in any common format and convert to YYYY-MM-DD.
7. If amount is not explicitly stated but quantity and price are, calculate amount = quantity * price.
8. Treat "latest transactions" as transactions.
9. Map "no of shares" or "units" to quantity.
10. Numeric values must not contain commas.

Example output:
[
  {
    "type": "buy",
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "quantity": 10,
    "price": 175.50,
    "amount": 1755.00,
    "currency": "USD",
    "date": "2024-01-15",
    "fee": 1.50
  },
  {
    "type": "dividend",
    "name": "Apple Inc. Dividend",
    "amount": 25.00,
    "currency": "USD",
    "date": "2024-02-01"
  }
]

Now extract transactions from this text:
{text}
''';

  /// Prompt for classifying document type and extracting metadata
  static const String documentClassificationPrompt = '''
You are a financial document classifier. Analyze the text and return metadata about the document.
Return ONLY a valid JSON object, no other text.

The JSON object should have these fields:
- "documentType": string (one of: "brokerage_statement", "bank_statement", "mutual_fund_statement", "tax_form", "insurance_policy", "fd_rd_receipt", "ppf_passbook", "real_estate_document", "crypto_wallet", "other")
- "institution": string (name of bank/broker/company)
- "accountHolder": optional string (name of account holder)
- "accountNumber": optional string
- "periodStart": optional string (YYYY-MM-DD)
- "periodEnd": optional string (YYYY-MM-DD)
- "statementDate": optional string (YYYY-MM-DD)
- "totalValue": optional number (total portfolio value or total balance if mentioned)
- "currency": optional string (primary currency of document, 3-letter code)
- "containsHoldings": boolean
- "containsTransactions": boolean

Rules:
1. Infer institution from logos, headers, or sender information.
2. Look for date ranges like "Statement Period: Jan 1, 2024 - Jan 31, 2024".
3. If total portfolio value, total asset value, or net worth is mentioned, extract it as totalValue (without commas).
4. Determine if the document contains holdings (positions/balances) and/or transactions (activity/ledger).

Example output:
{
  "documentType": "brokerage_statement",
  "institution": "Zerodha",
  "accountHolder": "John Doe",
  "accountNumber": "AB123456",
  "periodStart": "2024-01-01",
  "periodEnd": "2024-01-31",
  "statementDate": "2024-02-05",
  "totalValue": 125000.50,
  "currency": "INR",
  "containsHoldings": true,
  "containsTransactions": true
}

Now analyze this document text:
{text}
''';

  /// Prompt for vision models to extract everything from document images at once.
  static const String visionCombinedExtractionPrompt = '''
You are an expert financial data extraction system. Analyze the provided document image(s) and extract all relevant information.
Return ONLY a valid JSON object, no other text.

The JSON object must have three main sections:
1. "metadata": An object with fields:
   - "documentType": string (brokerage_statement, bank_statement, mutual_fund_statement, tax_form, insurance_policy, fd_rd_receipt, ppf_passbook, real_estate_document, crypto_wallet, other)
   - "institution": string (bank/broker name)
   - "accountNumber": optional string
   - "statementDate": optional string (YYYY-MM-DD)
   - "totalValue": optional number (total portfolio value)
   - "currency": string (3-letter ISO code)

2. "holdings": An array of objects, each with:
   - "symbol": string (e.g., "AAPL", "INFY.NS")
   - "name": string
   - "quantity": number
   - "averagePrice": number
   - "currency": string
   - "assetClass": string (MUST be: equity, etf, mutualFund, bond, fixedDeposit, recurringDeposit, ppf, epf, nps, insuranceTerm, cryptoSpot, realEstateLand, cash, commodity)
   - "country": string (india, usa, singapore, uk, other)
   - "purchaseDate": optional string (YYYY-MM-DD)
   - "latestPrice": optional number
   - "notionalValue": optional number (total value of this holding)

3. "transactions": An array of objects, each with:
   - "type": string (buy, sell, dividend, interest, withdrawal, premiumPaid)
   - "name": string
   - "quantity": optional number
   - "price": optional number
   - "amount": number
   - "currency": string
   - "date": string (YYYY-MM-DD)

Rules:
1. Extract data as accurately as possible from the visual text in the image.
2. If a field is missing, omit it or set to null. Numbers should not contain commas.
3. For mutual funds, use "mutualFund" assetClass. For FD/RD, use "fixedDeposit" or "recurringDeposit".
4. Return ONLY the JSON object. Do not include markdown code blocks.
''';
}
