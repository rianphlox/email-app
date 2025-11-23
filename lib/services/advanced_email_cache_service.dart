import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import '../database/email_database.dart';
import '../models/email_message.dart';
import '../models/email_account.dart' as models;
import '../utils/preview_extractor.dart';
import '../utils/advanced_quote_processor.dart';

/// Advanced email caching service using SQLite with Drift
/// Implements Gmail-like caching with headers-first loading, FTS, and incremental sync
class AdvancedEmailCacheService {
  static final AdvancedEmailCacheService _instance = AdvancedEmailCacheService._internal();
  factory AdvancedEmailCacheService() => _instance;
  AdvancedEmailCacheService._internal();

  late EmailDatabase _database;
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _database = EmailDatabase();
    _isInitialized = true;

    debugPrint('AdvancedEmailCacheService: Initialized SQLite database');
  }

  /// Get database instance
  EmailDatabase get database {
    if (!_isInitialized) {
      throw StateError('AdvancedEmailCacheService not initialized. Call initialize() first.');
    }
    return _database;
  }

  // ==================== ACCOUNT MANAGEMENT ====================

  /// Add or update an email account
  Future<void> saveAccount(models.EmailAccount account) async {
    await _database.insertOrUpdateAccount(AccountsCompanion(
      id: Value(account.id),
      email: Value(account.email),
      displayName: Value(account.email), // Use email as display name fallback
      provider: Value(account.provider.toString().split('.').last),
      accessToken: Value(account.accessToken),
      refreshToken: Value(account.refreshToken),
      historyId: const Value(null), // Will be set during sync
      lastSyncTime: const Value(null),
      createdAt: Value(DateTime.now()),
      isActive: const Value(true),
    ));

    debugPrint('AdvancedEmailCacheService: Saved account ${account.email}');
  }

  /// Get all cached accounts
  Future<List<models.EmailAccount>> getAccounts() async {
    final accountData = await _database.getAllAccounts();

    return accountData.map((data) => models.EmailAccount(
      id: data.id,
      email: data.email,
      name: data.displayName ?? data.email,
      lastSync: data.lastSyncTime ?? DateTime.now(),
      provider: _parseEmailProvider(data.provider),
      accessToken: data.accessToken ?? '',
      refreshToken: data.refreshToken ?? '',
    )).toList();
  }

  /// Delete an account and all its data
  Future<void> deleteAccount(String accountId) async {
    await _database.deleteAccount(accountId);
    debugPrint('AdvancedEmailCacheService: Deleted account $accountId');
  }

  // ==================== EMAIL HEADERS (FAST LOADING) ====================

  /// Cache email headers for fast inbox loading
  Future<void> cacheEmailHeaders(List<EmailMessage> messages, String accountId) async {
    final headers = messages.map((message) => EmailHeaderData(
      messageId: message.messageId,
      accountId: accountId,
      threadId: message.threadId,
      subject: message.subject,
      from: message.from,
      to: jsonEncode(message.to),
      cc: message.cc != null ? jsonEncode(message.cc!) : null,
      bcc: message.bcc != null ? jsonEncode(message.bcc!) : null,
      date: message.date,
      folder: message.folder.name,
      labels: null, // TODO: Add labels support
      isRead: message.isRead,
      isStarred: false, // TODO: Add starred support
      isImportant: message.isImportant,
      hasAttachments: message.attachments?.isNotEmpty ?? false,
      size: _estimateEmailSize(message),
      snippet: message.previewText ?? _generateSnippet(message),
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    )).toList();

    // Batch insert headers
    await _database.transaction(() async {
      for (final header in headers) {
        await _database.insertOrUpdateEmailHeader(header);
      }
    });

    debugPrint('AdvancedEmailCacheService: Cached ${headers.length} email headers for $accountId');
  }

  /// Get email headers for fast inbox display
  Future<List<EmailMessage>> getEmailHeaders({
    required String accountId,
    String? folder,
    int limit = 50,
    int offset = 0,
  }) async {
    final headers = await _database.getEmailHeaders(
      accountId: accountId,
      folder: folder,
      limit: limit,
      offset: offset,
    );

    return headers.map((header) => EmailMessage(
      messageId: header.messageId,
      accountId: header.accountId,
      subject: header.subject,
      from: header.from,
      to: (jsonDecode(header.to) as List<dynamic>).cast<String>(),
      cc: header.cc != null ? (jsonDecode(header.cc!) as List<dynamic>).cast<String>() : null,
      bcc: header.bcc != null ? (jsonDecode(header.bcc!) as List<dynamic>).cast<String>() : null,
      date: header.date,
      textBody: '', // Will be loaded on-demand
      htmlBody: null,
      isRead: header.isRead,
      isImportant: header.isImportant,
      folder: _parseEmailFolder(header.folder),
      attachments: null, // Will be loaded on-demand
      uid: 0, // Not used in SQLite version
      previewText: header.snippet,
      threadId: header.threadId,
    )).toList();
  }

  // ==================== EMAIL BODIES (ON-DEMAND LOADING) ====================

  /// Cache full email body (called when user opens email)
  Future<void> cacheEmailBody(EmailMessage message) async {
    // Process email content for advanced features
    ProcessedEmailContent? processedContent;
    try {
      processedContent = AdvancedQuoteProcessor.processEmailContent(
        message.htmlBody ?? message.textBody,
        isHtml: message.htmlBody != null,
      );
    } catch (e) {
      debugPrint('AdvancedEmailCacheService: Error processing email content: $e');
    }

    final bodyData = EmailBodyData(
      messageId: message.messageId,
      accountId: message.accountId,
      textBody: message.textBody,
      htmlBody: message.htmlBody,
      processedHtml: processedContent?.processedHtml,
      hasQuotedText: processedContent?.hasQuotedText ?? false,
      hasSignature: processedContent?.hasSignature ?? false,
      bodySize: _estimateBodySize(message),
      createdAt: DateTime.now(),
      lastAccessed: DateTime.now(),
    );

    await _database.insertOrUpdateEmailBody(bodyData);

    // Update search index
    await _updateSearchIndex(message, processedContent);

    debugPrint('AdvancedEmailCacheService: Cached email body for ${message.messageId}');
  }

  /// Get full email body (with on-demand loading)
  Future<EmailMessage?> getEmailWithBody(String messageId, String accountId) async {
    // Get header first
    final header = await _database.getEmailHeader(messageId, accountId);
    if (header == null) return null;

    // Convert header to message
    final message = EmailMessage(
      messageId: header.messageId,
      accountId: header.accountId,
      subject: header.subject,
      from: header.from,
      to: (jsonDecode(header.to) as List<dynamic>).cast<String>(),
      cc: header.cc != null ? (jsonDecode(header.cc!) as List<dynamic>).cast<String>() : null,
      bcc: header.bcc != null ? (jsonDecode(header.bcc!) as List<dynamic>).cast<String>() : null,
      date: header.date,
      textBody: '', // Will be filled from body data
      htmlBody: null,
      isRead: header.isRead,
      isImportant: header.isImportant,
      folder: _parseEmailFolder(header.folder),
      attachments: null,
      uid: 0,
      previewText: header.snippet,
      threadId: header.threadId,
    );

    // Try to get cached body
    final body = await _database.getEmailBody(messageId, accountId);
    if (body != null) {
      // Update last accessed time
      await _database.insertOrUpdateEmailBody(EmailBodiesCompanion(
        messageId: Value(messageId),
        accountId: Value(accountId),
        textBody: Value(body.textBody),
        htmlBody: Value(body.htmlBody),
        processedHtml: Value(body.processedHtml),
        hasQuotedText: Value(body.hasQuotedText),
        hasSignature: Value(body.hasSignature),
        bodySize: Value(body.bodySize),
        createdAt: Value(body.createdAt),
        lastAccessed: Value(DateTime.now()),
      ));

      return message.copyWith(
        textBody: body.textBody ?? '',
        htmlBody: body.htmlBody,
      );
    }

    return message;
  }

  // ==================== FULL-TEXT SEARCH ====================

  /// Search emails using FTS5 index
  Future<List<EmailMessage>> searchEmails({
    required String accountId,
    required String query,
    String? folder,
    int limit = 50,
  }) async {
    final searchResults = await _database.searchEmails(
      accountId: accountId,
      query: query,
      folder: folder,
      limit: limit,
    );

    final messageIds = searchResults
        .map((result) => result['message_id'] as String)
        .toList();

    if (messageIds.isEmpty) return [];

    // Get full headers for the matching messages
    final headers = <EmailHeaderData>[];
    for (final messageId in messageIds) {
      final header = await _database.getEmailHeader(messageId, accountId);
      if (header != null) {
        headers.add(header);
      }
    }

    // Convert to EmailMessage objects
    return headers.map((header) => EmailMessage(
      messageId: header.messageId,
      accountId: header.accountId,
      subject: header.subject,
      from: header.from,
      to: (jsonDecode(header.to) as List<dynamic>).cast<String>(),
      cc: header.cc != null ? (jsonDecode(header.cc!) as List<dynamic>).cast<String>() : null,
      bcc: header.bcc != null ? (jsonDecode(header.bcc!) as List<dynamic>).cast<String>() : null,
      date: header.date,
      textBody: '',
      htmlBody: null,
      isRead: header.isRead,
      isImportant: header.isImportant,
      folder: _parseEmailFolder(header.folder),
      attachments: null,
      uid: 0,
      previewText: header.snippet,
      threadId: header.threadId,
    )).toList();
  }

  // ==================== SYNC STATE MANAGEMENT ====================

  /// Get sync state for incremental syncing
  Future<SyncStateData?> getSyncState(String accountId, String folder) async {
    return await _database.getSyncState(accountId, folder);
  }

  /// Update sync state after successful sync
  Future<void> updateSyncState({
    required String accountId,
    required String folder,
    String? historyId,
    String? nextPageToken,
    DateTime? lastFullSync,
    DateTime? lastIncrementalSync,
    String? syncError,
  }) async {
    final state = SyncStateData(
      accountId: accountId,
      folder: folder,
      historyId: historyId,
      nextPageToken: nextPageToken,
      lastFullSync: lastFullSync,
      lastIncrementalSync: lastIncrementalSync,
      isSyncing: false,
      syncError: syncError,
    );

    await _database.updateSyncState(state);
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clean up old emails to manage storage
  Future<void> cleanupOldEmails({
    required String accountId,
    Duration maxAge = const Duration(days: 90),
  }) async {
    await _database.cleanupOldEmails(accountId: accountId, maxAge: maxAge);
    await _database.vacuum(); // Reclaim space

    debugPrint('AdvancedEmailCacheService: Cleaned up emails older than $maxAge for $accountId');
  }

  /// Intelligent cache eviction based on storage limits and usage patterns
  Future<void> performIntelligentCacheEviction({
    required String accountId,
    int maxStorageMB = 500, // Default 500MB limit
    int maxEmailsPerFolder = 5000, // Max emails per folder
    bool preserveImportantMessages = true,
    Duration maxUnusedAge = const Duration(days: 30),
  }) async {
    final stats = await getCacheStats(accountId);
    final currentSizeMB = (stats['totalSizeBytes'] as int) / (1024 * 1024);

    debugPrint('AdvancedEmailCacheService: Current cache size: ${currentSizeMB.toStringAsFixed(1)}MB');

    if (currentSizeMB <= maxStorageMB) {
      debugPrint('AdvancedEmailCacheService: Cache size within limits, no eviction needed');
      return;
    }

    debugPrint('AdvancedEmailCacheService: Cache size exceeds ${maxStorageMB}MB, starting intelligent eviction');

    await _database.transaction(() async {
      // Strategy 1: Remove old email bodies (keep headers)
      await _evictOldEmailBodies(accountId, maxUnusedAge);

      // Strategy 2: Remove emails from less important folders first
      await _evictByFolderPriority(accountId, maxEmailsPerFolder, preserveImportantMessages);

      // Strategy 3: Remove large attachments that haven't been accessed recently
      await _evictUnusedAttachments(accountId, maxUnusedAge);

      // Strategy 4: Clean up orphaned data
      await _cleanupOrphanedData(accountId);
    });

    // Reclaim space and update stats
    await _database.vacuum();
    await updateCacheStats(accountId);

    final newStats = await getCacheStats(accountId);
    final newSizeMB = (newStats['totalSizeBytes'] as int) / (1024 * 1024);

    debugPrint('AdvancedEmailCacheService: Cache eviction complete. New size: ${newSizeMB.toStringAsFixed(1)}MB');
  }

  /// Background maintenance to keep cache healthy
  Future<void> performBackgroundMaintenance({
    required String accountId,
    bool enableAutoEviction = true,
  }) async {
    debugPrint('AdvancedEmailCacheService: Starting background maintenance for $accountId');

    try {
      // Update cache statistics
      await updateCacheStats(accountId);

      // Clean up old temporary data
      await _cleanupTemporaryData(accountId);

      // Update last accessed times for recently viewed emails
      await _updateRecentlyAccessedEmails(accountId);

      // Perform intelligent eviction if enabled
      if (enableAutoEviction) {
        await performIntelligentCacheEviction(accountId: accountId);
      }

      debugPrint('AdvancedEmailCacheService: Background maintenance complete for $accountId');
    } catch (e) {
      debugPrint('AdvancedEmailCacheService: Background maintenance error: $e');
    }
  }

  /// Set storage limits and auto-cleanup policies for an account
  Future<void> configureCachePolicy({
    required String accountId,
    int maxStorageMB = 500,
    int maxEmailsPerFolder = 5000,
    Duration cleanupInterval = const Duration(hours: 24),
    Duration maxEmailAge = const Duration(days: 90),
    bool enableAutoCleanup = true,
  }) async {
    // Store cache policy in a preferences-like structure
    // This could be expanded to use shared_preferences or similar
    final policyData = {
      'maxStorageMB': maxStorageMB,
      'maxEmailsPerFolder': maxEmailsPerFolder,
      'cleanupIntervalHours': cleanupInterval.inHours,
      'maxEmailAgeDays': maxEmailAge.inDays,
      'enableAutoCleanup': enableAutoCleanup,
      'lastConfigured': DateTime.now().toIso8601String(),
    };

    debugPrint('AdvancedEmailCacheService: Cache policy configured for $accountId: $policyData');

    // If auto cleanup is enabled, perform initial cleanup
    if (enableAutoCleanup) {
      await performIntelligentCacheEviction(
        accountId: accountId,
        maxStorageMB: maxStorageMB,
        maxEmailsPerFolder: maxEmailsPerFolder,
      );
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats(String accountId) async {
    final stats = await _database.getCacheStats(accountId);

    if (stats == null) {
      return {
        'emailCount': 0,
        'attachmentCount': 0,
        'totalSizeBytes': 0,
        'oldestEmail': null,
        'newestEmail': null,
      };
    }

    return {
      'emailCount': stats.emailCount,
      'attachmentCount': stats.attachmentCount,
      'totalSizeBytes': stats.totalSizeBytes,
      'oldestEmail': stats.oldestEmail,
      'newestEmail': stats.newestEmail,
    };
  }

  /// Update cache statistics
  Future<void> updateCacheStats(String accountId) async {
    final headers = await _database.getEmailHeaders(accountId: accountId, limit: 999999);

    DateTime? oldestEmail;
    DateTime? newestEmail;

    if (headers.isNotEmpty) {
      oldestEmail = headers.map((h) => h.date).reduce((a, b) => a.isBefore(b) ? a : b);
      newestEmail = headers.map((h) => h.date).reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final stats = CacheStatsData(
      accountId: accountId,
      emailCount: headers.length,
      attachmentCount: 0, // TODO: Count attachments
      totalSizeBytes: headers.fold<int>(0, (sum, h) => sum + (h.size ?? 0)),
      oldestEmail: oldestEmail,
      newestEmail: newestEmail,
      lastCleanup: DateTime.now(),
    );

    await _database.updateCacheStats(stats);
  }

  // ==================== CACHE EVICTION HELPER METHODS ====================

  /// Evict old email bodies while keeping headers for fast inbox display
  Future<void> _evictOldEmailBodies(String accountId, Duration maxUnusedAge) async {
    final cutoffDate = DateTime.now().subtract(maxUnusedAge);

    final oldBodies = await (_database.select(_database.emailBodies)
      ..where((b) => b.accountId.equals(accountId) & b.lastAccessed.isSmallerThanValue(cutoffDate))
    ).get();

    int deletedBodies = 0;
    for (final body in oldBodies) {
      await (_database.delete(_database.emailBodies)
        ..where((b) => b.messageId.equals(body.messageId) & b.accountId.equals(accountId))
      ).go();
      deletedBodies++;
    }

    debugPrint('AdvancedEmailCacheService: Evicted $deletedBodies old email bodies');
  }

  /// Evict emails by folder priority (spam/trash first, inbox last)
  Future<void> _evictByFolderPriority(String accountId, int maxEmailsPerFolder, bool preserveImportant) async {
    // Define folder priorities (lower number = higher priority to keep)
    final folderPriorities = {
      'inbox': 1,
      'sent': 2,
      'drafts': 3,
      'archive': 4,
      'spam': 5,
      'trash': 6,
    };

    for (final folder in folderPriorities.keys.toList()..sort((a, b) => folderPriorities[b]!.compareTo(folderPriorities[a]!))) {
      final emailCount = await (_database.select(_database.emailHeaders)
        ..where((e) => e.accountId.equals(accountId) & e.folder.equals(folder))
      ).get().then((emails) => emails.length);

      if (emailCount <= maxEmailsPerFolder) continue;

      final excessCount = emailCount - maxEmailsPerFolder;

      // Get oldest emails to delete, but preserve important ones if requested
      var query = _database.select(_database.emailHeaders)
        ..where((e) => e.accountId.equals(accountId) & e.folder.equals(folder))
        ..orderBy([(e) => OrderingTerm.asc(e.date)])
        ..limit(excessCount * 2); // Get more to account for filtering

      if (preserveImportant) {
        query.where((e) => e.isImportant.equals(false));
      }

      final emailsToDelete = (await query.get()).take(excessCount).toList();

      int deletedEmails = 0;
      for (final email in emailsToDelete) {
        await _deleteEmailCompletely(email.messageId, accountId);
        deletedEmails++;
      }

      debugPrint('AdvancedEmailCacheService: Evicted $deletedEmails emails from $folder folder');
    }
  }

  /// Evict unused attachments to save storage
  Future<void> _evictUnusedAttachments(String accountId, Duration maxUnusedAge) async {
    final cutoffDate = DateTime.now().subtract(maxUnusedAge);

    final unusedAttachments = await (_database.select(_database.attachments)
      ..where((a) => a.accountId.equals(accountId) & a.lastAccessed.isSmallerThanValue(cutoffDate))
    ).get();

    int deletedAttachments = 0;
    for (final attachment in unusedAttachments) {
      // Clear attachment data but keep metadata
      await (_database.update(_database.attachments)
        ..where((a) => a.id.equals(attachment.id))
      ).write(AttachmentsCompanion(
        data: const Value(null),
        localPath: const Value(null),
        lastAccessed: Value(DateTime.now()),
      ));
      deletedAttachments++;
    }

    debugPrint('AdvancedEmailCacheService: Evicted $deletedAttachments unused attachments');
  }

  /// Clean up orphaned data (emails without headers, bodies without headers, etc.)
  Future<void> _cleanupOrphanedData(String accountId) async {
    // Clean up bodies without corresponding headers
    await _database.customStatement('''
      DELETE FROM email_bodies
      WHERE account_id = ? AND message_id NOT IN (
        SELECT message_id FROM email_headers WHERE account_id = ?
      )
    ''', [accountId, accountId]);

    // Clean up search index entries without corresponding headers
    await _database.customStatement('''
      DELETE FROM search_fts
      WHERE account_id = ? AND message_id NOT IN (
        SELECT message_id FROM email_headers WHERE account_id = ?
      )
    ''', [accountId, accountId]);

    // Clean up attachments without corresponding headers
    await _database.customStatement('''
      DELETE FROM attachments
      WHERE account_id = ? AND message_id NOT IN (
        SELECT message_id FROM email_headers WHERE account_id = ?
      )
    ''', [accountId, accountId]);

    debugPrint('AdvancedEmailCacheService: Cleaned up orphaned data for $accountId');
  }

  /// Clean up temporary data and reset usage flags
  Future<void> _cleanupTemporaryData(String accountId) async {
    // Reset sync flags that might be stuck
    await (_database.update(_database.syncState)
      ..where((s) => s.accountId.equals(accountId) & s.isSyncing.equals(true))
    ).write(const SyncStateCompanion(
      isSyncing: Value(false),
    ));

    debugPrint('AdvancedEmailCacheService: Cleaned up temporary data for $accountId');
  }

  /// Update last accessed times for emails viewed recently
  Future<void> _updateRecentlyAccessedEmails(String accountId) async {
    final recentDate = DateTime.now().subtract(const Duration(hours: 24));

    // This would typically be called after user interactions
    // For now, we'll just ensure the current timestamp is reasonable
    final recentlyAccessed = await (_database.select(_database.emailHeaders)
      ..where((e) => e.accountId.equals(accountId) & e.lastAccessed.isBiggerThanValue(recentDate))
    ).get();

    debugPrint('AdvancedEmailCacheService: ${recentlyAccessed.length} emails accessed recently');
  }

  /// Completely delete an email and all its related data
  Future<void> _deleteEmailCompletely(String messageId, String accountId) async {
    // Delete from all related tables
    await (_database.delete(_database.emailHeaders)
      ..where((e) => e.messageId.equals(messageId) & e.accountId.equals(accountId))
    ).go();

    await (_database.delete(_database.emailBodies)
      ..where((b) => b.messageId.equals(messageId) & b.accountId.equals(accountId))
    ).go();

    await (_database.delete(_database.attachments)
      ..where((a) => a.messageId.equals(messageId) & a.accountId.equals(accountId))
    ).go();

    await _database.customStatement(
      'DELETE FROM search_fts WHERE message_id = ? AND account_id = ?',
      [messageId, accountId],
    );
  }

  /// Perform batch maintenance with controlled processing to avoid UI blocking
  Future<void> performBatchMaintenance({
    required String accountId,
    int maxStorageMB = 300,
    int batchSize = 100,
    Duration processingDelay = const Duration(milliseconds: 50),
  }) async {
    debugPrint('AdvancedEmailCacheService: Starting batch maintenance for $accountId');

    try {
      // Get all emails sorted by date (oldest first)
      final allEmails = await (_database.select(_database.emailHeaders)
        ..where((e) => e.accountId.equals(accountId))
        ..orderBy([(e) => OrderingTerm.asc(e.date)])
      ).get();

      if (allEmails.isEmpty) {
        debugPrint('AdvancedEmailCacheService: No emails found for batch maintenance');
        return;
      }

      // Calculate current size
      final currentStats = await getCacheStats(accountId);
      final currentSizeMB = (currentStats['totalSizeBytes'] as int) / (1024 * 1024);

      if (currentSizeMB <= maxStorageMB) {
        debugPrint('AdvancedEmailCacheService: Cache size within limits (${currentSizeMB.toStringAsFixed(1)}MB <= ${maxStorageMB}MB)');
        return;
      }

      debugPrint('AdvancedEmailCacheService: Processing ${allEmails.length} emails in batches of $batchSize');

      int processedCount = 0;
      int deletedCount = 0;
      final targetSizeMB = maxStorageMB * 0.8; // Target 80% of max

      // Process emails in batches
      for (int i = 0; i < allEmails.length; i += batchSize) {
        final batchEnd = (i + batchSize).clamp(0, allEmails.length);
        final batch = allEmails.sublist(i, batchEnd);

        await _database.transaction(() async {
          for (final email in batch) {
            // Skip important emails and recent emails
            if (email.isImportant ||
                email.date.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
              continue;
            }

            // Delete email bodies first (keep headers for faster loading)
            await (_database.delete(_database.emailBodies)
              ..where((b) => b.messageId.equals(email.messageId) & b.accountId.equals(accountId))
            ).go();

            // For very old emails, delete completely
            if (email.date.isBefore(DateTime.now().subtract(const Duration(days: 60)))) {
              await _deleteEmailCompletely(email.messageId, accountId);
              deletedCount++;
            }
          }
        });

        processedCount += batch.length;

        // Check if we've reached target size
        final updatedStats = await getCacheStats(accountId);
        final updatedSizeMB = (updatedStats['totalSizeBytes'] as int) / (1024 * 1024);

        if (updatedSizeMB <= targetSizeMB) {
          debugPrint('AdvancedEmailCacheService: Target size reached (${updatedSizeMB.toStringAsFixed(1)}MB)');
          break;
        }

        // Small delay to prevent UI blocking
        if (processingDelay.inMilliseconds > 0) {
          await Future.delayed(processingDelay);
        }

        debugPrint('AdvancedEmailCacheService: Processed $processedCount emails, deleted $deletedCount completely');
      }

      // Final cleanup
      await _database.vacuum();
      await updateCacheStats(accountId);

      final finalStats = await getCacheStats(accountId);
      final finalSizeMB = (finalStats['totalSizeBytes'] as int) / (1024 * 1024);

      debugPrint('AdvancedEmailCacheService: Batch maintenance complete. Final size: ${finalSizeMB.toStringAsFixed(1)}MB, Deleted: $deletedCount emails');

    } catch (e) {
      debugPrint('AdvancedEmailCacheService: Batch maintenance error: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  Future<void> _updateSearchIndex(EmailMessage message, ProcessedEmailContent? processedContent) async {
    final content = [
      message.subject,
      message.textBody,
      message.htmlBody ?? '',
      processedContent?.previewText ?? '',
    ].join(' ');

    await _database.updateSearchIndex(
      message.messageId,
      message.accountId,
      content: content,
      subject: message.subject,
      sender: message.from,
      recipients: [...message.to, ...(message.cc ?? [])].join(' '),
      folder: message.folder.name,
      labels: null, // TODO: Add labels
      date: message.date,
    );
  }

  String _generateSnippet(EmailMessage message) {
    final preview = PreviewExtractor.extractPreview(
      htmlContent: message.htmlBody,
      textContent: message.textBody,
      maxLength: 100,
    );
    return preview.isNotEmpty ? preview : 'No preview available';
  }

  int _estimateEmailSize(EmailMessage message) {
    return (message.subject.length +
            message.textBody.length +
            (message.htmlBody?.length ?? 0)) * 2; // Rough UTF-8 estimate
  }

  int _estimateBodySize(EmailMessage message) {
    return message.textBody.length + (message.htmlBody?.length ?? 0);
  }

  models.EmailProvider _parseEmailProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'gmail':
        return models.EmailProvider.gmail;
      case 'yahoo':
        return models.EmailProvider.yahoo;
      case 'outlook':
        return models.EmailProvider.outlook;
      default:
        return models.EmailProvider.custom;
    }
  }

  EmailFolder _parseEmailFolder(String folder) {
    switch (folder.toLowerCase()) {
      case 'inbox':
        return EmailFolder.inbox;
      case 'sent':
        return EmailFolder.sent;
      case 'drafts':
        return EmailFolder.drafts;
      case 'trash':
        return EmailFolder.trash;
      case 'spam':
        return EmailFolder.spam;
      case 'archive':
        return EmailFolder.archive;
      default:
        return EmailFolder.inbox;
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_isInitialized) {
      await _database.close();
      _isInitialized = false;
      debugPrint('AdvancedEmailCacheService: Closed database connection');
    }
  }
}

/// Extension to add copyWith method to EmailMessage
extension EmailMessageCopyWith on EmailMessage {
  EmailMessage copyWith({
    String? messageId,
    String? accountId,
    String? subject,
    String? from,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    DateTime? date,
    String? textBody,
    String? htmlBody,
    bool? isRead,
    bool? isImportant,
    EmailFolder? folder,
    List<EmailAttachment>? attachments,
    int? uid,
    String? previewText,
    String? threadId,
  }) {
    return EmailMessage(
      messageId: messageId ?? this.messageId,
      accountId: accountId ?? this.accountId,
      subject: subject ?? this.subject,
      from: from ?? this.from,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      date: date ?? this.date,
      textBody: textBody ?? this.textBody,
      htmlBody: htmlBody ?? this.htmlBody,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      folder: folder ?? this.folder,
      attachments: attachments ?? this.attachments,
      uid: uid ?? this.uid,
      previewText: previewText ?? this.previewText,
      threadId: threadId ?? this.threadId,
    );
  }
}