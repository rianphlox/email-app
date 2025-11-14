
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

  /// Initializes the email provider.
  ///
  /// This method should be called once when the application starts. It initializes
  /// the Hive database, registers the necessary adapters, and loads the stored
  /// email accounts.
  Future<void> initialize() async {
    await Hive.initFlutter();

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

    // Immediately pre-load ALL cached emails into memory for fast access
    await _preloadAllCachedEmails();

    // Load stored accounts from the database.
    _accounts = _accountsBox!.values.toList();
    if (_accounts.isNotEmpty) {
      _currentAccount = _accounts.first;

      // Load emails for current folder immediately (now from fast memory cache)
      _loadAccountCachedEmails(_currentAccount!.id, _currentFolder);

      // Initialize network services in background without blocking UI
      _initializeNetworkServicesBackground();
    } else {
      // Even without accounts, show any cached emails that might exist
      _loadAllCachedEmails();
    }

    // Initialize operation queue and connectivity manager in background
    _initializeServicesBackground();

    // Mark as initialized
    _isInitialized = true;
    notifyListeners();
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

  /// Signs in the user with their Google account.
  Future<bool> signInWithGoogle() async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithGoogle();
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

        // Fetch emails after a short delay to ensure the Gmail API is ready.
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchEmails();
        });

        return true;
      }
    } catch (e) {
      setError('Failed to sign in with Google: $e');
    } finally {
      setLoading(false);
    }
    return false;
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

  /// Signs in with a Yahoo account using email and password.
  Future<bool> signInWithYahoo(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithYahoo(email, password);
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

    // Update current account
    _currentAccount = account;

    // Reset to inbox folder when switching accounts (common UX pattern)
    _currentFolder = EmailFolder.inbox;

    // Immediately load cached emails for this account and inbox folder
    _loadAccountCachedEmails(account.id, _currentFolder);

    // Update last sync time if available
    final lastSync = _lastSyncTime[account.id];
    if (lastSync != null) {
      debugPrint('EmailProvider: Last sync for ${account.email}: $lastSync');
    }

    // Notify listeners to update UI immediately
    notifyListeners();

    // Start background sync for this account
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_currentAccount?.id == account.id) {
        _syncEmailsInBackground();
      }
    });
  }

  /// Switches the current email folder.
  void switchFolder(EmailFolder folder) {
    if (_currentFolder != folder) {
      debugPrint('EmailProvider: Switching to folder ${folder.name}...');

      _currentFolder = folder;

      // Load cached emails for the new folder.
      if (_currentAccount != null) {
        // Load cached emails for current account and new folder
        _loadAccountCachedEmails(_currentAccount!.id, folder);
      } else {
        // In offline mode, load all cached emails for this folder
        _loadAllCachedEmailsForFolder(folder);
      }
      notifyListeners();

      // Sync emails in the background.
      _syncEmailsInBackground();
    }
  }

  /// Fetches emails for the current account and folder.
  Future<void> fetchEmails({int limit = 50, bool forceRefresh = false}) async {
    if (_currentAccount == null) return;

    setLoading(true);
    setError(null);

    try {
      // If not forcing a refresh, load cached emails first.
      if (!forceRefresh) {
        _loadAccountCachedEmails(_currentAccount!.id, _currentFolder);
        notifyListeners();
      }

      // Fetch fresh emails from the server.
      final emails = await _fetchEmailsForAccount(_currentAccount!, _currentFolder, limit: limit);

      // Merge the new emails with the cache.
      _mergeEmailsWithCache(_currentAccount!.id, _currentFolder, emails);

      // Update the last sync time.
      _lastSyncTime[_currentAccount!.id] = DateTime.now();

      notifyListeners();
    } catch (e) {
      setError('Failed to fetch emails: $e');
    } finally {
      setLoading(false);
    }
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

  /// Syncs emails with the server
  Future<void> syncEmails() async {
    if (_currentAccount == null) return;

    try {
      setLoading(true);
      setError(null);

      // First load cached emails to show immediately
      _loadAccountCachedEmails(_currentAccount!.id, _currentFolder);
      notifyListeners();

      // Then fetch fresh emails from server
      final emails = await _fetchEmailsForAccount(_currentAccount!, _currentFolder, limit: 50);

      // Merge with cache and update UI
      _mergeEmailsWithCache(_currentAccount!.id, _currentFolder, emails);
      _lastSyncTime[_currentAccount!.id] = DateTime.now();

      notifyListeners();
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
    } catch (e) {
      debugPrint('EmailProvider: Error pre-loading cached emails: $e');
    }
  }

  /// Initialize network services in background without blocking startup
  Future<void> _initializeNetworkServicesBackground() async {
    try {
      if (_currentAccount?.provider == models.EmailProvider.gmail) {
        await _reinitializeGmailServiceOnStartup();
      } else {
        // For non-Gmail accounts, try to sync emails in the background
        _syncEmailsInBackground();
      }
    } catch (e) {
      debugPrint('EmailProvider: Error initializing network services: $e');
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
  Future<void> _syncEmailsInBackground() async {
    if (_currentAccount == null) return;

    try {
      debugPrint('EmailProvider: Starting background sync for ${_currentAccount!.email}...');

      final gmailService = AuthService.getGmailApiService();
      if (gmailService == null) {
        throw Exception('Gmail API service not initialized');
      }

      // Fetch emails for the current folder
      final emails = await _fetchEmailsForAccount(_currentAccount!, _currentFolder);

      // Merge with cache
      _mergeEmailsWithCache(_currentAccount!.id, _currentFolder, emails);
      _lastSyncTime[_currentAccount!.id] = DateTime.now();

      debugPrint('EmailProvider: Background sync completed, fetched ${emails.length} emails');
      notifyListeners();
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
      }

      debugPrint('EmailProvider: Merged ${newEmails.length} new emails, total cached: ${cachedEmails.length}');
    } catch (e) {
      debugPrint('EmailProvider: Error merging emails with cache: $e');
    }
  }

  /// Fetches emails for a specific account without updating the UI state.
  Future<List<EmailMessage>> _fetchEmailsForAccount(models.EmailAccount account, EmailFolder folder, {int limit = 50}) async {
    try {
      if (account.provider == models.EmailProvider.gmail) {
        // Use Gmail API service
        final gmailService = AuthService.getGmailApiService();
        if (gmailService != null) {
          final emails = await gmailService.fetchEmails(
            accountId: account.email,
            maxResults: limit,
            folder: folder,
          );

          // Account ID and folder are now properly set in the Gmail service

          return emails;
        }
      } else {
        // Use IMAP service for other providers
        // For now, return empty list for non-Gmail accounts
        // TODO: Implement IMAP email fetching
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching emails for account ${account.email}: $e');
    }

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

  @override
  void dispose() {
    _emailService.disconnect();
    _connectivityManager.dispose();
    _operationQueue.dispose();
    _accountsBox?.close();
    _messagesBox?.close();
    super.dispose();
  }
}
