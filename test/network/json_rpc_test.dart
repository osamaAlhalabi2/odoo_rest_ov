import 'package:odoo_rest_ov/odoo_rest_ov.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    JsonRpcRequest.resetIdCounter();
  });

  group('JsonRpcRequest', () {
    test('builds valid JSON-RPC 2.0 request', () {
      final request = JsonRpcRequest.build(params: {'key': 'value'});

      expect(request['jsonrpc'], '2.0');
      expect(request['method'], 'call');
      expect(request['id'], 1);
      expect(request['params'], {'key': 'value'});
    });

    test('auto-increments request ID', () {
      final r1 = JsonRpcRequest.build(params: {});
      final r2 = JsonRpcRequest.build(params: {});
      final r3 = JsonRpcRequest.build(params: {});

      expect(r1['id'], 1);
      expect(r2['id'], 2);
      expect(r3['id'], 3);
    });

    test('supports custom method', () {
      final request = JsonRpcRequest.build(
        params: {},
        method: 'custom_method',
      );
      expect(request['method'], 'custom_method');
    });
  });

  group('JsonRpcResponse', () {
    test('parses successful response', () {
      final response = JsonRpcResponse.parse({
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'uid': 2, 'name': 'Admin'},
      });

      expect(response.isSuccess, true);
      expect(response.isError, false);
      expect(response.id, 1);
      expect(response.result, {'uid': 2, 'name': 'Admin'});
    });

    test('parses error response', () {
      final response = JsonRpcResponse.parse({
        'jsonrpc': '2.0',
        'id': 1,
        'error': {
          'message': 'Access Denied',
          'data': {
            'name': 'odoo.exceptions.AccessDenied',
            'message': 'Invalid credentials',
          },
        },
      });

      expect(response.isSuccess, false);
      expect(response.isError, true);
      expect(response.error, isNotNull);
    });

    test('throws OdooProtocolException for invalid response', () {
      expect(
        () => JsonRpcResponse.parse({'not': 'jsonrpc'}),
        throwsA(isA<OdooProtocolException>()),
      );
    });

    test('extractResult returns result on success', () {
      final response = JsonRpcResponse.parse({
        'jsonrpc': '2.0',
        'id': 1,
        'result': [1, 2, 3],
      });

      expect(response.extractResult(), [1, 2, 3]);
    });

    test('extractResult throws typed exception on error', () {
      final response = JsonRpcResponse.parse({
        'jsonrpc': '2.0',
        'id': 1,
        'error': {
          'message': 'Validation Error',
          'data': {
            'name': 'odoo.exceptions.ValidationError',
            'message': 'Field required',
          },
        },
      });

      expect(
        () => response.extractResult(),
        throwsA(isA<OdooValidationException>()),
      );
    });
  });

  group('JsonRpc helpers', () {
    test('buildRequest creates valid request', () {
      final request = JsonRpc.buildRequest({'db': 'test'});
      expect(request['jsonrpc'], '2.0');
      expect(request['params'], {'db': 'test'});
    });

    test('buildCallKwParams creates correct structure', () {
      final params = JsonRpc.buildCallKwParams(
        model: 'res.partner',
        method: 'search_read',
        args: [[]],
        kwargs: {'fields': ['name']},
      );

      expect(params['model'], 'res.partner');
      expect(params['method'], 'search_read');
      expect(params['args'], [[]]);
      expect(params['kwargs'], {'fields': ['name']});
    });

    test('extractResult from raw response data', () {
      final result = JsonRpc.extractResult({
        'jsonrpc': '2.0',
        'id': 1,
        'result': 42,
      });
      expect(result, 42);
    });

    test('extractResult throws on error response', () {
      expect(
        () => JsonRpc.extractResult({
          'jsonrpc': '2.0',
          'id': 1,
          'error': {
            'message': 'Error',
            'data': {'name': 'odoo.exceptions.UserError', 'message': 'Oops'},
          },
        }),
        throwsA(isA<OdooUserErrorException>()),
      );
    });
  });
}
