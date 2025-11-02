import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:email_mobile_application/constants/strings.dart';
import 'package:email_mobile_application/local_db/local_db.dart';
import 'package:email_mobile_application/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  GoogleSignIn? _googleSignIn;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => LocalDB.email != null;
  String? get userEmail => LocalDB.email;
  String? get userName => LocalDB.name;
  String? get userPhoto => LocalDB.photo;

  // Initialize Google Sign In
  void initialize() {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/gmail.settings.basic',
      ],
    );
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sign in with Google
  Future<bool> signInWithGoogle({bool forceAccountPicker = false}) async {
    if (_googleSignIn == null) {
      _setError('Google Sign In not initialized');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      // If forcing account picker or switching accounts, sign out first
      if (forceAccountPicker || await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
      }

      final GoogleSignInAccount? googleSignInAccount = await _googleSignIn!.signIn();

      if (googleSignInAccount == null) {
        _setLoading(false);
        return false; // User cancelled
      }

      final credentials = await _googleSignIn!.currentUser!.authentication;

      // Get Firebase ID token
      final idTokenResponse = await _getFirebaseIdToken(credentials.idToken!);
      if (idTokenResponse == null) {
        _setError('Failed to get Firebase ID token');
        _setLoading(false);
        return false;
      }

      // Prepare Gmail payload
      final gmailPayload = _buildGmailPayload(credentials, idTokenResponse);

      // Authenticate with backend
      final authResponse = await _apiService.authenticate(
        email: googleSignInAccount.email,
        gmailPayload: gmailPayload,
      );

      _setLoading(false);

      if (authResponse.isSuccess) {
        // Store user data locally
        LocalDB.setEmail(googleSignInAccount.email);
        LocalDB.setName(googleSignInAccount.displayName ?? "");
        LocalDB.setPhoto(googleSignInAccount.photoUrl ?? "");

        notifyListeners();
        return true;
      } else {
        _setError(authResponse.error);
        return false;
      }
    } catch (error) {
      _setError('Sign in failed: $error');
      _setLoading(false);
      return false;
    }
  }

  // Switch to a different Google account
  Future<bool> switchAccount() async {
    try {
      // Clear any existing authentication state first
      await signOut();

      // Now sign in with account picker
      return await signInWithGoogle(forceAccountPicker: true);
    } catch (e) {
      _setError('Failed to switch account: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn?.signOut();

      // Clear local storage
      LocalDB.setEmail('');
      LocalDB.setName('');
      LocalDB.setPhoto('');

      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    }
  }

  // Get Firebase ID token
  Future<Map<String, dynamic>?> _getFirebaseIdToken(String idToken) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=${AppConfig.firebaseApi}'
      );

      final response = await http.post(
        url,
        headers: {'Content-type': 'application/json'},
        body: jsonEncode({
          'postBody': 'id_token=$idToken&providerId=google.com',
          'requestUri': 'http://localhost',
          'returnIdpCredential': true,
          'returnSecureToken': true
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Build Gmail payload
  Map<String, dynamic> _buildGmailPayload(
    GoogleSignInAuthentication credentials,
    Map<String, dynamic> firebaseResponse,
  ) {
    final rawUserInfo = jsonDecode(firebaseResponse['rawUserInfo']);

    return {
      "access_token": credentials.accessToken,
      "client_id": AppConfig.clientId,
      "client_secret": AppConfig.clientSecret,
      "refresh_token": firebaseResponse['refreshToken'],
      "token_expiry": _convertExpiry(rawUserInfo['exp']),
      "token_uri": "https://oauth2.googleapis.com/token",
      "user_agent": null,
      "revoke_uri": "https://oauth2.googleapis.com/revoke",
      "id_token": null,
      "id_token_jwt": null,
      "token_response": {
        "access_token": credentials.accessToken,
        "expires_in": firebaseResponse['expiresIn'],
        "scope": "https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/gmail.settings.basic",
        "token_type": "Bearer"
      },
      "scopes": [
        "https://www.googleapis.com/auth/gmail.settings.basic",
        "https://www.googleapis.com/auth/gmail.modify"
      ],
      "token_info_uri": "https://oauth2.googleapis.com/tokeninfo",
      "invalid": false,
      "_class": "OAuth2Credentials",
      "_module": "oauth2client.client"
    };
  }

  // Convert expiry timestamp
  String _convertExpiry(int timestampInSeconds) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      timestampInSeconds * 1000,
      isUtc: true,
    );
    return dateTime.toIso8601String();
  }
}