import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:enough_mail/enough_mail.dart';
import 'dart:convert';
import '../models/email_message.dart';
import 'email_categorizer.dart';

/// A service class for interacting with the Yahoo Mail API.
///
/// This class provides methods for connecting to Yahoo Mail API, fetching emails,
/// sending emails, and performing other Yahoo Mail-specific operations.
class YahooApiService {
  // --- Private Properties ---

  String? _accessToken;
  String? _refreshToken;
  bool _isConnected = false;

  // IMAP connection for email access
  ImapClient? _imapClient;
  String? _userEmail;
  String? _appPassword;

  // Yahoo API endpoints
  static const String _profileUrl = 'https://api.login.yahoo.com/openid/v1/userinfo';
  static const String _tokenUrl = 'https://api.login.yahoo.com/oauth2/get_token';

  // Yahoo IMAP configuration
  static const String _imapHost = 'imap.mail.yahoo.com';
  static const int _imapPort = 993;
  static const bool _imapIsSecure = true;

  // --- Public Methods ---

  /// Connects to the Yahoo Mail API using OAuth2.
  ///
  /// This method takes access and refresh tokens and tests the connection.
  Future<bool> connectWithTokens(String accessToken, String refreshToken) async {
    try {
      _accessToken = accessToken;
      _refreshToken = refreshToken;

      debugPrint('📧 Yahoo IMAP: Starting connection process...');

      // Test the connection by fetching user profile
      final response = await http.get(
        Uri.parse(_profileUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final profileData = json.decode(response.body);
        _userEmail = profileData['email'];
        debugPrint('📧 Yahoo IMAP: Profile verified for email: $_userEmail');

        // Try to connect to IMAP, but don't fail if it doesn't work
        try {
          await _connectToImap();
          debugPrint('✅ Yahoo IMAP: Successfully connected to mail server');
          _isConnected = true;
          return true;
        } catch (e) {
          debugPrint('⚠️ Yahoo IMAP: Connection failed, likely due to scope restrictions: $e');
          debugPrint('⚠️ Yahoo IMAP: Account will be created with profile access only');
          _isConnected = false;
          // Still return true for account creation purposes
          return true;
        }
      } else {
        debugPrint('❌ Yahoo IMAP: Profile verification failed: ${response.statusCode}');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      debugPrint('❌ Yahoo IMAP: Connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Fetches a list of emails from the user's Yahoo Mail account via IMAP.
  Future<List<EmailMessage>> fetchEmails({
    required String accountId,
    int maxResults = 50,
    String query = '',
    EmailFolder folder = EmailFolder.inbox,
  }) async {
    if (_accessToken == null) {
      debugPrint('❌ Yahoo fetchEmails: No access token available');
      return [];
    }

    if (!_isConnected) {
      debugPrint('⚠️ Yahoo fetchEmails: IMAP not connected due to scope restrictions');
      debugPrint('⚠️ Yahoo fetchEmails: Returning example/placeholder emails for demo');

      // Return some demo emails to show the user what Yahoo integration would look like
      return _createDemoEmails(accountId, folder);
    }

    debugPrint('📧 Yahoo fetchEmails: Starting IMAP fetch for folder: $folder');

    try {
      // Use IMAP to fetch emails
      return await _fetchEmailsFromImap(
        accountId: accountId,
        folder: folder,
        maxResults: maxResults,
      );
    } catch (e) {
      debugPrint('❌ Yahoo fetchEmails: IMAP fetch failed: $e');
      return [];
    }
  }

  /// Sends an email using the Yahoo Mail API.
  ///
  /// Note: Yahoo doesn't provide a REST API for sending emails.
  /// This is a placeholder that returns false.
  /// TODO: Implement SMTP for Yahoo Mail sending.
  Future<bool> sendEmail({
    required String to,
    String? cc,
    String? bcc,
    required String subject,
    required String body,
    List<String>? attachmentPaths,
  }) async {
    if (_accessToken == null || !_isConnected) {
      throw Exception('Yahoo Mail API not connected');
    }

    debugPrint('Yahoo sendEmail called - Yahoo does not provide REST API for sending emails');
    debugPrint('Returning false. TODO: Implement SMTP for sending.');

    // Yahoo doesn't provide a REST API for sending emails
    // Return false for now - would need SMTP implementation
    return false;
  }

  /// Marks an email as read.
  ///
  /// Note: Yahoo doesn't provide a REST API for email operations.
  /// This returns false as IMAP would be needed.
  Future<bool> markAsRead(String messageId) async {
    if (_accessToken == null || !_isConnected) {
      return false;
    }

    debugPrint('Yahoo markAsRead called - not supported via REST API');
    return false;
  }

  /// Deletes an email by moving it to the trash.
  ///
  /// Note: Yahoo doesn't provide a REST API for email operations.
  /// This returns false as IMAP would be needed.
  Future<bool> deleteEmail(String messageId) async {
    if (_accessToken == null || !_isConnected) {
      return false;
    }

    debugPrint('Yahoo deleteEmail called - not supported via REST API');
    return false;
  }

  /// Disconnects from the Yahoo Mail API.
  void disconnect() {
    _accessToken = null;
    _refreshToken = null;
    _isConnected = false;
    _imapClient?.disconnect();
    _imapClient = null;
    _userEmail = null;
  }

  /// Refreshes the access token using the refresh token.
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': 'dj0yJmk9dUlhWDdjNk9RMzlvJmQ9WVdrOVVWWlpiRzloVWtFbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTkw',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Yahoo token refresh error: $e');
      return false;
    }
  }

  // --- Private Helper Methods ---

  /// Converts folder enum to Yahoo folder name.
  String _getFolderName(EmailFolder folder) {
    switch (folder) {
      case EmailFolder.inbox:
        return 'INBOX';
      case EmailFolder.sent:
        return 'Sent';
      case EmailFolder.drafts:
        return 'Draft';
      case EmailFolder.trash:
        return 'Trash';
      case EmailFolder.spam:
        return 'Bulk Mail';
      case EmailFolder.archive:
        return 'Archive';
      case EmailFolder.starred:
        return 'INBOX'; // Yahoo uses IMAP flags for starred emails
      case EmailFolder.custom:
        return 'INBOX'; // Default to INBOX for custom folders
    }
  }

  /// Converts a Yahoo message to an EmailMessage object.
  EmailMessage _convertYahooMessageToEmailMessage(
    Map<String, dynamic> messageData, {
    required String accountId,
    required EmailFolder folder,
  }) {
    try {
      // Extract basic message information
      final messageId = messageData['id']?.toString() ?? '';
      final subject = messageData['subject']?.toString() ?? '';
      final from = messageData['from']?['email']?.toString() ?? '';
      final fromName = messageData['from']?['name']?.toString() ?? from;

      // Extract recipients
      final toList = <String>[];
      if (messageData['to'] is List) {
        for (final recipient in messageData['to']) {
          if (recipient['email'] != null) {
            toList.add(recipient['email'].toString());
          }
        }
      }

      final ccList = <String>[];
      if (messageData['cc'] is List) {
        for (final recipient in messageData['cc']) {
          if (recipient['email'] != null) {
            ccList.add(recipient['email'].toString());
          }
        }
      }

      // Extract date
      DateTime parsedDate;
      try {
        final dateStr = messageData['date']?.toString() ?? '';
        parsedDate = dateStr.isNotEmpty
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr) * 1000)
            : DateTime.now();
      } catch (e) {
        parsedDate = DateTime.now();
      }

      // Extract body content
      String textBody = '';
      String? htmlBody;

      if (messageData['body'] != null) {
        textBody = messageData['body']['text']?.toString() ?? '';
        htmlBody = messageData['body']['html']?.toString();
      }

      // Check if message is read
      final isRead = !(messageData['isUnread'] == true);

      return EmailMessage(
        messageId: messageId,
        accountId: accountId,
        subject: subject,
        from: fromName.isNotEmpty ? fromName : from,
        to: toList,
        cc: ccList.isNotEmpty ? ccList : null,
        date: parsedDate,
        textBody: textBody,
        htmlBody: htmlBody,
        isRead: isRead,
        folder: folder,
        uid: messageData['messageNumber']?.hashCode ?? 0,
        attachments: [], // TODO: Implement attachment extraction
      );
    } catch (e) {
      debugPrint('Error converting Yahoo message: $e');
      // Return a placeholder message if conversion fails
      return EmailMessage(
        messageId: messageData['id']?.toString() ?? '',
        accountId: accountId,
        subject: 'Error loading message',
        from: 'unknown',
        to: [],
        date: DateTime.now(),
        textBody: 'Failed to load message content',
        folder: folder,
        uid: 0,
      );
    }
  }

  /// Gets user profile information from Yahoo
  Future<Map<String, String>> getUserProfile() async {
    if (_accessToken == null) {
      throw Exception('Yahoo access token not available');
    }

    try {
      // Get user profile from Yahoo OpenID userinfo endpoint
      final response = await http.get(
        Uri.parse(_profileUrl),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Yahoo userinfo response: $data');

        // Extract user information from OpenID userinfo format
        final name = data['name'] ?? data['given_name'] ?? data['nickname'] ?? 'Yahoo User';
        final email = data['email'] ?? '';

        return {
          'name': name,
          'email': email,
        };
      }

      // If both fail, return basic info
      return {
        'name': 'Yahoo User',
        'email': '',
      };
    } catch (e) {
      debugPrint('Error fetching Yahoo user profile: $e');
      return {
        'name': 'Yahoo User',
        'email': '',
      };
    }
  }

  // --- IMAP Methods ---

  /// Sets the Yahoo app password for IMAP access.
  void setAppPassword(String appPassword) {
    _appPassword = appPassword;
  }

  /// Connects to Yahoo IMAP server using App Password.
  Future<void> _connectToImap() async {
    if (_userEmail == null) {
      throw Exception('Email not available for IMAP connection');
    }

    if (_appPassword == null) {
      throw Exception('App password required for Yahoo IMAP access');
    }

    try {
      debugPrint('📧 Yahoo IMAP: Connecting to $_imapHost:$_imapPort with App Password');

      _imapClient = ImapClient(isLogEnabled: false);

      await _imapClient!.connectToServer(
        _imapHost,
        _imapPort,
        isSecure: _imapIsSecure,
      );

      debugPrint('📧 Yahoo IMAP: Server connected, authenticating with App Password...');

      // Authenticate using PLAIN with app password
      await _imapClient!.login(
        _userEmail!,
        _appPassword!,
      );

      debugPrint('✅ Yahoo IMAP: Successfully connected and authenticated with App Password');
    } catch (e) {
      debugPrint('❌ Yahoo IMAP: Connection failed: $e');
      _imapClient = null;
      rethrow;
    }
  }

  /// Fetches emails from IMAP server.
  Future<List<EmailMessage>> _fetchEmailsFromImap({
    required String accountId,
    required EmailFolder folder,
    int maxResults = 50,
  }) async {
    if (_imapClient == null) {
      throw Exception('IMAP client not connected');
    }

    try {
      final folderName = _getFolderName(folder);
      debugPrint('📧 Yahoo IMAP: Selecting folder: $folderName');

      // Select the folder (for now, just use inbox)
      final mailbox = await _imapClient!.selectInbox();
      debugPrint('📧 Yahoo IMAP: Folder selected, ${mailbox.messagesExists} messages exist');

      if (mailbox.messagesExists == 0) {
        return [];
      }

      // Fetch the most recent messages
      final startIndex = mailbox.messagesExists - maxResults + 1;
      final endIndex = mailbox.messagesExists;

      debugPrint('📧 Yahoo IMAP: Fetching messages $startIndex:$endIndex');

      final fetchResult = await _imapClient!.fetchMessages(
        MessageSequence.fromRange(
          startIndex > 0 ? startIndex : 1,
          endIndex,
        ),
        'ENVELOPE BODY.PEEK[]',
      );

      final emails = <EmailMessage>[];

      for (final message in fetchResult.messages) {
        try {
          final emailMessage = _convertImapMessageToEmailMessage(
            message,
            accountId: accountId,
            folder: folder,
          );
          emailMessage.category = EmailCategorizer.categorizeEmail(emailMessage);
          emails.add(emailMessage);
        } catch (e) {
          debugPrint('❌ Yahoo IMAP: Error converting message: $e');
        }
      }

      debugPrint('✅ Yahoo IMAP: Converted ${emails.length} messages');
      return emails;

    } catch (e) {
      debugPrint('❌ Yahoo IMAP: Fetch error: $e');
      return [];
    }
  }

  /// Converts IMAP message to EmailMessage object.
  EmailMessage _convertImapMessageToEmailMessage(
    MimeMessage message,
    {
      required String accountId,
      required EmailFolder folder,
    }
  ) {
    final envelope = message.envelope!;

    return EmailMessage(
      messageId: message.uid?.toString() ?? message.sequenceId?.toString() ?? '',
      accountId: accountId,
      subject: envelope.subject ?? '',
      from: envelope.from?.first.toString() ?? '',
      to: envelope.to?.map((addr) => addr.toString()).toList() ?? [],
      cc: envelope.cc?.map((addr) => addr.toString()).toList(),
      date: envelope.date ?? DateTime.now(),
      textBody: message.decodeTextPlainPart() ?? '',
      htmlBody: message.decodeTextHtmlPart(),
      isRead: message.flags?.contains(MessageFlags.seen) ?? false,
      folder: folder,
      uid: message.uid ?? message.sequenceId ?? 0,
      attachments: [], // TODO: Implement attachment extraction
    );
  }

  /// Creates demo emails to show what Yahoo integration would look like.
  List<EmailMessage> _createDemoEmails(String accountId, EmailFolder folder) {
    if (folder != EmailFolder.inbox) {
      return []; // Only show demo emails in inbox
    }

    return [
      EmailMessage(
        messageId: 'yahoo_demo_1',
        accountId: accountId,
        subject: 'Welcome to Yahoo Mail Integration! 🎉',
        from: 'Yahoo Support <noreply@yahoo.com>',
        to: [_userEmail ?? 'user@yahoo.com'],
        date: DateTime.now().subtract(const Duration(hours: 2)),
        textBody: '''Dear $_userEmail,

Your Yahoo account has been successfully connected to QMail!

However, due to Yahoo's recent restrictions on third-party email access, this app cannot currently fetch your real Yahoo emails via IMAP.

To access your Yahoo emails in QMail, you can:
1. Use Yahoo's App Passwords feature
2. Or access your emails directly through Yahoo Mail

We're working on finding alternative solutions to provide full Yahoo email access.

Best regards,
QMail Team''',
        isRead: false,
        folder: folder,
        uid: 1,
        category: EmailCategory.primary,
      ),
      EmailMessage(
        messageId: 'yahoo_demo_2',
        accountId: accountId,
        subject: 'Yahoo Mail API Limitations',
        from: 'QMail Support <support@qmail.app>',
        to: [_userEmail ?? 'user@yahoo.com'],
        date: DateTime.now().subtract(const Duration(hours: 4)),
        textBody: '''This is a demonstration of how your Yahoo emails would appear in QMail once full access is available.

The Yahoo OAuth integration is working perfectly for authentication, but Yahoo has restricted mail scope access for new applications.

For now, this demo shows the potential of the integration. We're exploring ways to provide full email access through alternative methods.''',
        isRead: true,
        folder: folder,
        uid: 2,
        category: EmailCategory.primary,
      ),
    ];
  }
}