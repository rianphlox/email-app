import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  // Yahoo API endpoints
  static const String _baseUrl = 'https://api.mail.yahoo.com';
  static const String _tokenUrl = 'https://api.login.yahoo.com/oauth2/get_token';

  // --- Public Methods ---

  /// Connects to the Yahoo Mail API using OAuth2.
  ///
  /// This method takes access and refresh tokens and tests the connection.
  Future<bool> connectWithTokens(String accessToken, String refreshToken) async {
    try {
      _accessToken = accessToken;
      _refreshToken = refreshToken;

      // Test the connection by fetching user profile
      final response = await http.get(
        Uri.parse('$_baseUrl/ws/v3/mailboxes/@/profile'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _isConnected = true;
        return true;
      } else {
        _isConnected = false;
        return false;
      }
    } catch (e) {
      debugPrint('Yahoo API connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Fetches a list of emails from the user's Yahoo Mail account.
  ///
  /// This method can fetch emails from a specific folder.
  Future<List<EmailMessage>> fetchEmails({
    required String accountId,
    int maxResults = 50,
    String query = '',
    EmailFolder folder = EmailFolder.inbox,
  }) async {
    if (_accessToken == null || !_isConnected) {
      throw Exception('Yahoo Mail API not connected');
    }

    try {
      // Build the folder name based on folder type
      String folderName = _getFolderName(folder);

      // Get list of messages from the specified folder
      final response = await http.get(
        Uri.parse('$_baseUrl/ws/v3/mailboxes/@/folders/$folderName/messages?count=$maxResults'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch emails: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final messagesData = data['messages'] as List<dynamic>?;

      if (messagesData == null || messagesData.isEmpty) {
        return [];
      }

      // Convert Yahoo messages to EmailMessage objects
      final List<EmailMessage> emails = [];
      for (final messageData in messagesData) {
        try {
          final emailMessage = _convertYahooMessageToEmailMessage(
            messageData,
            accountId: accountId,
            folder: folder,
          );
          emailMessage.category = EmailCategorizer.categorizeEmail(emailMessage);
          emails.add(emailMessage);
        } catch (e) {
          debugPrint('Error converting Yahoo message: $e');
          // Continue with other messages
        }
      }

      return emails;
    } catch (e) {
      throw Exception('Failed to fetch emails: $e');
    }
  }

  /// Sends an email using the Yahoo Mail API.
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

    try {
      // Construct the email message
      final messageData = {
        'message': {
          'to': [{'email': to}],
          if (cc != null) 'cc': [{'email': cc}],
          if (bcc != null) 'bcc': [{'email': bcc}],
          'subject': subject,
          'body': {
            'text': body,
          }
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/ws/v3/mailboxes/@/messages'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(messageData),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Yahoo send email error: $e');
      return false;
    }
  }

  /// Marks an email as read.
  Future<bool> markAsRead(String messageId) async {
    if (_accessToken == null || !_isConnected) {
      return false;
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/ws/v3/mailboxes/@/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'isUnread': false,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Yahoo mark as read error: $e');
      return false;
    }
  }

  /// Deletes an email by moving it to the trash.
  Future<bool> deleteEmail(String messageId) async {
    if (_accessToken == null || !_isConnected) {
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/ws/v3/mailboxes/@/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Yahoo delete email error: $e');
      return false;
    }
  }

  /// Disconnects from the Yahoo Mail API.
  void disconnect() {
    _accessToken = null;
    _refreshToken = null;
    _isConnected = false;
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
        return 'Inbox';
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
      case EmailFolder.custom:
        return 'Inbox'; // Default to inbox for custom folders
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
}