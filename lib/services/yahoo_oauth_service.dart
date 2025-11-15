import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

/// OAuth service for Yahoo Mail authentication.
///
/// Handles the OAuth2 flow for Yahoo Mail API access.
class YahooOAuthService {
  // Yahoo OAuth configuration from your provided credentials
  static const String _clientId = 'dj0yJmk9dUlhWDdjNk9RMzlvJmQ9WVdrOVVWWlpiRzloVWtFbWNHbzlNQT09JnM9Y29uc3VtZXJzZWNyZXQmc3Y9MCZ4PTkw';
  static const String _redirectUri = 'qmail://auth';
  static const String _authUrl = 'https://api.login.yahoo.com/oauth2/request_auth';
  static const String _tokenUrl = 'https://api.login.yahoo.com/oauth2/get_token';

  String? _codeVerifier;
  String? _state;

  /// Initiates the Yahoo OAuth flow.
  ///
  /// Returns the authorization URL that the user should visit.
  Future<String> getAuthorizationUrl() async {
    // Generate PKCE parameters
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);
    _state = _generateRandomString(32);

    // Build authorization URL
    final authUri = Uri.parse(_authUrl).replace(
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': 'mail-r mail-w',
        'state': _state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      },
    );

    return authUri.toString();
  }

  /// Handles the authorization callback and exchanges the code for tokens.
  ///
  /// Returns a map containing access_token and refresh_token.
  Future<Map<String, String>?> handleAuthorizationCallback(
    String callbackUrl,
  ) async {
    try {
      final uri = Uri.parse(callbackUrl);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        throw Exception('OAuth error: $error');
      }

      if (code == null) {
        throw Exception('No authorization code received');
      }

      if (state != _state) {
        throw Exception('Invalid state parameter');
      }

      // Exchange authorization code for tokens
      return await _exchangeCodeForTokens(code);
    } catch (e) {
      debugPrint('Yahoo OAuth callback error: $e');
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
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': _redirectUri,
          'client_id': _clientId,
          'code_verifier': _codeVerifier!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
        };
      } else {
        debugPrint('Token exchange failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Token exchange error: $e');
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