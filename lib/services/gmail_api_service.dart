import 'package:flutter/foundation.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/email_message.dart';
import '../models/email_account.dart' as models;
import 'dart:convert';
import 'dart:io';
import 'google_auth_client.dart';
import 'email_categorizer.dart';
import 'gmail_incremental_sync_service.dart';
import 'advanced_email_cache_service.dart';

/// A service class for interacting with the Gmail API.
///
/// This class provides methods for connecting to the Gmail API, fetching emails,
/// sending emails, and performing other Gmail-specific operations.
class GmailApiService {
  // --- Private Properties ---

  gmail.GmailApi? _gmailApi;
  bool _isConnected = false;

  // Enhanced services for incremental sync and caching
  final GmailIncrementalSyncService _incrementalSync = GmailIncrementalSyncService();
  final AdvancedEmailCacheService _cacheService = AdvancedEmailCacheService();

  // --- Public Methods ---

  /// Connects to the Gmail API using a Google Sign-In account.
  ///
  /// This method takes a [GoogleSignInAccount] object and uses its authentication
  /// headers to create a [gmail.GmailApi] client.
  Future<bool> connectWithGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('📬 GmailApi: Starting connection with Google Sign-In account...');
      debugPrint('📬 GmailApi: User email: ${googleUser.email}');

      debugPrint('📬 GmailApi: Getting auth headers...');
      final headers = await googleUser.authHeaders;

      debugPrint('📬 GmailApi: Auth headers received: ${headers.isNotEmpty}');
      debugPrint('📬 GmailApi: Headers keys: ${headers.keys.join(', ')}');

      if (headers.isEmpty) {
        debugPrint('❌ GmailApi: Auth headers are empty');
        return false;
      }

      debugPrint('📬 GmailApi: Creating GoogleAuthClient...');
      final client = GoogleAuthClient(headers);

      debugPrint('📬 GmailApi: Creating Gmail API instance...');
      _gmailApi = gmail.GmailApi(client);
      _isConnected = true;

      debugPrint('📬 GmailApi: Initializing enhanced services...');

      try {
        debugPrint('📬 GmailApi: Initializing cache service...');
        await _cacheService.initialize();

        debugPrint('📬 GmailApi: Initializing incremental sync...');
        await _incrementalSync.initialize(client as AuthClient);

        debugPrint('📬 GmailApi: Enhanced services initialized successfully');
      } catch (e) {
        debugPrint('⚠️ GmailApi: Enhanced services initialization failed: $e');
        // Continue with basic connection test
      }

      debugPrint('📬 GmailApi: Testing connection by fetching user profile...');
      // Test the connection by fetching the user's profile.
      try {
        final profile = await _gmailApi!.users.getProfile('me');
        debugPrint('✅ GmailApi: Connection test successful! Email: ${profile.emailAddress}');
        return true;
      } catch (e) {
        debugPrint('❌ GmailApi: Connection test failed: $e');
        debugPrint('❌ GmailApi: Error type: ${e.runtimeType}');
        _isConnected = false;
        return false;
      }
    } catch (e) {
      debugPrint('❌ GmailApi: Connection failed with error: $e');
      debugPrint('❌ GmailApi: Error type: ${e.runtimeType}');
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
    debugPrint('📧 GmailApi: fetchEmails called for account: $accountId');
    debugPrint('📧 GmailApi: Parameters - maxResults: $maxResults, folder: ${folder.name}, query: "$query"');

    if (_gmailApi == null || !_isConnected) {
      debugPrint('❌ GmailApi: Gmail API not connected - _gmailApi: ${_gmailApi != null}, _isConnected: $_isConnected');
      throw Exception('Gmail API not connected');
    }

    debugPrint('✅ GmailApi: Gmail API is connected, proceeding with fetch...');

    try {
      // Build the query based on folder
      debugPrint('📧 GmailApi: Building folder query...');
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
        case EmailFolder.starred:
          folderQuery = 'is:starred';
          break;
        case EmailFolder.custom:
          folderQuery = 'in:inbox'; // Default to inbox for custom folders
          break;
      }

      // Combine folder query with custom query
      final finalQuery = query.isEmpty ? folderQuery : '$folderQuery $query';
      debugPrint('📧 GmailApi: Final Gmail query: "$finalQuery"');

      // Get list of message IDs
      debugPrint('📧 GmailApi: Calling Gmail API to list messages...');
      final messagesList = await _gmailApi!.users.messages.list(
        'me',
        q: finalQuery,
        maxResults: maxResults,
      );

      debugPrint('📧 GmailApi: Gmail API list call completed');
      debugPrint('📧 GmailApi: Messages returned: ${messagesList.messages?.length ?? 0}');

      if (messagesList.messages == null || messagesList.messages!.isEmpty) {
        debugPrint('⚠️ GmailApi: No messages found for query: "$finalQuery"');
        return [];
      }

      // Fetch detailed message information for each message
      debugPrint('📧 GmailApi: Fetching detailed information for ${messagesList.messages!.length} messages...');
      final List<EmailMessage> emails = [];
      int processedCount = 0;
      int errorCount = 0;

      for (final message in messagesList.messages!) {
        if (message.id != null) {
          try {
            debugPrint('📧 GmailApi: Fetching details for message ${processedCount + 1}/${messagesList.messages!.length} (ID: ${message.id})');

            final detailedMessage = await _gmailApi!.users.messages.get(
              'me',
              message.id!,
              format: 'full',
            );

            debugPrint('📧 GmailApi: Successfully fetched message details for ${message.id}');
            debugPrint('📧 GmailApi: Message has payload: ${detailedMessage.payload != null}');
            debugPrint('📧 GmailApi: Message has headers: ${detailedMessage.payload?.headers?.length ?? 0}');

            final emailMessage = _convertGmailMessageToEmailMessage(
              detailedMessage,
              accountId: accountId,
              folder: folder,
            );

            debugPrint('📧 GmailApi: Successfully converted message to EmailMessage');
            debugPrint('📧 GmailApi: Subject: "${emailMessage.subject}"');
            debugPrint('📧 GmailApi: From: "${emailMessage.from}"');
            debugPrint('📧 GmailApi: Date: ${emailMessage.date}');

            emailMessage.category = EmailCategorizer.categorizeEmail(emailMessage);
            debugPrint('📧 GmailApi: Categorized as: ${emailMessage.category}');

            emails.add(emailMessage);
            processedCount++;

            debugPrint('📧 GmailApi: Added message to emails list. Total count: ${emails.length}');
          } catch (e) {
            errorCount++;
            debugPrint('❌ GmailApi: Error fetching message ${message.id}: $e');
            debugPrint('❌ GmailApi: Error type: ${e.runtimeType}');
            // Continue with other messages
          }
        } else {
          debugPrint('⚠️ GmailApi: Skipping message with null ID');
        }
      }

      debugPrint('📧 GmailApi: Completed fetching emails. Processed: $processedCount, Errors: $errorCount, Final count: ${emails.length}');
      debugPrint('✅ GmailApi: fetchEmails completed successfully, returning ${emails.length} emails');
      return emails;
    } catch (e) {
      debugPrint('❌ GmailApi: fetchEmails failed with error: $e');
      debugPrint('❌ GmailApi: Error type: ${e.runtimeType}');
      debugPrint('❌ GmailApi: Stack trace: ${StackTrace.current}');
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

      // Parse date - Use Gmail's internalDate as primary source, then header date as fallback
      DateTime parsedDate;
      try {
        // Gmail's internalDate is the most accurate timestamp (milliseconds since epoch)
        if (message.internalDate != null && message.internalDate!.isNotEmpty) {
          final internalDateMs = int.tryParse(message.internalDate!);
          if (internalDateMs != null && internalDateMs > 0) {
            parsedDate = DateTime.fromMillisecondsSinceEpoch(internalDateMs);
            debugPrint('📧 GmailApi: Using Gmail internalDate: $parsedDate');
          } else {
            throw Exception('Invalid internalDate format');
          }
        }
        // Fallback to parsing header date
        else if (date.isNotEmpty) {
          parsedDate = _parseRfc2822Date(date);
          debugPrint('📧 GmailApi: Using parsed header date: $parsedDate');
        }
        // Last resort: use a very old date to indicate unknown timestamp
        else {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(0); // Unix epoch
          debugPrint('⚠️ GmailApi: No date available, using epoch');
        }
      } catch (e) {
        debugPrint('❌ GmailApi: Error parsing date "$date": $e');
        // If all parsing fails, use epoch instead of current time
        parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
      }

      // Extract sender name
      final senderName = _extractSenderName(from);

      // Check if message is read (not in UNREAD label)
      final labels = message.labelIds ?? [];
      final isRead = !labels.contains('UNREAD');

      // Use Gmail's built-in snippet - it's already clean and perfect!
      final previewText = message.snippet ?? 'No preview available';

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
      )..previewText = previewText;
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

  // ==================== ENHANCED EMAIL FETCHING WITH INCREMENTAL SYNC ====================

  /// Performs efficient email sync using incremental sync when possible
  /// Falls back to traditional fetch for first-time sync or errors
  Future<List<EmailMessage>> fetchEmailsEfficient({
    required models.EmailAccount account,
    required EmailFolder folder,
    int maxResults = 100,
    bool forceFullSync = false,
  }) async {
    if (!_isConnected || _gmailApi == null) {
      throw Exception('Gmail API not connected');
    }

    try {
      final folderId = _getFolderLabelId(folder);

      if (forceFullSync) {
        // Force a complete resync
        await _incrementalSync.forceFullResync(
          account: account,
          folderId: folderId,
        );
      } else {
        // Perform incremental sync
        final syncSuccess = await _incrementalSync.performIncrementalSync(
          account: account,
          folderId: folderId,
          maxResults: maxResults,
        );

        if (!syncSuccess) {
          debugPrint('GmailApiService: Incremental sync failed, falling back to cache');
        }
      }

      // Return cached headers (fast)
      final cachedEmails = await _cacheService.getEmailHeaders(
        accountId: account.id,
        folder: folder.name,
        limit: maxResults,
      );

      debugPrint('GmailApiService: Returning ${cachedEmails.length} cached emails');
      return cachedEmails;

    } catch (e) {
      debugPrint('GmailApiService: Error in efficient email fetch: $e');

      // Fallback to cached data if available
      try {
        final cachedEmails = await _cacheService.getEmailHeaders(
          accountId: account.id,
          folder: folder.name,
          limit: maxResults,
        );

        if (cachedEmails.isNotEmpty) {
          debugPrint('GmailApiService: Returning ${cachedEmails.length} cached emails as fallback');
          return cachedEmails;
        }
      } catch (cacheError) {
        debugPrint('GmailApiService: Cache fallback also failed: $cacheError');
      }

      rethrow;
    }
  }

  /// Loads full email body on-demand (when user opens email)
  Future<EmailMessage?> loadEmailBody({
    required String messageId,
    required String accountId,
  }) async {
    if (!_isConnected || _gmailApi == null) {
      throw Exception('Gmail API not connected');
    }

    try {
      // First check if we have it cached
      final cachedEmail = await _cacheService.getEmailWithBody(messageId, accountId);
      if (cachedEmail != null && cachedEmail.textBody.isNotEmpty) {
        debugPrint('GmailApiService: Returning cached email body for $messageId');
        return cachedEmail;
      }

      // Fetch from server using incremental sync service
      final fullMessage = await _incrementalSync.fetchFullMessage(messageId, accountId);
      if (fullMessage != null) {
        // Cache the full body
        await _cacheService.cacheEmailBody(fullMessage);
        debugPrint('GmailApiService: Fetched and cached email body for $messageId');
        return fullMessage;
      }

      return null;

    } catch (e) {
      debugPrint('GmailApiService: Error loading email body for $messageId: $e');

      // Return cached header-only version if available
      return await _cacheService.getEmailWithBody(messageId, accountId);
    }
  }

  /// Search emails using full-text search index
  Future<List<EmailMessage>> searchEmailsFTS({
    required String accountId,
    required String query,
    EmailFolder? folder,
    int limit = 50,
  }) async {
    try {
      await _cacheService.initialize();

      final searchResults = await _cacheService.searchEmails(
        accountId: accountId,
        query: query,
        folder: folder?.name,
        limit: limit,
      );

      debugPrint('GmailApiService: FTS search for "$query" returned ${searchResults.length} results');
      return searchResults;

    } catch (e) {
      debugPrint('GmailApiService: FTS search failed: $e');
      return [];
    }
  }

  /// Get sync statistics for monitoring
  Future<Map<String, dynamic>> getSyncStatistics(String accountId) async {
    try {
      final syncStats = await _incrementalSync.getSyncStats(accountId);
      final cacheStats = await _cacheService.getCacheStats(accountId);

      return {
        'sync': syncStats,
        'cache': cacheStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('GmailApiService: Error getting sync statistics: $e');
      return {};
    }
  }

  /// Trigger background sync for better performance
  Future<void> triggerBackgroundSync(models.EmailAccount account) async {
    if (!_isConnected) return;

    try {
      final folders = [EmailFolder.inbox, EmailFolder.sent, EmailFolder.drafts];

      for (final folder in folders) {
        final folderId = _getFolderLabelId(folder);

        // Perform incremental sync in background
        await _incrementalSync.performIncrementalSync(
          account: account,
          folderId: folderId,
          maxResults: 50, // Smaller batch for background
        );

        // Small delay between folders to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Update cache statistics
      await _cacheService.updateCacheStats(account.id);

      debugPrint('GmailApiService: Background sync completed for ${account.email}');

    } catch (e) {
      debugPrint('GmailApiService: Background sync failed for ${account.email}: $e');
    }
  }

  /// Clean up old cached data
  Future<void> cleanupCache(String accountId, {Duration maxAge = const Duration(days: 90)}) async {
    try {
      await _cacheService.cleanupOldEmails(accountId: accountId, maxAge: maxAge);
      await _cacheService.updateCacheStats(accountId);
      debugPrint('GmailApiService: Cache cleanup completed for $accountId');
    } catch (e) {
      debugPrint('GmailApiService: Cache cleanup failed for $accountId: $e');
    }
  }

  /// Convert EmailFolder to Gmail label ID
  String _getFolderLabelId(EmailFolder folder) {
    switch (folder) {
      case EmailFolder.inbox:
        return 'INBOX';
      case EmailFolder.sent:
        return 'SENT';
      case EmailFolder.drafts:
        return 'DRAFT';
      case EmailFolder.trash:
        return 'TRASH';
      case EmailFolder.spam:
        return 'SPAM';
      case EmailFolder.archive:
        return 'ARCHIVE'; // Note: Gmail doesn't have a dedicated archive label
      default:
        return 'INBOX';
    }
  }
}