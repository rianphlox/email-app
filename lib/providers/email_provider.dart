import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/email_account.dart' as models;
import '../models/email_message.dart';
import '../services/auth_service.dart';
import '../services/final_email_service.dart';
import '../services/gmail_api_service.dart';
import '../services/operation_queue.dart';
import '../services/connectivity_manager.dart';
import '../models/pending_operation.dart';
import '../utils/preview_extractor.dart';
import '../services/conversation_manager.dart';
import '../services/advanced_email_cache_service.dart';
import '../services/cache_maintenance_service.dart';
import '../models/conversation.dart';
import '../services/spam_detection_service.dart';

/// A provider class that manages the state of the email application.
///
/// This class is responsible for handling all the business logic of the application,
/// including user authentication, fetching and sending emails, and managing the
/// local cache.
class EmailProvider extends ChangeNotifier {
  // --- Private Properties ---

  final AuthService _authService = AuthService();
  final FinalEmailService _emailService = FinalEmailService();
  final OperationQueue _operationQueue = OperationQueue();
  final ConnectivityManager _connectivityManager = ConnectivityManager();
  final AdvancedEmailCacheService _cacheService = AdvancedEmailCacheService();
  final CacheMaintenanceService _maintenanceService = CacheMaintenanceService();

  Box<models.EmailAccount>? _accountsBox;
  Box<EmailMessage>? _messagesBox;

  List<models.EmailAccount> _accounts = [];
  models.EmailAccount? _currentAccount;
  List<EmailMessage> _messages = [];
  EmailFolder _currentFolder = EmailFolder.inbox;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // In-memory cache for faster email access.
  final Map<String, Map<EmailFolder, List<EmailMessage>>> _accountEmailCache = {};
  final Map<String, DateTime> _lastSyncTime = {};

  // Background sync debouncing
  Timer? _backgroundSyncTimer;

  // Search functionality
  bool _isSearching = false;
  String _searchQuery = '';
  List<EmailMessage> _searchResults = [];
  List<EmailMessage> _originalMessages = [];

  // Conversation threading
  final ConversationManager _conversationManager = ConversationManager();
  bool _conversationMode = true;
  List<Conversation> _conversations = [];
  List<Conversation> _originalConversations = [];

  // --- Public Properties ---

  /// A list of all the email accounts added to the application.
  List<models.EmailAccount> get accounts => _accounts;

  /// The currently selected email account.
  models.EmailAccount? get currentAccount => _currentAccount;

  /// A list of emails for the current account and folder.
  List<EmailMessage> get messages => _messages;

  /// The currently selected email folder.
  EmailFolder get currentFolder => _currentFolder;

  /// Whether the application is currently busy with a task.
  bool get isLoading => _isLoading;

  /// The last error that occurred, if any.
  String? get error => _error;

  /// Whether the provider has finished initialization and cached emails are loaded.
  bool get isInitialized => _isInitialized;

  /// Network connectivity status
  bool get isOnline => _connectivityManager.isOnline;
  bool get isOffline => _connectivityManager.isOffline;
  String get connectivityStatus => _connectivityManager.connectivityStatus;

  /// Operation queue status
  bool get hasPendingOperations => _operationQueue.hasPendingOperations;
  int get pendingOperationsCount => _operationQueue.pendingOperations.length;

  /// Spam detection settings and results
  final Map<String, SpamDetectionResult> _spamResults = {};
  bool _spamDetectionEnabled = true;
  bool get spamDetectionEnabled => _spamDetectionEnabled;

  /// Search functionality status
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;

  /// Conversation threading status
  bool get conversationMode => _conversationMode;
  List<Conversation> get conversations => _conversations;

  /// Initializes the email provider.
  ///
  /// This method should be called once when the application starts. It initializes
  /// the Hive database, registers the necessary adapters, and loads the stored
  /// email accounts.
  Future<void> initialize() async {
    debugPrint('EmailProvider: Starting fast initialization...');

    await Hive.initFlutter();

    // Initialize advanced cache service
    await _cacheService.initialize();
    debugPrint('EmailProvider: Advanced cache service initialized');

    // Register Hive adapters for data models.
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(models.EmailAccountAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(models.EmailProviderAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(EmailMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(EmailFolderAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(EmailAttachmentAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(OperationTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(PendingOperationAdapter());
    }

    // Open Hive boxes for storing data.
    _accountsBox = await Hive.openBox<models.EmailAccount>('accounts');
    _messagesBox = await Hive.openBox<EmailMessage>('messages');

    // Load stored accounts from the database.
    _accounts = _accountsBox!.values.toList();
    if (_accounts.isNotEmpty) {
      _currentAccount = _accounts.first;
      debugPrint('EmailProvider: Found account ${_currentAccount!.email}, loading cached emails...');
    }

    // FAST PATH: Pre-load ALL cached emails into memory for instant access
    await _preloadAllCachedEmails();

    // IMMEDIATE UI UPDATE: Load cached emails for current view right now
    if (_currentAccount != null) {
      _loadAccountCachedEmails(_currentAccount!.id, _currentFolder);
      debugPrint('EmailProvider: Loaded ${_messages.length} cached emails for immediate display');
    } else {
      // Even without accounts, show any cached emails that might exist
      _loadAllCachedEmails();
    }

    // Mark as initialized IMMEDIATELY so UI shows cached content
    _isInitialized = true;
    notifyListeners();
    debugPrint('EmailProvider: Fast initialization complete, UI updated with cached content');

    // Pre-load common folders for instant switching
    if (_currentAccount != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _preloadCommonFolders(_currentAccount!);
      });
    }

    // BACKGROUND OPERATIONS: Do all network operations asynchronously without blocking
    Future.microtask(() async {
      debugPrint('EmailProvider: Starting background operations...');

      try {
        // Initialize network services in background
        if (_currentAccount != null) {
          await _initializeNetworkServicesBackground();
        }

        // Initialize operation queue and connectivity manager in background
        await _initializeServicesBackground();

        // Start background cache maintenance
        _initializeCacheMaintenanceBackground();

        debugPrint('EmailProvider: All background initialization completed');
      } catch (e) {
        debugPrint('EmailProvider: Background initialization failed: $e');
        // Don't set error - the app is still functional with cached content
      }
    });
  }

  /// Sets the loading state of the application.
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets the error message for the application.
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// Adds an account to the provider.
  Future<void> addAccount(models.EmailAccount account) async {
    // Check if the account already exists
    final existingAccount = _accounts.firstWhere(
      (existingAcc) => existingAcc.email.toLowerCase() == account.email.toLowerCase(),
      orElse: () => models.EmailAccount.empty(),
    );

    if (existingAccount.id.isNotEmpty) {
      throw Exception('Account ${account.email} is already added.');
    }

    // Add to storage and memory
    await _accountsBox!.put(account.id, account);
    _accounts.add(account);
    _currentAccount = account;
    notifyListeners();

    // Fetch emails after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      fetchEmails();
    });
  }

  /// Signs in the user with their Google account.
  Future<bool> signInWithGoogle() async {
    debugPrint('📧 EmailProvider: Starting Google Sign-In process...');
    setLoading(true);
    setError(null);

    try {
      debugPrint('📧 EmailProvider: Calling AuthService.signInWithGoogle()...');
      final account = await _authService.signInWithGoogle();

      debugPrint('📧 EmailProvider: AuthService returned account: ${account?.email ?? 'null'}');

      if (account != null) {
        debugPrint('📧 EmailProvider: Checking for existing account...');
        // Check if the account already exists.
        final existingAccount = _accounts.firstWhere(
          (existingAcc) => existingAcc.email.toLowerCase() == account.email.toLowerCase(),
          orElse: () => models.EmailAccount.empty(),
        );

        if (existingAccount.id.isNotEmpty) {
          debugPrint('❌ EmailProvider: Account ${account.email} already exists');
          setError('Account ${account.email} is already added. Please choose a different account.');
          return false;
        }

        debugPrint('📧 EmailProvider: Storing account in Hive box...');
        await _accountsBox!.put(account.id, account);

        debugPrint('📧 EmailProvider: Adding account to provider lists...');
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();

        debugPrint('📧 EmailProvider: Scheduling email fetch...');
        // Fetch emails after a short delay to ensure the Gmail API is ready.
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchEmails();
        });

        debugPrint('✅ EmailProvider: Google Sign-In completed successfully');
        return true;
      } else {
        debugPrint('⚠️ EmailProvider: AuthService returned null (user likely cancelled)');
        return false;
      }
    } catch (e) {
      debugPrint('❌ EmailProvider: Google Sign-In failed with error: $e');
      debugPrint('❌ EmailProvider: Error type: ${e.runtimeType}');
      setError('Failed to sign in with Google: $e');
      return false;
    } finally {
      debugPrint('📧 EmailProvider: Setting loading to false');
      setLoading(false);
    }
  }

  /// Signs in with an Outlook account using email and password.
  Future<bool> signInWithOutlook(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithOutlook(email, password);
      if (account != null) {
        // Check if the account already exists.
        final existingAccount = _accounts.firstWhere(
          (existingAcc) => existingAcc.email.toLowerCase() == account.email.toLowerCase(),
          orElse: () => models.EmailAccount.empty(),
        );

        if (existingAccount.id.isNotEmpty) {
          setError('Account ${account.email} is already added. Please choose a different account.');
          return false;
        }

        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();

        // Fetch emails after a short delay.
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchEmails();
        });

        return true;
      }
    } catch (e) {
      setError('Failed to sign in with Outlook: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  /// Signs in with a Yahoo account using OAuth.
  Future<bool> signInWithYahoo() async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithYahoo();
      if (account != null) {
        // Check if the account already exists.
        final existingAccount = _accounts.firstWhere(
          (existingAcc) => existingAcc.email.toLowerCase() == account.email.toLowerCase(),
          orElse: () => models.EmailAccount.empty(),
        );

        if (existingAccount.id.isNotEmpty) {
          setError('Account ${account.email} is already added. Please choose a different account.');
          return false;
        }

        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();

        // Fetch emails after a short delay.
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchEmails();
        });

        return true;
      }
    } catch (e) {
      setError('Failed to sign in with Yahoo: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  /// Adds a custom email account with manual server configuration.
  Future<bool> addCustomEmailAccount({
    required String name,
    required String email,
    required String password,
    required String imapServer,
    required int imapPort,
    required String smtpServer,
    required int smtpPort,
    required bool isSSL,
  }) async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.addCustomEmailAccount(
        name: name,
        email: email,
        password: password,
        imapServer: imapServer,
        imapPort: imapPort,
        smtpServer: smtpServer,
        smtpPort: smtpPort,
        isSSL: isSSL,
      );

      if (account != null) {
        // Check if the account already exists.
        final existingAccount = _accounts.firstWhere(
          (existingAcc) => existingAcc.email.toLowerCase() == account.email.toLowerCase(),
          orElse: () => models.EmailAccount.empty(),
        );

        if (existingAccount.id.isNotEmpty) {
          setError('Account ${account.email} is already added. Please choose a different account.');
          return false;
        }

        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();

        // Fetch emails after a short delay.
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchEmails();
        });

        return true;
      }
    } catch (e) {
      setError('Failed to add custom email account: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  /// Switches the current email account and loads its cached emails immediately.
  void switchAccount(models.EmailAccount account) {
    debugPrint('EmailProvider: Switching to account ${account.email}...');

    // Clear search when switching accounts
    clearSearch();

    // Reset infinite scroll state
    _resetInfiniteScroll();

    // Update current account FIRST
    _currentAccount = account;

    // Reset to inbox folder when switching accounts (common UX pattern)
    _currentFolder = EmailFolder.inbox;

    debugPrint('EmailProvider: INSTANT loading data for account ${account.email} (${account.id})...');

    // INSTANT SWITCH: Load cached emails/conversations immediately and synchronously
    if (_conversationMode) {
      // For conversation mode, load synchronously by checking cache directly
      final cachedMessages = _accountEmailCache[account.id]?[_currentFolder] ?? [];
      final accountMessages = cachedMessages.where((msg) => msg.accountId == account.id).toList();

      if (accountMessages.isNotEmpty) {
        // Use synchronous conversation grouping for instant switch
        _loadConversationsForCurrentContextSync(accountMessages, account.id);
      } else {
        _conversations.clear();
      }
      _messages.clear(); // Clear messages when in conversation mode
    } else {
      // For message mode, load instantly from cache
      _loadAccountCachedEmails(account.id, _currentFolder);
      _conversations.clear(); // Clear conversations when in message mode
    }

    // Update last sync time if available
    final lastSync = _lastSyncTime[account.id];
    if (lastSync != null) {
      debugPrint('EmailProvider: Last sync for ${account.email}: $lastSync');
    }

    // Notify listeners immediately with new account's cached data
    notifyListeners();
    debugPrint('EmailProvider: INSTANT switch complete for ${account.email} - ${_conversationMode ? _conversations.length : _messages.length} items shown');

    // Start background sync for this account (non-blocking)
    _scheduleBackgroundSync();

    // Pre-fetch other common folders in the background for instant switching
    _preloadCommonFolders(account);
  }

  /// Pre-loads common folders for instant folder switching
  void _preloadCommonFolders(models.EmailAccount account) {
    final commonFolders = [EmailFolder.inbox, EmailFolder.sent, EmailFolder.drafts, EmailFolder.spam];

    // Schedule folder preloading after a short delay
    Future.delayed(const Duration(seconds: 2), () async {
      for (final folder in commonFolders) {
        if (_currentAccount?.id == account.id && folder != _currentFolder) {
          try {
            debugPrint('EmailProvider: Pre-loading folder ${folder.name} for instant switching...');
            final emails = await _fetchEmailsForAccount(account, folder, limit: 25);
            _mergeEmailsWithCache(account.id, folder, emails);
          } catch (e) {
            debugPrint('EmailProvider: Error pre-loading folder ${folder.name}: $e');
          }

          // Small delay between folder loads to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    });
  }

  /// Switches the current email folder.
  void switchFolder(EmailFolder folder) {
    if (_currentFolder != folder) {
      debugPrint('EmailProvider: Switching to folder ${folder.name}...');

      // Clear search when switching folders
      clearSearch();

      // Reset infinite scroll state
      _resetInfiniteScroll();

      _currentFolder = folder;

      // INSTANT LOAD: Load cached emails or conversations for the new folder instantly
      if (_currentAccount != null) {
        if (_conversationMode) {
          // Use synchronous method for instant folder switching
          final cachedMessages = _accountEmailCache[_currentAccount!.id]?[folder] ?? [];
          final accountMessages = cachedMessages.where((msg) => msg.accountId == _currentAccount!.id).toList();
          _loadConversationsForCurrentContextSync(accountMessages, _currentAccount!.id);
        } else {
          // Load cached emails for current account and new folder instantly
          _loadAccountCachedEmails(_currentAccount!.id, folder);
        }
      } else {
        // In offline mode, load all cached emails for this folder
        _loadAllCachedEmailsForFolder(folder);
      }

      // Notify UI immediately with cached content
      notifyListeners();

      // Debounced background sync to avoid interfering with instant switching
      _scheduleBackgroundSync();
    }
  }

  /// Fetches emails for the current account and folder.
  Future<void> fetchEmails({int limit = 50, bool forceRefresh = false}) async {
    debugPrint('📬 EmailProvider: fetchEmails called with limit=$limit, forceRefresh=$forceRefresh');

    if (_currentAccount == null) {
      debugPrint('❌ EmailProvider: No current account set, cannot fetch emails');
      return;
    }

    debugPrint('📬 EmailProvider: Fetching emails for account: ${_currentAccount!.email}');
    debugPrint('📬 EmailProvider: Current folder: ${_currentFolder.name}');
    debugPrint('📬 EmailProvider: Account provider: ${_currentAccount!.provider}');

    setLoading(true);
    setError(null);

    try {
      // ALWAYS load cached emails first for offline-first experience
      debugPrint('📬 EmailProvider: Loading cached emails first...');
      _loadAccountCachedEmails(_currentAccount!.id, _currentFolder);
      debugPrint('📬 EmailProvider: Current cached emails count: ${_messages.length}');


      // Show cached emails immediately
      notifyListeners();

      // Check connectivity before attempting server fetch
      if (!_connectivityManager.isOnline && !forceRefresh) {
        debugPrint('📬 EmailProvider: Offline mode - showing cached emails only');
        setLoading(false);
        return;
      }

      // Only fetch from server if online or force refresh
      if (_connectivityManager.isOnline || forceRefresh) {
        debugPrint('📬 EmailProvider: Fetching fresh emails from server...');
        final emails = await _fetchEmailsForAccount(_currentAccount!, _currentFolder, limit: limit);

        if (emails.isNotEmpty) {
          debugPrint('📬 EmailProvider: Fetched ${emails.length} fresh emails from server');

          // Merge the new emails with the cache.
          debugPrint('📬 EmailProvider: Merging new emails with cache...');
          _mergeEmailsWithCache(_currentAccount!.id, _currentFolder, emails);

          debugPrint('📬 EmailProvider: After merge, total emails: ${_messages.length}');

          // Update the last sync time.
          _lastSyncTime[_currentAccount!.id] = DateTime.now();
          debugPrint('📬 EmailProvider: Updated last sync time for account');

          notifyListeners();
        } else {
          debugPrint('📬 EmailProvider: No new emails fetched, keeping cached emails');
        }
      }

      // Start IMAP IDLE for real-time notifications (for non-Gmail accounts)
      if (_currentAccount!.provider != models.EmailProvider.gmail) {
        debugPrint('📬 EmailProvider: Starting IMAP IDLE for real-time notifications');
        await _emailService.startIdling(
          onNewMessage: (newEmail) {
            debugPrint('📬 Real-time email received: ${newEmail.subject}');
            // Add new email to the list
            _messages.insert(0, newEmail);
            notifyListeners();
          },
        );
      }

      debugPrint('✅ EmailProvider: fetchEmails completed successfully');
    } catch (e) {
      debugPrint('❌ EmailProvider: fetchEmails failed with error: $e');
      debugPrint('❌ EmailProvider: Error type: ${e.runtimeType}');
      setError('Failed to fetch emails: $e');
    } finally {
      setLoading(false);
      debugPrint('📬 EmailProvider: Setting loading to false');
    }
  }

  // Gmail-style infinite scroll loading
  bool _isLoadingMore = false;
  bool _hasMoreEmails = true;
  int _currentEmailLimit = 15; // Start with 15 emails for faster initial load

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreEmails => _hasMoreEmails;

  /// Loads more emails for Gmail-style infinite scroll
  Future<void> loadMoreEmails() async {
    debugPrint('📬 EmailProvider: loadMoreEmails called');

    if (_currentAccount == null) {
      debugPrint('❌ EmailProvider: No current account set');
      return;
    }

    if (_isLoadingMore) {
      debugPrint('❌ EmailProvider: Already loading more emails');
      return;
    }

    if (!_hasMoreEmails) {
      debugPrint('❌ EmailProvider: No more emails available');
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      debugPrint('📬 EmailProvider: Current emails count: ${_messages.length}');
      final previousEmailCount = _messages.length;

      // Increase the limit to fetch more emails
      _currentEmailLimit += 15; // Load 15 more emails at a time
      debugPrint('📬 EmailProvider: New limit: $_currentEmailLimit');

      // Use progressive loading for infinite scroll too
      await _loadMoreEmailsProgressively(_currentAccount!, _currentFolder,
          previousCount: previousEmailCount, newLimit: _currentEmailLimit);

      debugPrint('✅ EmailProvider: loadMoreEmails completed successfully');
    } catch (e) {
      debugPrint('❌ EmailProvider: loadMoreEmails failed: $e');
      setError('Failed to load more emails: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Reset infinite scroll state when switching folders or accounts
  void _resetInfiniteScroll() {
    _isLoadingMore = false;
    _hasMoreEmails = true;
    _currentEmailLimit = 15; // Start with 15 emails for consistency
  }

  /// Sends an email.
  Future<bool> sendEmail({
    required String to,
    String? cc,
    String? bcc,
    required String subject,
    required String body,
    List<String>? attachmentPaths,
  }) async {
    if (_currentAccount == null) return false;

    setLoading(true);
    setError(null);

    try {
      bool success;

      if (_currentAccount!.provider == models.EmailProvider.gmail) {
        // Use the Gmail API for Gmail accounts.
        final gmailService = AuthService.getGmailApiService();
        if (gmailService == null) {
          throw Exception('Gmail API service not initialized');
        }

        success = await gmailService.sendEmail(
          to: to,
          cc: cc,
          bcc: bcc,
          subject: subject,
          body: body,
          attachmentPaths: attachmentPaths,
        );
      } else {
        // Use SMTP for other email providers.
        success = await _emailService.sendEmail(
          account: _currentAccount!,
          to: to,
          cc: cc,
          bcc: bcc,
          subject: subject,
          body: body,
          attachmentPaths: attachmentPaths,
        );
      }

      if (!success) {
        setError('Failed to send email');
      }

      return success;
    } catch (e) {
      setError('Failed to send email: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  /// Marks an email as read with optimistic UI updates
  Future<void> markAsRead(EmailMessage message) async {
    if (_currentAccount == null) return;

    try {
      // 1. Optimistic UI update - update immediately
      message.isRead = true;
      await _messagesBox?.put(message.messageId, message);
      notifyListeners();

      // 2. Queue operation for server sync
      await _operationQueue.queueOperation(
        operationType: OperationType.markRead,
        emailId: message.messageId,
        data: {},
        accountId: _currentAccount!.id,
      );

      // 3. If online, the operation queue will process immediately
      // If offline, it will sync when connectivity returns
    } catch (e) {
      // Rollback on failure
      message.isRead = false;
      await _messagesBox?.put(message.messageId, message);
      notifyListeners();
      setError('Failed to mark email as read: $e');
    }
  }

  /// Archives an email with optimistic UI updates
  Future<void> archiveEmail(EmailMessage message) async {
    if (_currentAccount == null) return;

    // Store original index for rollback
    final emailIndex = _messages.indexWhere((m) => m.messageId == message.messageId);

    try {
      // 1. Optimistic UI update - remove from current view (usually inbox)
      if (emailIndex != -1) {
        _messages.removeAt(emailIndex);
        notifyListeners();
      }

      // 2. Queue operation for server sync
      await _operationQueue.queueOperation(
        operationType: OperationType.archive,
        emailId: message.messageId,
        data: {},
        accountId: _currentAccount!.id,
      );

      // 3. If online, the operation queue will process immediately
      // If offline, it will sync when connectivity returns
    } catch (e) {
      // Rollback on failure - add back to list
      if (emailIndex != -1) {
        _messages.insert(emailIndex, message);
        notifyListeners();
      }
      setError('Failed to archive email: $e');
    }
  }

  /// Deletes an email with optimistic UI updates
  Future<void> deleteEmail(EmailMessage message) async {
    if (_currentAccount == null) return;

    // Store original index for rollback
    final emailIndex = _messages.indexWhere((m) => m.messageId == message.messageId);

    try {
      // 1. Optimistic UI update - remove from UI immediately
      if (emailIndex != -1) {
        _messages.removeAt(emailIndex);
        await _messagesBox?.delete(message.messageId);
        notifyListeners();
      }

      // 2. Queue operation for server sync
      await _operationQueue.queueOperation(
        operationType: OperationType.delete,
        emailId: message.messageId,
        data: {},
        accountId: _currentAccount!.id,
      );

      // 3. If online, the operation queue will process immediately
      // If offline, it will sync when connectivity returns
    } catch (e) {
      // Rollback on failure - add back to list
      if (emailIndex != -1) {
        _messages.insert(emailIndex, message);
        await _messagesBox?.put(message.messageId, message);
        notifyListeners();
      }
      setError('Failed to delete email: $e');
    }
  }

  /// Snoozes an email until a specific date and time
  Future<void> snoozeEmail(EmailMessage message, DateTime snoozeUntil) async {
    if (_currentAccount == null) return;

    // Store original index for rollback
    final emailIndex = _messages.indexWhere((m) => m.messageId == message.messageId);

    try {
      // 1. Optimistic UI update - remove from current view and set snooze
      message.snoozeUntil = snoozeUntil;

      if (emailIndex != -1) {
        _messages.removeAt(emailIndex);
        notifyListeners();
      }

      // Update in storage
      await _messagesBox?.put(message.messageId, message);

      // 2. Queue operation for server sync (if supported by email provider)
      await _operationQueue.queueOperation(
        operationType: OperationType.snooze,
        emailId: message.messageId,
        data: {'snoozeUntil': snoozeUntil.toIso8601String()},
        accountId: _currentAccount!.id,
      );

      // 3. Schedule auto-unsnooze
      _scheduleUnsnooze(message, snoozeUntil);

    } catch (e) {
      // Rollback on failure
      message.snoozeUntil = null;
      if (emailIndex != -1) {
        _messages.insert(emailIndex, message);
        await _messagesBox?.put(message.messageId, message);
        notifyListeners();
      }
      setError('Failed to snooze email: $e');
    }
  }

  /// Unsnoozes an email (makes it visible again)
  Future<void> unsnoozeEmail(EmailMessage message) async {
    try {
      // Clear snooze information
      message.snoozeUntil = null;

      // Add back to current view if it belongs to current folder
      if (message.folder == _currentFolder) {
        if (!_messages.any((m) => m.messageId == message.messageId)) {
          _messages.add(message);
          _messages.sort((a, b) => b.date.compareTo(a.date));
          notifyListeners();
        }
      }

      // Update in storage
      await _messagesBox?.put(message.messageId, message);

    } catch (e) {
      setError('Failed to unsnooze email: $e');
    }
  }

  /// Gets all snoozed emails
  List<EmailMessage> getSnoozedEmails() {
    return _messages.where((message) => message.isSnoozed).toList();
  }

  /// Gets emails that should be unsnoozed (snooze time has passed)
  List<EmailMessage> getEmailsToUnsnooze() {
    final now = DateTime.now();
    return _messages.where((message) =>
      message.snoozeUntil != null &&
      message.snoozeUntil!.isBefore(now)
    ).toList();
  }

  /// Checks for and unsnoozes emails whose snooze time has passed
  Future<void> checkAndUnsnoozeEmails() async {
    final emailsToUnsnooze = getEmailsToUnsnooze();

    for (final message in emailsToUnsnooze) {
      await unsnoozeEmail(message);
    }

    if (emailsToUnsnooze.isNotEmpty) {
      debugPrint('Unsnoozed ${emailsToUnsnooze.length} emails');
    }
  }

  /// Schedules auto-unsnooze for an email
  void _scheduleUnsnooze(EmailMessage message, DateTime snoozeUntil) {
    final duration = snoozeUntil.difference(DateTime.now());
    if (duration.isNegative) return;

    Timer(duration, () {
      unsnoozeEmail(message);
    });
  }

  /// Analyzes an email for spam and phishing content
  void _analyzeEmailForSpam(EmailMessage email) {
    try {
      final result = SpamDetectionService.analyzeEmail(email);
      _spamResults[email.messageId] = result;

      if (result.isSuspicious) {
        debugPrint('🚨 Suspicious email detected: ${email.subject}');
        debugPrint('   Risk: ${result.riskSummary}');
        debugPrint('   Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%');
        if (result.detectedPatterns.isNotEmpty) {
          debugPrint('   Patterns: ${result.detectedPatterns.join(', ')}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error analyzing email for spam: $e');
    }
  }

  /// Gets spam detection result for an email
  SpamDetectionResult? getSpamResult(String messageId) {
    return _spamResults[messageId];
  }

  /// Toggles spam detection on/off
  void toggleSpamDetection(bool enabled) {
    _spamDetectionEnabled = enabled;
    notifyListeners();
  }

  /// Gets all emails flagged as suspicious
  List<EmailMessage> getSuspiciousEmails() {
    return _messages.where((email) {
      final result = _spamResults[email.messageId];
      return result?.isSuspicious == true;
    }).toList();
  }


  /// Caches emails to Hive storage after fetching from server
  Future<void> _cacheEmails(List<EmailMessage> emails, String accountId, EmailFolder folder) async {
    try {
      debugPrint('💾 CacheStore: Caching ${emails.length} emails for $accountId/$folder');
      final stopwatch = Stopwatch()..start();

      // Store each email in Hive
      for (final email in emails) {
        await _messagesBox?.put(email.messageId, email);
      }

      stopwatch.stop();
      debugPrint('💾 CacheStore: Cached ${emails.length} emails in ${stopwatch.elapsedMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ CacheStore: Error caching emails: $e');
    }
  }

  /// Background sync of emails (non-blocking)
  Future<void> backgroundSyncEmails() async {
    if (_currentAccount == null) return;

    debugPrint('🔄 BackgroundSync: Starting background email sync...');
    try {
      // Fetch new emails from server
      final newEmails = await _fetchEmailsForAccount(
        _currentAccount!,
        _currentFolder,
        limit: 50,
      );

      // Cache the new emails
      await _cacheEmails(newEmails, _currentAccount!.id, _currentFolder);

      // Update UI with new emails (merge with existing)
      _mergeNewEmails(newEmails);

      debugPrint('✅ BackgroundSync: Completed successfully, updated UI with ${newEmails.length} new emails');
    } catch (e) {
      debugPrint('❌ BackgroundSync: Failed with error: $e');
      // Don't show error to user for background sync - just log it
    }
  }

  /// Merges new emails with existing cached emails and updates UI
  void _mergeNewEmails(List<EmailMessage> newEmails) {
    try {
      // Create a map for fast lookup of existing emails
      final existingIds = Set<String>.from(_messages.map((e) => e.messageId));

      // Add only truly new emails
      final trulyNewEmails = newEmails.where((email) => !existingIds.contains(email.messageId)).toList();

      if (trulyNewEmails.isNotEmpty) {
        _messages.addAll(trulyNewEmails);

        // Re-sort by date (newest first)
        _messages.sort((a, b) => b.date.compareTo(a.date));

        // Notify UI of updates
        notifyListeners();

        debugPrint('📧 MergeEmails: Added ${trulyNewEmails.length} new emails to UI');
      } else {
        debugPrint('📧 MergeEmails: No new emails to add');
      }
    } catch (e) {
      debugPrint('❌ MergeEmails: Error merging emails: $e');
    }
  }

  /// Syncs emails with the server
  Future<void> syncEmails() async {
    if (_currentAccount == null) return;

    try {
      setLoading(true);
      setError(null);

      // First load cached emails to show immediately
      _loadAccountCachedEmails(_currentAccount!.id, _currentFolder);
      notifyListeners();

      // Then fetch fresh emails from server progressively
      await _fetchEmailsProgressively(_currentAccount!, _currentFolder, limit: _currentEmailLimit);
      _lastSyncTime[_currentAccount!.id] = DateTime.now();
    } catch (e) {
      setError('Failed to sync emails: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Removes an account
  Future<void> removeAccount(String accountId) async {
    try {
      _accounts.removeWhere((account) => account.id == accountId);
      await _accountsBox?.delete(accountId);

      // If this was the current account, switch to another or clear
      if (_currentAccount?.id == accountId) {
        _currentAccount = _accounts.isNotEmpty ? _accounts.first : null;
        _messages.clear();
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to remove account: $e');
    }
  }

  /// Signs out the current user and clears all data.
  Future<void> signOut() async {
    await _authService.signOut();
    await _accountsBox!.clear();
    await _messagesBox!.clear();
    _accounts.clear();
    _currentAccount = null;
    _messages.clear();
    notifyListeners();
  }



  // --- Private Helper Methods ---

  /// Pre-loads all cached emails into memory for fast access
  Future<void> _preloadAllCachedEmails() async {
    try {
      debugPrint('EmailProvider: Pre-loading all cached emails into memory...');

      final allEmails = _messagesBox?.values.toList() ?? [];
      debugPrint('EmailProvider: Found ${allEmails.length} total cached emails');

      if (allEmails.isEmpty) {
        debugPrint('EmailProvider: No cached emails found in Hive database');
        return;
      }

      // Group emails by account and folder for fast lookup
      for (final email in allEmails) {
        final accountId = email.accountId;
        final folder = email.folder;

        // Generate preview text if missing (for existing cached emails)
        if (email.previewText == null || email.previewText!.isEmpty) {
          email.previewText = PreviewExtractor.extractPreview(
            htmlContent: email.htmlBody,
            textContent: email.textBody,
            maxLength: 150,
          );
          // Save the updated email back to Hive
          _messagesBox?.put(email.messageId, email);
        }

        // Initialize nested maps if they don't exist
        if (!_accountEmailCache.containsKey(accountId)) {
          _accountEmailCache[accountId] = {};
        }
        if (!_accountEmailCache[accountId]!.containsKey(folder)) {
          _accountEmailCache[accountId]![folder] = [];
        }

        _accountEmailCache[accountId]![folder]!.add(email);
      }

      // Sort all cached emails by date (newest first)
      for (final accountCache in _accountEmailCache.values) {
        for (final folderEmails in accountCache.values) {
          folderEmails.sort((a, b) => b.date.compareTo(a.date));
        }
      }

      debugPrint('EmailProvider: Cached emails loaded for ${_accountEmailCache.length} accounts');

      // Debug: Print cache contents
      for (final accountId in _accountEmailCache.keys) {
        for (final folder in _accountEmailCache[accountId]!.keys) {
          final emailCount = _accountEmailCache[accountId]![folder]!.length;
          debugPrint('EmailProvider: Account $accountId, folder ${folder.name}: $emailCount emails');
        }
      }
    } catch (e) {
      debugPrint('EmailProvider: Error pre-loading cached emails: $e');
    }
  }

  /// Initialize network services in background without blocking startup
  Future<void> _initializeNetworkServicesBackground() async {
    debugPrint('EmailProvider: Initializing network services in background...');

    try {
      if (_currentAccount?.provider == models.EmailProvider.gmail) {
        debugPrint('EmailProvider: Initializing Gmail service in background...');
        await _reinitializeGmailServiceOnStartup();
        debugPrint('EmailProvider: Gmail service initialized, starting background sync...');

        // Start background sync after Gmail service is ready
        Future.microtask(() => _syncEmailsInBackground());
      } else if (_currentAccount?.provider == models.EmailProvider.yahoo) {
        debugPrint('EmailProvider: Yahoo account detected, starting background sync...');
        // For Yahoo and other accounts, try to sync emails in the background
        Future.microtask(() => _syncEmailsInBackground());
      } else {
        debugPrint('EmailProvider: No supported provider found for background sync');
      }
    } catch (e) {
      debugPrint('EmailProvider: Network services initialization failed (continuing with cached content): $e');
      // Don't propagate error - app should work with cached content even if network fails
    }
  }

  /// Initialize operation queue and connectivity manager in background
  Future<void> _initializeServicesBackground() async {
    try {
      await _operationQueue.initialize();
      await _connectivityManager.initialize();

      // Set up connectivity change callbacks
      _connectivityManager.onConnected = () {
        // When back online, process pending operations
        _operationQueue.processPendingOperations();
        notifyListeners();
      };

      _connectivityManager.onDisconnected = () {
        notifyListeners();
      };
    } catch (e) {
      debugPrint('EmailProvider: Error initializing services: $e');
    }
  }

  /// Loads cached emails from the in-memory cache (fast, synchronous).
  void _loadAccountCachedEmails(String accountId, EmailFolder folder) {
    try {
      debugPrint('EmailProvider: Loading cached emails for account $accountId, folder ${folder.name}...');

      // Debug: Print available accounts in cache
      debugPrint('EmailProvider: Available account IDs in cache: ${_accountEmailCache.keys.toList()}');

      // Get emails from fast in-memory cache
      final cachedEmails = _accountEmailCache[accountId]?[folder] ?? [];
      _messages = List.from(cachedEmails);

      // Verify account isolation
      final wrongAccountEmails = _messages.where((email) => email.accountId != accountId).toList();
      if (wrongAccountEmails.isNotEmpty) {
        debugPrint('WARNING: Found ${wrongAccountEmails.length} emails from wrong account!');
        // Filter out emails from wrong accounts as a safety measure
        _messages = _messages.where((email) => email.accountId == accountId).toList();
      }

      // Verify folder isolation
      final wrongFolderEmails = _messages.where((email) => email.folder != folder).toList();
      if (wrongFolderEmails.isNotEmpty) {
        debugPrint('WARNING: Found ${wrongFolderEmails.length} emails from wrong folder!');
        // Filter out emails from wrong folders as a safety measure
        _messages = _messages.where((email) => email.folder == folder).toList();
      }

      debugPrint('EmailProvider: Set ${_messages.length} emails for current view (account: $accountId, folder: ${folder.name})');
    } catch (e) {
      debugPrint('EmailProvider: Error loading cached emails: $e');
      _messages = [];
    }
  }

  /// Loads all cached emails regardless of account (for offline access).
  void _loadAllCachedEmails() {
    try {
      debugPrint('EmailProvider: Loading all cached emails for offline access...');

      final allEmails = <EmailMessage>[];

      // Collect emails from all accounts and folders
      for (final accountCache in _accountEmailCache.values) {
        for (final folderEmails in accountCache.values) {
          allEmails.addAll(folderEmails);
        }
      }

      // Sort by date (newest first)
      allEmails.sort((a, b) => b.date.compareTo(a.date));

      _messages = allEmails;
      debugPrint('EmailProvider: Set ${_messages.length} cached emails for offline viewing');
    } catch (e) {
      debugPrint('EmailProvider: Error loading all cached emails: $e');
      _messages = [];
    }
  }

  /// Loads cached emails for a specific folder from all accounts (for offline folder switching).
  void _loadAllCachedEmailsForFolder(EmailFolder folder) {
    try {
      debugPrint('EmailProvider: Loading cached emails for folder ${folder.name} from all accounts...');

      final folderEmails = <EmailMessage>[];

      // Collect emails from all accounts for this specific folder
      for (final accountCache in _accountEmailCache.values) {
        final emails = accountCache[folder] ?? [];
        folderEmails.addAll(emails);
      }

      // Sort by date (newest first)
      folderEmails.sort((a, b) => b.date.compareTo(a.date));

      _messages = folderEmails;
      debugPrint('EmailProvider: Set ${_messages.length} cached emails for folder ${folder.name}');
    } catch (e) {
      debugPrint('EmailProvider: Error loading cached emails for folder: $e');
      _messages = [];
    }
  }

  /// Syncs emails in the background without blocking the UI.
  /// Schedule background sync with debouncing to avoid interfering with instant UI updates
  void _scheduleBackgroundSync() {
    // Cancel any existing timer
    _backgroundSyncTimer?.cancel();

    // Schedule sync after a brief delay to allow UI to update first
    _backgroundSyncTimer = Timer(const Duration(milliseconds: 300), () {
      if (_currentAccount != null) {
        _syncEmailsInBackground();
      }
    });
  }

  Future<void> _syncEmailsInBackground() async {
    if (_currentAccount == null) return;

    try {
      debugPrint('EmailProvider: Starting background sync for ${_currentAccount!.email}...');

      // For Gmail accounts, ensure the API service is initialized
      if (_currentAccount!.provider == models.EmailProvider.gmail) {
        final gmailService = AuthService.getGmailApiService();
        if (gmailService == null) {
          debugPrint('EmailProvider: Gmail API service not initialized, attempting to re-initialize...');
          await _reinitializeGmailServiceOnStartup();

          // Check again after re-initialization
          final retryGmailService = AuthService.getGmailApiService();
          if (retryGmailService == null) {
            debugPrint('EmailProvider: Failed to re-initialize Gmail API service, skipping sync');
            return;
          }
        }
      }

      // Fetch emails for the current folder
      final emails = await _fetchEmailsForAccount(_currentAccount!, _currentFolder);

      // Get previous message count
      final previousCount = _messages.length;

      // Merge with cache
      _mergeEmailsWithCache(_currentAccount!.id, _currentFolder, emails);
      _lastSyncTime[_currentAccount!.id] = DateTime.now();

      // Only notify listeners if new emails were added
      final newCount = _messages.length;
      if (newCount != previousCount) {
        debugPrint('EmailProvider: Background sync completed, added ${newCount - previousCount} new emails');
        notifyListeners();
      } else {
        debugPrint('EmailProvider: Background sync completed, no new emails');
      }
    } catch (e) {
      debugPrint('EmailProvider: Background sync failed: $e');
    }
  }

  /// Merges new emails with the cached emails, avoiding duplicates.
  void _mergeEmailsWithCache(String accountId, EmailFolder folder, List<EmailMessage> newEmails) {
    try {
      // Initialize cache for this account if it doesn't exist
      if (!_accountEmailCache.containsKey(accountId)) {
        _accountEmailCache[accountId] = {};
      }

      // Initialize folder cache if it doesn't exist
      if (!_accountEmailCache[accountId]!.containsKey(folder)) {
        _accountEmailCache[accountId]![folder] = [];
      }

      final cachedEmails = _accountEmailCache[accountId]![folder]!;

      // Create a set of existing message IDs for quick lookup
      final existingIds = cachedEmails.map((e) => e.messageId).toSet();

      // Add new emails that don't already exist
      for (final newEmail in newEmails) {
        if (!existingIds.contains(newEmail.messageId)) {
          // Generate preview text if not already present
          if (newEmail.previewText == null || newEmail.previewText!.isEmpty) {
            newEmail.previewText = PreviewExtractor.extractPreview(
              htmlContent: newEmail.htmlBody,
              textContent: newEmail.textBody,
              maxLength: 150,
            );
          }

          cachedEmails.add(newEmail);

          // Also store in Hive
          _messagesBox?.put(newEmail.messageId, newEmail);
        }
      }

      // Sort by date (newest first)
      cachedEmails.sort((a, b) => b.date.compareTo(a.date));

      // Update the current messages if this is the current account and folder
      if (_currentAccount?.id == accountId && _currentFolder == folder) {
        _messages = List.from(cachedEmails);
        debugPrint('EmailProvider: Updated current view with ${_messages.length} emails, notifying UI...');
        notifyListeners(); // Immediately notify UI when current view is updated
      }

      debugPrint('EmailProvider: Merged ${newEmails.length} new emails, total cached: ${cachedEmails.length}');
    } catch (e) {
      debugPrint('EmailProvider: Error merging emails with cache: $e');
    }
  }

  /// Fetches emails progressively in small batches for instant UI updates
  Future<void> _fetchEmailsProgressively(models.EmailAccount account, EmailFolder folder, {int limit = 15}) async {
    debugPrint('🔄 EmailProvider: Starting progressive fetch for ${account.email}');

    try {
      // Fetch emails in smaller batches
      final batchSize = 5; // 5 emails at a time
      int processed = 0;

      while (processed < limit) {
        final currentBatchLimit = (processed + batchSize > limit) ? limit - processed : batchSize;

        debugPrint('🔄 EmailProvider: Fetching batch of $currentBatchLimit emails');

        // Fetch this batch
        final batchEmails = await _fetchEmailsForAccount(account, folder, limit: processed + currentBatchLimit);

        // Get only the new emails from this batch
        List<EmailMessage> newEmails;
        if (processed == 0) {
          // First batch - take first 'currentBatchLimit' emails
          newEmails = batchEmails.take(currentBatchLimit).toList();
        } else {
          // Subsequent batches - take emails from 'processed' index onwards
          newEmails = batchEmails.skip(processed).take(currentBatchLimit).toList();
        }

        if (newEmails.isEmpty) {
          debugPrint('📧 EmailProvider: No more emails available');
          break;
        }

        // Add emails progressively to cache and UI
        for (final email in newEmails) {
          _addEmailToCache(account.id, folder, email);
        }

        // Update the UI immediately - handle both conversation and message modes
        if (_conversationMode) {
          // For conversation mode, reload and process conversations
          final accountMessages = _accountEmailCache[account.id]?[folder] ?? [];
          final filteredMessages = accountMessages.where((msg) => msg.accountId == account.id).toList();
          _loadConversationsForCurrentContextSync(filteredMessages, account.id);
        } else {
          // For message mode, load messages directly
          _loadAccountCachedEmails(account.id, folder);
        }

        notifyListeners();

        debugPrint('📧 EmailProvider: Added ${newEmails.length} emails to UI (batch ${processed ~/ batchSize + 1})');

        processed += newEmails.length;

        // Small delay to let UI render
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ EmailProvider: Progressive fetch completed, processed $processed emails');
    } catch (e) {
      debugPrint('❌ EmailProvider: Error in progressive fetch: $e');
    }
  }

  /// Loads more emails progressively for infinite scroll
  Future<void> _loadMoreEmailsProgressively(models.EmailAccount account, EmailFolder folder, {required int previousCount, required int newLimit}) async {
    debugPrint('🔄 EmailProvider: Loading more emails progressively from $previousCount to $newLimit');

    try {
      // Fetch all emails up to new limit
      final allEmails = await _fetchEmailsForAccount(account, folder, limit: newLimit);

      debugPrint('📬 EmailProvider: Fetched ${allEmails.length} total emails');

      if (allEmails.length <= previousCount) {
        // No new emails
        _hasMoreEmails = false;
        debugPrint('📬 EmailProvider: No new emails, reached end');
        return;
      }

      // Get only the new emails
      final newEmails = allEmails.skip(previousCount).toList();
      debugPrint('📬 EmailProvider: Found ${newEmails.length} new emails to add');

      // Add new emails progressively in batches of 3
      final batchSize = 3;
      for (int i = 0; i < newEmails.length; i += batchSize) {
        final batchEnd = (i + batchSize > newEmails.length) ? newEmails.length : i + batchSize;
        final batch = newEmails.sublist(i, batchEnd);

        // Add this batch to cache and messages
        for (final email in batch) {
          _addEmailToCache(account.id, folder, email);

          // Add to current messages list if it's for the current view
          if (account.id == _currentAccount?.id && folder == _currentFolder) {
            _messages.add(email);
          }
        }

        // Update UI immediately after each batch
        if (account.id == _currentAccount?.id && folder == _currentFolder) {
          // Handle both conversation and message modes for infinite scroll too
          if (_conversationMode) {
            final accountMessages = _accountEmailCache[account.id]?[folder] ?? [];
            final filteredMessages = accountMessages.where((msg) => msg.accountId == account.id).toList();
            _loadConversationsForCurrentContextSync(filteredMessages, account.id);
          } else {
            // Messages are already added above, just need to update _messages list
            _loadAccountCachedEmails(account.id, folder);
          }

          notifyListeners();
          debugPrint('📧 EmailProvider: Added batch of ${batch.length} emails (${i ~/ batchSize + 1}/${(newEmails.length / batchSize).ceil()})');
        }

        // Small delay between batches for smooth rendering
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Check if we've reached the end
      if (allEmails.length < newLimit) {
        _hasMoreEmails = false;
        debugPrint('📬 EmailProvider: Reached end of emails');
      }

      // Merge all emails with cache for persistence
      _mergeEmailsWithCache(account.id, folder, allEmails);

      debugPrint('✅ EmailProvider: Progressive load more completed, total emails: ${_messages.length}');
    } catch (e) {
      debugPrint('❌ EmailProvider: Error in progressive load more: $e');
    }
  }

  /// Adds a single email to the cache
  void _addEmailToCache(String accountId, EmailFolder folder, EmailMessage email) {
    try {
      // Add to in-memory cache
      _accountEmailCache[accountId] ??= {};
      _accountEmailCache[accountId]![folder] ??= [];

      // Check if email already exists to avoid duplicates
      final existingIndex = _accountEmailCache[accountId]![folder]!.indexWhere((e) => e.messageId == email.messageId);
      if (existingIndex == -1) {
        _accountEmailCache[accountId]![folder]!.add(email);

        // Sort by date (newest first)
        _accountEmailCache[accountId]![folder]!.sort((a, b) => b.date.compareTo(a.date));
      }

      // Add to Hive cache for persistence
      _messagesBox?.put(email.messageId, email);

    } catch (e) {
      debugPrint('❌ EmailProvider: Error adding email to cache: $e');
    }
  }

  /// Fetches emails for a specific account without updating the UI state.
  Future<List<EmailMessage>> _fetchEmailsForAccount(models.EmailAccount account, EmailFolder folder, {int limit = 15}) async {
    debugPrint('🔄 _fetchEmailsForAccount: Starting fetch for ${account.email}');
    debugPrint('🔄 _fetchEmailsForAccount: Provider: ${account.provider}, Folder: ${folder.name}, Limit: $limit');

    try {
      if (account.provider == models.EmailProvider.gmail) {
        debugPrint('🔄 _fetchEmailsForAccount: Using Gmail API service');

        // Use Gmail API service
        final gmailService = AuthService.getGmailApiService();
        debugPrint('🔄 _fetchEmailsForAccount: Gmail service available: ${gmailService != null}');

        if (gmailService != null) {
          debugPrint('🔄 _fetchEmailsForAccount: Calling gmailService.fetchEmails...');
          final emails = await gmailService.fetchEmails(
            accountId: account.email,
            maxResults: limit,
            folder: folder,
          );

          debugPrint('✅ _fetchEmailsForAccount: Gmail API returned ${emails.length} emails');

          // Analyze emails for spam/phishing if detection is enabled
          if (_spamDetectionEnabled) {
            for (final email in emails) {
              _analyzeEmailForSpam(email);
            }
          }

          // Account ID and folder are now properly set in the Gmail service
          return emails;
        } else {
          debugPrint('❌ _fetchEmailsForAccount: Gmail service is null');
        }
      } else if (account.provider == models.EmailProvider.yahoo) {
        debugPrint('🔄 _fetchEmailsForAccount: Using Yahoo API service');

        // Use Yahoo API service
        final yahooService = AuthService.getYahooApiService();
        debugPrint('🔄 _fetchEmailsForAccount: Yahoo service available: ${yahooService != null}');

        if (yahooService != null) {
          debugPrint('🔄 _fetchEmailsForAccount: Calling yahooService.fetchEmails...');
          final emails = await yahooService.fetchEmails(
            accountId: account.email,
            maxResults: limit,
            folder: folder,
          );

          debugPrint('✅ _fetchEmailsForAccount: Yahoo API returned ${emails.length} emails');
          return emails;
        } else {
          debugPrint('❌ _fetchEmailsForAccount: Yahoo service is null');
        }
      } else {
        debugPrint('⚠️ _fetchEmailsForAccount: Unsupported provider: ${account.provider}');
        // Use IMAP service for other providers (Outlook, custom)
        // For now, return empty list for non-supported accounts
        // TODO: Implement IMAP email fetching for Outlook and custom providers
        return [];
      }
    } catch (e) {
      debugPrint('❌ _fetchEmailsForAccount: Error fetching emails for account ${account.email}: $e');
      debugPrint('❌ _fetchEmailsForAccount: Error type: ${e.runtimeType}');
    }

    debugPrint('❌ _fetchEmailsForAccount: Returning empty list');
    return [];
  }

  /// Re-initializes the Gmail API service on application startup.
  Future<void> _reinitializeGmailServiceOnStartup() async {
    try {
      debugPrint('EmailProvider: Re-initializing Gmail API service on startup...');

      // Check if there's a currently signed-in Google user
      final googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/gmail.readonly',
          'https://www.googleapis.com/auth/gmail.send',
          'https://www.googleapis.com/auth/gmail.modify',
        ],
      );

      final currentUser = googleSignIn.currentUser;
      if (currentUser == null) {
        // Try to sign in silently
        final signedInUser = await googleSignIn.signInSilently();
        if (signedInUser == null) {
          debugPrint('EmailProvider: No signed-in user found on startup');
          return;
        }

        debugPrint('EmailProvider: Found silently signed-in user: ${signedInUser.email}');
        await _initializeGmailApiService(signedInUser);
      } else {
        debugPrint('EmailProvider: Found current signed-in user: ${currentUser.email}');
        await _initializeGmailApiService(currentUser);
      }
    } catch (e) {
      debugPrint('EmailProvider: Error re-initializing Gmail API service: $e');
    }
  }

  /// Helper method to initialize Gmail API service with a Google user
  Future<void> _initializeGmailApiService(GoogleSignInAccount googleUser) async {
    try {
      final gmailService = GmailApiService();
      final connected = await gmailService.connectWithGoogleSignIn(googleUser);

      if (connected) {
        AuthService.setGmailApiService(gmailService);
        debugPrint('EmailProvider: Gmail API service successfully initialized');

        // Sync emails in background after successful initialization
        // This will load cached emails first, then fetch fresh ones
        _syncEmailsInBackground();
      } else {
        debugPrint('EmailProvider: Failed to connect Gmail API service');
      }
    } catch (e) {
      debugPrint('EmailProvider: Error initializing Gmail API service: $e');
    }
  }

  /// Searches emails based on a query string
  void searchEmails(String query) {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _searchQuery = query.trim().toLowerCase();

    // Store original messages if this is the first search
    if (_originalMessages.isEmpty) {
      _originalMessages = List.from(_messages);
    }

    // Perform search across subject, sender, and body
    _searchResults = _originalMessages.where((email) {
      final searchableText = [
        email.subject.toLowerCase(),
        email.from.toLowerCase(),
        email.textBody.toLowerCase(),
        email.htmlBody?.toLowerCase() ?? '',
        ...email.to.map((to) => to.toLowerCase()),
      ].join(' ');

      return searchableText.contains(_searchQuery);
    }).toList();

    // Update the displayed messages
    _messages = _searchResults;

    debugPrint('EmailProvider: Search for "$_searchQuery" found ${_searchResults.length} results');
    notifyListeners();
  }

  /// Clears the current search and shows all emails
  void clearSearch() {
    if (_isSearching) {
      _isSearching = false;
      _searchQuery = '';
      _searchResults.clear();

      // Restore original messages or conversations
      if (_conversationMode && _originalConversations.isNotEmpty) {
        _conversations = _originalConversations;
        _originalConversations.clear();
      } else if (!_conversationMode && _originalMessages.isNotEmpty) {
        _messages = _originalMessages;
        _originalMessages.clear();
      }

      debugPrint('EmailProvider: Search cleared, showing all emails');
      notifyListeners();
    }
  }

  /// Toggles between conversation and individual message mode
  void toggleConversationMode() {
    _conversationMode = !_conversationMode;
    debugPrint('EmailProvider: Conversation mode toggled to: $_conversationMode');

    // Refresh the current view
    if (_currentAccount != null && _currentFolder != null) {
      if (_conversationMode) {
        _loadConversationsForCurrentContext();
      } else {
        _loadAccountCachedEmails(_currentAccount!.id, _currentFolder!);
      }
    }

    notifyListeners();
  }

  /// Loads conversations for the current account and folder (async version)
  Future<void> _loadConversationsForCurrentContext() async {
    final currentAccount = _currentAccount;
    final currentFolder = _currentFolder;

    if (currentAccount == null || currentFolder == null) {
      _conversations = [];
      return;
    }

    try {
      debugPrint('EmailProvider: Loading conversations for account ${currentAccount.email}, folder ${currentFolder.name}...');

      // Get messages for the current context - ensure account isolation
      final messages = _accountEmailCache[currentAccount.id]?[currentFolder] ?? [];

      // Double-check account isolation at conversation level
      final accountMessages = messages.where((msg) => msg.accountId == currentAccount.id).toList();
      if (accountMessages.length != messages.length) {
        debugPrint('EmailProvider: WARNING - Filtered out ${messages.length - accountMessages.length} messages from wrong account');
      }

      if (accountMessages.isNotEmpty) {
        // Group messages into conversations
        _conversations = await _conversationManager.groupIntoConversations(accountMessages, currentAccount.id);
        debugPrint('EmailProvider: Grouped ${accountMessages.length} messages into ${_conversations.length} conversations for account ${currentAccount.email}');
      } else {
        _conversations = [];
        debugPrint('EmailProvider: No messages to group into conversations for account ${currentAccount.email}');
      }
    } catch (e) {
      debugPrint('EmailProvider: Error loading conversations: $e');
      _conversations = [];
    }
  }

  /// Loads conversations synchronously for instant account switching
  void _loadConversationsForCurrentContextSync(List<EmailMessage> accountMessages, String accountId) {
    try {
      debugPrint('EmailProvider: INSTANT loading conversations for account ID $accountId with ${accountMessages.length} messages...');

      if (accountMessages.isNotEmpty) {
        // Use a simple synchronous conversation grouping for instant switching
        // Group by subject for fast switching (we can do full async grouping in background)
        final Map<String, List<EmailMessage>> subjectGroups = {};

        for (final message in accountMessages) {
          final normalizedSubject = _normalizeSubject(message.subject);
          subjectGroups.putIfAbsent(normalizedSubject, () => []).add(message);
        }

        _conversations = subjectGroups.entries.map((entry) {
          final messages = entry.value;
          messages.sort((a, b) => b.date.compareTo(a.date)); // Latest first

          return Conversation(
            id: '${accountId}_${entry.key}_${messages.first.messageId}',
            subject: messages.first.subject,
            participants: _extractUniqueParticipants(messages),
            messageIds: messages.map((m) => m.messageId).toList(),
            lastMessageDate: messages.first.date,
            accountId: accountId,
            folder: messages.first.folder,
            hasUnreadMessages: !messages.every((m) => m.isRead),
            hasImportantMessages: messages.any((m) => m.isImportant),
            previewText: messages.first.previewText ?? messages.first.textBody,
            messageCount: messages.length,
          );
        }).toList();

        // Sort conversations by latest message date
        _conversations.sort((a, b) => b.lastMessageDate.compareTo(a.lastMessageDate));

        debugPrint('EmailProvider: INSTANT grouped ${accountMessages.length} messages into ${_conversations.length} conversations');
      } else {
        _conversations = [];
        debugPrint('EmailProvider: INSTANT - no messages for conversations');
      }
    } catch (e) {
      debugPrint('EmailProvider: Error in instant conversation loading: $e');
      _conversations = [];
    }
  }

  /// Helper method to normalize email subjects for grouping
  String _normalizeSubject(String subject) {
    // Remove common prefixes and normalize for conversation grouping
    String normalized = subject.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'^(re:|fwd?:|fw:)\s*'), '');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  /// Helper method to extract unique participants from messages
  List<String> _extractUniqueParticipants(List<EmailMessage> messages) {
    final Set<String> participants = {};
    for (final message in messages) {
      participants.add(message.from);
      participants.addAll(message.to);
    }
    return participants.toList();
  }

  /// Gets messages for a specific conversation
  List<EmailMessage> getMessagesForConversation(Conversation conversation) {
    if (_currentAccount == null) return [];

    final allMessages = _accountEmailCache[_currentAccount!.id]?[_currentFolder!] ?? [];
    return allMessages.where((message) => conversation.messageIds.contains(message.messageId)).toList();
  }

  /// Searches conversations
  void searchConversations(String query) {
    if (!_conversationMode) {
      // Fallback to regular search
      searchEmails(query);
      return;
    }

    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }

    _isSearching = true;
    _searchQuery = query.trim().toLowerCase();

    // Store original conversations if this is the first search
    if (_originalConversations.isEmpty) {
      _originalConversations = List.from(_conversations);
    }

    // Search conversations
    final filteredConversations = _originalConversations.where((conversation) {
      final searchableText = [
        conversation.subject.toLowerCase(),
        conversation.previewText?.toLowerCase() ?? '',
        ...conversation.participants.map((p) => p.toLowerCase()),
      ].join(' ');

      return searchableText.contains(_searchQuery);
    }).toList();

    _conversations = filteredConversations;

    debugPrint('EmailProvider: Conversation search for "$_searchQuery" found ${_conversations.length} results');
    notifyListeners();
  }

  /// Forces a complete refresh of all cached emails for all accounts
  /// This is a troubleshooting method to fix cache issues
  Future<void> forceRefreshAllAccounts() async {
    debugPrint('EmailProvider: Force refreshing all accounts...');

    if (_accounts.isEmpty) {
      debugPrint('EmailProvider: No accounts to refresh');
      return;
    }

    setLoading(true);

    for (final account in _accounts) {
      try {
        debugPrint('EmailProvider: Force refreshing account ${account.email}...');

        // Switch to this account temporarily to initialize services
        switchAccount(account);

        // Initialize services based on provider type
        if (account.provider == models.EmailProvider.gmail) {
          await _initializeGmailForAccount(account);
        }
        // Yahoo and other providers would be added here

        // Force fetch emails for all folders
        await _forceFetchAllFolders(account);

        debugPrint('EmailProvider: Completed refresh for ${account.email}');
      } catch (e) {
        debugPrint('EmailProvider: Error refreshing account ${account.email}: $e');
      }
    }

    setLoading(false);
    debugPrint('EmailProvider: Force refresh completed');
  }

  /// Initialize Gmail services for a specific account
  Future<void> _initializeGmailForAccount(models.EmailAccount account) async {
    try {
      debugPrint('EmailProvider: Initializing Gmail for ${account.email}...');
      await _reinitializeGmailServiceOnStartup();
    } catch (e) {
      debugPrint('EmailProvider: Failed to initialize Gmail for ${account.email}: $e');
    }
  }

  /// Force fetch emails for all folders of an account
  Future<void> _forceFetchAllFolders(models.EmailAccount account) async {
    final folders = [EmailFolder.inbox, EmailFolder.sent, EmailFolder.drafts, EmailFolder.trash];

    for (final folder in folders) {
      try {
        debugPrint('EmailProvider: Force fetching ${folder.name} for ${account.email}...');
        final emails = await _fetchEmailsForAccount(account, folder);
        _mergeEmailsWithCache(account.id, folder, emails);
        debugPrint('EmailProvider: Fetched ${emails.length} emails from ${folder.name}');
      } catch (e) {
        debugPrint('EmailProvider: Error fetching ${folder.name} for ${account.email}: $e');
      }
    }
  }

  /// Initialize cache maintenance in background
  void _initializeCacheMaintenanceBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // Configure cache policies for all accounts
        for (final account in _accounts) {
          await _cacheService.configureCachePolicy(
            accountId: account.id,
            maxStorageMB: 500,
            maxEmailsPerFolder: 5000,
            enableAutoCleanup: true,
          );
        }

        // Start background maintenance service
        await _maintenanceService.startMaintenance(
          interval: const Duration(hours: 6),
          runImmediately: false, // Don't run immediately on startup
        );

        debugPrint('EmailProvider: Cache maintenance initialized and started');
      } catch (e) {
        debugPrint('EmailProvider: Error initializing cache maintenance: $e');
      }
    });
  }

  /// Perform manual cache cleanup for current account
  Future<void> performCacheCleanup() async {
    if (_currentAccount == null) return;

    try {
      setLoading(true);
      await _cacheService.performIntelligentCacheEviction(accountId: _currentAccount!.id);
      setLoading(false);
      debugPrint('EmailProvider: Manual cache cleanup completed for ${_currentAccount!.email}');
    } catch (e) {
      setLoading(false);
      setError('Cache cleanup failed: $e');
      debugPrint('EmailProvider: Manual cache cleanup failed: $e');
    }
  }

  /// Get cache statistics for current account
  Future<Map<String, dynamic>> getCacheStatistics() async {
    if (_currentAccount == null) {
      return {'error': 'No account selected'};
    }

    try {
      final stats = await _cacheService.getCacheStats(_currentAccount!.id);
      final maintenanceStatus = _maintenanceService.getStatus();

      return {
        ...stats,
        'maintenance': maintenanceStatus,
      };
    } catch (e) {
      debugPrint('EmailProvider: Error getting cache statistics: $e');
      return {'error': e.toString()};
    }
  }


  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    _emailService.disconnect();
    _connectivityManager.dispose();
    _operationQueue.dispose();
    _maintenanceService.stopMaintenance();
    _cacheService.close();
    _accountsBox?.close();
    _messagesBox?.close();
    super.dispose();
  }
}