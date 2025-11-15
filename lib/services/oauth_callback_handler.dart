import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import '../models/email_account.dart';

/// Handles OAuth callbacks from external browsers
class OAuthCallbackHandler {
  static OAuthCallbackHandler? _instance;
  static const MethodChannel _methodChannel = MethodChannel('qmail/oauth');

  // Callback for when account is successfully added
  Function(EmailAccount)? _onAccountAdded;
  Function(String)? _onError;

  static OAuthCallbackHandler get instance {
    _instance ??= OAuthCallbackHandler._internal();
    return _instance!;
  }

  OAuthCallbackHandler._internal() {
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    _methodChannel.setMethodCallHandler((MethodCall call) async {
      try {
        if (call.method == 'handleOAuthCallback') {
          final String? url = call.arguments['url'];
          if (url != null) {
            await _handleCallback(url);
          }
        }
      } catch (e) {
        debugPrint('OAuth callback error: $e');
        _onError?.call('OAuth callback failed: $e');
      }
    });
  }

  void setCallbacks({
    Function(EmailAccount)? onAccountAdded,
    Function(String)? onError,
  }) {
    _onAccountAdded = onAccountAdded;
    _onError = onError;
  }

  Future<void> _handleCallback(String url) async {
    if (url.startsWith('qmail://auth')) {
      try {
        // Complete Yahoo OAuth flow
        final authService = AuthService();
        final account = await authService.completeYahooSignIn(url);

        if (account != null) {
          _onAccountAdded?.call(account);
        } else {
          _onError?.call('Failed to complete Yahoo authentication');
        }
      } catch (e) {
        debugPrint('OAuth completion error: $e');
        _onError?.call('Authentication failed: $e');
      }
    }
  }

  /// Register for OAuth callbacks
  void registerForCallbacks() {
    // This method is called to ensure the handler is initialized
    // The actual registration happens in the constructor
    debugPrint('OAuth callback handler registered');
  }
}