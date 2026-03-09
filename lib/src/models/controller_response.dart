/// Structured response from an Odoo web controller call.
class OdooControllerResponse {
  /// HTTP status code.
  final int statusCode;

  /// Whether the request was successful (2xx status code).
  final bool isSuccess;

  /// The parsed response data.
  ///
  /// For JSON-RPC endpoints this is the extracted result.
  /// For REST endpoints this is the raw decoded body.
  final dynamic data;

  /// Response headers.
  final Map<String, List<String>> headers;

  /// The request URL path.
  final String requestPath;

  /// The HTTP method used.
  final String method;

  const OdooControllerResponse({
    required this.statusCode,
    required this.isSuccess,
    required this.data,
    required this.headers,
    required this.requestPath,
    required this.method,
  });

  /// Convenience getter: casts [data] to `Map<String, dynamic>`.
  ///
  /// Throws if data is not a Map.
  Map<String, dynamic> get dataAsMap => data as Map<String, dynamic>;

  /// Convenience getter: casts [data] to `List<dynamic>`.
  ///
  /// Throws if data is not a List.
  List<dynamic> get dataAsList => data as List<dynamic>;

  @override
  String toString() =>
      'OdooControllerResponse($method $requestPath -> $statusCode, '
      'success: $isSuccess)';
}
