// Version: 1.0.0
// Document parsing prompts for extracting holdings and transactions from text

class DocumentParsingPrompts {
  static const String version = '1.0.0';

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
- "assetClass": string (one of: "equity", "etf", "mutual_fund", "bond", "fd", "rd", "ppf", "insurance", "crypto", "real_estate")
- "country": string (one of: "IN", "US", "SG", "other")
- "exchange": optional string (e.g., "NSE", "BSE", "NASDAQ", "NYSE")
- "isin": optional string (for stocks/ETFs)
- "folioNumber": optional string (for mutual funds)
- "accountNumber": optional string (for FD/RD/insurance)
- "maturityDate": optional string (YYYY-MM-DD format for FD/RD/bonds)
- "interestRate": optional number (for FD/RD/bonds, as percentage)
- "purchaseDate": optional string (YYYY-MM-DD, when the security was bought)
- "latestPrice": optional number (current market price if shown)
- "notionalValue": optional number (current total value of position)

Rules:
1. If quantity is not specified but value is, infer quantity = value / price if price is known.
2. For mutual funds, use "mutual_fund" assetClass.
3. For fixed deposits, use "fd" assetClass.
4. For recurring deposits, use "rd" assetClass.
5. For PPF, use "ppf" assetClass.
6. For insurance policies, use "insurance" assetClass.
7. For crypto, use "crypto" assetClass.
8. For real estate, use "real_estate" assetClass.
9. If country is India, default exchange to "NSE" for equities.
10. If country is USA, default exchange to "NASDAQ" for tech stocks, "NYSE" otherwise.
11. Parse dates in DD/MM/YYYY, MM/DD/YYYY, or YYYY-MM-DD formats.
12. "Portfolio composition" sections tell overall portfolio assetclasses and value.
13. "Consolidated Account Statement" tells details about current account, while "Summary" gives detail of all accounts in brief.
14. Treat "latest portfolio positions" as holdings.
15. Map "no of shares" to quantity.

Example output:
[
  {
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "quantity": 25,
    "averagePrice": 175.50,
    "currency": "USD",
    "assetClass": "equity",
    "country": "US",
    "exchange": "NASDAQ"
  },
  {
    "symbol": "INFY.NS",
    "name": "Infosys Limited",
    "quantity": 100,
    "averagePrice": 1500.75,
    "currency": "INR",
    "assetClass": "equity",
    "country": "IN",
    "exchange": "NSE"
  }
]

Now extract holdings from this text:
{text}
''';

  /// Prompt for extracting transactions (buys, sells, dividends, etc.)
  static const String transactionsExtractionPrompt = '''
You are a financial transaction extraction assistant. Extract transactions from the provided text.
Return ONLY a valid JSON array of objects, no other text.

Each object should have these fields:
- "type": string (one of: "buy", "sell", "dividend", "interest", "redemption", "premium_payment", "maturity", "transfer_in", "transfer_out")
- "symbol": optional string (for equity/ETF/mutual fund transactions)
- "name": string (security name or description)
- "quantity": optional number (for buy/sell transactions)
- "price": optional number (per-unit price in original currency)
- "amount": number (total transaction amount, positive for inflows, negative for outflows)
- "currency": string (3-letter ISO code)
- "date": string (YYYY-MM-DD format)
- "fee": optional number (transaction fees/taxes)
- "account": optional string (account/broker name)

Rules:
1. For dividends and interest, type should be "dividend" or "interest".
2. For mutual fund SIP purchases, type is "buy".
3. For insurance premium payments, type is "premium_payment".
4. For FD/RD maturity, type is "maturity".
5. Parse dates in any common format and convert to YYYY-MM-DD.
6. If amount is not explicitly stated but quantity and price are, calculate amount = quantity * price.
7. For sells, amount should be positive (inflow). For buys, amount should be negative (outflow).
8. Treat "latest transactions" as transactions.
9. Map "no of shares" to quantity.

Example output:
[
  {
    "type": "buy",
    "symbol": "AAPL",
    "name": "Apple Inc.",
    "quantity": 10,
    "price": 175.50,
    "amount": -1755.00,
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
- "totalValue": optional number (total portfolio value if mentioned)
- "currency": optional string (primary currency of document)
- "containsHoldings": boolean
- "containsTransactions": boolean

Rules:
1. Infer institution from logos, headers, or sender information.
2. Look for date ranges like "Statement Period: Jan 1, 2024 - Jan 31, 2024".
3. If total portfolio value is mentioned, extract it.
4. Determine if the document contains holdings (positions) and/or transactions (activity).
5. "Consolidated Account Statement" tells details about current account, while "Summary" gives detail of all accounts in brief.

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
   - "currency": string (3-letter ISO code)

2. "holdings": An array of objects, each with:
   - "symbol": string (e.g., "AAPL", "INFY.NS")
   - "name": string
   - "quantity": number
   - "averagePrice": number
   - "currency": string
   - "assetClass": string (equity, etf, mutual_fund, bond, fd, rd, ppf, insurance, crypto, real_estate)
   - "country": string (IN, US, SG, other)
   - "purchaseDate": optional string (YYYY-MM-DD)
   - "latestPrice": optional number
   - "notionalValue": optional number

3. "transactions": An array of objects, each with:
   - "type": string (buy, sell, dividend, interest, redemption, premium_payment, maturity)
   - "name": string
   - "quantity": optional number
   - "price": optional number
   - "amount": number
   - "currency": string
   - "date": string (YYYY-MM-DD)

Rules:
1. Extract data as accurately as possible from the visual text in the image.
2. If a field is missing, omit it or set to null.
3. For mutual funds, use "mutual_fund" assetClass.
4. For FD/RD, use "fd" or "rd" assetClass.
5. "Portfolio composition" sections tell overall portfolio assetclasses and value.
6. "Consolidated Account Statement" tells details about current account, while "Summary" gives detail of all accounts in brief.
7. Treat "latest portfolio positions" as holdings.
8. Map "no of shares" to quantity.
9. Treat "latest transactions" as transactions.
10. Return ONLY the JSON object. Do not include markdown code blocks or explanations.
''';
}
