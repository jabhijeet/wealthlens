# WealthLens 📈

[![Flutter](https://img.shields.io/badge/Flutter-3.11.4+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-001F3F?logo=dart&logoColor=white)](https://riverpod.dev)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Version](https://img.shields.io/badge/Version-1.0.1+3-4CAF50)](RELEASENOTES.md)

**WealthLens** is a premium, privacy-first personal finance and investment portfolio tracker built with Flutter. It provides a unified view of your net worth across asset classes, countries, and currencies, powered by local-first encryption and anonymized AI insights.

---

## ✨ Key Features

### 📊 Portfolio Dashboard
- **Comprehensive Overview**: Track total net worth and asset distribution in real-time.
- **Dynamic Allocation**: Interactive carousels for Asset Class, Country, and Currency breakdowns.
- **Performance Tracking**: Visual charts (FL Chart) for historical performance and trend analysis.

### 💼 Holdings Management
- **Multi-Asset Support**: Track stocks, cryptocurrencies, fixed deposits, real estate, and more.
- **Smart Entry**: Integrated market search and manual entry for private assets.
- **Data Import**: High-efficiency workflows for importing data from various sources (Excel/PDF).

### 🤖 AI-Driven Insights
- **LLM Integration**: Get personalized financial insights using Gemini or other LLM providers.
- **Anonymized Processing**: Your financial data is anonymized before processing to ensure maximum privacy.
- **Actionable Advice**: Tailored recommendations based on your portfolio allocation and market trends.

### 📰 Market Context
- **Curated News**: Real-time market news integrated via Finnhub API.
- **Contextual Filtering**: Filter news based on your specific holdings and regions.

### 🧮 Systematic Planning
- **Investment Calculators**: Built-in tools for SIP, FD, RD, PPF, and Loan Amortization.
- **XIRR & Yield**: Advanced calculations for true portfolio returns and rental yields.

### 🛡️ Security & Privacy
- **Privacy-First**: Local-first storage ensures your data never leaves your device unless you choose to.
- **SQLCipher Encryption**: Your database is encrypted at rest using industry-standard SQLCipher.
- **Biometric Lock**: Secure your financial data with Fingerprint/FaceID authentication.
- **Secure Storage**: API keys and sensitive tokens are managed via Flutter Secure Storage.

---

## 🛠️ Technology Stack

- **Core**: [Flutter](https://flutter.dev) (v3.11.4+)
- **State Management**: [Riverpod](https://riverpod.dev) (Generator & Annotation based)
- **Database**: [Drift](https://drift.simonbinder.eu/) (SQLite) with [SQLCipher](https://www.zetetic.net/sqlcipher/)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio) with Smart Retry
- **UI/UX**: 
  - Typography: **Outfit** (Headings) & **Sora** (Body)
  - Animations: [Flutter Animate](https://pub.dev/packages/flutter_animate)
  - Charts: [FL Chart](https://pub.dev/packages/fl_chart)
- **AI/ML**: [Google ML Kit](https://developers.google.com/ml-kit) (OCR) & LLM API integrations

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.11.4 or higher)
- Android Studio / VS Code with Flutter extension
- API Keys for:
  - [Finnhub](https://finnhub.io/) (Market News)
  - [Google AI Studio](https://aistudio.google.com/) (Gemini API for Insights)

### Installation
1. **Clone the repository**:
   ```bash
   git clone https://github.com/jabhijeet/wealthlens.git
   cd WealthLens
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📂 Project Structure

```text
lib/
├── app/          # App-wide configuration & themes
├── common/       # Reusable components & constants
├── core/         # Core business logic & base classes
├── data/         # Data sources, local db (Drift), & repositories
├── domain/       # Domain entities & use cases
├── features/     # Feature-based modules (Dashboard, Holdings, etc.)
├── services/     # External services (API, Auth, Backup, etc.)
├── utils/        # Helper functions & formatters
└── widgets/      # Shared UI widgets
```

---

## 🗺️ Roadmap

- [ ] **Advanced Backup**: AES-256-GCM encrypted cloud backups.
- [ ] **Isolate Processing**: Moving heavy portfolio computations to background isolates.
- [ ] **Offline-First Sync**: Enhanced sync queue for multi-device data consistency.
- [ ] **Golden Testing**: Comprehensive UI snapshot testing for design consistency.

---

## 📋 Release Notes

See [RELEASENOTES.md](RELEASENOTES.md) for version history and changelog.

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ for privacy-conscious investors.
</p>
