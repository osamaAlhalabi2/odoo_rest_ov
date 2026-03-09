import 'package:dio/dio.dart';
import 'package:odoo_rest_ov/odoo_rest_ov.dart';
import 'package:test/test.dart';

/// A simple mock adapter for Dio that captures requests and returns
/// predefined responses.
class MockAdapter implements HttpClientAdapter {
  final Map<String, dynamic> Function(RequestOptions) handler;

  MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final result = handler(options);
    final jsonString = _encode(result);
    return ResponseBody.fromString(jsonString, 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}

  String _encode(Map<String, dynamic> data) {
    return _jsonEncode(data);
  }
}

String _jsonEncode(Object? value) {
  if (value == null) return 'null';
  if (value is bool) return value.toString();
  if (value is num) return value.toString();
  if (value is String) {
    return '"${value.replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }
  if (value is List) {
    return '[${value.map(_jsonEncode).join(',')}]';
  }
  if (value is Map) {
    final entries =
        value.entries.map((e) => '"${e.key}":${_jsonEncode(e.value)}');
    return '{${entries.join(',')}}';
  }
  return '"$value"';
}

OdooClient _createMockClient(
    Map<String, dynamic> Function(RequestOptions) handler) {
  const options = OdooClientOptions(
    baseUrl: 'http://localhost:8069',
    database: 'testdb',
  );
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8069'));
  dio.httpClientAdapter = MockAdapter(handler);
  return OdooClient.withDio(options, dio);
}

void main() {
  setUp(() {
    JsonRpcRequest.resetIdCounter();
  });

  group('OdooClient authentication', () {
    test('authenticate sets session on success', () async {
      final client = _createMockClient((req) {
        return {
          'jsonrpc': '2.0',
          'id': 1,
          'result': {
            'uid': 2,
            'db': 'testdb',
            'name': 'Admin',
            'username': 'admin',
            'company_id': 1,
            'partner_id': 3,
            'user_context': {'lang': 'en_US', 'tz': 'Asia/Damascus'},
            'is_admin': true,
            'is_system': true,
            'is_internal_user': true,
            'is_public': false,
            'server_version': '17.0',
            'session_id': 'abc123',
          },
        };
      });

      expect(client.isAuthenticated, false);
      final session = await client.authenticate('admin', 'admin');

      expect(client.isAuthenticated, true);
      expect(session.uid, 2);
      expect(session.db, 'testdb');
      expect(session.name, 'Admin');
      expect(session.username, 'admin');
      expect(session.isAdmin, true);
      expect(session.isSystem, true);
      expect(session.isInternalUser, true);
      expect(session.userType, OdooUserType.internal);
      expect(session.timezone, 'Asia/Damascus');
      expect(session.serverVersion, '17.0');
      // Verify timezone was auto-applied to context
      expect(client.buildContext()['tz'], 'Asia/Damascus');

      client.close();
    });

    test('authenticate throws on uid=false', () async {
      final client = _createMockClient((req) {
        return {
          'jsonrpc': '2.0',
          'id': 1,
          'result': {'uid': false},
        };
      });

      expect(
        () => client.authenticate('admin', 'wrong'),
        throwsA(isA<OdooAccessDeniedException>()),
      );

      client.close();
    });

    test('authenticate throws on RPC error', () async {
      final client = _createMockClient((req) {
        return {
          'jsonrpc': '2.0',
          'id': 1,
          'error': {
            'message': 'Access Denied',
            'data': {
              'name': 'odoo.exceptions.AccessDenied',
              'message': 'Bad credentials',
            },
          },
        };
      });

      expect(
        () => client.authenticate('admin', 'wrong'),
        throwsA(isA<OdooAccessDeniedException>()),
      );

      client.close();
    });
  });

  group('OdooClient ORM methods', () {
    late OdooClient client;
    late List<RequestOptions> capturedRequests;

    setUp(() {
      capturedRequests = [];
      client = _createMockClient((req) {
        capturedRequests.add(req);
        final path = req.path;

        if (path.contains('search_read')) {
          return {
            'jsonrpc': '2.0',
            'id': 1,
            'result': [
              {'id': 1, 'name': 'Partner 1'},
              {'id': 2, 'name': 'Partner 2'},
            ],
          };
        }
        if (path.contains('search_count')) {
          return {'jsonrpc': '2.0', 'id': 1, 'result': 42};
        }
        if (path.contains('/search')) {
          return {
            'jsonrpc': '2.0',
            'id': 1,
            'result': [1, 2, 3],
          };
        }
        if (path.contains('/read')) {
          return {
            'jsonrpc': '2.0',
            'id': 1,
            'result': [
              {'id': 1, 'name': 'Partner 1'},
            ],
          };
        }
        if (path.contains('/create')) {
          return {'jsonrpc': '2.0', 'id': 1, 'result': 10};
        }
        if (path.contains('/write')) {
          return {'jsonrpc': '2.0', 'id': 1, 'result': true};
        }
        if (path.contains('/unlink')) {
          return {'jsonrpc': '2.0', 'id': 1, 'result': true};
        }
        if (path.contains('fields_get')) {
          return {
            'jsonrpc': '2.0',
            'id': 1,
            'result': {
              'name': {'type': 'char', 'string': 'Name'},
            },
          };
        }

        return {'jsonrpc': '2.0', 'id': 1, 'result': null};
      });
    });

    tearDown(() => client.close());

    test('searchRead returns list of records', () async {
      final records = await client.searchRead(
        'res.partner',
        [
          ['is_company', '=', true]
        ],
        fields: ['name'],
        limit: 10,
      );

      expect(records, hasLength(2));
      expect(records[0]['name'], 'Partner 1');
      expect(records[1]['name'], 'Partner 2');
    });

    test('search returns list of IDs', () async {
      final ids = await client.search('res.partner', []);
      expect(ids, [1, 2, 3]);
    });

    test('searchCount returns count', () async {
      final count = await client.searchCount('res.partner', []);
      expect(count, 42);
    });

    test('read returns records by ID', () async {
      final records = await client.read('res.partner', [1]);
      expect(records, hasLength(1));
      expect(records[0]['id'], 1);
    });

    test('create returns new record ID', () async {
      final id = await client.create('res.partner', {'name': 'New'});
      expect(id, 10);
    });

    test('write returns true on success', () async {
      final result =
          await client.write('res.partner', [1], {'name': 'Updated'});
      expect(result, true);
    });

    test('unlink returns true on success', () async {
      final result = await client.unlink('res.partner', [1]);
      expect(result, true);
    });

    test('fieldsGet returns field metadata', () async {
      final fields = await client.fieldsGet('res.partner');
      expect(fields, containsPair('name', {'type': 'char', 'string': 'Name'}));
    });
  });

  group('OdooClient context', () {
    test('setLanguage updates context', () {
      final client = _createMockClient((_) => {
            'jsonrpc': '2.0',
            'id': 1,
            'result': null,
          });

      client.setLanguage('fr_FR');
      final ctx = client.buildContext();
      expect(ctx['lang'], 'fr_FR');

      client.close();
    });

    test('setTimezone updates context', () {
      final client = _createMockClient((_) => {
            'jsonrpc': '2.0',
            'id': 1,
            'result': null,
          });

      client.setTimezone('Europe/Paris');
      final ctx = client.buildContext();
      expect(ctx['tz'], 'Europe/Paris');

      client.close();
    });

    test('context overrides take priority', () {
      final client = _createMockClient((_) => {
            'jsonrpc': '2.0',
            'id': 1,
            'result': null,
          });

      client.setLanguage('en_US');
      final ctx = client.buildContext({'lang': 'ar_SY'});
      expect(ctx['lang'], 'ar_SY');

      client.close();
    });
  });

  group('OdooSession', () {
    test('emits session changes', () async {
      final client = _createMockClient((req) {
        return {
          'jsonrpc': '2.0',
          'id': 1,
          'result': {
            'uid': 2,
            'db': 'testdb',
            'name': 'Admin',
            'username': 'admin',
            'company_id': 1,
            'partner_id': 3,
            'user_context': {},
            'is_admin': true,
            'server_version': '17.0',
          },
        };
      });

      final sessions = <OdooSession?>[];
      client.sessionStream.listen(sessions.add);

      await client.authenticate('admin', 'admin');

      // Give the stream time to emit
      await Future<void>.delayed(Duration.zero);

      expect(sessions, hasLength(1));
      expect(sessions[0]?.uid, 2);

      client.close();
    });

    test('checkSession returns true when valid', () async {
      final client = _createMockClient((req) {
        return {
          'jsonrpc': '2.0',
          'id': 1,
          'result': {
            'uid': 2,
            'db': 'testdb',
            'name': 'Admin',
            'username': 'admin',
            'company_id': 1,
            'partner_id': 3,
            'user_context': {'tz': 'UTC'},
            'is_admin': true,
            'is_internal_user': true,
            'server_version': '17.0',
          },
        };
      });

      // First authenticate
      await client.authenticate('admin', 'admin');
      expect(client.isAuthenticated, true);

      // Then check session
      final isValid = await client.checkSession();
      expect(isValid, true);
      expect(client.isAuthenticated, true);

      client.close();
    });

    test('checkSession returns false when no session', () async {
      final client = _createMockClient((_) => {
            'jsonrpc': '2.0',
            'id': 1,
            'result': null,
          });

      final isValid = await client.checkSession();
      expect(isValid, false);

      client.close();
    });
  });
}
