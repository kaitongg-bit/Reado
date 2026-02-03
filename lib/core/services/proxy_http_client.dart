import 'package:http/http.dart' as http;

/// A custom HTTP client that proxies requests to a specified base URL
/// when the target host is a Google API.
class ProxyHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final String proxyUrl;

  ProxyHttpClient(this.proxyUrl);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.host.contains('googleapis.com')) {
      final proxyUri = Uri.parse(proxyUrl);

      // 🚀 优化路径拼接逻辑
      String proxyPath = proxyUri.path;
      if (proxyPath.endsWith('/')) {
        proxyPath = proxyPath.substring(0, proxyPath.length - 1);
      }

      String originalPath = request.url.path;
      if (!originalPath.startsWith('/')) {
        originalPath = '/$originalPath';
      }

      final newPath = '$proxyPath$originalPath';

      final newUrl = request.url.replace(
        scheme: proxyUri.scheme,
        host: proxyUri.host,
        port: proxyUri.port,
        path: newPath,
      );

      final newRequest = http.Request(request.method, newUrl);
      newRequest.headers.addAll(request.headers);

      if (request is http.Request) {
        newRequest.bodyBytes = request.bodyBytes;
      }

      return _inner.send(newRequest);
    }
    return _inner.send(request);
  }
}
