import 'package:odoo_rest_ov/odoo_rest_ov.dart';
import 'package:test/test.dart';

void main() {
  group('OdooClientOptions', () {
    test('normalizedBaseUrl strips trailing slashes', () {
      const options = OdooClientOptions(
        baseUrl: 'https://example.com///',
        database: 'test',
      );
      expect(options.normalizedBaseUrl, 'https://example.com');
    });

    test('normalizedBaseUrl preserves clean URL', () {
      const options = OdooClientOptions(
        baseUrl: 'https://example.com',
        database: 'test',
      );
      expect(options.normalizedBaseUrl, 'https://example.com');
    });

    test('default timeouts are 30 seconds', () {
      const options = OdooClientOptions(
        baseUrl: 'https://example.com',
        database: 'test',
      );
      expect(options.connectTimeout, const Duration(seconds: 30));
      expect(options.receiveTimeout, const Duration(seconds: 30));
      expect(options.sendTimeout, const Duration(seconds: 30));
    });
  });

  group('OdooSession', () {
    test('fromJson parses complete session data', () {
      final session = OdooSession.fromJson({
        'uid': 2,
        'db': 'testdb',
        'name': 'Administrator',
        'username': 'admin',
        'company_id': 1,
        'partner_id': 3,
        'user_context': {'lang': 'en_US', 'tz': 'UTC'},
        'is_admin': true,
        'is_system': true,
        'is_internal_user': true,
        'is_public': false,
        'server_version': '17.0',
        'session_id': 'session123',
        'partner_display_name': 'MyCompany, Administrator',
      });

      expect(session.uid, 2);
      expect(session.db, 'testdb');
      expect(session.name, 'Administrator');
      expect(session.username, 'admin');
      expect(session.companyId, 1);
      expect(session.partnerId, 3);
      expect(session.userContext['lang'], 'en_US');
      expect(session.isAdmin, true);
      expect(session.isSystem, true);
      expect(session.isInternalUser, true);
      expect(session.isPublic, false);
      expect(session.serverVersion, '17.0');
      expect(session.sessionId, 'session123');
      expect(session.partnerDisplayName, 'MyCompany, Administrator');
    });

    test('fromJson handles minimal session data', () {
      final session = OdooSession.fromJson({
        'uid': 1,
      });

      expect(session.uid, 1);
      expect(session.db, '');
      expect(session.name, '');
      expect(session.username, '');
      expect(session.companyId, 0);
      expect(session.isSystem, false);
      expect(session.isInternalUser, false);
      expect(session.isPublic, false);
    });

    test('fromJson handles login field as fallback for username', () {
      final session = OdooSession.fromJson({
        'uid': 1,
        'login': 'admin@example.com',
      });

      expect(session.username, 'admin@example.com');
    });

    test('fromJson extracts company from user_companies', () {
      final session = OdooSession.fromJson({
        'uid': 2,
        'user_companies': {
          'current_company': 5,
          'allowed_companies': {
            '5': {'id': 5, 'name': 'Company A'},
            '10': {'id': 10, 'name': 'Company B'},
          },
        },
      });

      expect(session.companyId, 5);
      expect(session.allowedCompanies, hasLength(2));
    });

    test('copyWith creates modified copy', () {
      final original = OdooSession.fromJson({
        'uid': 1,
        'db': 'test',
        'name': 'Admin',
        'username': 'admin',
        'company_id': 1,
        'partner_id': 1,
        'user_context': {'lang': 'en_US'},
        'is_admin': true,
        'server_version': '17.0',
      });

      final updated = original.copyWith(
        userContext: {'lang': 'fr_FR'},
      );

      expect(updated.uid, 1);
      expect(updated.userContext['lang'], 'fr_FR');
      expect(original.userContext['lang'], 'en_US');
    });

    test('toString includes key info and user type', () {
      final session = OdooSession.fromJson({
        'uid': 2,
        'db': 'testdb',
        'username': 'admin',
        'name': 'Admin',
        'company_id': 1,
        'partner_id': 1,
        'user_context': {},
        'is_admin': false,
        'is_internal_user': true,
        'server_version': '17.0',
      });

      expect(session.toString(), contains('uid: 2'));
      expect(session.toString(), contains('db: testdb'));
      expect(session.toString(), contains('internal'));
    });
  });

  group('OdooSession - User Type', () {
    test('internal user type', () {
      final session = OdooSession.fromJson({
        'uid': 1,
        'is_internal_user': true,
        'is_public': false,
      });
      expect(session.userType, OdooUserType.internal);
      expect(session.isInternalUser, true);
      expect(session.isPortalUser, false);
    });

    test('portal user type', () {
      final session = OdooSession.fromJson({
        'uid': 1,
        'is_internal_user': false,
        'is_public': false,
      });
      expect(session.userType, OdooUserType.portal);
      expect(session.isPortalUser, true);
    });

    test('public user type', () {
      final session = OdooSession.fromJson({
        'uid': 1,
        'is_internal_user': false,
        'is_public': true,
      });
      expect(session.userType, OdooUserType.public);
      expect(session.isPublic, true);
      expect(session.isPortalUser, false);
    });
  });

  group('OdooSession - Timezone & Language', () {
    test('timezone returns tz from context', () {
      final session = OdooSession.fromJson({
        'uid': 1,
        'user_context': {'tz': 'Asia/Damascus', 'lang': 'en_US'},
      });
      expect(session.timezone, 'Asia/Damascus');
      expect(session.language, 'en_US');
    });

    test('timezone returns null when not set', () {
      final session = OdooSession.fromJson({
        'uid': 1,
        'user_context': {'lang': 'en_US'},
      });
      expect(session.timezone, isNull);
    });
  });

  group('OdooRecord extensions', () {
    test('id returns record ID', () {
      final record = <String, dynamic>{'id': 42, 'name': 'Test'};
      expect(record.id, 42);
    });

    test('name returns record name', () {
      final record = <String, dynamic>{'id': 1, 'name': 'Test Partner'};
      expect(record.name, 'Test Partner');
    });

    test('name returns empty string when missing', () {
      final record = <String, dynamic>{'id': 1};
      expect(record.name, '');
    });

    test('many2oneId extracts ID from list', () {
      final record = <String, dynamic>{
        'id': 1,
        'country_id': [1, 'United States'],
      };
      expect(record.many2oneId('country_id'), 1);
    });

    test('many2oneId returns int directly', () {
      final record = <String, dynamic>{'id': 1, 'country_id': 5};
      expect(record.many2oneId('country_id'), 5);
    });

    test('many2oneId returns null for false', () {
      final record = <String, dynamic>{'id': 1, 'country_id': false};
      expect(record.many2oneId('country_id'), null);
    });

    test('many2oneName extracts name from list', () {
      final record = <String, dynamic>{
        'id': 1,
        'country_id': [1, 'United States'],
      };
      expect(record.many2oneName('country_id'), 'United States');
    });

    test('many2oneName returns null for false', () {
      final record = <String, dynamic>{'id': 1, 'country_id': false};
      expect(record.many2oneName('country_id'), null);
    });

    test('x2manyIds extracts IDs from list', () {
      final record = <String, dynamic>{
        'id': 1,
        'tag_ids': [1, 2, 3],
      };
      expect(record.x2manyIds('tag_ids'), [1, 2, 3]);
    });

    test('x2manyIds returns empty list for false', () {
      final record = <String, dynamic>{'id': 1, 'tag_ids': false};
      expect(record.x2manyIds('tag_ids'), isEmpty);
    });
  });

  group('ServerInfo', () {
    test('fromJson parses server info', () {
      final info = ServerInfo.fromJson({
        'server_version': '17.0',
        'server_serie': '17.0',
        'protocol_version': 1,
        'server_version_info': [17, 0, 0, 'final', 0],
      });

      expect(info.serverVersion, '17.0');
      expect(info.serverSerie, '17.0');
      expect(info.protocolVersion, 1);
      expect(info.serverVersionInfo, [17, 0, 0, 'final', 0]);
    });

    test('toString includes version', () {
      final info = ServerInfo.fromJson({
        'server_version': '17.0',
        'server_serie': '17.0',
        'protocol_version': 1,
        'server_version_info': [],
      });
      expect(info.toString(), contains('17.0'));
    });
  });

  group('OdooControllerResponse', () {
    test('basic properties', () {
      const resp = OdooControllerResponse(
        statusCode: 200,
        isSuccess: true,
        data: {'key': 'value'},
        headers: {},
        requestPath: '/api/test',
        method: 'POST',
      );

      expect(resp.statusCode, 200);
      expect(resp.isSuccess, true);
      expect(resp.dataAsMap, {'key': 'value'});
      expect(resp.requestPath, '/api/test');
      expect(resp.method, 'POST');
    });

    test('dataAsList works for list data', () {
      const resp = OdooControllerResponse(
        statusCode: 200,
        isSuccess: true,
        data: [1, 2, 3],
        headers: {},
        requestPath: '/api/list',
        method: 'GET',
      );

      expect(resp.dataAsList, [1, 2, 3]);
    });

    test('toString includes method and path', () {
      const resp = OdooControllerResponse(
        statusCode: 404,
        isSuccess: false,
        data: null,
        headers: {},
        requestPath: '/api/missing',
        method: 'GET',
      );

      expect(resp.toString(), contains('GET'));
      expect(resp.toString(), contains('/api/missing'));
      expect(resp.toString(), contains('404'));
    });
  });
}
