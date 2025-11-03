
import 'package:http/http.dart' as http;

/// A custom HTTP client that adds authentication headers to every request.
///
/// This client is used to make authenticated requests to the Google API.
/// It wraps a standard [http.Client] and adds the necessary OAuth 2.0
/// headers to each request.
class GoogleAuthClient extends http.BaseClient {
  /// The authentication headers to be added to each request.
  final Map<String, String> _headers;

  /// The underlying HTTP client.
  final http.Client _client = http.Client();

  /// Creates a new instance of the [GoogleAuthClient].
  ///
  /// The [headers] parameter should contain the authentication headers
  /// required by the Google API.
  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Add the authentication headers to the request before sending it.
    return _client.send(request..headers.addAll(_headers));
  }

  @override
  void close() {
    // Close the underlying HTTP client when this client is closed.
    _client.close();
  }
}
