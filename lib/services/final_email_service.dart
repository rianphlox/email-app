
import 'dart:async';
import 'dart:io';
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
  StreamSubscription? _idleSubscription;
  Timer? _reconnectTimer;
  bool _isIdling = false;
  Function(EmailMessage)? _onNewMessage;

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
    try {
      // Ensure SMTP connection is established
      if (_smtpClient == null || !_isConnected) {
        await connectToAccount(account);
      }

      // Create message builder
      final messageBuilder = MessageBuilder();
      messageBuilder.from = [MailAddress(account.name, account.email)];
      messageBuilder.to = _parseEmailAddresses(to);

      if (cc?.isNotEmpty == true) {
        messageBuilder.cc = _parseEmailAddresses(cc!);
      }
      if (bcc?.isNotEmpty == true) {
        messageBuilder.bcc = _parseEmailAddresses(bcc!);
      }

      messageBuilder.subject = subject;
      messageBuilder.addTextPlain(body);

      // Add attachments if provided
      if (attachmentPaths?.isNotEmpty == true) {
        for (final path in attachmentPaths!) {
          final file = File(path);
          final fileName = file.path.split('/').last;
          messageBuilder.addBinary(await file.readAsBytes(), MediaType.fromSubtype(MediaSubtype.applicationOctetStream), filename: fileName);
        }
      }

      final mimeMessage = messageBuilder.buildMimeMessage();
      await _smtpClient!.sendMessage(mimeMessage);

      debugPrint('✅ Email sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending email: $e');
      return false;
    }
  }

  /// Helper method to parse email addresses
  List<MailAddress> _parseEmailAddresses(String emailString) {
    return emailString
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => MailAddress('', e))
        .toList();
  }

  /// Marks an email as read on the server.
  Future<bool> markAsRead(EmailAccount account, EmailMessage message) async {
    // ... (implementation for marking as read)
    return false;
  }

  /// Deletes an email from the server.
  Future<bool> deleteEmail(EmailAccount account, EmailMessage message) async {
    try {
      // Ensure IMAP connection is established
      if (_imapClient == null || !_isConnected) {
        await connectToAccount(account);
      }

      if (_imapClient == null) {
        debugPrint('❌ IMAP client not available for deletion');
        return false;
      }

      // Select the appropriate folder
      await _imapClient!.selectInbox();

      // Mark the email as deleted using IMAP flags
      final sequence = MessageSequence.fromId(message.uid);
      await _imapClient!.store(sequence, [MessageFlags.deleted]);

      // Expunge to permanently remove deleted messages
      await _imapClient!.expunge();

      debugPrint('✅ Email deleted successfully from server: ${message.subject}');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting email from server: $e');
      return false;
    }
  }

  /// Starts IMAP IDLE for real-time email notifications.
  Future<void> startIdling({Function(EmailMessage)? onNewMessage}) async {
    if (!_isConnected || _imapClient == null || _isIdling) return;

    _onNewMessage = onNewMessage;
    _isIdling = true;

    try {
      // Select inbox for IDLE
      await _imapClient!.selectInbox();

      // Use timer-based approach for real-time checking (pseudo-IDLE)
      _idleSubscription = Stream.periodic(const Duration(seconds: 10))
          .listen((_) async {
        try {
          await _imapClient!.noop();
          // Check for new messages directly
          final mailbox = await _imapClient!.selectInbox();
          if (mailbox.messagesExists > 0) {
            await _handleNewMessage();
          }
        } catch (e) {
          debugPrint('IDLE check error: $e');
          _handleIdleError();
        }
      });
    } catch (e) {
      debugPrint('Failed to start IDLE: $e');
      _isIdling = false;
      _scheduleReconnect();
    }
  }

  /// Stops IMAP IDLE.
  Future<void> stopIdling() async {
    _isIdling = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    try {
      await _idleSubscription?.cancel();
      _idleSubscription = null;
      // enough_mail 2.1.7 doesn't have idleStop, just cancel the subscription
    } catch (e) {
      debugPrint('Error stopping IDLE: $e');
    }
  }

  /// Disconnects from the IMAP and SMTP servers.
  Future<void> disconnect() async {
    try {
      await stopIdling();
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
    try {
      _imapClient = ImapClient(isLogEnabled: false);

      await _imapClient!.connectToServer(
        account.imapServer!,
        account.imapPort!,
        isSecure: account.isSSL,
      );

      await _imapClient!.login(account.email, account.password!);
      debugPrint('✅ IMAP connection successful for ${account.email}');
    } catch (e) {
      debugPrint('❌ IMAP connection failed: $e');
      _imapClient = null;
      rethrow;
    }
  }

  /// Connects to the SMTP server.
  Future<void> _connectSmtp(EmailAccount account) async {
    try {
      _smtpClient = SmtpClient('${account.email}.smtp', isLogEnabled: false);

      await _smtpClient!.connectToServer(
        account.smtpServer!,
        account.smtpPort!,
        isSecure: account.isSSL,
      );

      await _smtpClient!.ehlo();
      await _smtpClient!.authenticate(account.email, account.password!);
      debugPrint('✅ SMTP connection successful for ${account.email}');
    } catch (e) {
      debugPrint('❌ SMTP connection failed: $e');
      _smtpClient = null;
      rethrow;
    }
  }

  /// Handles new messages detected via IDLE.
  Future<void> _handleNewMessage() async {
    try {
      if (_onNewMessage == null) return;

      // Fetch the latest message
      final mailbox = await _imapClient!.selectInbox();
      if (mailbox.messagesExists == 0) return;

      final fetchResult = await _imapClient!.fetchMessages(
        MessageSequence.fromRange(mailbox.messagesExists, mailbox.messagesExists),
        'BODY.PEEK[]',
      );

      if (fetchResult.messages.isNotEmpty) {
        final message = fetchResult.messages.first;
        final emailMessage = _convertToEmailMessage(message, '', EmailFolder.inbox);
        _onNewMessage!(emailMessage);
      }
    } catch (e) {
      debugPrint('Error handling new message: $e');
    }
  }

  /// Handles IDLE errors with exponential backoff.
  void _handleIdleError() {
    _isIdling = false;
    _scheduleReconnect();
  }


  /// Schedules reconnection with exponential backoff.
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), () async {
      if (!_isConnected) return;

      try {
        // Attempt to restart IDLE
        await startIdling(onNewMessage: _onNewMessage);
      } catch (e) {
        debugPrint('Reconnect failed: $e');
        // Schedule another reconnect
        _scheduleReconnect();
      }
    });
  }

  /// Converts a [MimeMessage] to an [EmailMessage].
  EmailMessage _convertToEmailMessage(MimeMessage message, String accountId, EmailFolder folder) {
    // ... (implementation for message conversion)
    return EmailMessage(messageId: '', accountId: '', subject: '', from: '', to: [], date: DateTime.now(), textBody: '', folder: EmailFolder.inbox, uid: 0);
  }

}
