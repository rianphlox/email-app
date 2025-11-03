
import 'package:flutter/foundation.dart';
import 'package:enough_mail/enough_mail.dart';
import '../models/email_account.dart';
import '../models/email_message.dart';

/// A service class for handling email operations for non-Gmail accounts.
///
/// This class uses the `enough_mail` package to interact with IMAP and SMTP
/// servers. It provides methods for connecting to an email account, fetching
/// emails, sending emails, and other email-related operations.
class FinalEmailService {
  // --- Private Properties ---

  ImapClient? _imapClient;
  SmtpClient? _smtpClient;
  bool _isConnected = false;

  // --- Public Methods ---

  /// Connects to an email account using IMAP and SMTP.
  ///
  /// This method establishes a connection to both the IMAP and SMTP servers
  /// for the given email account.
  Future<bool> connectToAccount(EmailAccount account) async {
    try {
      await _connectImap(account);
      await _connectSmtp(account);
      _isConnected = true;
      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Fetches a list of emails from the server.
  ///
  /// This method retrieves a list of emails from the specified folder of the
  /// given email account.
  Future<List<EmailMessage>> fetchEmails(
    EmailAccount account, {
    EmailFolder folder = EmailFolder.inbox,
    int limit = 50,
  }) async {
    if (_imapClient == null || !_isConnected) {
      final connected = await connectToAccount(account);
      if (!connected) {
        throw Exception('Failed to connect to email server');
      }
    }

    try {
      final mailbox = await _imapClient!.selectInbox();

      if (mailbox.messagesExists == 0) {
        return [];
      }

      // Fetch the most recent messages.
      final messageCount = mailbox.messagesExists;
      final startSequence = messageCount > limit ? messageCount - limit + 1 : 1;
      final endSequence = messageCount;

      final fetchResult = await _imapClient!.fetchMessages(
        MessageSequence.fromRange(startSequence, endSequence),
        'BODY.PEEK[]',
      );

      final emails = <EmailMessage>[];
      for (final message in fetchResult.messages.reversed) {
        try {
          final emailMessage = _convertToEmailMessage(message, account.id, folder);
          emails.add(emailMessage);
        } catch (e) {
          debugPrint('Error converting message: $e');
        }
      }

      return emails;
    } catch (e) {
      debugPrint('Error fetching emails: $e');
      return [];
    }
  }

  /// Sends an email using the SMTP server.
  Future<bool> sendEmail({
    required EmailAccount account,
    required String to,
    String? cc,
    String? bcc,
    required String subject,
    required String body,
    List<String>? attachmentPaths,
  }) async {
    // ... (implementation for sending email)
    return false;
  }

  /// Marks an email as read on the server.
  Future<bool> markAsRead(EmailAccount account, EmailMessage message) async {
    // ... (implementation for marking as read)
    return false;
  }

  /// Deletes an email from the server.
  Future<bool> deleteEmail(EmailAccount account, EmailMessage message) async {
    // ... (implementation for deleting email)
    return false;
  }

  /// Disconnects from the IMAP and SMTP servers.
  Future<void> disconnect() async {
    try {
      await _imapClient?.disconnect();
      await _smtpClient?.disconnect();
      _imapClient = null;
      _smtpClient = null;
      _isConnected = false;
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  // --- Private Helper Methods ---

  /// Connects to the IMAP server.
  Future<void> _connectImap(EmailAccount account) async {
    // ... (implementation for IMAP connection)
  }

  /// Connects to the SMTP server.
  Future<void> _connectSmtp(EmailAccount account) async {
    // ... (implementation for SMTP connection)
  }

  /// Converts a [MimeMessage] to an [EmailMessage].
  EmailMessage _convertToEmailMessage(MimeMessage message, String accountId, EmailFolder folder) {
    // ... (implementation for message conversion)
    return EmailMessage(messageId: '', accountId: '', subject: '', from: '', to: [], date: DateTime.now(), textBody: '', folder: EmailFolder.inbox, uid: 0);
  }

}
