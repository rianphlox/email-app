import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/email_message.dart';
import 'dart:convert';
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
  }) async {
    if (_gmailApi == null || !_isConnected) {
      throw Exception('Gmail API not connected');
    }

    try {
      // Get list of message IDs
      final messagesList = await _gmailApi!.users.messages.list(
        'me',
        maxResults: maxResults,
        q: query.isEmpty ? 'in:inbox' : query,
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
        date = DateTime.parse(dateStr);
      }
    } catch (e) {
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
      from: from.contains('<') ? RegExp(r'<([^>]+)>').firstMatch(from)?.group(1) ?? from : from,
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

  void disconnect() {
    _gmailApi = null;
    _isConnected = false;
  }
}

