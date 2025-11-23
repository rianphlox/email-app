import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'email_database.g.dart';

// Account table - stores email account information
@DataClassName('AccountData')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get provider => text()(); // 'gmail', 'yahoo', 'outlook', etc.
  TextColumn get accessToken => text().nullable()();
  TextColumn get refreshToken => text().nullable()();
  TextColumn get historyId => text().nullable()(); // For Gmail incremental sync
  DateTimeColumn get lastSyncTime => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// Email headers table - stores basic email metadata for fast loading
@DataClassName('EmailHeaderData')
class EmailHeaders extends Table {
  TextColumn get messageId => text()();
  TextColumn get accountId => text()();
  TextColumn get threadId => text().nullable()();
  TextColumn get subject => text()();
  TextColumn get from => text()();
  TextColumn get to => text()(); // JSON array of recipients
  TextColumn get cc => text().nullable()(); // JSON array
  TextColumn get bcc => text().nullable()(); // JSON array
  DateTimeColumn get date => dateTime()();
  TextColumn get folder => text()(); // inbox, sent, drafts, etc.
  TextColumn get labels => text().nullable()(); // JSON array of Gmail labels
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isStarred => boolean().withDefault(const Constant(false))();
  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();
  BoolColumn get hasAttachments => boolean().withDefault(const Constant(false))();
  IntColumn get size => integer().nullable()(); // Email size in bytes
  TextColumn get snippet => text().nullable()(); // Short preview text
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastAccessed => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {messageId, accountId};
}

// Email bodies table - stores full email content (loaded on-demand)
@DataClassName('EmailBodyData')
class EmailBodies extends Table {
  TextColumn get messageId => text()();
  TextColumn get accountId => text()();
  TextColumn get textBody => text().nullable()();
  TextColumn get htmlBody => text().nullable()();
  TextColumn get processedHtml => text().nullable()(); // Enhanced HTML with quote processing
  BoolColumn get hasQuotedText => boolean().withDefault(const Constant(false))();
  BoolColumn get hasSignature => boolean().withDefault(const Constant(false))();
  IntColumn get bodySize => integer().nullable()(); // Body size in bytes
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastAccessed => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {messageId, accountId};
}

// Attachments table - stores attachment metadata and data
@DataClassName('AttachmentData')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get messageId => text()();
  TextColumn get accountId => text()();
  TextColumn get filename => text()();
  TextColumn get mimeType => text()();
  IntColumn get size => integer()();
  BlobColumn get data => blob().nullable()(); // Actual file data (for small attachments)
  TextColumn get localPath => text().nullable()(); // Path to cached file
  TextColumn get downloadUrl => text().nullable()(); // Server download URL
  BoolColumn get isInline => boolean().withDefault(const Constant(false))();
  TextColumn get contentId => text().nullable()(); // For inline attachments
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastAccessed => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}

// Conversations table - groups related emails for threading
@DataClassName('ConversationData')
class Conversations extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get subject => text()();
  TextColumn get participants => text()(); // JSON array of email addresses
  IntColumn get messageCount => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastMessageDate => dateTime()();
  BoolColumn get hasUnreadMessages => boolean().withDefault(const Constant(false))();
  BoolColumn get hasStarredMessages => boolean().withDefault(const Constant(false))();
  BoolColumn get hasImportantMessages => boolean().withDefault(const Constant(false))();
  TextColumn get latestSnippet => text().nullable()();
  TextColumn get folder => text()(); // Primary folder
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  DateTimeColumn get lastAccessed => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}

// Labels table - stores Gmail labels and custom labels
@DataClassName('LabelData')
class Labels extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'system', 'user'
  IntColumn get color => integer().nullable()(); // Color as int
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id, accountId};
}

// Full-Text Search table for instant offline search
@DataClassName('SearchIndexData')
class SearchIndex extends Table {
  TextColumn get messageId => text()();
  TextColumn get accountId => text()();
  TextColumn get content => text()(); // Combined searchable text
  TextColumn get subject => text()();
  TextColumn get sender => text()();
  TextColumn get recipients => text()(); // All recipients combined
  TextColumn get folder => text()();
  TextColumn get labels => text().nullable()();
  DateTimeColumn get date => dateTime()();

  @override
  Set<Column> get primaryKey => {messageId, accountId};
}

// Sync state table - tracks synchronization state for incremental sync
@DataClassName('SyncStateData')
class SyncState extends Table {
  TextColumn get accountId => text()();
  TextColumn get folder => text()();
  TextColumn get historyId => text().nullable()();
  TextColumn get nextPageToken => text().nullable()();
  DateTimeColumn get lastFullSync => dateTime().nullable()();
  DateTimeColumn get lastIncrementalSync => dateTime().nullable()();
  BoolColumn get isSyncing => boolean().withDefault(const Constant(false))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {accountId, folder};
}

// Cache statistics table - for monitoring and cleanup
@DataClassName('CacheStatsData')
class CacheStats extends Table {
  TextColumn get accountId => text()();
  IntColumn get emailCount => integer().withDefault(const Constant(0))();
  IntColumn get attachmentCount => integer().withDefault(const Constant(0))();
  IntColumn get totalSizeBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get oldestEmail => dateTime().nullable()();
  DateTimeColumn get newestEmail => dateTime().nullable()();
  DateTimeColumn get lastCleanup => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {accountId};
}

@DriftDatabase(tables: [
  Accounts,
  EmailHeaders,
  EmailBodies,
  Attachments,
  Conversations,
  Labels,
  SearchIndex,
  SyncState,
  CacheStats,
])
class EmailDatabase extends _$EmailDatabase {
  EmailDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create FTS5 virtual table for full-text search
        await customStatement('''
          CREATE VIRTUAL TABLE search_fts USING fts5(
            message_id,
            account_id,
            content,
            subject,
            sender,
            recipients,
            folder,
            labels,
            date UNINDEXED
          );
        ''');

        // Create indexes for better performance
        await customStatement('CREATE INDEX idx_email_headers_account_folder ON email_headers(account_id, folder);');
        await customStatement('CREATE INDEX idx_email_headers_date ON email_headers(date DESC);');
        await customStatement('CREATE INDEX idx_email_headers_thread ON email_headers(thread_id);');
        await customStatement('CREATE INDEX idx_conversations_account ON conversations(account_id, last_message_date DESC);');
        await customStatement('CREATE INDEX idx_attachments_message ON attachments(message_id, account_id);');
        await customStatement('CREATE INDEX idx_sync_state_account ON sync_state(account_id);');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle schema migrations here as we evolve
      },
    );
  }

  // Account management
  Future<List<AccountData>> getAllAccounts() => select(accounts).get();

  Future<AccountData?> getAccount(String accountId) =>
      (select(accounts)..where((a) => a.id.equals(accountId))).getSingleOrNull();

  Future<void> insertOrUpdateAccount(Insertable<AccountData> account) =>
      into(accounts).insertOnConflictUpdate(account);

  Future<void> deleteAccount(String accountId) async {
    await transaction(() async {
      // Delete all related data
      await (delete(emailHeaders)..where((e) => e.accountId.equals(accountId))).go();
      await (delete(emailBodies)..where((e) => e.accountId.equals(accountId))).go();
      await (delete(attachments)..where((a) => a.accountId.equals(accountId))).go();
      await (delete(conversations)..where((c) => c.accountId.equals(accountId))).go();
      await (delete(labels)..where((l) => l.accountId.equals(accountId))).go();
      await (delete(syncState)..where((s) => s.accountId.equals(accountId))).go();
      await (delete(cacheStats)..where((c) => c.accountId.equals(accountId))).go();
      await customStatement('DELETE FROM search_fts WHERE account_id = ?', [accountId]);

      // Finally delete the account
      await (delete(accounts)..where((a) => a.id.equals(accountId))).go();
    });
  }

  // Email header operations (fast, always available)
  Future<List<EmailHeaderData>> getEmailHeaders({
    required String accountId,
    String? folder,
    int limit = 50,
    int offset = 0,
  }) {
    final query = select(emailHeaders)
      ..where((e) => e.accountId.equals(accountId))
      ..orderBy([(e) => OrderingTerm.desc(e.date)])
      ..limit(limit, offset: offset);

    if (folder != null) {
      query.where((e) => e.folder.equals(folder));
    }

    return query.get();
  }

  Future<EmailHeaderData?> getEmailHeader(String messageId, String accountId) =>
      (select(emailHeaders)..where((e) => e.messageId.equals(messageId) & e.accountId.equals(accountId)))
          .getSingleOrNull();

  Future<void> insertOrUpdateEmailHeader(EmailHeaderData header) =>
      into(emailHeaders).insertOnConflictUpdate(header);

  // Email body operations (on-demand loading)
  Future<EmailBodyData?> getEmailBody(String messageId, String accountId) =>
      (select(emailBodies)..where((e) => e.messageId.equals(messageId) & e.accountId.equals(accountId)))
          .getSingleOrNull();

  Future<void> insertOrUpdateEmailBody(Insertable<EmailBodyData> body) =>
      into(emailBodies).insertOnConflictUpdate(body);

  // Full-text search
  Future<List<Map<String, Object?>>> searchEmails({
    required String accountId,
    required String query,
    String? folder,
    int limit = 50,
  }) async {
    var sql = '''
      SELECT * FROM search_fts
      WHERE search_fts MATCH ? AND account_id = ?
    ''';

    final params = [query, accountId];

    if (folder != null) {
      sql += ' AND folder = ?';
      params.add(folder);
    }

    sql += ' ORDER BY date DESC LIMIT ?';
    params.add(limit.toString());

    final results = await customSelect(sql, variables: params.map((p) => Variable(p)).toList()).get();
    return results.map((row) => row.data).toList();
  }

  Future<void> updateSearchIndex(String messageId, String accountId, {
    required String content,
    required String subject,
    required String sender,
    required String recipients,
    required String folder,
    String? labels,
    required DateTime date,
  }) async {
    await customStatement('''
      INSERT OR REPLACE INTO search_fts (
        message_id, account_id, content, subject, sender, recipients, folder, labels, date
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [messageId, accountId, content, subject, sender, recipients, folder, labels, date.toIso8601String()]);
  }

  // Conversation operations
  Future<List<ConversationData>> getConversations({
    required String accountId,
    String? folder,
    int limit = 50,
    int offset = 0,
  }) {
    final query = select(conversations)
      ..where((c) => c.accountId.equals(accountId))
      ..orderBy([(c) => OrderingTerm.desc(c.lastMessageDate)])
      ..limit(limit, offset: offset);

    if (folder != null) {
      query.where((c) => c.folder.equals(folder));
    }

    return query.get();
  }

  Future<void> insertOrUpdateConversation(ConversationData conversation) =>
      into(conversations).insertOnConflictUpdate(conversation);

  // Sync state management
  Future<SyncStateData?> getSyncState(String accountId, String folder) =>
      (select(syncState)..where((s) => s.accountId.equals(accountId) & s.folder.equals(folder)))
          .getSingleOrNull();

  Future<void> updateSyncState(SyncStateData state) =>
      into(syncState).insertOnConflictUpdate(state);

  // Cache management
  Future<CacheStatsData?> getCacheStats(String accountId) =>
      (select(cacheStats)..where((c) => c.accountId.equals(accountId))).getSingleOrNull();

  Future<void> updateCacheStats(CacheStatsData stats) =>
      into(cacheStats).insertOnConflictUpdate(stats);

  // Cleanup operations
  Future<void> cleanupOldEmails({
    required String accountId,
    required Duration maxAge,
  }) async {
    final cutoffDate = DateTime.now().subtract(maxAge);

    await transaction(() async {
      // Get message IDs to delete
      final oldMessages = await (select(emailHeaders)
        ..where((e) => e.accountId.equals(accountId) & e.date.isSmallerThanValue(cutoffDate)))
        .get();

      final messageIds = oldMessages.map((m) => m.messageId).toList();

      if (messageIds.isNotEmpty) {
        // Delete bodies and search index entries
        for (final messageId in messageIds) {
          await (delete(emailBodies)..where((b) => b.messageId.equals(messageId) & b.accountId.equals(accountId))).go();
          await customStatement('DELETE FROM search_fts WHERE message_id = ? AND account_id = ?', [messageId, accountId]);
        }
      }
    });
  }

  Future<void> vacuum() async {
    await customStatement('VACUUM');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'qmail_cache.db'));

    // Ensure SQLite3 is properly initialized
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = sqlite3.tempDirectory;
    print('Using sqlite3 at $cachebase');

    return NativeDatabase.createInBackground(file);
  });
}