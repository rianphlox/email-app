import 'package:enough_mail/enough_mail.dart';
import 'dart:io';
import '../models/email_account.dart';
import '../models/email_message.dart';

class FinalEmailService {
  ImapClient? _imapClient;
  SmtpClient? _smtpClient;
  bool _isConnected = false;

  Future<bool> connectToAccount(EmailAccount account) async {
    try {
      await _connectImap(account);
      await _connectSmtp(account);
      _isConnected = true;
      return true;
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> _connectImap(EmailAccount account) async {
    _imapClient = ImapClient(isLogEnabled: false);

    await _imapClient!.connectToServer(
      account.imapServer!,
      account.imapPort!,
      isSecure: account.isSSL,
    );

    // For all providers, use regular login with email and password/app-password
    await _imapClient!.login(
      account.email,
      account.accessToken,
    );
  }

  Future<void> _connectSmtp(EmailAccount account) async {
    _smtpClient = SmtpClient('readify_email_app', isLogEnabled: false);

    await _smtpClient!.connectToServer(
      account.smtpServer!,
      account.smtpPort!,
      isSecure: account.isSSL,
    );

    // For all providers, use regular authentication
    await _smtpClient!.authenticate(account.email, account.accessToken);
  }

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

      // Get the most recent messages
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
          print('Error converting message: $e');
        }
      }

      return emails;
    } catch (e) {
      print('Error fetching emails: $e');
      return [];
    }
  }

  EmailMessage _convertToEmailMessage(MimeMessage message, String accountId, EmailFolder folder) {
    final attachments = <EmailAttachment>[];

    // Simple attachment handling
    try {
      if (message.hasAttachments()) {
        // For now, just indicate that attachments exist
        attachments.add(EmailAttachment(
          name: 'attachment',
          mimeType: 'application/octet-stream',
          size: 0,
          contentId: 'attachment',
        ));
      }
    } catch (e) {
      // Ignore attachment errors
    }

    // Get email addresses safely
    final fromEmail = message.from?.isNotEmpty == true ? message.from!.first.email : null;
    final fromEmailString = fromEmail ?? 'Unknown';
    final toEmails = message.to?.map((addr) => addr.email).whereType<String>().toList() ?? [];
    final ccEmails = message.cc?.map((addr) => addr.email).whereType<String>().toList();
    final bccEmails = message.bcc?.map((addr) => addr.email).whereType<String>().toList();

    return EmailMessage(
      messageId: message.guid?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      accountId: accountId,
      subject: message.decodeSubject() ?? 'No Subject',
      from: fromEmailString,
      to: toEmails,
      cc: ccEmails,
      bcc: bccEmails,
      date: message.decodeDate() ?? DateTime.now(),
      textBody: message.decodeTextPlainPart() ?? '',
      htmlBody: message.decodeTextHtmlPart(),
      isRead: message.isSeen,
      isImportant: message.isFlagged,
      folder: folder,
      attachments: attachments.isNotEmpty ? attachments : null,
      uid: message.sequenceId ?? 0,
    );
  }

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
      if (_smtpClient == null || !_isConnected) {
        await _connectSmtp(account);
      }

      final message = MessageBuilder()
        ..from = [MailAddress(account.name, account.email)]
        ..to = _parseAddresses(to)
        ..subject = subject;

      message.addText(body);

      if (cc != null && cc.isNotEmpty) {
        message.cc = _parseAddresses(cc);
      }

      if (bcc != null && bcc.isNotEmpty) {
        message.bcc = _parseAddresses(bcc);
      }

      // Simple attachment handling
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        for (final path in attachmentPaths) {
          final file = File(path);
          if (await file.exists()) {
            try {
              final fileName = path.split('/').last;
              final fileBytes = await file.readAsBytes();
              message.addBinary(fileBytes, MediaType.guessFromFileName(fileName));
            } catch (e) {
              print('Error adding attachment: $e');
            }
          }
        }
      }

      final mimeMessage = message.buildMimeMessage();
      await _smtpClient!.sendMessage(mimeMessage);
      return true;
    } catch (e) {
      print('Send email error: $e');
      return false;
    }
  }

  List<MailAddress> _parseAddresses(String addresses) {
    return addresses
        .split(',')
        .map((addr) => addr.trim())
        .where((addr) => addr.isNotEmpty)
        .map((addr) => MailAddress('', addr))
        .toList();
  }

  Future<bool> markAsRead(EmailAccount account, EmailMessage message) async {
    try {
      if (_imapClient == null || !_isConnected) {
        await connectToAccount(account);
      }

      await _imapClient!.selectInbox();

      // Simple mark as read using sequence ID
      final sequenceId = message.uid > 0 ? message.uid : 1;
      await _imapClient!.store(MessageSequence.fromId(sequenceId), [MessageFlags.seen]);
      return true;
    } catch (e) {
      print('Mark as read error: $e');
      return false;
    }
  }

  Future<bool> deleteEmail(EmailAccount account, EmailMessage message) async {
    try {
      if (_imapClient == null || !_isConnected) {
        await connectToAccount(account);
      }

      await _imapClient!.selectInbox();

      // Simple delete using sequence ID
      final sequenceId = message.uid > 0 ? message.uid : 1;
      await _imapClient!.store(MessageSequence.fromId(sequenceId), [MessageFlags.deleted]);
      await _imapClient!.expunge();
      return true;
    } catch (e) {
      print('Delete email error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _imapClient?.disconnect();
      await _smtpClient?.disconnect();
      _imapClient = null;
      _smtpClient = null;
      _isConnected = false;
    } catch (e) {
      print('Disconnect error: $e');
    }
  }
}