
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/email_account.dart';
import 'gmail_api_service.dart';
import 'yahoo_api_service.dart';
import 'yahoo_oauth_service.dart';

/// A service class that handles user authentication for different email providers.
///
/// This class provides methods for signing in with Google, Outlook, Yahoo, and
/// custom email providers. It also manages the storage of account credentials
/// in a secure storage.
class AuthService {
  // --- Private Properties ---

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.send',
      'https://www.googleapis.com/auth/gmail.modify',
    ],
    // The serverClientId is not supported on the web platform.
    serverClientId: kIsWeb ? null : '968928828097-lh79bdv88j7quj5e2eh30tujskqts17b.apps.googleusercontent.com',
  );

  static GmailApiService? _gmailApiService;
  static YahooApiService? _yahooApiService;

  // --- Public Methods ---

  /// Signs in the user with their Google account.
  ///
  /// This method initiates the Google Sign-In flow and, if successful, creates
  /// an [EmailAccount] object with the user's information.
  Future<EmailAccount?> signInWithGoogle() async {
    try {
      debugPrint('🔐 AuthService: Starting Google Sign-In process...');
      debugPrint('🔐 AuthService: GoogleSignIn configuration scopes: ${_googleSignIn.scopes}');
      debugPrint('🔐 AuthService: ServerClientId: ${_googleSignIn.serverClientId}');

      // Signing out first ensures that the user is prompted to select an account.
      debugPrint('🔐 AuthService: Signing out existing user...');
      await _googleSignIn.signOut();

      debugPrint('🔐 AuthService: Initiating Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('🔐 AuthService: User cancelled the sign-in flow');
        // The user cancelled the sign-in flow.
        return null;
      }

      debugPrint('🔐 AuthService: Sign-In successful! User: ${googleUser.email}');
      debugPrint('🔐 AuthService: Display Name: ${googleUser.displayName}');
      debugPrint('🔐 AuthService: User ID: ${googleUser.id}');

      debugPrint('🔐 AuthService: Getting authentication tokens...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('🔐 AuthService: Access Token available: ${googleAuth.accessToken != null}');
      debugPrint('🔐 AuthService: ID Token available: ${googleAuth.idToken != null}');

      if (googleAuth.accessToken == null) {
        debugPrint('❌ AuthService: Failed to get access token from Google');
        throw Exception('Failed to get access token from Google.');
      }

      debugPrint('🔐 AuthService: Access Token (first 20 chars): ${googleAuth.accessToken!.substring(0, 20)}...');

      // Initialize the Gmail API service with the signed-in user.
      debugPrint('🔐 AuthService: Initializing Gmail API service...');
      _gmailApiService = GmailApiService();
      final connected = await _gmailApiService!.connectWithGoogleSignIn(googleUser);

      debugPrint('🔐 AuthService: Gmail API connection successful: $connected');

      if (!connected) {
        debugPrint('❌ AuthService: Failed to connect to Gmail API');
        throw Exception('Failed to connect to Gmail API.');
      }

      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: googleUser.displayName ?? googleUser.email.split('@')[0],
        email: googleUser.email,
        provider: EmailProvider.gmail,
        accessToken: googleAuth.accessToken!,
        refreshToken: googleAuth.idToken,
        lastSync: DateTime.now(),
      );

      debugPrint('🔐 AuthService: Created EmailAccount object for: ${account.email}');
      debugPrint('🔐 AuthService: Account ID: ${account.id}');

      debugPrint('🔐 AuthService: Storing credentials...');
      await _storeCredentials(account);

      debugPrint('✅ AuthService: Google Sign-In completed successfully!');
      return account;
    } catch (e) {
      debugPrint('❌ AuthService: Google Sign-In failed with error: $e');
      debugPrint('❌ AuthService: Error type: ${e.runtimeType}');
      debugPrint('❌ AuthService: Stack trace: ${StackTrace.current}');

      // Provide more specific error messages to the user.
      String errorMessage = 'Failed to sign in with Google';
      if (e.toString().contains('network_error')) {
        errorMessage = 'Network error: Please check your internet connection.';
        debugPrint('❌ AuthService: Detected network error');
      } else if (e.toString().contains('developer_error')) {
        errorMessage = 'Google Sign-In configuration error. Please check your setup.';
        debugPrint('❌ AuthService: Detected developer/configuration error');
      } else if (e.toString().contains('sign_in_canceled')) {
        errorMessage = 'Sign-in was canceled by user.';
        debugPrint('❌ AuthService: Detected sign-in cancellation');
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage = 'Sign-in failed. Please try again.';
        debugPrint('❌ AuthService: Detected generic sign-in failure');
      }

      debugPrint('❌ AuthService: Final error message: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  /// Returns the currently initialized Gmail API service.
  static GmailApiService? getGmailApiService() {
    return _gmailApiService;
  }

  /// Sets the Gmail API service.
  static void setGmailApiService(GmailApiService service) {
    _gmailApiService = service;
  }

  /// Gets the Yahoo API service instance for authorized requests.
  static YahooApiService? getYahooApiService() {
    return _yahooApiService;
  }

  /// Sets the Yahoo API service.
  static void setYahooApiService(YahooApiService service) {
    _yahooApiService = service;
  }

  /// Signs in the user with their Outlook account.
  ///
  /// For production, this should be replaced with a proper OAuth flow.
  Future<EmailAccount?> signInWithOutlook(String email, String password) async {
    // ... (implementation for Outlook sign-in)
    return null;
  }

  /// Signs in the user with their Yahoo account using OAuth2.
  ///
  /// This method initiates the Yahoo OAuth flow and returns an EmailAccount
  /// if successful.
  Future<EmailAccount?> signInWithYahoo() async {
    try {
      final yahooOAuth = YahooOAuthService();

      // Launch OAuth flow
      final launched = await yahooOAuth.launchOAuthFlow();
      if (!launched) {
        throw Exception('Failed to launch Yahoo OAuth flow');
      }

      // Note: The OAuth flow will redirect to qmail://auth
      // You'll need to handle this deep link in your app
      debugPrint('Yahoo OAuth flow launched. The user will be redirected to qmail://auth after authentication.');
      debugPrint('To complete the flow, call completeYahooSignIn(callbackUrl) when you receive the deep link.');

      // Return null to indicate that the flow needs to be completed via deep link
      return null;

    } catch (e) {
      debugPrint('Yahoo sign-in error: $e');
      throw Exception('Failed to sign in with Yahoo: $e');
    }
  }

  /// Completes Yahoo sign-in after OAuth callback.
  ///
  /// This should be called when your app receives the OAuth callback.
  Future<EmailAccount?> completeYahooSignIn(String callbackUrl) async {
    try {
      final yahooOAuth = YahooOAuthService();

      // Handle the OAuth callback and get tokens
      final tokens = await yahooOAuth.handleAuthorizationCallback(callbackUrl);
      if (tokens == null) {
        throw Exception('Failed to get tokens from Yahoo');
      }

      final accessToken = tokens['access_token']!;
      final refreshToken = tokens['refresh_token']!;

      // Initialize Yahoo API service
      _yahooApiService = YahooApiService();
      final connected = await _yahooApiService!.connectWithTokens(
        accessToken,
        refreshToken,
      );

      if (!connected) {
        throw Exception('Failed to connect to Yahoo Mail API');
      }

      // Get user profile information
      final userProfile = await _yahooApiService!.getUserProfile();
      final userName = userProfile['name'] ?? 'Yahoo User';
      final userEmail = userProfile['email'] ?? 'user@yahoo.com';

      // Create account with actual user info
      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: userName,
        email: userEmail,
        provider: EmailProvider.yahoo,
        accessToken: accessToken,
        refreshToken: refreshToken,
        lastSync: DateTime.now(),
      );

      await _storeCredentials(account);
      return account;
    } catch (e) {
      debugPrint('Yahoo sign-in completion error: $e');
      throw Exception('Failed to complete Yahoo sign-in: $e');
    }
  }

  /// Adds a custom email account with IMAP and SMTP settings.
  /// Adds a custom email account with manual server configuration.
  Future<EmailAccount?> addCustomEmailAccount({
    required String name,
    required String email,
    required String password,
    required String imapServer,
    required int imapPort,
    required String smtpServer,
    required int smtpPort,
    required bool isSSL,
  }) async {
    try {
      debugPrint('🔐 AuthService: Adding custom email account for $email');

      // Create EmailAccount object for custom provider
      final account = EmailAccount(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        provider: EmailProvider.custom,
        accessToken: '', // Custom accounts use password auth, not OAuth
        lastSync: DateTime.now(),
        password: password, // Store password for IMAP/SMTP auth
        imapServer: imapServer,
        imapPort: imapPort,
        smtpServer: smtpServer,
        smtpPort: smtpPort,
        isSSL: isSSL,
      );

      // Store account credentials
      await _storeCredentials(account);

      debugPrint('✅ AuthService: Custom email account added successfully');
      return account;
    } catch (e) {
      debugPrint('❌ AuthService: Failed to add custom email account: $e');
      return null;
    }
  }

  /// Stores the credentials of an email account in secure storage.
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
        'password': account.password,
      }),
    );
  }

  /// Retrieves all the stored email accounts from secure storage.
  Future<List<EmailAccount>> getStoredAccounts() async {
    // ... (implementation for retrieving stored accounts)
    return [];
  }

  /// Removes an email account from secure storage.
  Future<void> removeAccount(String accountId) async {
    await _secureStorage.delete(key: 'email_account_$accountId');
  }

  /// Signs out the user from all accounts and clears all stored data.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _secureStorage.deleteAll();
  }
}
