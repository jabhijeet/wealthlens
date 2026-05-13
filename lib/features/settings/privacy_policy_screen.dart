import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            // ─── Header ──────────────────────────────────────────────────
            Text(
              'WealthLens Privacy Policy',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last Updated: May 13, 2026',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: WealthColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'WealthLens ("we," "our," or "us") is committed to protecting your privacy. '
              'This Privacy Policy explains how we collect, use, disclose, and safeguard '
              'your information when you use our mobile application. By using WealthLens, '
              'you agree to the data practices described in this policy.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // ─── Sections ────────────────────────────────────────────────
            _buildSection(
              '1. Information We Collect',
              _informationWeCollect,
              Icons.description_outlined,
            ),
            _buildSection(
              '2. How We Use Your Information',
              _howWeUseInformation,
              Icons.settings_suggest_rounded,
            ),
            _buildSection(
              '3. Data Storage & Security',
              _dataStorageAndSecurity,
              Icons.security_rounded,
            ),
            _buildSection(
              '4. Third-Party Services & Disclosures',
              _thirdPartyServices,
              Icons.hub_rounded,
            ),
            _buildSection(
              '5. Your Data Rights & Choices',
              _yourRights,
              Icons.gavel_rounded,
            ),
            _buildSection(
              "6. Children's Privacy",
              _childrenPrivacy,
              Icons.child_care_rounded,
            ),
            _buildSection(
              '7. Changes to This Policy',
              _changesToPolicy,
              Icons.update_rounded,
            ),
            _buildSection(
              '8. Contact Us',
              _contactUs,
              Icons.mail_outline_rounded,
            ),

            const SizedBox(height: 16),

            // ─── View Online Link ────────────────────────────────────────
            GestureDetector(
              onTap: () => _launchUrl('https://wealthlens.app/privacy'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: WealthColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: WealthColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.open_in_browser_rounded, size: 16, color: WealthColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'View full policy online',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: WealthColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Disclaimer ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Text(
                'This privacy policy is provided for informational purposes. '
                'For complete legal compliance, consult with a qualified privacy law specialist '
                'regarding GDPR, CCPA, LGPD, PDPA, PDPB, and other applicable regulations.',
                style: GoogleFonts.sora(fontSize: 11, color: Colors.orange.shade800, height: 1.5),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
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
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Policy Content Strings ───────────────────────────────────────────────────

const String _informationWeCollect = '''
What You Provide:
• Investment holdings — asset names, quantities, purchase prices, dates, and categories (stocks, mutual funds, crypto, fixed deposits, real estate, etc.) that you manually enter or import.
• Transaction records — buy/sell transactions, dividend payments, interest credits, and systematic investment plan details.
• Document uploads — when you use the AI Document Parser, we process images (photos/scans) or text extracted from your financial statements.

Automatically Collected:
• Usage data — anonymized, aggregated information about how you interact with the app. This is stored locally only and is not transmitted to external analytics servers.
• Device information — device model, OS version, and app version for debugging.

We DO NOT Collect:
• Personal identifiers — we do not require your name, email, phone, or address.
• Bank credentials — we never connect to your bank or brokerage accounts.
• Location data — no precise geolocation is collected.
• Biometric data — biometric lock is handled entirely by your device; we never receive or store biometric data.
''';

const String _howWeUseInformation = '''
• Core functionality — calculate portfolio value, asset allocation, performance metrics (XIRR, CAGR), and generate financial summaries on your device.
• AI-powered insights — provide intelligent portfolio analysis and document parsing using LLMs. Only relevant, anonymized portfolio summaries or document text are sent.
• Market data — fetch current asset prices from public providers. Only asset symbols are shared.
• Notifications — send local push notifications for price alerts, maturity reminders, premium due dates, and other events you configure.
• Security — encrypt your data, authenticate via biometric lock, and protect against unauthorized access.
• Improvement — identify bugs, crashes, and performance issues to improve the app.
''';

const String _dataStorageAndSecurity = '''
Local-First Architecture:
All your sensitive financial data is stored exclusively on your device. We do not maintain remote databases or cloud backups of your personal portfolio data.

Encryption:
• At Rest — your local database is encrypted using AES-256 via SQLCipher.
• Key Management — the 256-bit encryption key is unique to your device and stored in your system's hardware-backed Secure Enclave (iOS Keychain / Android Keystore).
• Backups — exported backup files are AES-256 encrypted. You control the encryption password.

Data Retention:
Your data remains on your device until you choose to delete it. Use "Delete All Data" in Settings to permanently wipe the database and encryption keys.
''';

const String _thirdPartyServices = '''
LLM Providers (AI Features):
When you use AI features, data is sent to the LLM provider you configure. Supported providers:
• OpenAI (GPT models) — openai.com/privacy
• Anthropic (Claude models) — anthropic.com/privacy
• Google (Gemini models) — policies.google.com/privacy

You choose the provider and supply your own API key. Data sent is subject to each provider's privacy policy. Only anonymized portfolio summaries or document text you submit are transmitted.

Market Data Providers:
• Yahoo Finance — asset symbols sent to retrieve prices
• CoinGecko — crypto symbols sent to retrieve prices
• Frankfurter API — currency codes sent for FX rates

Legal Disclosure:
We do not sell, trade, or rent your personal data. We may disclose information only if required by law or valid legal requests. Since data is stored locally, our ability to produce it is limited.
''';

const String _yourRights = '''
Depending on your jurisdiction, you may have the following rights:

• Access & Portability — view all your data in the app and export encrypted backups.
• Deletion (Right to Erasure) — permanently delete all data using "Delete All Data" in Settings. This is irreversible.
• Opt-Out of AI Features — disable AI insights and document parsing in Settings.
• Opt-Out of Notifications — manage each notification preference individually.
• Biometric Lock — enable or disable biometric authentication at any time.
• Privacy Mode — mask sensitive amounts on screen.

Since all data is stored locally on your device, you have full and immediate control over your information.
''';

const String _childrenPrivacy = '''
WealthLens is not intended for use by children under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with information, please contact us. Since all data is stored locally on the device, you can delete it directly through the app's Settings.
''';

const String _changesToPolicy = '''
We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy within the app and updating the "Last Updated" date. You are advised to review this policy periodically. Continued use of the app after changes constitutes acceptance of the updated policy.
''';

const String _contactUs = '''
If you have any questions about this Privacy Policy or our data practices, please contact us:

Email: privacy@wealthlens.app
Website: https://wealthlens.app/privacy

We aim to respond to all inquiries within 5 business days.
''';