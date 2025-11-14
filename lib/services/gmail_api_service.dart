import 'package:flutter/foundation.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/email_message.dart';
import 'dart:convert';
import 'dart:io';
import 'google_auth_client.dart';
import 'email_categorizer.dart';

/// A service class for interacting with the Gmail API.
///
/// This class provides methods for connecting to the Gmail API, fetching emails,
/// sending emails, and performing other Gmail-specific operations.
class GmailApiService {
  // --- Private Properties ---

  gmail.GmailApi? _gmailApi;
  bool _isConnected = false;

  // --- Public Methods ---

  /// Connects to the Gmail API using a Google Sign-In account.
  ///
  /// This method takes a [GoogleSignInAccount] object and uses its authentication
  /// headers to create a [gmail.GmailApi] client.
  Future<bool> connectWithGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      final headers = await googleUser.authHeaders;

      if (headers.isEmpty) {
        return false;
      }

      final client = GoogleAuthClient(headers);
      _gmailApi = gmail.GmailApi(client);
      _isConnected = true;

      // Test the connection by fetching the user's profile.
      try {
        await _gmailApi!.users.getProfile('me');
        return true;
      } catch (e) {
        _isConnected = false;
        return false;
      }
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Fetches a list of emails from the user's Gmail account.
  ///
  /// This method can fetch emails from a specific folder and can also be used
  /// with a custom query.
  Future<List<EmailMessage>> fetchEmails({
    required String accountId,
    int maxResults = 50,
    String query = '',
    EmailFolder folder = EmailFolder.inbox,
  }) async {
    if (_gmailApi == null || !_isConnected) {
      throw Exception('Gmail API not connected');
    }

    try {
      // Build the query based on folder
      String folderQuery = '';
      switch (folder) {
        case EmailFolder.inbox:
          folderQuery = 'in:inbox';
          break;
        case EmailFolder.sent:
          folderQuery = 'in:sent';
          break;
        case EmailFolder.drafts:
          folderQuery = 'in:drafts';
          break;
        case EmailFolder.trash:
          folderQuery = 'in:trash';
          break;
        case EmailFolder.spam:
          folderQuery = 'in:spam';
          break;
        case EmailFolder.archive:
          folderQuery = 'in:all -in:inbox -in:sent -in:drafts -in:trash -in:spam';
          break;
        case EmailFolder.custom:
          folderQuery = 'in:inbox'; // Default to inbox for custom folders
          break;
      }

      // Combine folder query with custom query
      final finalQuery = query.isEmpty ? folderQuery : '$folderQuery $query';

      // Get list of message IDs
      final messagesList = await _gmailApi!.users.messages.list(
        'me',
        q: finalQuery,
        maxResults: maxResults,
      );

      if (messagesList.messages == null || messagesList.messages!.isEmpty) {
        return [];
      }

      // Fetch detailed message information for each message
      final List<EmailMessage> emails = [];
      for (final message in messagesList.messages!) {
        if (message.id != null) {
          try {
            final detailedMessage = await _gmailApi!.users.messages.get(
              'me',
              message.id!,
              format: 'full',
            );

            final emailMessage = _convertGmailMessageToEmailMessage(
              detailedMessage,
              accountId: accountId,
              folder: folder,
            );
            emailMessage.category = EmailCategorizer.categorizeEmail(emailMessage);
            emails.add(emailMessage);
          } catch (e) {
            debugPrint('Error fetching message ${message.id}: $e');
            // Continue with other messages
          }
        }
      }

      return emails;
    } catch (e) {
      throw Exception('Failed to fetch emails: $e');
    }
  }

  /// Sends an email using the Gmail API.
  Future<bool> sendEmail({
    required String to,
    String? cc,
    String? bcc,
    required String subject,
    required String body,
    List<String>? attachmentPaths,
  }) async {
    if (_gmailApi == null || !_isConnected) {
      throw Exception('Gmail API not connected');
    }

    try {
      // ... (implementation for sending email)
    } catch (e) {
      return false;
    }
    return false;
  }

  /// Marks an email as read.
  Future<bool> markAsRead(String messageId) async {
    if (_gmailApi == null || !_isConnected) {
      return false;
    }

    try {
      final request = gmail.ModifyMessageRequest()..removeLabelIds = ['UNREAD'];
      await _gmailApi!.users.messages.modify(request, 'me', messageId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deletes an email by moving it to the trash.
  Future<bool> deleteEmail(String messageId) async {
    if (_gmailApi == null || !_isConnected) {
      return false;
    }

    try {
      await _gmailApi!.users.messages.trash('me', messageId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Disconnects from the Gmail API.
  void disconnect() {
    _gmailApi = null;
    _isConnected = false;
  }

  // --- Private Helper Methods ---

  /// Converts a [gmail.Message] object to an [EmailMessage] object.
  EmailMessage _convertGmailMessageToEmailMessage(
    gmail.Message message, {
    required String accountId,
    required EmailFolder folder,
  }) {
    try {
      // Extract headers
      final headers = message.payload?.headers ?? [];
      String subject = '';
      String from = '';
      String to = '';
      String cc = '';
      String bcc = '';
      String date = '';

      for (final header in headers) {
        switch (header.name?.toLowerCase()) {
          case 'subject':
            subject = header.value ?? '';
            break;
          case 'from':
            from = header.value ?? '';
            break;
          case 'to':
            to = header.value ?? '';
            break;
          case 'cc':
            cc = header.value ?? '';
            break;
          case 'bcc':
            bcc = header.value ?? '';
            break;
          case 'date':
            date = header.value ?? '';
            break;
        }
      }

      // Parse email addresses
      final List<String> toList = to.isEmpty ? [] : to.split(',').map((e) => e.trim()).toList();
      final List<String> ccList = cc.isEmpty ? [] : cc.split(',').map((e) => e.trim()).toList();
      final List<String> bccList = bcc.isEmpty ? [] : bcc.split(',').map((e) => e.trim()).toList();

      // Extract body content
      final bodyData = _extractBodyFromPayload(message.payload);

      // Parse date
      DateTime parsedDate;
      try {
        parsedDate = date.isNotEmpty ? _parseRfc2822Date(date) : DateTime.now();
      } catch (e) {
        parsedDate = DateTime.now();
      }

      // Extract sender name
      final senderName = _extractSenderName(from);

      // Check if message is read (not in UNREAD label)
      final labels = message.labelIds ?? [];
      final isRead = !labels.contains('UNREAD');

      return EmailMessage(
        messageId: message.id ?? '',
        accountId: accountId, // Use actual account ID
        subject: subject,
        from: senderName.isNotEmpty ? senderName : from,
        to: toList,
        cc: ccList,
        bcc: bccList,
        date: parsedDate,
        textBody: bodyData['text'] ?? '',
        htmlBody: bodyData['html'],
        isRead: isRead,
        folder: folder, // Use actual folder
        uid: message.threadId?.hashCode ?? 0,
        attachments: [], // TODO: Implement attachment extraction
      );
    } catch (e) {
      debugPrint('Error converting Gmail message: $e');
      return EmailMessage(
        messageId: message.id ?? '',
        accountId: accountId,
        subject: 'Error loading message',
        from: 'unknown',
        to: [],
        date: DateTime.now(),
        textBody: 'Failed to load message content',
        folder: EmailFolder.inbox,
        uid: 0,
      );
    }
  }

  /// Extracts the body of an email from its payload.
  Map<String, String?> _extractBodyFromPayload(gmail.MessagePart? payload) {
    if (payload == null) return {'text': '', 'html': null};

    String? textBody;
    String? htmlBody;

    // Check if this part has a body
    if (payload.body?.data != null) {
      final mimeType = payload.mimeType?.toLowerCase() ?? '';
      final bodyData = _decodeBase64Url(payload.body!.data!);

      if (mimeType.contains('text/plain')) {
        textBody = bodyData;
      } else if (mimeType.contains('text/html')) {
        htmlBody = bodyData;
      }
    }

    // Check multipart payload
    if (payload.parts != null && payload.parts!.isNotEmpty) {
      for (final part in payload.parts!) {
        final partBodyData = _extractBodyFromPayload(part);
        if (partBodyData['text'] != null && textBody == null) {
          textBody = partBodyData['text'];
        }
        if (partBodyData['html'] != null && htmlBody == null) {
          htmlBody = partBodyData['html'];
        }
      }
    }

    return {
      'text': textBody ?? htmlBody ?? 'No content available',
      'html': htmlBody,
    };
  }

  /// Decodes a base64 URL-encoded string.
  String _decodeBase64Url(String data) {
    try {
      // Replace URL-safe characters
      String normalized = data.replaceAll('-', '+').replaceAll('_', '/');

      // Add padding if necessary
      switch (normalized.length % 4) {
        case 1:
          normalized += '===';
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final bytes = base64.decode(normalized);
      return utf8.decode(bytes);
    } catch (e) {
      return '';
    }
  }

  /// Parses an RFC 2822 formatted date string.
  DateTime _parseRfc2822Date(String dateStr) {
    try {
      // Remove common prefixes and clean up the date string
      String cleanDateStr = dateStr.trim();

      // Handle timezone abbreviations
      const timezoneMap = {
        'PST': '-0800',
        'PDT': '-0700',
        'EST': '-0500',
        'EDT': '-0400',
        'CST': '-0600',
        'CDT': '-0500',
        'MST': '-0700',
        'MDT': '-0600',
        'GMT': '+0000',
        'UTC': '+0000',
      };

      for (final entry in timezoneMap.entries) {
        cleanDateStr = cleanDateStr.replaceAll(entry.key, entry.value);
      }

      return DateTime.parse(cleanDateStr);
    } catch (e) {
      try {
        // Try HttpDate format as fallback
        return HttpDate.parse(dateStr);
      } catch (e2) {
        return DateTime.now();
      }
    }
  }

  /// Extracts the sender's name from the 'From' header.
  String _extractSenderName(String fromHeader) {
    if (fromHeader.isEmpty) return '';

    try {
      // Pattern: "Display Name <email@domain.com>" or just "email@domain.com"
      final RegExp nameEmailPattern = RegExp(r'^(.*?)\s*<(.+?)>$');
      final match = nameEmailPattern.firstMatch(fromHeader.trim());

      if (match != null) {
        final name = match.group(1)?.trim().replaceAll('"', '') ?? '';
        final email = match.group(2)?.trim() ?? '';

        if (name.isNotEmpty) {
          return name;
        }
        return _extractNameFromEmail(email);
      }

      // If no display name, extract from email
      return _extractNameFromEmail(fromHeader.trim());
    } catch (e) {
      return fromHeader.split('@').first;
    }
  }

  /// Extracts a readable name from an email address.
  String _extractNameFromEmail(String email) {
    if (email.isEmpty) return '';

    try {
      final localPart = email.split('@').first;

      // Replace common separators with spaces and capitalize
      return localPart
          .replaceAll(RegExp(r'[._-]'), ' ')
          .split(' ')
          .map((word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '')
          .join(' ')
          .trim();
    } catch (e) {
      return email;
    }
  }
}