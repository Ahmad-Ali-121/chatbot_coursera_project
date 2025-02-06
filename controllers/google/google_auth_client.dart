import 'package:http/http.dart' as http;

// A custom client class to handle authentication headers
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return http.Client().send(request);
  }
}