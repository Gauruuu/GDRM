import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Service for sending transactional and OTP emails using Gmail SMTP.
class SmtpEmailService {
  static const String _senderEmail = 'gauraangdalal@gmail.com';
  // Gmail App Password with spaces removed for reliability
  static const String _appPassword = 'recrejzzmqtoxmkz';

  static SmtpServer _getSmtpServer() {
    return gmail(_senderEmail, _appPassword);
  }

  /// Generate a secure 6-digit numeric OTP
  static String generateOtp() {
    final random = Random.secure();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  /// Send an OTP verification email to the given recipient
  static Future<bool> sendOtp({
    required String recipientEmail,
    required String otp,
    required String title,
    required String subtitle,
  }) async {
    try {
      final smtpServer = _getSmtpServer();

      final message = Message()
        ..from = const Address(_senderEmail, 'GDRM Ecosystem Security')
        ..recipients.add(recipientEmail.trim())
        ..subject = '[GDRM] $title - OTP: $otp'
        ..html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0b0f19; color: #e2e8f0; padding: 24px; margin: 0; }
    .card { background-color: #111827; border: 1px solid #1f2937; border-radius: 14px; max-width: 520px; margin: 0 auto; padding: 32px; box-shadow: 0 10px 30px rgba(0,0,0,0.6); }
    .badge { display: inline-block; background: #059669; color: #ffffff; padding: 5px 14px; border-radius: 20px; font-size: 11px; font-weight: 800; letter-spacing: 0.8px; text-transform: uppercase; }
    .otp-box { background: #030712; border: 2px dashed #3b82f6; border-radius: 10px; padding: 20px; text-align: center; margin: 24px 0; }
    .otp-code { font-size: 34px; font-weight: 800; letter-spacing: 10px; color: #60a5fa; font-family: 'Courier New', Courier, monospace; margin: 8px 0; }
    .footer { font-size: 11px; color: #64748b; text-align: center; margin-top: 28px; border-top: 1px solid #1e293b; padding-top: 18px; }
  </style>
</head>
<body>
  <div class="card">
    <div style="text-align: center; margin-bottom: 20px;">
      <span class="badge">GDRM Security Governance</span>
      <h2 style="color: #f8fafc; margin: 14px 0 6px 0; font-size: 22px;">$title</h2>
      <p style="color: #94a3b8; margin: 0; font-size: 14px;">$subtitle</p>
    </div>
    <div class="otp-box">
      <div style="font-size: 11px; color: #94a3b8; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 1.5px; font-weight: 600;">One-Time Security Passcode</div>
      <div class="otp-code">$otp</div>
      <div style="font-size: 11px; color: #f59e0b; margin-top: 4px;">Expires in 10 minutes</div>
    </div>
    <p style="font-size: 13px; color: #94a3b8; line-height: 1.6; margin: 0 0 12px 0;">
      Please enter this verification code in the GDRM application to authorize your action. If you did not request this code, please ignore this email or review your account security.
    </p>
    <div class="footer">
      GDRM Document Protection Ecosystem &bull; Autonomous DRM &amp; Cryptographic Governance
    </div>
  </div>
</body>
</html>
''';

      final sendReport = await send(message, smtpServer);
      debugPrint('[SmtpEmailService] OTP email sent successfully to $recipientEmail: $sendReport');
      return true;
    } catch (e) {
      debugPrint('[SmtpEmailService] Error sending email to $recipientEmail: $e');
      return false;
    }
  }
}
