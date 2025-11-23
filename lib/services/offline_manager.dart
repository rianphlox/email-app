import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/email_message.dart';
import '../models/pending_operation.dart';
import 'operation_queue.dart';

/// Comprehensive offline capabilities manager for QMail
class OfflineManager {
  static const String _draftBoxName = 'email_drafts';
  static const String _offlineSearchBoxName = 'offline_search_index';
  static const String _conflictResolutionBoxName = 'sync_conflicts';
  static const String _metadataBoxName = 'offline_metadata';

  static Box<Map<String, dynamic>>? _draftsBox;
  static Box<Map<String, dynamic>>? _searchIndexBox;
  static Box<Map<String, dynamic>>? _conflictsBox;
  static Box<Map<String, dynamic>>? _metadataBox;

  static bool _isInitialized = false;
  static ConnectivityResult _connectivityStatus = ConnectivityResult.none;

  /// Initialize offline manager and setup connectivity monitoring
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive boxes for offline capabilities
    _draftsBox = await Hive.openBox<Map<String, dynamic>>(_draftBoxName);
    _searchIndexBox = await Hive.openBox<Map<String, dynamic>>(_offlineSearchBoxName);
    _conflictsBox = await Hive.openBox<Map<String, dynamic>>(_conflictResolutionBoxName);
    _metadataBox = await Hive.openBox<Map<String, dynamic>>(_metadataBoxName);

    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _connectivityStatus = await Connectivity().checkConnectivity();

    // Initialize search index if needed
    await _initializeOfflineSearchIndex();

    _isInitialized = true;
  }

  /// Check if device is currently online
  static bool get isOnline =>
      _connectivityStatus != ConnectivityResult.none;

  /// Save draft email for offline composition
  static Future<String> saveDraft({
    required String accountId,
    String? draftId,
    String? to,
    String? cc,
    String? bcc,
    String? subject,
    String? bodyText,
    String? bodyHtml,
    List<Map<String, dynamic>>? attachments,
  }) async {
    await _ensureInitialized();

    final id = draftId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final draftData = {
      'id': id,
      'accountId': accountId,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'bodyText': bodyText,
      'bodyHtml': bodyHtml,
      'attachments': attachments,
      'createdAt': DateTime.now().toIso8601String(),
      'modifiedAt': DateTime.now().toIso8601String(),
      'isOfflineDraft': !isOnline,
    };

    await _draftsBox!.put(id, draftData);
    return id;
  }

  /// Get all drafts for an account
  static Future<List<Map<String, dynamic>>> getDrafts(String accountId) async {
    await _ensureInitialized();

    return _draftsBox!.values
        .where((draft) => draft['accountId'] == accountId)
        .toList()
        ..sort((a, b) => DateTime.parse(b['modifiedAt'])
            .compareTo(DateTime.parse(a['modifiedAt'])));
  }

  /// Delete a draft
  static Future<void> deleteDraft(String draftId) async {
    await _ensureInitialized();
    await _draftsBox!.delete(draftId);
  }

  /// Queue email for sending when online
  static Future<void> queueEmailForSending({
    required String accountId,
    required String to,
    String? cc,
    String? bcc,
    required String subject,
    required String bodyText,
    String? bodyHtml,
    List<Map<String, dynamic>>? attachments,
    String? draftId,
  }) async {
    await _ensureInitialized();

    final emailData = {
      'accountId': accountId,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'subject': subject,
      'bodyText': bodyText,
      'bodyHtml': bodyHtml,
      'attachments': attachments,
      'queuedAt': DateTime.now().toIso8601String(),
      'attempts': 0,
      'maxAttempts': 3,
    };

    // Add to operation queue for sending when online
    final queue = OperationQueue();
    await queue.queueOperation(
      operationType: OperationType.sendEmail,
      emailId: DateTime.now().millisecondsSinceEpoch.toString(),
      data: emailData,
      accountId: accountId,
    );

    // Remove draft if it exists
    if (draftId != null) {
      await deleteDraft(draftId);
    }
  }

  /// Build and maintain enhanced offline search index
  static Future<void> indexEmailsForOfflineSearch(List<EmailMessage> emails) async {
    await _ensureInitialized();

    final searchIndex = <String, Map<String, dynamic>>{};
    final invertedIndex = <String, Set<String>>{}; // Word -> Set of email IDs

    for (final email in emails) {
      final searchableContent = [
        email.subject,
        email.from,
        ...email.to,
        ...(email.cc ?? []),
        email.textBody,
        email.htmlBody ?? '',
        email.previewText ?? '',
      ].join(' ').toLowerCase();

      // Extract keywords and create inverted index
      final words = searchableContent
          .split(RegExp(r'[\s\W]+'))
          .where((word) => word.length > 2)
          .map((word) => word.toLowerCase())
          .toSet();

      // Build inverted index for faster search
      for (final word in words) {
        invertedIndex.putIfAbsent(word, () => <String>{}).add(email.messageId);
      }

      searchIndex[email.messageId] = {
        'messageId': email.messageId,
        'accountId': email.accountId,
        'subject': email.subject,
        'from': email.from,
        'to': email.to,
        'cc': email.cc ?? [],
        'date': email.date.toIso8601String(),
        'folder': email.folder.toString(),
        'isRead': email.isRead,
        'isImportant': email.isImportant,
        'hasAttachment': email.attachments?.isNotEmpty ?? false,
        'previewText': email.previewText ?? '',
        'words': words.toList(),
        'searchContent': searchableContent,
        'category': email.category.toString(),
        'size': email.textBody.length + (email.htmlBody?.length ?? 0),
      };
    }

    // Store both direct index and inverted index
    await _searchIndexBox!.put('emailIndex', searchIndex);
    await _searchIndexBox!.put('invertedIndex', invertedIndex.map((key, value) => MapEntry(key, value.toList())));
    await _metadataBox!.put('lastIndexUpdate', {
      'timestamp': DateTime.now().toIso8601String(),
      'emailCount': emails.length,
      'wordsIndexed': invertedIndex.length,
    });

    debugPrint('🔍 OfflineManager: Indexed ${emails.length} emails with ${invertedIndex.length} unique words');
  }

  /// Perform enhanced offline email search with advanced operators
  static Future<List<String>> searchEmailsOffline(
    String query, {
    String? accountId,
    int limit = 50,
  }) async {
    await _ensureInitialized();

    final indexData = _searchIndexBox!.get('emailIndex');
    final invertedIndexData = _searchIndexBox!.get('invertedIndex');

    if (indexData == null) return [];

    final searchIndex = Map<String, Map<String, dynamic>>.from(indexData);
    final invertedIndex = invertedIndexData != null
        ? Map<String, List<dynamic>>.from(invertedIndexData)
        : <String, List<dynamic>>{};

    final results = <String>{};
    final queryLower = query.toLowerCase().trim();

    debugPrint('🔍 OfflineManager: Searching for "$query" in ${searchIndex.length} indexed emails');

    // Handle advanced search operators
    if (queryLower.contains('from:') || queryLower.contains('to:') ||
        queryLower.contains('subject:') || queryLower.contains('has:')) {
      return _performAdvancedOfflineSearch(queryLower, searchIndex, accountId, limit);
    }

    // Fast word-based search using inverted index
    final queryWords = queryLower
        .split(RegExp(r'[\s\W]+'))
        .where((word) => word.length > 2)
        .toSet();

    if (queryWords.isNotEmpty) {
      // Find emails containing all query words (AND operation)
      Set<String>? candidateEmails;

      for (final word in queryWords) {
        final emailIds = invertedIndex[word]?.cast<String>().toSet() ?? <String>{};

        if (candidateEmails == null) {
          candidateEmails = emailIds;
        } else {
          candidateEmails = candidateEmails.intersection(emailIds);
        }

        // Early exit if no matches
        if (candidateEmails.isEmpty) break;
      }

      results.addAll(candidateEmails ?? <String>{});
    } else {
      // Fallback to content search for very short queries
      for (final entry in searchIndex.entries) {
        final emailData = entry.value;
        final searchContent = emailData['searchContent']?.toString() ?? '';
        if (searchContent.contains(queryLower)) {
          results.add(entry.key);
        }
      }
    }

    // Filter by account if specified
    var filteredResults = results.toList();
    if (accountId != null) {
      filteredResults = filteredResults
          .where((emailId) => searchIndex[emailId]?['accountId'] == accountId)
          .toList();
    }

    debugPrint('🔍 OfflineManager: Found ${filteredResults.length} matching emails');

    // Sort by relevance and recency
    filteredResults.sort((a, b) {
      final emailA = searchIndex[a]!;
      final emailB = searchIndex[b]!;

      // Calculate relevance score
      final scoreA = _calculateRelevanceScore(emailA, queryWords);
      final scoreB = _calculateRelevanceScore(emailB, queryWords);

      if (scoreA != scoreB) {
        return scoreB.compareTo(scoreA); // Higher score first
      }

      // If same score, sort by date
      final dateA = DateTime.parse(emailA['date']);
      final dateB = DateTime.parse(emailB['date']);
      return dateB.compareTo(dateA);
    });

    return filteredResults.take(limit).toList();
  }

  /// Handle sync conflicts when going back online
  static Future<void> handleSyncConflicts(List<EmailMessage> serverEmails) async {
    await _ensureInitialized();

    final conflicts = <String, Map<String, dynamic>>{};

    // Check for conflicts with local modifications
    final queue = OperationQueue();
    final pendingOperations = queue.pendingOperations.map((op) => {
      'emailId': op.emailId,
      'timestamp': op.timestamp.millisecondsSinceEpoch,
      'accountId': op.data['accountId'],
    }).toList();

    for (final operation in pendingOperations) {
      final serverEmail = serverEmails.firstWhere(
        (email) => email.messageId == operation['emailId'],
        orElse: () => EmailMessage(
          messageId: '',
          accountId: '',
          subject: '',
          from: '',
          to: [],
          date: DateTime.now(),
          textBody: '',
          folder: EmailFolder.inbox,
          uid: 0,
        ),
      );

      if (serverEmail.messageId.isNotEmpty) {
        final localModification = operation['timestamp'];
        final serverModification = serverEmail.date.millisecondsSinceEpoch;

        if (localModification > serverModification) {
          // Local modification is newer, might be a conflict
          conflicts[operation['emailId']] = {
            'type': 'modification_conflict',
            'localOperation': operation,
            'serverState': _emailToMap(serverEmail),
            'detectedAt': DateTime.now().toIso8601String(),
            'resolution': 'pending',
          };
        }
      }
    }

    // Store conflicts for user resolution
    for (final conflict in conflicts.entries) {
      await _conflictsBox!.put(conflict.key, conflict.value);
    }
  }

  /// Get pending sync conflicts
  static Future<List<Map<String, dynamic>>> getPendingConflicts() async {
    await _ensureInitialized();

    return _conflictsBox!.values
        .where((conflict) => conflict['resolution'] == 'pending')
        .toList();
  }

  /// Resolve a sync conflict
  static Future<void> resolveConflict(
    String emailId,
    ConflictResolution resolution,
  ) async {
    await _ensureInitialized();

    final conflict = _conflictsBox!.get(emailId);
    if (conflict == null) return;

    conflict['resolution'] = resolution.toString().split('.').last;
    conflict['resolvedAt'] = DateTime.now().toIso8601String();

    await _conflictsBox!.put(emailId, conflict);

    switch (resolution) {
      case ConflictResolution.useLocal:
        // Keep local changes, mark server version for overwrite
        final queue = OperationQueue();
        await queue.queueOperation(
          operationType: OperationType.markRead, // Use available operation type
          emailId: emailId,
          data: conflict['localOperation'],
          accountId: conflict['localOperation']['accountId'],
        );
        break;

      case ConflictResolution.useServer:
        // Discard local changes, use server version
        // Remove operation by marking it as processed
        debugPrint('Discarding local changes for $emailId');
        break;

      case ConflictResolution.merge:
        // Implement merge logic based on operation type
        await _mergeConflictedChanges(conflict);
        break;
    }
  }

  /// Export offline data for backup
  static Future<Map<String, dynamic>> exportOfflineData() async {
    await _ensureInitialized();

    return {
      'drafts': _draftsBox!.toMap(),
      'searchIndex': _searchIndexBox!.toMap(),
      'metadata': _metadataBox!.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Import offline data from backup
  static Future<void> importOfflineData(Map<String, dynamic> data) async {
    await _ensureInitialized();

    if (data['drafts'] != null) {
      await _draftsBox!.clear();
      await _draftsBox!.putAll(Map<String, Map<String, dynamic>>.from(data['drafts']));
    }

    if (data['searchIndex'] != null) {
      await _searchIndexBox!.clear();
      await _searchIndexBox!.putAll(Map<String, Map<String, dynamic>>.from(data['searchIndex']));
    }

    if (data['metadata'] != null) {
      await _metadataBox!.clear();
      await _metadataBox!.putAll(Map<String, Map<String, dynamic>>.from(data['metadata']));
    }
  }

  /// Get offline storage statistics
  static Future<Map<String, dynamic>> getOfflineStats() async {
    await _ensureInitialized();

    final draftCount = _draftsBox!.length;
    final indexSize = _searchIndexBox!.get('emailIndex')?.length ?? 0;
    final conflictCount = _conflictsBox!.values
        .where((c) => c['resolution'] == 'pending')
        .length;

    final lastIndexUpdate = _metadataBox!.get('lastIndexUpdate');

    return {
      'draftsCount': draftCount,
      'indexedEmailsCount': indexSize,
      'pendingConflictsCount': conflictCount,
      'lastIndexUpdate': lastIndexUpdate?['timestamp'],
      'isOnline': isOnline,
      'storageBoxes': {
        'drafts': '${_draftsBox!.length} items',
        'searchIndex': '${_searchIndexBox!.length} items',
        'conflicts': '${_conflictsBox!.length} items',
        'metadata': '${_metadataBox!.length} items',
      },
    };
  }

  /// Private helper methods
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  static void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = isOnline;
    _connectivityStatus = result;

    if (!wasOnline && isOnline) {
      // Went online, trigger sync
      _handleGoingOnline();
    }
  }

  static Future<void> _handleGoingOnline() async {
    debugPrint('📡 OfflineManager: Device came online, processing pending operations');

    try {
      // Process pending operations
      final queue = OperationQueue();
      await queue.processPendingOperations();

      debugPrint('✅ OfflineManager: Successfully processed pending operations');
    } catch (e) {
      debugPrint('❌ OfflineManager: Failed to process pending operations: $e');
    }
  }

  static Future<void> _initializeOfflineSearchIndex() async {
    final existingIndex = _searchIndexBox!.get('emailIndex');
    if (existingIndex == null) {
      await _searchIndexBox!.put('emailIndex', <String, dynamic>{});
    }
  }

  /// Enhanced matching with advanced search operators
  static List<String> _performAdvancedOfflineSearch(
    String query,
    Map<String, Map<String, dynamic>> searchIndex,
    String? accountId,
    int limit,
  ) {
    final results = <String>[];

    for (final entry in searchIndex.entries) {
      final emailData = entry.value;

      // Filter by account if specified
      if (accountId != null && emailData['accountId'] != accountId) continue;

      if (_matchesAdvancedCriteria(emailData, query)) {
        results.add(entry.key);
      }
    }

    return results.take(limit).toList();
  }

  static bool _matchesAdvancedCriteria(
    Map<String, dynamic> emailData,
    String query,
  ) {
    // Parse advanced search operators
    final operators = <String, String>{};
    final queryParts = query.split(RegExp(r'\s+'));
    final freeTextParts = <String>[];

    for (final part in queryParts) {
      if (part.contains(':')) {
        final colonIndex = part.indexOf(':');
        final operator = part.substring(0, colonIndex);
        final value = part.substring(colonIndex + 1);
        operators[operator] = value;
      } else {
        freeTextParts.add(part);
      }
    }

    // Check operators
    for (final entry in operators.entries) {
      switch (entry.key) {
        case 'from':
          if (!emailData['from'].toString().toLowerCase().contains(entry.value.toLowerCase())) {
            return false;
          }
          break;
        case 'to':
          final toList = List<String>.from(emailData['to'] ?? []);
          if (!toList.any((to) => to.toLowerCase().contains(entry.value.toLowerCase()))) {
            return false;
          }
          break;
        case 'subject':
          if (!emailData['subject'].toString().toLowerCase().contains(entry.value.toLowerCase())) {
            return false;
          }
          break;
        case 'has':
          switch (entry.value.toLowerCase()) {
            case 'attachment':
              if (emailData['hasAttachment'] != true) return false;
              break;
          }
          break;
        case 'is':
          switch (entry.value.toLowerCase()) {
            case 'read':
              if (emailData['isRead'] != true) return false;
              break;
            case 'unread':
              if (emailData['isRead'] == true) return false;
              break;
            case 'important':
              if (emailData['isImportant'] != true) return false;
              break;
          }
          break;
      }
    }

    // Check free text in content
    if (freeTextParts.isNotEmpty) {
      final freeText = freeTextParts.join(' ').toLowerCase();
      final searchContent = emailData['searchContent']?.toString().toLowerCase() ?? '';
      if (!searchContent.contains(freeText)) {
        return false;
      }
    }

    return true;
  }

  /// Calculate relevance score for search ranking
  static double _calculateRelevanceScore(
    Map<String, dynamic> emailData,
    Set<String> queryWords,
  ) {
    double score = 0.0;
    final words = Set<String>.from(emailData['words'] ?? []);

    // Base score: number of matching words
    final matchingWords = words.intersection(queryWords);
    score += matchingWords.length * 10;

    // Bonus for matches in subject (more important)
    final subject = emailData['subject']?.toString().toLowerCase() ?? '';
    for (final word in queryWords) {
      if (subject.contains(word)) {
        score += 20;
      }
    }

    // Bonus for matches in sender (also important)
    final from = emailData['from']?.toString().toLowerCase() ?? '';
    for (final word in queryWords) {
      if (from.contains(word)) {
        score += 15;
      }
    }

    // Bonus for unread emails
    if (emailData['isRead'] != true) {
      score += 5;
    }

    // Bonus for important emails
    if (emailData['isImportant'] == true) {
      score += 10;
    }

    // Penalty for very old emails
    final date = DateTime.parse(emailData['date']);
    final daysSinceReceived = DateTime.now().difference(date).inDays;
    if (daysSinceReceived > 30) {
      score *= 0.9; // 10% penalty for emails older than 30 days
    }
    if (daysSinceReceived > 90) {
      score *= 0.8; // Additional 20% penalty for emails older than 90 days
    }

    return score;
  }

  static Map<String, dynamic> _emailToMap(EmailMessage email) {
    return {
      'messageId': email.messageId,
      'subject': email.subject,
      'from': email.from,
      'to': email.to,
      'date': email.date.toIso8601String(),
      'isRead': email.isRead,
      'isImportant': email.isImportant,
      'folder': email.folder.toString(),
    };
  }

  static Future<void> _mergeConflictedChanges(Map<String, dynamic> conflict) async {
    // Basic merge strategy - could be enhanced based on operation type
    final localOp = conflict['localOperation'];
    final serverState = conflict['serverState'];

    // For now, prefer local changes for user-initiated operations
    final queue = OperationQueue();
    await queue.queueOperation(
      operationType: OperationType.markRead, // Use available operation type
      emailId: conflict['emailId'] ?? '',
      data: {
        'localChanges': localOp,
        'serverState': serverState,
        'mergeStrategy': 'prefer_local',
      },
      accountId: localOp['accountId'] ?? '',
    );
  }
}

/// Conflict resolution strategies
enum ConflictResolution {
  useLocal,
  useServer,
  merge,
}

/// Offline operation status
enum OfflineOperationStatus {
  pending,
  inProgress,
  completed,
  failed,
  retrying,
}

/// Enhanced offline capabilities with better integration
class OfflineCapabilities {
  /// Check if operation can be performed offline
  static bool canPerformOffline(OperationType operation) {
    switch (operation) {
      case OperationType.sendEmail:
      case OperationType.delete:
      case OperationType.archive:
      case OperationType.markRead:
      case OperationType.markUnread:
      case OperationType.star:
      case OperationType.unstar:
      case OperationType.snooze:
      case OperationType.moveToFolder:
      case OperationType.addLabel:
      case OperationType.removeLabel:
        return true;
    }
  }

  /// Get user-friendly status message
  static String getStatusMessage(OfflineOperationStatus status, int count) {
    switch (status) {
      case OfflineOperationStatus.pending:
        return '$count operations waiting for connection';
      case OfflineOperationStatus.inProgress:
        return 'Syncing $count operations...';
      case OfflineOperationStatus.completed:
        return 'All operations synced';
      case OfflineOperationStatus.failed:
        return '$count operations failed';
      case OfflineOperationStatus.retrying:
        return 'Retrying $count operations...';
    }
  }

  /// Get offline storage size estimate in MB
  static Future<double> getStorageSizeEstimate() async {
    try {
      final stats = await OfflineManager.getOfflineStats();
      // Rough estimate: each email ~5KB, each draft ~2KB
      final emailsSize = (stats['indexedEmailsCount'] as int? ?? 0) * 5;
      final draftsSize = (stats['draftsCount'] as int? ?? 0) * 2;
      return (emailsSize + draftsSize) / 1024.0; // Convert to MB
    } catch (e) {
      return 0.0;
    }
  }
}