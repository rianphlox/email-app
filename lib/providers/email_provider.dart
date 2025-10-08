import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/email_account.dart' as models;
import '../models/email_message.dart';
import '../services/auth_service.dart';
import '../services/final_email_service.dart';

class EmailProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FinalEmailService _emailService = FinalEmailService();

  Box<models.EmailAccount>? _accountsBox;
  Box<EmailMessage>? _messagesBox;

  List<models.EmailAccount> _accounts = [];
  models.EmailAccount? _currentAccount;
  List<EmailMessage> _messages = [];
  EmailFolder _currentFolder = EmailFolder.inbox;
  bool _isLoading = false;
  String? _error;

  List<models.EmailAccount> get accounts => _accounts;
  models.EmailAccount? get currentAccount => _currentAccount;
  List<EmailMessage> get messages => _messages;
  EmailFolder get currentFolder => _currentFolder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
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

    // Open boxes
    _accountsBox = await Hive.openBox<models.EmailAccount>('accounts');
    _messagesBox = await Hive.openBox<EmailMessage>('messages');

    // Load stored accounts
    _accounts = _accountsBox!.values.toList();
    if (_accounts.isNotEmpty) {
      _currentAccount = _accounts.first;
    }

    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithGoogle();
      if (account != null) {
        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();
        return true;
      }
    } catch (e) {
      setError('Failed to sign in with Google: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  Future<bool> signInWithOutlook(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithOutlook(email, password);
      if (account != null) {
        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();
        return true;
      }
    } catch (e) {
      setError('Failed to sign in with Outlook: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  Future<bool> signInWithYahoo(String email, String password) async {
    setLoading(true);
    setError(null);

    try {
      final account = await _authService.signInWithYahoo(email, password);
      if (account != null) {
        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();
        return true;
      }
    } catch (e) {
      setError('Failed to sign in with Yahoo: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  Future<bool> addCustomEmailAccount({
    required String name,
    required String email,
    required String password,
    required String imapServer,
    required int imapPort,
    required String smtpServer,
    required int smtpPort,
    bool isSSL = true,
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
        await _accountsBox!.put(account.id, account);
        _accounts.add(account);
        _currentAccount = account;
        notifyListeners();
        return true;
      }
    } catch (e) {
      setError('Failed to add custom email account: $e');
    } finally {
      setLoading(false);
    }
    return false;
  }

  void switchAccount(models.EmailAccount account) {
    _currentAccount = account;
    _messages.clear();
    notifyListeners();
    fetchEmails();
  }

  void switchFolder(EmailFolder folder) {
    _currentFolder = folder;
    _messages.clear();
    notifyListeners();
    fetchEmails();
  }

  Future<void> fetchEmails({int limit = 50}) async {
    if (_currentAccount == null) return;

    setLoading(true);
    setError(null);

    try {
      List<EmailMessage> emails;

      if (_currentAccount!.provider == models.EmailProvider.gmail) {
        // Use Gmail API for Gmail accounts
        final gmailService = AuthService.getGmailApiService();
        if (gmailService == null) {
          throw Exception('Gmail API service not initialized');
        }

        emails = await gmailService.fetchEmails(maxResults: limit);

        // Update account ID for each message
        for (var email in emails) {
          email.accountId = _currentAccount!.id;
        }
      } else {
        // Use IMAP for other providers
        final connected = await _emailService.connectToAccount(_currentAccount!);
        if (!connected) {
          throw Exception('Failed to connect to email server');
        }

        emails = await _emailService.fetchEmails(
          _currentAccount!,
          folder: _currentFolder,
          limit: limit,
        );
      }

      _messages = emails;

      // Cache messages locally
      for (final email in emails) {
        await _messagesBox!.put(email.messageId, email);
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to fetch emails: $e');
    } finally {
      setLoading(false);
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
    if (_currentAccount == null) return false;

    setLoading(true);
    setError(null);

    try {
      bool success;

      if (_currentAccount!.provider == models.EmailProvider.gmail) {
        // Use Gmail API for Gmail accounts
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
        // Use SMTP for other providers
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

  Future<void> markAsRead(EmailMessage message) async {
    if (_currentAccount == null) return;

    try {
      if (_currentAccount!.provider == models.EmailProvider.gmail) {
        // Use Gmail API for Gmail accounts
        final gmailService = AuthService.getGmailApiService();
        if (gmailService != null) {
          await gmailService.markAsRead(message.messageId);
        }
      } else {
        // Use IMAP for other providers
        await _emailService.markAsRead(_currentAccount!, message);
      }

      message.isRead = true;
      await _messagesBox!.put(message.messageId, message);
      notifyListeners();
    } catch (e) {
      setError('Failed to mark email as read: $e');
    }
  }

  Future<void> deleteEmail(EmailMessage message) async {
    if (_currentAccount == null) return;

    try {
      if (_currentAccount!.provider == models.EmailProvider.gmail) {
        // Use Gmail API for Gmail accounts
        final gmailService = AuthService.getGmailApiService();
        if (gmailService != null) {
          await gmailService.deleteEmail(message.messageId);
        }
      } else {
        // Use IMAP for other providers
        await _emailService.deleteEmail(_currentAccount!, message);
      }

      _messages.removeWhere((m) => m.messageId == message.messageId);
      await _messagesBox!.delete(message.messageId);
      notifyListeners();
    } catch (e) {
      setError('Failed to delete email: $e');
    }
  }

  Future<void> removeAccount(String accountId) async {
    try {
      await _authService.removeAccount(accountId);
      await _accountsBox!.delete(accountId);
      _accounts.removeWhere((account) => account.id == accountId);

      if (_currentAccount?.id == accountId) {
        _currentAccount = _accounts.isNotEmpty ? _accounts.first : null;
        _messages.clear();
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to remove account: $e');
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await _accountsBox!.clear();
    await _messagesBox!.clear();
    _accounts.clear();
    _currentAccount = null;
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _emailService.disconnect();
    _accountsBox?.close();
    _messagesBox?.close();
    super.dispose();
  }
}