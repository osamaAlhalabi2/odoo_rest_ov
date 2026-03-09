// ignore_for_file: avoid_print, unused_local_variable

import 'package:odoo_rest_ov/odoo_rest_ov.dart';

Future<void> main() async {
  // 1. Create client
  final client = OdooClient(OdooClientOptions(
    baseUrl: 'https://mycompany.odoo.com',
    database: 'mydb',
    enableLogging: true,
    onSessionChanged: (session) {
      if (session != null) {
        print('Logged in as ${session.name} (${session.userType.name})');
      } else {
        print('Logged out');
      }
    },
  ));

  try {
    // ==========================================
    // AUTHENTICATION & SESSION
    // ==========================================

    // Authenticate (timezone is auto-detected from user settings)
    final session = await client.authenticate('admin', 'admin');
    print('User: ${session.name} (uid: ${session.uid})');
    print('Timezone: ${session.timezone}'); // e.g. "Asia/Damascus"
    print('Language: ${session.language}'); // e.g. "en_US"

    // User type detection (F)
    print('User type: ${session.userType}'); // OdooUserType.internal
    print('Is internal: ${session.isInternalUser}');
    print('Is portal: ${session.isPortalUser}');
    print('Is public: ${session.isPublic}');
    print('Is admin: ${session.isAdmin}');
    print('Is system: ${session.isSystem}');

    // Check session validity (B1)
    final isValid = await client.checkSession();
    print('Session valid: $isValid');

    // Refresh session to get latest data (B3)
    final refreshed = await client.refreshSession();
    print('Refreshed session for: ${refreshed.name}');

    // ==========================================
    // TIMEZONE FIX (A)
    // ==========================================

    // The timezone is auto-applied after authenticate().
    // To override manually (e.g. use device timezone):
    client.setTimezone('America/New_York');

    // All subsequent ORM calls will use this timezone in context.
    // Odoo converts datetime fields from UTC to this timezone
    // in views and reports.

    // ==========================================
    // ORM METHODS
    // ==========================================

    // Search & Read with fluent domain builder
    final domain = OdooDomain()
        .where('is_company').equals(true)
        .where('customer_rank').greaterThan(0)
        .build();

    final partners = await client.searchRead(
      'res.partner',
      domain,
      fields: ['name', 'email', 'phone', 'country_id'],
      limit: 10,
      order: 'name asc',
    );

    for (final partner in partners) {
      print('${partner.name} - ${partner['email']}');
      final country = partner.many2oneName('country_id');
      if (country != null) print('  Country: $country');
    }

    // Count
    final count = await client.searchCount('res.partner', domain);
    print('Total matching: $count');

    // Create
    final newId = await client.create('res.partner', {
      'name': 'Test Partner',
      'email': 'test@example.com',
    });
    print('Created partner ID: $newId');

    // Update
    await client.write('res.partner', [newId], {'phone': '+1234567890'});

    // Read
    final records = await client.read('res.partner', [newId],
        fields: ['name', 'email', 'phone']);
    print('Read: ${records.first}');

    // Delete
    await client.unlink('res.partner', [newId]);

    // OR domain example
    final orDomain = OdooDomain()
        .or()
        .where('email').ilike('%@gmail.com')
        .where('email').ilike('%@yahoo.com')
        .build();

    // Raw domain (backward compatible)
    final rawDomain = [
      ['name', 'ilike', 'test'],
      ['active', '=', true],
    ];

    // ==========================================
    // CONTROLLER CALLS (D)
    // ==========================================

    // JSON-RPC endpoint (auto-wrapped)
    final rpcResponse = await client.callController(
      '/web/webclient/version_info',
      params: {},
    );
    print('Controller status: ${rpcResponse.statusCode}');
    print('Controller data: ${rpcResponse.data}');
    print('Success: ${rpcResponse.isSuccess}');

    // REST-style GET endpoint
    // final restResponse = await client.callController(
    //   '/api/v1/partners',
    //   method: 'GET',
    //   params: {'limit': '10'},
    //   isJsonRpc: false,
    // );
    // print('Partners: ${restResponse.dataAsList}');

    // Custom headers
    // final customResponse = await client.callController(
    //   '/api/v1/data',
    //   method: 'POST',
    //   params: {'key': 'value'},
    //   headers: {'X-Custom-Header': 'my-value'},
    //   isJsonRpc: false,
    // );

    // ==========================================
    // ERROR HANDLING (C)
    // ==========================================

    // Errors provide both raw and user-friendly messages:
    try {
      await client.write('res.partner', [999999999], {'name': 'test'});
    } on OdooMissingErrorException catch (e) {
      // e.message = raw Odoo error (for logging)
      // e.userMessage = clean message (for UI)
      print('Show to user: ${e.userMessage}');
      // → "Record does not exist or has been deleted."
      print('Log for debug: ${e.message}');
      // → "Odoo Server Error" (with full traceback in e.errorData)
    }

    try {
      await client.create('res.partner', {'email': 'no-name'});
    } on OdooValidationException catch (e) {
      print('Show to user: ${e.userMessage}');
      // → "Contacts require a name."
      // (stripped "The operation cannot be completed:" prefix)
    }

    // ==========================================
    // SESSION MANAGEMENT (B)
    // ==========================================

    // Listen to session changes (login, logout, expiry)
    client.sessionStream.listen((session) {
      if (session == null) {
        // Redirect to login screen
        print('Session ended — redirect to login');
      }
    });

    // Multi-company: switch company
    // await client.switchCompany(otherCompanyId);

    // Change password
    // await client.changePassword('oldPass', 'newPass');

    // Logout (B2)
    await client.logout();
    print('Logged out, session cleared');
    print('Is authenticated: ${client.isAuthenticated}'); // false
  } on OdooAccessDeniedException catch (e) {
    print(e.userMessage); // "Invalid username or password."
  } on OdooSessionExpiredException catch (e) {
    print(e.userMessage); // "Your session has expired. Please log in again."
  } on OdooValidationException catch (e) {
    print(e.userMessage); // Clean validation message
  } on OdooAccessErrorException catch (e) {
    print(e.userMessage); // "You do not have permission..."
  } on OdooNetworkException catch (e) {
    print(e.userMessage); // Network error details
  } on OdooException catch (e) {
    print(e.userMessage); // Generic clean message
  } finally {
    client.close();
  }
}
