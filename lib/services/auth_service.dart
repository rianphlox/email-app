import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/email_account.dart';
import 'gmail_api_service.dart';

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/gmail.modify',
    ],
    serverClientId: '968928828097-lh79bdv88j7quj5e2eh30tujskqts17b.apps.googleusercontent.com',
  );

  static GmailApiService? _gmailApiService;

  Future<EmailAccount?> signInWithGoogle() async {
    try {
      print('Starting Google sign in...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google sign in cancelled by user');
        return null;
      }

      print('Google user signed in: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null) {
        print('Failed to get access token');
        throw Exception('Failed to get access token from Google. Please try again.');
      }

      // Initialize Gmail API service
      _gmailApiService = GmailApiService();
      final connected = await _gmailApiService!.connectWithGoogleSignIn(googleUser);

      if (!connected) {
        print('Failed to connect to Gmail API');
        throw Exception('Failed to connect to Gmail API. Please check your internet connection and try again.');
      }

      print('Got access token, creating account...');
      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: googleUser.displayName ?? googleUser.email.split('@')[0],
        email: googleUser.email,
        provider: EmailProvider.gmail,
        accessToken: googleAuth.accessToken!,
        refreshToken: googleAuth.idToken,
        lastSync: DateTime.now(),
        imapServer: null, // Not needed for Gmail API
        imapPort: null,
        smtpServer: null,
        smtpPort: null,
      );

      await _storeCredentials(account);
      print('Google account created successfully');
      return account;
    } catch (e) {
      print('Google sign in error: $e');

      // Provide more specific error messages
      String errorMessage = 'Failed to sign in with Google';
      if (e.toString().contains('network_error') || e.toString().contains('NetworkError')) {
        errorMessage = 'Network error: Please check your internet connection and try again.';
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('SIGN_IN_FAILED')) {
        errorMessage = 'Google Sign-In failed. This might be due to missing configuration. Please contact support.';
      } else if (e.toString().contains('sign_in_canceled') || e.toString().contains('SIGN_IN_CANCELED')) {
        errorMessage = 'Sign-in was cancelled by user.';
      } else if (e.toString().contains('sign_in_required') || e.toString().contains('SIGN_IN_REQUIRED')) {
        errorMessage = 'Please sign in to continue.';
      } else if (e.toString().contains('developer_error') || e.toString().contains('DEVELOPER_ERROR') || e.toString().contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In configuration error. Please ensure:\n• SHA-1 fingerprint is added to Firebase\n• OAuth client is configured\n• Google Sign-In API is enabled';
      }

      throw Exception(errorMessage);
    }
  }

  static GmailApiService? getGmailApiService() {
    return _gmailApiService;
  }

  Future<EmailAccount?> signInWithOutlook(String email, String password) async {
    try {
      // For production, you'd implement proper OAuth flow
      // For now, we'll create account with app password
      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0],
        email: email,
        provider: EmailProvider.outlook,
        accessToken: password, // App password for Outlook
        lastSync: DateTime.now(),
        imapServer: 'outlook.office365.com',
        imapPort: 993,
        smtpServer: 'smtp-mail.outlook.com',
        smtpPort: 587,
      );

      await _storeCredentials(account);
      return account;
    } catch (e) {
      print('Outlook sign in error: $e');
    }
    return null;
  }

  Future<EmailAccount?> signInWithYahoo(String email, String password) async {
    try {
      // Yahoo requires app password for IMAP/SMTP access
      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0],
        email: email,
        provider: EmailProvider.yahoo,
        accessToken: password, // App password for Yahoo
        lastSync: DateTime.now(),
        imapServer: 'imap.mail.yahoo.com',
        imapPort: 993,
        smtpServer: 'smtp.mail.yahoo.com',
        smtpPort: 587,
      );

      await _storeCredentials(account);
      return account;
    } catch (e) {
      print('Yahoo sign in error: $e');
    }
    return null;
  }

  Future<EmailAccount?> addCustomEmailAccount({
    required String name,
    required String email,
    required String password,
    required String imapServer,
    required int imapPort,
    required String smtpServer,
    required int smtpPort,
    bool isSSL = true,
  }) async {
    try {
      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        provider: EmailProvider.custom,
        accessToken: password, // For custom accounts, we store password as access token
        lastSync: DateTime.now(),
        imapServer: imapServer,
        imapPort: imapPort,
        smtpServer: smtpServer,
        smtpPort: smtpPort,
        isSSL: isSSL,
      );

      await _storeCredentials(account);
      return account;
    } catch (e) {
      print('Custom email account error: $e');
      return null;
    }
  }

  Future<void> _storeCredentials(EmailAccount account) async {
    await _secureStorage.write(
      key: 'email_account_${account.id}',
      value: json.encode({
        'id': account.id,
        'name': account.name,
        'email': account.email,
        'provider': account.provider.index,
        'accessToken': account.accessToken,
        'refreshToken': account.refreshToken,
        'imapServer': account.imapServer,
        'imapPort': account.imapPort,
        'smtpServer': account.smtpServer,
        'smtpPort': account.smtpPort,
        'isSSL': account.isSSL,
      }),
    );
  }

  Future<List<EmailAccount>> getStoredAccounts() async {
    final accounts = <EmailAccount>[];
    final allKeys = await _secureStorage.readAll();

    for (final entry in allKeys.entries) {
      if (entry.key.startsWith('email_account_')) {
        try {
          final data = json.decode(entry.value);
          final account = EmailAccount(
            id: data['id'],
            name: data['name'],
            email: data['email'],
            provider: EmailProvider.values[data['provider']],
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
            lastSync: DateTime.now(), // Will be updated from local cache
            imapServer: data['imapServer'],
            imapPort: data['imapPort'],
            smtpServer: data['smtpServer'],
            smtpPort: data['smtpPort'],
            isSSL: data['isSSL'] ?? true,
          );
          accounts.add(account);
        } catch (e) {
          print('Error loading account: $e');
        }
      }
    }
    return accounts;
  }

  Future<void> removeAccount(String accountId) async {
    await _secureStorage.delete(key: 'email_account_$accountId');
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _secureStorage.deleteAll();
  }
}