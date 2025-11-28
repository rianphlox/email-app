import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dialog for collecting Yahoo App Password for IMAP access.
///
/// Yahoo blocks OAuth2 IMAP access for new apps, so users need to
/// generate an app-specific password for full email functionality.
class YahooAppPasswordDialog extends StatefulWidget {
  final String userEmail;

  const YahooAppPasswordDialog({
    super.key,
    required this.userEmail,
  });

  @override
  State<YahooAppPasswordDialog> createState() => _YahooAppPasswordDialogState();
}

class _YahooAppPasswordDialogState extends State<YahooAppPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openYahooSecurityPage() async {
    const url = "https://login.yahoo.com/account/security/app-passwords";
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Yahoo security page. Please visit Yahoo.com manually.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening URL: $e')),
        );
      }
    }
  }

  void _validateAndSubmit() {
    final password = _controller.text.replaceAll(' ', '').replaceAll('-', '');

    if (password.length == 16) {
      Navigator.pop(context, password);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App password must be exactly 16 characters'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.purple),
          SizedBox(width: 8),
          Text('Yahoo App Password Required'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account: ${widget.userEmail}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yahoo requires an App Password for third-party email apps to access your inbox.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is a one-time setup that takes about 30 seconds:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Tap "Open Yahoo Security Page" below\n'
              '2. Sign in if prompted\n'
              '3. Generate a new App Password\n'
              '4. Copy and paste it here',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _openYahooSecurityPage,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open Yahoo Security Page'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'App Password',
                hintText: 'abcd efgh ijkl mnop',
                helperText: 'Paste the 16-character password here',
                prefixIcon: Icon(Icons.password),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _validateAndSubmit(),
              maxLength: 20, // Allow for spaces/dashes
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'App Passwords are safer than your main password for third-party apps',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _validateAndSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}