# Release Notes

## 1.0.1+3 (2026-05-14)

- **Fix**: Resolved a critical app crash on Android startup caused by an outdated `WorkManagerInitializer` configuration in `AndroidManifest.xml`.
- **Optimization**: Cleaned up manual Android manifest configurations to rely on modern library initialization.

## 1.0.0+2 (2026-05-13)

- Bumped Android version code from 1 to 2 for Play Store publishing (version code 1 was already consumed).

## 1.0.0+1 (Initial Release)

- **Portfolio Dashboard** — Net worth tracking with asset class, country, and currency allocation breakdowns.
- **Holdings Management** — Multi-asset support (stocks, crypto, fixed deposits, real estate, etc.) with integrated market search and Excel/PDF import.
- **AI-Driven Insights** — LLM-powered financial insights via Gemini with anonymized data processing.
- **Market News** — Curated news feed integrated via Finnhub API, filterable by holdings and region.
- **Systematic Planning** — Calculators for SIP, FD, RD, PPF, loan amortization, XIRR, and rental yield.
- **Security & Privacy** — SQLCipher-encrypted local database, biometric lock, and secure API key storage.