import '../models/odoo_response.dart';

/// Static helpers for JSON-RPC 2.0 communication with Odoo.
class JsonRpc {
  JsonRpc._();

  /// Builds a JSON-RPC request for an Odoo endpoint.
  static Map<String, dynamic> buildRequest(Map<String, dynamic> params) {
    return JsonRpcRequest.build(params: params);
  }

  /// Builds parameters for a `call_kw` ORM method call.
  static Map<String, dynamic> buildCallKwParams({
    required String model,
    required String method,
    required List<dynamic> args,
    required Map<String, dynamic> kwargs,
  }) {
    return {
      'model': model,
      'method': method,
      'args': args,
      'kwargs': kwargs,
    };
  }

  /// Extracts the result from a raw JSON-RPC response map.
  ///
  /// Throws a typed [OdooException] on error.
  static dynamic extractResult(Map<String, dynamic> responseData) {
    final response = JsonRpcResponse.parse(responseData);
    return response.extractResult();
  }
}
