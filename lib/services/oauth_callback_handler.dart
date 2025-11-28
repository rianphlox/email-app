import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'auth_service.dart';
import '../models/email_account.dart';

/// Handles OAuth callbacks from external browsers using app_links
class OAuthCallbackHandler {
  static OAuthCallbackHandler? _instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback for when account is successfully added
  Function(EmailAccount)? _onAccountAdded;
  Function(String)? _onError;

  static OAuthCallbackHandler get instance {
    _instance ??= OAuthCallbackHandler._internal();
    return _instance!;
  }

  OAuthCallbackHandler._internal() {
    _setupAppLinks();
  }

  void _setupAppLinks() {
    debugPrint('🔗 Deep Link Handler: Setting up app links...');

    // Listen for incoming links when the app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Deep Link Handler: Link received while app running');
        debugPrint('🔗 Deep Link Handler: URI: $uri');
        debugPrint('🔗 Deep Link Handler: Scheme: ${uri.scheme}');
        debugPrint('🔗 Deep Link Handler: Host: ${uri.host}');
        debugPrint('🔗 Deep Link Handler: Path: ${uri.path}');
        debugPrint('🔗 Deep Link Handler: Query: ${uri.query}');
        _handleCallback(uri.toString());
      },
      onError: (err) {
        debugPrint('❌ Deep Link Handler: Error occurred: $err');
        debugPrint('❌ Deep Link Handler: Error type: ${err.runtimeType}');
        _onError?.call('Deep link error: $err');
      },
    );

    debugPrint('🔗 Deep Link Handler: Stream listener established');

    // Check for any initial link that started the app
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      debugPrint('🔗 Deep Link Handler: Checking for initial link...');
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        debugPrint('🔗 Deep Link Handler: Initial deep link found: $uri');
        await _handleCallback(uri.toString());
      } else {
        debugPrint('🔗 Deep Link Handler: No initial link found');
      }
    } catch (e) {
      debugPrint('❌ Deep Link Handler: Initial link check error: $e');
      debugPrint('❌ Deep Link Handler: Error type: ${e.runtimeType}');
    }
  }

  void setCallbacks({
    Function(EmailAccount)? onAccountAdded,
    Function(String)? onError,
  }) {
    _onAccountAdded = onAccountAdded;
    _onError = onError;
  }

  Future<void> _handleCallback(String url) async {
    debugPrint('📞 OAuth Callback: Handling callback URL...');
    debugPrint('📞 OAuth Callback: URL: $url');

    if (url.startsWith('qmail://auth')) {
      debugPrint('✅ OAuth Callback: Valid qmail:// scheme detected');
      try {
        debugPrint('📞 OAuth Callback: Creating AuthService instance...');
        final authService = AuthService();

        debugPrint('📞 OAuth Callback: Calling completeYahooSignIn...');
        final account = await authService.completeYahooSignIn(url);

        if (account != null) {
          debugPrint('✅ OAuth Callback: Account created successfully!');
          debugPrint('✅ OAuth Callback: Account email: ${account.email}');
          debugPrint('✅ OAuth Callback: Account ID: ${account.id}');

          // For Yahoo accounts, we need to handle app password setup
          if (account.provider == EmailProvider.yahoo) {
            debugPrint('📞 OAuth Callback: Yahoo account detected - app password required');
            _onAccountAdded?.call(account);
          } else {
            debugPrint('📞 OAuth Callback: Calling onAccountAdded callback...');
            _onAccountAdded?.call(account);
          }
        } else {
          debugPrint('❌ OAuth Callback: Account creation returned null');
          _onError?.call('Failed to complete Yahoo authentication');
        }
      } catch (e) {
        debugPrint('❌ OAuth Callback: Exception during completion: $e');
        debugPrint('❌ OAuth Callback: Exception type: ${e.runtimeType}');
        debugPrint('❌ OAuth Callback: Stack trace: ${StackTrace.current}');
        _onError?.call('Authentication failed: $e');
      }
    } else {
      debugPrint('❌ OAuth Callback: Invalid URL scheme');
      debugPrint('❌ OAuth Callback: Expected qmail://auth, got: $url');
    }
  }

  /// Register for OAuth callbacks
  void registerForCallbacks() {
    // This method is called to ensure the handler is initialized
    // The actual registration happens in the constructor
    debugPrint('OAuth callback handler registered');
  }

  /// Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    debugPrint('OAuth callback handler disposed');
  }
}