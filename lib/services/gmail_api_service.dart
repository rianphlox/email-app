import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/email_message.dart';
import 'dart:convert';
import 'dart:io';
import 'google_auth_client.dart';

class GmailApiService {
  gmail.GmailApi? _gmailApi;
  bool _isConnected = false;

  Future<bool> connectWithGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      final headers = await googleUser.authHeaders;

      if (headers.isEmpty) {
        print('Failed to get auth headers');
        return false;
      }

      final client = GoogleAuthClient(headers);
      _gmailApi = gmail.GmailApi(client);
      _isConnected = true;

      // Test the connection
      try {
        final profile = await _gmailApi!.users.getProfile('me');
        print('Gmail API connected successfully for: ${profile.emailAddress}');
        return true;
      } catch (e) {
        print('Failed to get user profile: $e');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      print('Gmail API connection error: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<List<EmailMessage>> fetchEmails({
    int maxResults = 50,
    String query = '',
    EmailFolder folder = EmailFolder.inbox,
  }) async {
    if (_gmailApi == null || !_isConnected) {
      throw Exception('Gmail API not connected');
    }

    try {
      // Build folder-specific query
      String folderQuery;
      if (query.isNotEmpty) {
        folderQuery = query;
      } else {
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
          default:
            folderQuery = 'in:inbox';
        }
      }

      // Get list of message IDs
      final messagesList = await _gmailApi!.users.messages.list(
        'me',
        maxResults: maxResults,
        q: folderQuery,
      );

      if (messagesList.messages == null || messagesList.messages!.isEmpty) {
        return [];
      }

      final emails = <EmailMessage>[];

      // Fetch each message details
      for (final messageRef in messagesList.messages!) {
        try {
          final message = await _gmailApi!.users.messages.get(
            'me',
            messageRef.id!,
            format: 'full',
          );

          final emailMessage = _convertGmailMessageToEmailMessage(message);
          emails.add(emailMessage);
        } catch (e) {
          print('Error fetching message ${messageRef.id}: $e');
        }
      }

      return emails;
    } catch (e) {
      print('Error fetching emails: $e');
      throw Exception('Failed to fetch emails: $e');
    }
  }

  EmailMessage _convertGmailMessageToEmailMessage(gmail.Message message) {
    final headers = message.payload?.headers ?? [];

    String getHeader(String name) {
      final header = headers.firstWhere(
        (h) => h.name?.toLowerCase() == name.toLowerCase(),
        orElse: () => gmail.MessagePartHeader(),
      );
      return header.value ?? '';
    }

    final subject = getHeader('Subject');
    final from = getHeader('From');
    final to = getHeader('To');
    final cc = getHeader('Cc');
    final bcc = getHeader('Bcc');
    final dateStr = getHeader('Date');

    DateTime? date;
    try {
      if (dateStr.isNotEmpty) {
        // Parse RFC 2822 date format (e.g., "Wed, 1 Nov 2025 12:30:45 +0000")
        date = _parseRfc2822Date(dateStr);
      }
    } catch (e) {
      print('Error parsing date "$dateStr": $e');
      date = DateTime.now();
    }

    // Extract body content
    String textBody = '';
    String? htmlBody;

    final bodyData = _extractBodyFromPayload(message.payload);
    textBody = bodyData['text'] ?? '';
    htmlBody = bodyData['html'];

    // Parse email addresses
    List<String> parseAddresses(String addressString) {
      if (addressString.isEmpty) return [];
      return addressString
          .split(',')
          .map((addr) => addr.trim())
          .where((addr) => addr.isNotEmpty)
          .map((addr) {
            // Extract email from "Name <email@domain.com>" format
            final match = RegExp(r'<([^>]+)>').firstMatch(addr);
            return match?.group(1) ?? addr;
          })
          .toList();
    }

    // Check if message is read
    final labels = message.labelIds ?? [];
    final isRead = !labels.contains('UNREAD');

    return EmailMessage(
      messageId: message.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      accountId: 'gmail_account', // This should be set from the account
      subject: subject.isEmpty ? 'No Subject' : subject,
      from: _extractSenderName(from),
      to: parseAddresses(to),
      cc: parseAddresses(cc),
      bcc: parseAddresses(bcc),
      date: date ?? DateTime.now(),
      textBody: textBody,
      htmlBody: htmlBody,
      isRead: isRead,
      isImportant: labels.contains('IMPORTANT'),
      folder: EmailFolder.inbox,
      attachments: null, // TODO: Extract attachments
      uid: int.tryParse(message.id ?? '0') ?? 0,
    );
  }

  Map<String, String?> _extractBodyFromPayload(gmail.MessagePart? payload) {
    if (payload == null) return {'text': '', 'html': null};

    String textBody = '';
    String? htmlBody;

    void extractFromPart(gmail.MessagePart part) {
      final mimeType = part.mimeType?.toLowerCase();

      if (mimeType == 'text/plain' && part.body?.data != null) {
        final decodedText = _decodeBase64Url(part.body!.data!);
        if (textBody.isEmpty) textBody = decodedText;
      } else if (mimeType == 'text/html' && part.body?.data != null) {
        htmlBody = _decodeBase64Url(part.body!.data!);
      } else if (part.parts != null) {
        for (final subPart in part.parts!) {
          extractFromPart(subPart);
        }
      }
    }

    extractFromPart(payload);

    return {'text': textBody, 'html': htmlBody};
  }

  String _decodeBase64Url(String data) {
    try {
      // Add padding if needed
      String normalizedData = data.replaceAll('-', '+').replaceAll('_', '/');
      while (normalizedData.length % 4 != 0) {
        normalizedData += '=';
      }

      final bytes = base64Decode(normalizedData);
      return utf8.decode(bytes);
    } catch (e) {
      print('Error decoding base64: $e');
      return '';
    }
  }

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
      // Create the email message
      final message = StringBuffer();
      message.writeln('To: $to');
      if (cc != null && cc.isNotEmpty) {
        message.writeln('Cc: $cc');
      }
      if (bcc != null && bcc.isNotEmpty) {
        message.writeln('Bcc: $bcc');
      }
      message.writeln('Subject: $subject');
      message.writeln('Content-Type: text/plain; charset=utf-8');
      message.writeln('');
      message.writeln(body);

      // Encode the message
      final encodedMessage = base64UrlEncode(utf8.encode(message.toString()));

      final gmailMessage = gmail.Message()
        ..raw = encodedMessage;

      await _gmailApi!.users.messages.send(gmailMessage, 'me');
      return true;
    } catch (e) {
      print('Error sending email: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    if (_gmailApi == null || !_isConnected) {
      return false;
    }

    try {
      final request = gmail.ModifyMessageRequest()
        ..removeLabelIds = ['UNREAD'];

      await _gmailApi!.users.messages.modify(request, 'me', messageId);
      return true;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }

  Future<bool> deleteEmail(String messageId) async {
    if (_gmailApi == null || !_isConnected) {
      return false;
    }

    try {
      await _gmailApi!.users.messages.trash('me', messageId);
      return true;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  DateTime _parseRfc2822Date(String dateStr) {
    try {
      // Clean up the date string by removing extra whitespace
      String cleanDate = dateStr.trim();

      // Handle common RFC 2822 format variations
      // Examples:
      // "Wed, 1 Nov 2025 12:30:45 +0000"
      // "1 Nov 2025 12:30:45 +0000"
      // "Wed, 1 Nov 2025 12:30:45 GMT"

      // First, try HttpDate.parse which handles RFC 2822
      return HttpDate.parse(cleanDate);
    } catch (e1) {
      try {
        // If HttpDate fails, try to manually parse common patterns
        // Remove day of week if present (e.g., "Wed, ")
        String withoutDay = dateStr.replaceFirst(RegExp(r'^[A-Za-z]{3},?\s*'), '');

        // Try parsing with DateTime.parse after normalizing
        // Convert RFC 2822 timezone to ISO format (+0000 -> Z for UTC)
        if (withoutDay.contains('+0000') || withoutDay.contains('GMT')) {
          withoutDay = withoutDay.replaceAll('+0000', 'Z').replaceAll('GMT', 'Z');
        }

        // Replace month names with numbers for DateTime.parse
        final monthMap = {
          'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
          'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
          'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
        };

        for (final entry in monthMap.entries) {
          withoutDay = withoutDay.replaceAll(entry.key, entry.value);
        }

        // Try to rearrange to ISO format if possible
        // Pattern: "1 11 2025 12:30:45 Z" -> "2025-11-01T12:30:45Z"
        final parts = withoutDay.split(' ');
        if (parts.length >= 4) {
          final day = parts[0].padLeft(2, '0');
          final month = parts[1].padLeft(2, '0');
          final year = parts[2];
          final time = parts[3];
          final isoDate = '$year-$month-${day}T$time';
          return DateTime.parse(isoDate);
        }

        throw Exception('Unable to parse date format');
      } catch (e2) {
        // If all parsing fails, extract at least the timestamp portion
        print('Failed to parse RFC 2822 date: $dateStr, using current time');
        return DateTime.now();
      }
    }
  }

  void disconnect() {
    _gmailApi = null;
    _isConnected = false;
  }

  /// Extract sender display name from email header
  /// Examples:
  /// "Quora Digest" <digest-noreply@quora.com> -> "Quora Digest"
  /// digest-noreply@quora.com -> "digest-noreply@quora.com"
  /// "John Doe" <john@example.com> -> "John Doe"
  String _extractSenderName(String fromHeader) {
    if (fromHeader.isEmpty) return 'Unknown Sender';

    // Check if format is "Display Name" <email@domain.com>
    final nameEmailPattern = RegExp(r'^"?([^"<]+?)"?\s*<[^>]+>$');
    final match = nameEmailPattern.firstMatch(fromHeader.trim());

    if (match != null) {
      final displayName = match.group(1)?.trim() ?? '';
      if (displayName.isNotEmpty) {
        return displayName;
      }
    }

    // Check if format is Display Name <email@domain.com> (without quotes)
    final nameWithoutQuotesPattern = RegExp(r'^([^<]+?)\s*<[^>]+>$');
    final matchWithoutQuotes = nameWithoutQuotesPattern.firstMatch(fromHeader.trim());

    if (matchWithoutQuotes != null) {
      final displayName = matchWithoutQuotes.group(1)?.trim() ?? '';
      if (displayName.isNotEmpty && !displayName.contains('@')) {
        return displayName;
      }
    }

    // If no display name found, extract email from <email@domain.com> format
    final emailOnlyPattern = RegExp(r'<([^>]+)>');
    final emailMatch = emailOnlyPattern.firstMatch(fromHeader);
    if (emailMatch != null) {
      final email = emailMatch.group(1) ?? '';
      return _extractNameFromEmail(email);
    }

    // If just email address, try to extract a meaningful name
    if (fromHeader.contains('@')) {
      return _extractNameFromEmail(fromHeader);
    }

    // Fallback to original header
    return fromHeader;
  }

  /// Extract a readable name from email address
  /// Examples:
  /// digest-noreply@quora.com -> "Digest Noreply"
  /// john.doe@company.com -> "John Doe"
  /// support@company.com -> "Support"
  String _extractNameFromEmail(String email) {
    if (!email.contains('@')) return email;

    final localPart = email.split('@')[0];

    // Handle common patterns
    if (localPart.contains('.') || localPart.contains('-') || localPart.contains('_')) {
      return localPart
          .replaceAll(RegExp(r'[._-]'), ' ')
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word)
          .join(' ');
    }

    // Single word - capitalize first letter
    return localPart.isNotEmpty
        ? '${localPart[0].toUpperCase()}${localPart.substring(1).toLowerCase()}'
        : email;
  }
}

