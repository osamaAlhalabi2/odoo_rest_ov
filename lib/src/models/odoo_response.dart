import '../exceptions/odoo_exceptions.dart';

/// Auto-incrementing request ID counter for JSON-RPC calls.
int _nextId = 1;

/// Builds a JSON-RPC 2.0 request payload.
class JsonRpcRequest {
  /// Builds a JSON-RPC 2.0 request map.
  ///
  /// [method] is typically `'call'` for Odoo.
  /// [params] are the request parameters.
  static Map<String, dynamic> build({
    required Map<String, dynamic> params,
    String method = 'call',
  }) {
    return {
      'jsonrpc': '2.0',
      'method': method,
      'id': _nextId++,
      'params': params,
    };
  }

  /// Resets the ID counter (useful for testing).
  static void resetIdCounter() {
    _nextId = 1;
  }
}

/// Parses a JSON-RPC 2.0 response.
class JsonRpcResponse {
  /// The result data if the call succeeded.
  final dynamic result;

  /// The error data if the call failed.
  final Map<String, dynamic>? error;

  /// The response ID.
  final int? id;

  const JsonRpcResponse._({this.result, this.error, this.id});

  /// Whether this response represents a success.
  bool get isSuccess => error == null;

  /// Whether this response represents an error.
  bool get isError => error != null;

  /// Parses a raw JSON-RPC response map.
  ///
  /// Throws [OdooProtocolException] if the response is not valid JSON-RPC 2.0.
  factory JsonRpcResponse.parse(Map<String, dynamic> data) {
    if (data['jsonrpc'] != '2.0') {
      throw const OdooProtocolException(
        'Invalid JSON-RPC response: missing jsonrpc 2.0 field',
      );
    }

    final error = data['error'] as Map<String, dynamic>?;
    return JsonRpcResponse._(
      result: data['result'],
      error: error,
      id: data['id'] as int?,
    );
  }

  /// Extracts the result, throwing a typed [OdooException] if the response
  /// contains an error.
  dynamic extractResult() {
    if (error != null) {
      throw OdooException.fromRpcError(error!);
    }
    return result;
  }
}
