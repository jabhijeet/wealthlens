import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now().toLocal().toString().split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WealthLens Terms of Service',
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

            _buildSection(
              'Acceptance of Terms',
              'By downloading, installing, or using the WealthLens mobile application ("Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to all these Terms, do not use the Service.',
            ),

            _buildSection(
              'Description of Service',
              'WealthLens is a personal finance and investment portfolio tracking application that allows users to:\n\n'
                  '• Track investments, assets, and liabilities\n'
                  '• Monitor portfolio performance with analytics and insights\n'
                  '• Import financial documents and statements\n'
                  '• Receive AI-powered financial insights (optional)\n'
                  '• Set financial goals and track progress\n\n'
                  'The Service is provided "AS IS" and "AS AVAILABLE" without warranties of any kind, either express or implied.',
            ),

            _buildSection(
              'User Responsibilities',
              'You agree to:\n\n'
                  '• Provide accurate and up-to-date information\n'
                  '• Maintain the confidentiality of your account credentials\n'
                  '• Notify us immediately of any unauthorized use of your account\n'
                  '• Use the Service only for lawful purposes\n'
                  '• Not attempt to reverse engineer, decompile, or disassemble the app\n'
                  '• Not use the Service to store illegal or harmful content\n\n'
                  'You are solely responsible for all activities that occur under your account.',
            ),

            _buildSection(
              'Financial Information Disclaimer',
              'IMPORTANT: WealthLens is a tracking and analysis tool, NOT a financial advisor.\n\n'
                  '• No Financial Advice: All information provided is for informational purposes only\n'
                  '• Not a Broker: We do not execute trades or access your brokerage accounts\n'
                  '• Accuracy: We strive for accuracy but cannot guarantee all data is error-free\n'
                  '• Consult Professionals: Always consult qualified financial advisors before making investment decisions\n'
                  '• Risk Acknowledgment: You acknowledge that all investments carry risk, and past performance does not guarantee future results\n'
                  '• Tax Implications: We do not provide tax advice; consult tax professionals for tax-related matters',
            ),

            _buildSection(
              'Intellectual Property Rights',
              '• The Service and its original content, features, and functionality are owned by WealthLens\n'
                  '• Protected by copyright, trademark, and other intellectual property laws\n'
                  '• You may not copy, modify, distribute, or create derivative works without written permission\n'
                  '• All trademarks, logos, and service marks are property of their respective owners',
            ),

            _buildSection(
              'Limitation of Liability',
              'To the maximum extent permitted by law, WealthLens shall NOT be liable for:\n\n'
                  '• Indirect, incidental, special, consequential, or punitive damages\n'
                  '• Loss of profits, data, or use, arising out of or in connection with the Service\n'
                  '• Financial losses based on information provided by the Service\n'
                  '• Unauthorized access to or alteration of your transmissions or data\n'
                  '• Errors or omissions in any content or for any loss or damage incurred\n\n'
                  'Our total liability shall not exceed the amount you paid for the Service (if any) in the past 12 months.',
            ),

            _buildSection(
              'Indemnification',
              'You agree to indemnify and hold harmless WealthLens and its officers, directors, employees, and agents from any claims, damages, losses, or expenses (including legal fees) arising from:\n\n'
                  '• Your use of the Service\n'
                  '• Your violation of these Terms\n'
                  '• Your violation of any third-party rights\n'
                  '• Any content or data you provide through the Service',
            ),

            _buildSection(
              'Termination',
              'We may terminate or suspend your access to the Service immediately, without prior notice or liability, for any reason, including:\n\n'
                  '• Breach of these Terms\n'
                  '• Request by law enforcement or government agencies\n'
                  '• Discontinuation or material modification of the Service\n'
                  '• Unexpected technical or security issues\n\n'
                  'Upon termination, your right to use the Service will cease immediately. Provisions that should survive termination shall survive.',
            ),

            _buildSection(
              'Governing Law',
              'These Terms shall be governed and construed in accordance with the laws of Singapore, without regard to its conflict of law provisions.\n\n'
                  'Any disputes arising from these Terms or your use of the Service shall be subject to the exclusive jurisdiction of the courts in Singapore.',
            ),

            _buildSection(
              'Severability',
              'If any provision of these Terms is held to be invalid or unenforceable, such provision shall be struck and the remaining provisions shall remain in full force and effect.',
            ),

            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify or replace these Terms at any time. We will provide notice of changes by:\n\n'
                  '• Updating the "Last Updated" date\n'
                  '• In-app notification for significant changes\n'
                  '• Email notification (if provided)\n\n'
                  'Your continued use of the Service after changes constitutes acceptance of the new Terms.',
            ),

            _buildSection(
              'Contact Information',
              'For questions about these Terms, contact us:\n\n'
                  'Email: legal@wealthlens.app\n'
                  'Subject: "Terms of Service Inquiry"\n\n'
                  'Response time: Within 30 days for legitimate inquiries.',
            ),

            const SizedBox(height: 32),
            Text(
              'These terms are designed for mobile application distribution. For the complete legal version, consult with a legal professional in your jurisdiction.',
              style: GoogleFonts.sora(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(content, style: GoogleFonts.sora(fontSize: 14, height: 1.5)),
      ],
    );
  }
}
