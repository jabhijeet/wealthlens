import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now().toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WealthLens Privacy Policy',
              style: GoogleFonts.outfit(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: $currentDate',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: WealthColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            _buildIntroduction(),
            _buildSection(
              'Information We Collect',
              _informationWeCollect,
              Icons.data_usage_rounded,
            ),
            _buildSection(
              'How We Use Information',
              _howWeUseInformation,
              Icons.settings_suggest_rounded,
            ),
            _buildSection(
              'Data Storage and Security',
              _dataStorageAndSecurity,
              Icons.security_rounded,
            ),
            _buildSection(
              'Third-Party Services',
              _thirdPartyServices,
              Icons.hub_rounded,
            ),
            _buildSection('Your Rights', _yourRights, Icons.gavel_rounded),
            _buildSection('Contact Us', _contactUs, Icons.mail_outline_rounded),
            const SizedBox(height: 32),
            Text(
              'This privacy policy is designed for mobile application distribution. For the complete legal version, consult with a privacy law specialist in your jurisdiction.',
              style: GoogleFonts.sora(fontSize: 12, color: Colors.orange),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Introduction',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: WealthColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'WealthLens is a local-first personal finance tracker. We prioritize your privacy by keeping your sensitive financial data on your device, protected by industry-standard encryption. This policy explains what data we process and how we protect it.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: WealthColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: WealthColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

const String _informationWeCollect = '''
• Financial Data: We process investment holdings, transactions, and performance data which you enter manually or import.
• Document Data: When you use the AI Document Parser, we process images or text from your financial statements to extract investment details.
• Security Data: We use your device's biometric systems (FaceID/TouchID) for authentication if enabled. We do not store your actual biometric data.
• Usage Data: We collect anonymized information about how you use the app to improve performance and user experience.
''';

const String _howWeUseInformation = '''
• Service Provision: To calculate your portfolio value, performance metrics (XIRR), and generate financial insights.
• AI Insights: To provide intelligent analysis of your holdings using Large Language Models (LLMs).
• Local Security: To encrypt and lock your data using device-level security features.
• Optimization: To identify and fix technical issues and improve the app's features.
''';

const String _dataStorageAndSecurity = '''
• 100% Local Storage: All your sensitive financial data is stored directly on your device. We do not maintain remote databases of your personal holdings.
• SQLCipher Encryption: Your local database is encrypted at rest using AES-256 via SQLCipher.
• Secure Key Management: The 256-bit encryption key is unique to your device and is stored in your system's Secure Enclave (iOS Keychain / Android Keystore).
• No Institution Access: WealthLens does not connect directly to your bank accounts or brokerage accounts. You remain in full control of the data you input.
''';

const String _thirdPartyServices = '''
• LLM Providers: We integrate with providers like OpenAI, Anthropic, and Google Gemini to provide insights and document parsing. 
    - Insights: Only relevant portfolio summaries (anonymized) are sent to the provider.
    - Parsing: Raw text or images you provide are sent for extraction. No personal identifiers are explicitly shared unless present in the documents.
• Data Sources: We fetch market prices from public providers (e.g., Yahoo Finance). Only asset symbols are shared to retrieve current valuations.
• Local Analytics: We track basic usage patterns locally. No data is currently transmitted to third-party analytics servers.
''';

const String _yourRights = '''
• Data Access & Portability: You can view all your data within the app and export encrypted backups for your own records.
• Data Erasure: You can wipe all data from your device at any time using the "Delete All Data" option in Settings. This permanently deletes the database and encryption keys.
• Opt-out: You can disable AI features, biometrics, and analytics at any time in the settings.
''';

const String _contactUs = '''
If you have any questions about this Privacy Policy or our data practices, please contact us at:

Email: privacy@wealthlens.app
Website: https://wealthlens.app/privacy
''';
