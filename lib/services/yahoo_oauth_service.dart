import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// OAuth service for Yahoo Mail authentication.
///
/// Handles the OAuth2 flow for Yahoo Mail API access.
class YahooOAuthService {
  // Singleton pattern to preserve state across instances
  static YahooOAuthService? _instance;
  static YahooOAuthService get instance {
    _instance ??= YahooOAuthService._internal();
    return _instance!;
  }
  YahooOAuthService._internal();

  // Yahoo OAuth configuration from your provided credentials
  static const String _clientId = 'dj0yJmk9dUlhWDdjNk9RMzlvJmQ9WVdrOVVWWlpiRzloVWtFbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTkw';
  static const String _redirectUri = 'qmail://auth';
  static const String _authUrl = 'https://api.login.yahoo.com/oauth2/request_auth';
  static const String _tokenUrl = 'https://api.login.yahoo.com/oauth2/get_token';

  String? _codeVerifier;
  String? _state;

  // Secure storage for persisting OAuth state across app restarts
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Initiates the Yahoo OAuth flow.
  ///
  /// Returns the authorization URL that the user should visit.
  Future<String> getAuthorizationUrl() async {
    debugPrint('🔑 Yahoo OAuth: Starting authorization URL generation...');

    // Generate PKCE parameters
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);
    _state = _generateRandomString(32);

    // Store OAuth state in secure storage to persist across app restarts
    await _secureStorage.write(key: 'yahoo_oauth_state', value: _state);
    await _secureStorage.write(key: 'yahoo_oauth_code_verifier', value: _codeVerifier);

    debugPrint('🔑 Yahoo OAuth: Generated PKCE parameters');
    debugPrint('🔑 Yahoo OAuth: Code verifier length: ${_codeVerifier!.length}');
    debugPrint('🔑 Yahoo OAuth: State: $_state');
    debugPrint('🔑 Yahoo OAuth: State stored in secure storage for persistence');

    // Build authorization URL
    final authUri = Uri.parse(_authUrl).replace(
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': 'openid profile email',
        'state': _state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    final url = authUri.toString();
    debugPrint('🔑 Yahoo OAuth: Generated authorization URL');
    debugPrint('🔑 Yahoo OAuth: URL: $url');
    debugPrint('🔑 Yahoo OAuth: Scope in URL: openid profile email');

    return url;
  }

  /// Handles the authorization callback and exchanges the code for tokens.
  ///
  /// Returns a map containing access_token and refresh_token.
  Future<Map<String, String>?> handleAuthorizationCallback(
    String callbackUrl,
  ) async {
    try {
      debugPrint('🔙 Yahoo OAuth Callback: Received callback URL');
      debugPrint('🔙 Yahoo OAuth Callback: URL: $callbackUrl');

      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      debugPrint('🔙 Yahoo OAuth Callback: Parsed URL parameters:');
      debugPrint('🔙 Yahoo OAuth Callback: - code: ${code != null ? '${code.substring(0, 10)}...' : 'null'}');
      debugPrint('🔙 Yahoo OAuth Callback: - state: $state');
      debugPrint('🔙 Yahoo OAuth Callback: - error: $error');
      debugPrint('🔙 Yahoo OAuth Callback: - error_description: $errorDescription');

      if (error != null) {
        debugPrint('❌ Yahoo OAuth Callback: Error from Yahoo: $error');
        if (errorDescription != null) {
          debugPrint('❌ Yahoo OAuth Callback: Error description: $errorDescription');
        }
        throw Exception('OAuth error: $error${errorDescription != null ? ' - $errorDescription' : ''}');
      }

      if (code == null) {
        debugPrint('❌ Yahoo OAuth Callback: No authorization code received');
        throw Exception('No authorization code received');
      }

      // Load stored state from secure storage
      debugPrint('🔙 Yahoo OAuth Callback: Loading stored state from secure storage...');
      final storedState = await _secureStorage.read(key: 'yahoo_oauth_state');
      final storedCodeVerifier = await _secureStorage.read(key: 'yahoo_oauth_code_verifier');

      // Update instance variables from storage
      _state = storedState;
      _codeVerifier = storedCodeVerifier;

      debugPrint('🔙 Yahoo OAuth Callback: Validating state parameter...');
      debugPrint('🔙 Yahoo OAuth Callback: Expected state (from storage): $_state');
      debugPrint('🔙 Yahoo OAuth Callback: Received state: $state');

      if (state != _state) {
        debugPrint('❌ Yahoo OAuth Callback: State validation failed!');
        debugPrint('❌ Yahoo OAuth Callback: Stored state available: ${storedState != null}');
        debugPrint('❌ Yahoo OAuth Callback: Code verifier available: ${storedCodeVerifier != null}');
        throw Exception('Invalid state parameter');
      }

      debugPrint('✅ Yahoo OAuth Callback: State validation passed');
      debugPrint('🔄 Yahoo OAuth Callback: Starting token exchange...');

      // Exchange authorization code for tokens
      final result = await _exchangeCodeForTokens(code);

      if (result != null) {
        // Clear OAuth state from storage after successful authentication
        debugPrint('✅ Yahoo OAuth Callback: Clearing stored OAuth state...');
        await _secureStorage.delete(key: 'yahoo_oauth_state');
        await _secureStorage.delete(key: 'yahoo_oauth_code_verifier');
      }

      return result;
    } catch (e) {
      debugPrint('❌ Yahoo OAuth callback error: $e');
      return null;
    }
  }

  /// Launches the Yahoo OAuth flow in the browser.
  Future<bool> launchOAuthFlow() async {
    try {
      final authUrl = await getAuthorizationUrl();
      final uri = Uri.parse(authUrl);

      debugPrint('Attempting to launch Yahoo OAuth URL: $authUrl');

      // Try different launch modes for better compatibility
      bool launched = false;

      try {
        // First try external application mode
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('External application mode failed: $e');
      }

      if (!launched) {
        try {
          // Fallback to platform default
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('Platform default mode failed: $e');
        }
      }

      if (!launched) {
        try {
          // Last resort - external non-browser mode
          launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
        } catch (e) {
          debugPrint('External non-browser mode failed: $e');
        }
      }

      if (launched) {
        debugPrint('Yahoo OAuth URL launched successfully');
        return true;
      } else {
        throw Exception('Could not launch OAuth URL - no compatible browser found');
      }
    } catch (e) {
      debugPrint('Yahoo OAuth launch error: $e');
      return false;
    }
  }

  /// Refreshes an access token using a refresh token.
  Future<Map<String, String>?> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': _clientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'] ?? refreshToken,
        };
      } else {
        debugPrint('Yahoo token refresh failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Yahoo token refresh error: $e');
      return null;
    }
  }

  // --- Private Helper Methods ---

  /// Exchanges the authorization code for access and refresh tokens.
  Future<Map<String, String>?> _exchangeCodeForTokens(String code) async {
    try {
      debugPrint('🔄 Yahoo Token Exchange: Starting token exchange...');
      debugPrint('🔄 Yahoo Token Exchange: Code: ${code.substring(0, 10)}...');
      debugPrint('🔄 Yahoo Token Exchange: Client ID: ${_clientId.substring(0, 20)}...');
      debugPrint('🔄 Yahoo Token Exchange: Redirect URI: $_redirectUri');
      debugPrint('🔄 Yahoo Token Exchange: Code verifier length: ${_codeVerifier?.length}');

      final requestBody = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'client_id': _clientId,
        'code_verifier': _codeVerifier!,
      };

      debugPrint('🔄 Yahoo Token Exchange: Making POST request to: $_tokenUrl');

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      );

      debugPrint('🔄 Yahoo Token Exchange: Response status: ${response.statusCode}');
      debugPrint('🔄 Yahoo Token Exchange: Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        debugPrint('✅ Yahoo Token Exchange: Success! Parsing response...');
        final data = json.decode(response.body);
        debugPrint('✅ Yahoo Token Exchange: Access token received: ${data['access_token'] != null}');
        debugPrint('✅ Yahoo Token Exchange: Refresh token received: ${data['refresh_token'] != null}');

        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
        };
      } else {
        debugPrint('❌ Yahoo Token Exchange: Failed with status ${response.statusCode}');
        debugPrint('❌ Yahoo Token Exchange: Response body: ${response.body}');

        // Try to parse error details
        try {
          final errorData = json.decode(response.body);
          debugPrint('❌ Yahoo Token Exchange: Error details: $errorData');
        } catch (e) {
          debugPrint('❌ Yahoo Token Exchange: Could not parse error response as JSON');
        }

        return null;
      }
    } catch (e) {
      debugPrint('❌ Yahoo Token Exchange: Exception occurred: $e');
      debugPrint('❌ Yahoo Token Exchange: Exception type: ${e.runtimeType}');
      return null;
    }
  }

  /// Generates a random string for PKCE code verifier.
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      128,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Generates a SHA256-based code challenge for PKCE.
  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Generates a random string of specified length.
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}