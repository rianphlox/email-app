import 'package:flutter/foundation.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import '../models/email_message.dart';
import '../models/email_account.dart' as models;
import '../services/advanced_email_cache_service.dart';
import '../database/email_database.dart';
import '../utils/preview_extractor.dart';

/// Enhanced Gmail sync service with incremental syncing using History API
/// Implements Gmail's efficient delta sync to minimize data transfer and improve performance
class GmailIncrementalSyncService {
  static final GmailIncrementalSyncService _instance = GmailIncrementalSyncService._internal();
  factory GmailIncrementalSyncService() => _instance;
  GmailIncrementalSyncService._internal();

  gmail.GmailApi? _gmailApi;
  final AdvancedEmailCacheService _cacheService = AdvancedEmailCacheService();

  /// Initialize Gmail API with authenticated client
  Future<void> initialize(AuthClient authClient) async {
    _gmailApi = gmail.GmailApi(authClient);
    await _cacheService.initialize();
    debugPrint('GmailIncrementalSyncService: Initialized with authenticated client');
  }

  /// Performs incremental sync for an account
  /// Returns true if sync was successful, false otherwise
  Future<bool> performIncrementalSync({
    required models.EmailAccount account,
    required String folderId,
    int maxResults = 100,
  }) async {
    if (_gmailApi == null) {
      throw StateError('Gmail API not initialized');
    }

    try {
      // Get current sync state
      final syncState = await _cacheService.getSyncState(account.id, folderId);

      if (syncState?.historyId != null) {
        // Perform incremental sync using History API
        return await _performHistorySync(
          account: account,
          folderId: folderId,
          startHistoryId: syncState!.historyId!,
          maxResults: maxResults,
        );
      } else {
        // Perform initial full sync
        return await _performInitialSync(
          account: account,
          folderId: folderId,
          maxResults: maxResults,
        );
      }
    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Sync failed for ${account.email}: $e');

      // Update sync state with error
      await _cacheService.updateSyncState(
        accountId: account.id,
        folder: folderId,
        syncError: e.toString(),
        lastIncrementalSync: DateTime.now(),
      );

      return false;
    }
  }

  /// Performs initial full sync for new accounts or reset scenarios
  Future<bool> _performInitialSync({
    required models.EmailAccount account,
    required String folderId,
    int maxResults = 100,
  }) async {
    debugPrint('GmailIncrementalSyncService: Performing initial sync for ${account.email}');

    try {
      // Get user profile to obtain current historyId
      final profile = await _gmailApi!.users.getProfile('me');
      final currentHistoryId = profile.historyId;

      // Fetch initial batch of messages (headers only)
      final messageList = await _gmailApi!.users.messages.list(
        'me',
        labelIds: [folderId],
        maxResults: maxResults,
        includeSpamTrash: false,
      );

      if (messageList.messages == null || messageList.messages!.isEmpty) {
        // No messages found, but sync was successful
        await _cacheService.updateSyncState(
          accountId: account.id,
          folder: folderId,
          historyId: currentHistoryId,
          lastFullSync: DateTime.now(),
        );
        return true;
      }

      // Fetch headers for all messages in batch
      final messages = await _fetchMessageHeaders(
        messageIds: messageList.messages!.map((m) => m.id!).toList(),
        accountId: account.id,
      );

      // Cache the headers
      await _cacheService.cacheEmailHeaders(messages, account.id);

      // Update sync state
      await _cacheService.updateSyncState(
        accountId: account.id,
        folder: folderId,
        historyId: currentHistoryId,
        nextPageToken: messageList.nextPageToken,
        lastFullSync: DateTime.now(),
      );

      debugPrint('GmailIncrementalSyncService: Initial sync completed - ${messages.length} messages cached');
      return true;

    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Initial sync failed: $e');
      return false;
    }
  }

  /// Performs incremental sync using Gmail History API
  Future<bool> _performHistorySync({
    required models.EmailAccount account,
    required String folderId,
    required String startHistoryId,
    int maxResults = 100,
  }) async {
    debugPrint('GmailIncrementalSyncService: Performing incremental sync from historyId $startHistoryId');

    try {
      // Get history list since last sync
      final historyList = await _gmailApi!.users.history.list(
        'me',
        startHistoryId: startHistoryId,
        labelId: folderId,
        maxResults: maxResults,
        historyTypes: ['messageAdded', 'messageDeleted', 'labelAdded', 'labelRemoved'],
      );

      if (historyList.history == null || historyList.history!.isEmpty) {
        debugPrint('GmailIncrementalSyncService: No changes since last sync');

        // Update last sync time even if no changes
        await _cacheService.updateSyncState(
          accountId: account.id,
          folder: folderId,
          lastIncrementalSync: DateTime.now(),
        );
        return true;
      }

      // Process all history records
      final changesProcessed = await _processHistoryChanges(
        historyRecords: historyList.history!,
        accountId: account.id,
        folderId: folderId,
      );

      // Update sync state with new historyId
      final newHistoryId = historyList.historyId ?? startHistoryId;
      await _cacheService.updateSyncState(
        accountId: account.id,
        folder: folderId,
        historyId: newHistoryId,
        lastIncrementalSync: DateTime.now(),
      );

      debugPrint('GmailIncrementalSyncService: Incremental sync completed - $changesProcessed changes processed');
      return true;

    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Incremental sync failed: $e');
      return false;
    }
  }

  /// Process history changes (added, deleted, label changes)
  Future<int> _processHistoryChanges({
    required List<gmail.History> historyRecords,
    required String accountId,
    required String folderId,
  }) async {
    int changesProcessed = 0;

    for (final historyRecord in historyRecords) {
      // Process added messages
      if (historyRecord.messagesAdded != null) {
        for (final historyMessageAdded in historyRecord.messagesAdded!) {
          final message = historyMessageAdded.message;
          if (message?.id != null) {
            try {
              final emailMessage = await _fetchSingleMessageHeader(message!.id!, accountId);
              if (emailMessage != null) {
                await _cacheService.cacheEmailHeaders([emailMessage], accountId);
                changesProcessed++;
              }
            } catch (e) {
              debugPrint('GmailIncrementalSyncService: Error processing added message ${message!.id}: $e');
            }
          }
        }
      }

      // Process deleted messages
      if (historyRecord.messagesDeleted != null) {
        for (final historyMessageDeleted in historyRecord.messagesDeleted!) {
          final message = historyMessageDeleted.message;
          if (message?.id != null) {
            try {
              await _deleteMessageFromCache(message!.id!, accountId);
              changesProcessed++;
            } catch (e) {
              debugPrint('GmailIncrementalSyncService: Error processing deleted message ${message!.id}: $e');
            }
          }
        }
      }

      // Process label changes (read/unread, important, etc.)
      if (historyRecord.labelsAdded != null) {
        for (final historyLabelAdded in historyRecord.labelsAdded!) {
          final message = historyLabelAdded.message;
          if (message?.id != null) {
            try {
              await _updateMessageLabels(message!.id!, accountId, historyLabelAdded.labelIds ?? []);
              changesProcessed++;
            } catch (e) {
              debugPrint('GmailIncrementalSyncService: Error processing label addition for ${message!.id}: $e');
            }
          }
        }
      }

      if (historyRecord.labelsRemoved != null) {
        for (final historyLabelRemoved in historyRecord.labelsRemoved!) {
          final message = historyLabelRemoved.message;
          if (message?.id != null) {
            try {
              await _removeMessageLabels(message!.id!, accountId, historyLabelRemoved.labelIds ?? []);
              changesProcessed++;
            } catch (e) {
              debugPrint('GmailIncrementalSyncService: Error processing label removal for ${message!.id}: $e');
            }
          }
        }
      }
    }

    return changesProcessed;
  }

  /// Fetch message headers for multiple messages efficiently
  Future<List<EmailMessage>> _fetchMessageHeaders({
    required List<String> messageIds,
    required String accountId,
  }) async {
    final messages = <EmailMessage>[];

    // Use batch request for efficiency (process in chunks)
    const batchSize = 50;
    for (int i = 0; i < messageIds.length; i += batchSize) {
      final batch = messageIds.skip(i).take(batchSize).toList();

      for (final messageId in batch) {
        try {
          final emailMessage = await _fetchSingleMessageHeader(messageId, accountId);
          if (emailMessage != null) {
            messages.add(emailMessage);
          }
        } catch (e) {
          debugPrint('GmailIncrementalSyncService: Error fetching message $messageId: $e');
        }
      }

      // Small delay to avoid rate limiting
      if (i + batchSize < messageIds.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    return messages;
  }

  /// Fetch a single message header (not the full body)
  Future<EmailMessage?> _fetchSingleMessageHeader(String messageId, String accountId) async {
    try {
      final message = await _gmailApi!.users.messages.get(
        'me',
        messageId,
        format: 'metadata',
        metadataHeaders: ['From', 'To', 'Cc', 'Bcc', 'Subject', 'Date', 'Message-ID'],
      );

      return _convertGmailMessageToEmailMessage(message, accountId);
    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Failed to fetch message $messageId: $e');
      return null;
    }
  }

  /// Convert Gmail API message to EmailMessage (header only)
  EmailMessage? _convertGmailMessageToEmailMessage(gmail.Message gmailMessage, String accountId) {
    try {
      final headers = gmailMessage.payload?.headers ?? [];
      final headerMap = <String, String>{};

      for (final header in headers) {
        if (header.name != null && header.value != null) {
          headerMap[header.name!.toLowerCase()] = header.value!;
        }
      }

      // Extract basic information
      final messageId = headerMap['message-id'] ?? gmailMessage.id ?? '';
      final subject = headerMap['subject'] ?? 'No Subject';
      final from = headerMap['from'] ?? 'Unknown Sender';
      final to = _parseEmailAddresses(headerMap['to'] ?? '');
      final cc = _parseEmailAddresses(headerMap['cc'] ?? '');
      final bcc = _parseEmailAddresses(headerMap['bcc'] ?? '');
      final dateStr = headerMap['date'] ?? '';

      // Parse date
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (e) {
        date = DateTime.now();
      }

      // Determine read status from labels
      final isRead = !(gmailMessage.labelIds?.contains('UNREAD') ?? false);
      final isImportant = gmailMessage.labelIds?.contains('IMPORTANT') ?? false;

      // Determine folder from labels
      EmailFolder folder = EmailFolder.inbox;
      if (gmailMessage.labelIds?.contains('SENT') ?? false) {
        folder = EmailFolder.sent;
      } else if (gmailMessage.labelIds?.contains('DRAFT') ?? false) {
        folder = EmailFolder.drafts;
      } else if (gmailMessage.labelIds?.contains('TRASH') ?? false) {
        folder = EmailFolder.trash;
      } else if (gmailMessage.labelIds?.contains('SPAM') ?? false) {
        folder = EmailFolder.spam;
      }

      // Generate preview text (placeholder for header-only message)
      final snippet = gmailMessage.snippet ?? '';

      return EmailMessage(
        messageId: messageId,
        accountId: accountId,
        subject: subject,
        from: from,
        to: to,
        cc: cc.isNotEmpty ? cc : null,
        bcc: bcc.isNotEmpty ? bcc : null,
        date: date,
        textBody: '', // Will be loaded on-demand
        htmlBody: null, // Will be loaded on-demand
        isRead: isRead,
        isImportant: isImportant,
        folder: folder,
        attachments: null, // Will be loaded on-demand
        uid: int.tryParse(gmailMessage.id ?? '0') ?? 0,
        previewText: snippet,
        threadId: gmailMessage.threadId,
      );

    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Error converting Gmail message: $e');
      return null;
    }
  }

  /// Parse email addresses from header string
  List<String> _parseEmailAddresses(String addressString) {
    if (addressString.isEmpty) return [];

    // Simple parsing - in production, you'd want a more robust email parser
    return addressString
        .split(',')
        .map((addr) => addr.trim())
        .where((addr) => addr.isNotEmpty && addr.contains('@'))
        .toList();
  }

  /// Delete message from cache
  Future<void> _deleteMessageFromCache(String messageId, String accountId) async {
    // TODO: Implement message deletion in cache service
    debugPrint('GmailIncrementalSyncService: Should delete message $messageId from cache');
  }

  /// Update message labels in cache
  Future<void> _updateMessageLabels(String messageId, String accountId, List<String> labelIds) async {
    // TODO: Implement label updates in cache service
    debugPrint('GmailIncrementalSyncService: Should update labels for $messageId: $labelIds');
  }

  /// Remove message labels from cache
  Future<void> _removeMessageLabels(String messageId, String accountId, List<String> labelIds) async {
    // TODO: Implement label removal in cache service
    debugPrint('GmailIncrementalSyncService: Should remove labels from $messageId: $labelIds');
  }

  /// Fetch full message body (for on-demand loading)
  Future<EmailMessage?> fetchFullMessage(String messageId, String accountId) async {
    if (_gmailApi == null) {
      throw StateError('Gmail API not initialized');
    }

    try {
      // Get full message with body
      final message = await _gmailApi!.users.messages.get(
        'me',
        messageId,
        format: 'full',
      );

      return _convertGmailMessageToFullEmailMessage(message, accountId);
    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Failed to fetch full message $messageId: $e');
      return null;
    }
  }

  /// Convert Gmail message to full EmailMessage with body content
  EmailMessage? _convertGmailMessageToFullEmailMessage(gmail.Message gmailMessage, String accountId) {
    try {
      // First get header information (reuse existing method)
      final headerMessage = _convertGmailMessageToEmailMessage(gmailMessage, accountId);
      if (headerMessage == null) return null;

      // Extract body content
      final bodyText = _extractTextBody(gmailMessage.payload);
      final bodyHtml = _extractHtmlBody(gmailMessage.payload);

      // Generate enhanced preview
      final previewText = PreviewExtractor.extractPreview(
        htmlContent: bodyHtml,
        textContent: bodyText,
        maxLength: 200,
      );

      return headerMessage.copyWith(
        textBody: bodyText,
        htmlBody: bodyHtml,
        previewText: previewText.isNotEmpty ? previewText : headerMessage.previewText,
      );

    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Error converting full Gmail message: $e');
      return null;
    }
  }

  /// Extract text body from Gmail message payload
  String _extractTextBody(gmail.MessagePart? payload) {
    if (payload == null) return '';

    // Handle multipart messages
    if (payload.parts != null && payload.parts!.isNotEmpty) {
      for (final part in payload.parts!) {
        if (part.mimeType == 'text/plain') {
          return _decodeMessagePart(part);
        }

        // Recursively search in nested parts
        final nestedText = _extractTextBody(part);
        if (nestedText.isNotEmpty) return nestedText;
      }
    }

    // Handle single-part text message
    if (payload.mimeType == 'text/plain') {
      return _decodeMessagePart(payload);
    }

    return '';
  }

  /// Extract HTML body from Gmail message payload
  String? _extractHtmlBody(gmail.MessagePart? payload) {
    if (payload == null) return null;

    // Handle multipart messages
    if (payload.parts != null && payload.parts!.isNotEmpty) {
      for (final part in payload.parts!) {
        if (part.mimeType == 'text/html') {
          return _decodeMessagePart(part);
        }

        // Recursively search in nested parts
        final nestedHtml = _extractHtmlBody(part);
        if (nestedHtml != null) return nestedHtml;
      }
    }

    // Handle single-part HTML message
    if (payload.mimeType == 'text/html') {
      return _decodeMessagePart(payload);
    }

    return null;
  }

  /// Decode message part data
  String _decodeMessagePart(gmail.MessagePart part) {
    if (part.body?.data == null) return '';

    try {
      // Gmail API returns base64url-encoded data
      final decodedBytes = Uri.decodeFull(part.body!.data!);
      return String.fromCharCodes(decodedBytes.codeUnits);
    } catch (e) {
      debugPrint('GmailIncrementalSyncService: Error decoding message part: $e');
      return '';
    }
  }

  /// Get sync statistics for monitoring
  Future<Map<String, dynamic>> getSyncStats(String accountId) async {
    final syncStates = <SyncStateData>[];
    final folders = ['INBOX', 'SENT', 'DRAFTS', 'TRASH'];

    for (final folder in folders) {
      final state = await _cacheService.getSyncState(accountId, folder);
      if (state != null) {
        syncStates.add(state);
      }
    }

    final now = DateTime.now();
    final recentSyncs = syncStates
        .where((state) => state.lastIncrementalSync != null)
        .where((state) => now.difference(state.lastIncrementalSync!).inHours < 24)
        .length;

    return {
      'totalFolders': folders.length,
      'syncedFolders': syncStates.length,
      'recentSyncs24h': recentSyncs,
      'lastSyncTime': syncStates
          .where((s) => s.lastIncrementalSync != null)
          .map((s) => s.lastIncrementalSync!)
          .fold<DateTime?>(null, (latest, time) =>
              latest == null || time.isAfter(latest) ? time : latest),
      'errors': syncStates
          .where((s) => s.syncError != null)
          .map((s) => s.syncError!)
          .toList(),
    };
  }

  /// Force a full resync (useful for troubleshooting)
  Future<bool> forceFullResync({
    required models.EmailAccount account,
    required String folderId,
  }) async {
    // Clear existing sync state
    await _cacheService.updateSyncState(
      accountId: account.id,
      folder: folderId,
      historyId: null,
      lastFullSync: null,
      lastIncrementalSync: null,
    );

    // Perform initial sync
    return await _performInitialSync(
      account: account,
      folderId: folderId,
      maxResults: 200, // Fetch more for full resync
    );
  }
}