import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static const String _recipientEmail = 'jamin@jamingingerich.com';
  static const String _subject = 'ColdPlunge Pro Feedback';

  /// Send feedback email with prefilled template
  static Future<void> sendEmailFeedback(BuildContext context) async {
    try {
      // Get app version and build info
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      // Get user info if available
      final user = Supabase.instance.client.auth.currentUser;
      final userEmail = user?.email ?? 'Not logged in';
      final userId = user?.id ?? 'Not logged in';

      // Get platform info
      final platform = Platform.isIOS ? 'iOS' : 'Android';
      final osVersion = Platform.operatingSystemVersion;

      // Build email body
      final body = '''
Thanks for sharing feedback!

What were you trying to do?


What happened instead?


Suggestions or ideas:


---
Diagnostics:
- App version: $appVersion (build $buildNumber)
- Platform: $platform
- OS version: $osVersion
- User email: $userEmail
- User ID: $userId
---
''';

      // Create mailto URI with manual query string to avoid + encoding issues
      // Gmail and some clients don't properly decode + as space, so we use %20
      final encodedSubject =
          Uri.encodeComponent(_subject).replaceAll('+', '%20');
      final encodedBody = Uri.encodeComponent(body).replaceAll('+', '%20');

      final uri = Uri.parse(
          'mailto:$_recipientEmail?subject=$encodedSubject&body=$encodedBody');

      // Try to launch email client directly
      // Note: canLaunchUrl is unreliable on some Android devices/emulators
      // so we try launchUrl directly and handle failures
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          // Launch returned false - no email app available
          _showFallbackMessage(context, body);
        }
      } catch (error) {
        debugPrint('Error launching email client: $error');
        // Launch threw exception - show fallback
        _showFallbackMessage(context, body);
      }
    } catch (error) {
      debugPrint('Error sending feedback: $error');
      _showFallbackMessage(context, null);
    }
  }

  /// Show fallback message and copy email/body to clipboard
  static Future<void> _showFallbackMessage(
      BuildContext context, String? body) async {
    // Copy email to clipboard
    await Clipboard.setData(const ClipboardData(text: _recipientEmail));

    // Optionally copy the full email body too
    if (body != null) {
      debugPrint('Email body copied for manual sending');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No email app found. Email address copied to clipboard.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
