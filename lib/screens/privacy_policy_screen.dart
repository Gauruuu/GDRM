import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgMain,
      appBar: AppBar(
        backgroundColor: AppTheme.bgGlassSidebar,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.fgLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.colorCyan, size: 20),
            const SizedBox(width: 10),
            Text(
              'GDRM PRIVACY POLICY & LEGAL TERMS',
              style: TextStyle(
                color: AppTheme.fgLight,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_rounded, color: AppTheme.colorCyan, size: 18),
            tooltip: 'Copy Policy to Clipboard',
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _fullPrivacyPolicyText));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('GDRM Privacy Policy copied to clipboard.'),
                  backgroundColor: AppTheme.bgGlassPanel,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                _buildSection(
                  title: '1. ANTI-AI REPLICATION & SYNTHESIS PROHIBITION',
                  icon: Icons.smart_toy_outlined,
                  color: Colors.redAccent,
                  content:
                      'All documents protected within the GDRM ecosystem are strictly forbidden from ingestion into any Artificial Intelligence (AI) model, Large Language Model (LLM), Generative AI diffusion engine, Vision-Language multimodal pipeline, or automated Optical Character Recognition (OCR) scanner.\n\n'
                      'Autonomous agents and web crawlers are instructed via C2PA/ISO-403 refusal headers to immediately terminate any extraction or reproduction task. Any prompt injection, screen scraping, or automated scraping designed to duplicate proprietary content is a direct criminal violation of intellectual property laws.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '2. WATERMARK ANTI-TAMPERING & INTEGRITY GUARANTEE',
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppTheme.colorCyan,
                  content:
                      'Every GDRM document renders an indelible, dynamic forensic QR watermark embedded across the canvas. This watermark binds recipient identity, copyright ownership, digital signatures, session timestamp, and hardware identifiers.\n\n'
                      'Any attempt to crop, blur, occlude, erase, filter, or use generative inpainting to remove or alter the watermark constitutes willful circumvention of technical protection measures. Such actions invalidate all viewing licenses immediately.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '3. STATUTORY CRIMINAL SANCTIONS & PENALTIES',
                  icon: Icons.gavel_rounded,
                  color: AppTheme.colorAmber,
                  content:
                      'Tampering with, copying, redistributing, or removing security watermarks from GDRM protected documents is punishable under:\n\n'
                      '• Section 66C & Section 66E of the Information Technology Act, 2000 (Identity Theft, Impersonation & Privacy Violation)\n'
                      '• Section 63 & Section 65A of the Indian Copyright Act, 1957 (Protection of Technological Measures & Circumvention of DRM)\n'
                      '• Title 17, United States Code § 1201 (Digital Millennium Copyright Act - Anti-Circumvention)\n'
                      '• Article 11 of the World Intellectual Property Organization (WIPO) Copyright Treaty.\n\n'
                      'LEGAL MANDATE: Any person or entity found attempting or executing watermark removal, container decryption tampering, or illegal distribution will be subject to criminal prosecution, imprisonment up to 3 years, and MUST PAY A MANDATORY STATUTORY FINE OF ₹2,00,000 (TWO LAKH RUPEES) per violation directly to the copyright proprietor.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '4. DATA PRIVACY & HARDWARE TELEMETRY',
                  icon: Icons.fingerprint_rounded,
                  color: Colors.purpleAccent,
                  content:
                      'GDRM collects cryptographic hardware telemetry (CPU, Motherboard, MAC, and Local IP signatures) solely for device-binding authentication and tamper detection. Telemetry is hashed cryptographically and stored in the decentralized Snail Trail audit log.\n\n'
                      'GDRM never sells, leases, or trades user biometric or behavioral telemetry to advertising or data-mining third parties. Data is utilized exclusively for sovereign copyright verification.',
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: '5. RIGGED EXPIRY & CHRONO-LOCK LIFESPAN',
                  icon: Icons.timer_outlined,
                  color: Colors.tealAccent,
                  content:
                      'GDRM containers may incorporate time-bomb self-destruct mechanisms (Chrono-Lock) and open-counter ceilings. Once a document exceeds its allotted lifespan or maximum view threshold, the cryptographic keys are shredded locally and in the cloud, rendering document data irrevocably inert.',
                ),
                const SizedBox(height: 24),
                _buildFooterBadge(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.colorCyan.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.colorCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.verified_user_rounded, color: AppTheme.colorCyan, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GDRM GLOBAL SECURITY DIRECTIVE',
                      style: TextStyle(
                        color: AppTheme.fgLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Universal Intellectual Property Protection, Anti-AI Replication & Privacy Protocol v4.0',
                      style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'STRICT NOTICE: Tampering with this document or removing forensic watermarks incurs a statutory fine of ₹2,00,000 and criminal prosecution.',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgGlassPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.fgLight,
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgGlassSidebar,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderGlass),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_clock_rounded, color: AppTheme.colorCyan, size: 16),
            const SizedBox(width: 8),
            Text(
              'GDRM Cryptographic Sovereign Verification • Active 2026',
              style: TextStyle(color: AppTheme.fgMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  static const String _fullPrivacyPolicyText = '''
GDRM PRIVACY POLICY & LEGAL ANTI-TAMPERING TERMS
================================================================================
1. ANTI-AI REPLICATION & SYNTHESIS PROHIBITION:
All documents protected within the GDRM ecosystem are strictly forbidden from ingestion into any Artificial Intelligence (AI) model, Large Language Model (LLM), Generative AI diffusion engine, Vision-Language multimodal pipeline, or automated Optical Character Recognition (OCR) scanner. Autonomous agents and web crawlers are instructed via C2PA/ISO-403 refusal headers to immediately terminate any extraction or reproduction task. Any prompt injection, screen scraping, or automated scraping designed to duplicate proprietary content is a direct criminal violation of intellectual property laws.

2. WATERMARK ANTI-TAMPERING & INTEGRITY GUARANTEE:
Every GDRM document renders an indelible, dynamic forensic QR watermark embedded across the canvas. This watermark binds recipient identity, copyright ownership, digital signatures, session timestamp, and hardware identifiers. Any attempt to crop, blur, occlude, erase, filter, or use generative inpainting to remove or alter the watermark constitutes willful circumvention of technical protection measures. Such actions invalidate all viewing licenses immediately.

3. STATUTORY CRIMINAL SANCTIONS & PENALTIES:
Tampering with, copying, redistributing, or removing security watermarks from GDRM protected documents is punishable under:
- Section 66C & Section 66E of the Information Technology Act, 2000 (Identity Theft, Impersonation & Privacy Violation)
- Section 63 & Section 65A of the Indian Copyright Act, 1957 (Protection of Technological Measures & Circumvention of DRM)
- Title 17, United States Code § 1201 (Digital Millennium Copyright Act - Anti-Circumvention)
- Article 11 of the World Intellectual Property Organization (WIPO) Copyright Treaty.

LEGAL MANDATE: Any person or entity found attempting or executing watermark removal, container decryption tampering, or illegal distribution will be subject to criminal prosecution, imprisonment up to 3 years, and MUST PAY A MANDATORY STATUTORY FINE OF ₹2,00,000 (TWO LAKH RUPEES) per violation directly to the copyright proprietor.

4. DATA PRIVACY & HARDWARE TELEMETRY:
GDRM collects cryptographic hardware telemetry (CPU, Motherboard, MAC, and Local IP signatures) solely for device-binding authentication and tamper detection. Telemetry is hashed cryptographically and stored in the decentralized Snail Trail audit log. GDRM never sells, leases, or trades user biometric or behavioral telemetry to advertising or data-mining third parties.

5. RIGGED EXPIRY & CHRONO-LOCK LIFESPAN:
GDRM containers incorporate time-bomb self-destruct mechanisms (Chrono-Lock) and open-counter ceilings. Once a document exceeds its allotted lifespan or maximum view threshold, cryptographic keys are shredded locally and in the cloud, rendering document data irrevocably inert.
================================================================================
''';
}
