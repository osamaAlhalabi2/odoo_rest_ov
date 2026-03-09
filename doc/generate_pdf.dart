// ignore_for_file: avoid_print
/// Generates the odoo_rest_ov Developer Manual as a PDF.
/// Run: dart doc/generate_pdf.dart

import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─── Colors ───
const _primary = PdfColor.fromInt(0xFF714B67); // Odoo purple
const _accent = PdfColor.fromInt(0xFF00A09D); // Odoo teal
const _dark = PdfColor.fromInt(0xFF2C2C2C);
const _gray = PdfColor.fromInt(0xFF666666);
const _lightBg = PdfColor.fromInt(0xFFF5F0F4);
const _codeBg = PdfColor.fromInt(0xFFF4F4F4);
const _white = PdfColors.white;

// ─── Styles ───
pw.TextStyle _h1() => pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: _primary,
    );

pw.TextStyle _h2() => pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
      color: _primary,
    );

pw.TextStyle _h3() => pw.TextStyle(
      fontSize: 13,
      fontWeight: pw.FontWeight.bold,
      color: _dark,
    );

pw.TextStyle _body() => const pw.TextStyle(fontSize: 10, color: _dark, lineSpacing: 2);

pw.TextStyle _bodyBold() =>
    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _dark);

pw.TextStyle _code() => pw.TextStyle(
      font: pw.Font.courier(),
      fontSize: 9,
      color: _dark,
      lineSpacing: 1.5,
    );

pw.TextStyle _codeBold() => pw.TextStyle(
      font: pw.Font.courierBold(),
      fontSize: 9,
      color: _primary,
      lineSpacing: 1.5,
    );

pw.TextStyle _small() => const pw.TextStyle(fontSize: 8, color: _gray);

// ─── Helpers ───

pw.Widget heading1(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Text(text, style: _h1()),
    );

pw.Widget heading2(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
      child: pw.Text(text, style: _h2()),
    );

pw.Widget heading3(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8, bottom: 3),
      child: pw.Text(text, style: _h3()),
    );

pw.Widget para(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text, style: _body()),
    );

pw.Widget paraBold(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(text, style: _bodyBold()),
    );

pw.Widget bullet(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('  -  ', style: _bodyBold()),
          pw.Expanded(child: pw.Text(text, style: _body())),
        ],
      ),
    );

pw.Widget codeBlock(String code) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: _codeBg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(code, style: _code()),
    );

pw.Widget codeInline(String text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: const pw.BoxDecoration(
        color: _codeBg,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
      ),
      child: pw.Text(text, style: _code()),
    );

pw.Widget divider() => pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      height: 1,
      color: PdfColor.fromInt(0xFFDDDDDD),
    );

pw.Widget tipBox(String title, String text) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE8F5E9),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColor.fromInt(0xFF4CAF50), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2E7D32))),
          pw.SizedBox(height: 3),
          pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: _dark)),
        ],
      ),
    );

pw.Widget warnBox(String title, String text) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFF3E0),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFFF9800), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFFE65100))),
          pw.SizedBox(height: 3),
          pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: _dark)),
        ],
      ),
    );

pw.Widget apiTable(List<List<String>> rows) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFDDDDDD), width: 0.5),
    columnWidths: {
      0: const pw.FlexColumnWidth(2),
      1: const pw.FlexColumnWidth(1.2),
      2: const pw.FlexColumnWidth(3),
    },
    children: [
      // Header
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _primary),
        children: rows.first
            .map((h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(h,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: _white)),
                ))
            .toList(),
      ),
      // Data rows
      for (var i = 1; i < rows.length; i++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isOdd ? _white : _codeBg,
          ),
          children: rows[i]
              .map((c) => pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(c, style: const pw.TextStyle(fontSize: 9, color: _dark)),
                  ))
              .toList(),
        ),
    ],
  );
}

// ─── MAIN ───

Future<void> main() async {
  final pdf = pw.Document(
    title: 'odoo_rest_ov Developer Manual',
    author: 'Nexxa Group',
    subject: 'Dart package for Odoo JSON-RPC integration',
    creator: 'odoo_rest_ov doc generator',
  );

  // ============================================================
  //  COVER PAGE
  // ============================================================
  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: pw.EdgeInsets.zero,
    build: (context) => pw.Stack(
      children: [
        // Background
        pw.Positioned.fill(
          child: pw.Container(color: _primary),
        ),
        // Content
        pw.Positioned.fill(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(60),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('odoo_rest_ov',
                    style: pw.TextStyle(
                        fontSize: 48, fontWeight: pw.FontWeight.bold, color: _white)),
                pw.SizedBox(height: 8),
                pw.Text('Developer Manual',
                    style: const pw.TextStyle(fontSize: 24, color: _white)),
                pw.SizedBox(height: 24),
                pw.Container(height: 3, width: 80, color: _accent),
                pw.SizedBox(height: 24),
                pw.Text(
                  'A Dart package for interacting with Odoo servers\nvia JSON-RPC 2.0',
                  style: pw.TextStyle(
                      fontSize: 14, color: _white, lineSpacing: 4),
                ),
                pw.SizedBox(height: 40),
                pw.Text('Version 0.1.0', style: const pw.TextStyle(fontSize: 12, color: _white)),
                pw.SizedBox(height: 6),
                pw.Text('Pure Dart core  |  Flutter optional  |  Odoo 14 - 19+',
                    style: const pw.TextStyle(fontSize: 10, color: _white)),
                pw.Spacer(),
                pw.Text('by Nexxa Group',
                    style: const pw.TextStyle(fontSize: 11, color: _white)),
              ],
            ),
          ),
        ),
      ],
    ),
  ));

  // ============================================================
  //  TABLE OF CONTENTS
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('Table of Contents'),
    pw.SizedBox(height: 10),
    _tocEntry('1.', 'Quick Start', '3'),
    _tocEntry('2.', 'Installation', '3'),
    _tocEntry('3.', 'Authentication', '4'),
    _tocEntry('4.', 'Session Management', '5'),
    _tocEntry('5.', 'User Type Detection', '6'),
    _tocEntry('6.', 'Timezone Handling', '6'),
    _tocEntry('7.', 'ORM Methods', '7'),
    _tocEntry('8.', 'Domain Builder', '9'),
    _tocEntry('9.', 'Error Handling', '10'),
    _tocEntry('10.', 'Controller Calls', '12'),
    _tocEntry('11.', 'Reports & Binary Fields', '13'),
    _tocEntry('12.', 'Flutter Integration', '13'),
    _tocEntry('13.', 'API Reference Tables', '14'),
    _tocEntry('14.', 'Package Structure', '16'),
  ]));

  // ============================================================
  //  1. QUICK START  &  2. INSTALLATION
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('1. Quick Start'),
    para('Get connected to Odoo in under 30 seconds:'),
    codeBlock('''import 'package:odoo_rest_ov/odoo_rest_ov.dart';

final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://mycompany.odoo.com',
  database: 'mydb',
));

// Login
final session = await client.authenticate('admin', 'admin');
print(session.name);       // "Mitchell Admin"
print(session.userType);   // OdooUserType.internal
print(session.timezone);   // "Asia/Damascus"

// Read partners
final partners = await client.searchRead(
  'res.partner',
  OdooDomain().where('is_company').equals(true).build(),
  fields: ['name', 'email'],
  limit: 10,
);

// Create a record
final id = await client.create('res.partner', {
  'name': 'ACME Corp',
  'is_company': true,
});

// Cleanup
client.close();'''),
    divider(),
    heading1('2. Installation'),
    heading3('Add to pubspec.yaml'),
    codeBlock('''dependencies:
  odoo_rest_ov: ^0.1.0'''),
    heading3('Import'),
    codeBlock('''// Pure Dart (CLI, server, Flutter)
import 'package:odoo_rest_ov/odoo_rest_ov.dart';

// Flutter with persistent cookies
import 'package:odoo_rest_ov/odoo_rest_ov_flutter.dart';'''),
    heading3('Dependencies (handled automatically)'),
    bullet('dio ^5.9.0 - HTTP client with interceptors'),
    bullet('cookie_jar ^4.0.8 - Cookie storage'),
    bullet('dio_cookie_manager ^3.3.0 - Cookie management for Dio'),
    bullet('meta ^1.9.0 - Annotations'),
    tipBox('Dart & Flutter', 'The core package is pure Dart and works in CLI apps, server-side Dart, and Flutter. Flutter-specific helpers (persistent cookies) are in a separate import.'),
  ]));

  // ============================================================
  //  3. AUTHENTICATION
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('3. Authentication'),
    heading2('3.1 Username & Password'),
    codeBlock('''final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://odoo.example.com',
  database: 'production',
  enableLogging: true,  // logs requests to dart:developer
));

try {
  final session = await client.authenticate('user@example.com', 'password');
  print('Welcome \${session.name}!');
  print('UID: \${session.uid}');
  print('Company: \${session.companyId}');
} on OdooAccessDeniedException catch (e) {
  print(e.userMessage); // "Invalid username or password."
}'''),
    heading2('3.2 API Key (Odoo 14+)'),
    codeBlock('''client.setApiKey('your-api-key-here');
// Now all requests use Bearer token auth
final partners = await client.searchRead('res.partner', []);'''),
    heading2('3.3 Client Options'),
    codeBlock('''OdooClientOptions(
  baseUrl: 'https://odoo.example.com',  // required
  database: 'mydb',                      // required
  connectTimeout: Duration(seconds: 15),  // default: 30s
  receiveTimeout: Duration(seconds: 15),  // default: 30s
  sendTimeout: Duration(seconds: 15),     // default: 30s
  enableLogging: true,                    // default: false
  defaultContext: {'lang': 'ar_SY'},      // merged into every call
  cookieJar: myCustomJar,                 // optional
  interceptors: [myInterceptor],          // custom Dio interceptors
  onSessionChanged: (session) {           // login/logout/expiry
    if (session == null) navigateToLogin();
  },
)'''),
    warnBox('Important', 'Always call client.close() when done to release resources. In Flutter, do this in dispose().'),
  ]));

  // ============================================================
  //  4. SESSION MANAGEMENT
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('4. Session Management'),
    heading2('4.1 Check Session Validity'),
    para('Call checkSession() to verify the session is still alive on the server. Returns true/false without throwing.'),
    codeBlock('''final isValid = await client.checkSession();
if (!isValid) {
  // Session expired or invalid - redirect to login
  navigateToLogin();
}'''),
    heading2('4.2 Refresh Session'),
    para('Re-fetch session data from the server (e.g. after admin changes user permissions):'),
    codeBlock('''final updated = await client.refreshSession();
print(updated.isAdmin); // may have changed'''),
    heading2('4.3 Logout'),
    para('Destroys the session on the server and clears local state:'),
    codeBlock('''await client.logout();
print(client.isAuthenticated); // false'''),
    heading2('4.4 Session Stream'),
    para('Listen reactively to session state changes:'),
    codeBlock('''client.sessionStream.listen((session) {
  if (session != null) {
    print('Logged in as \${session.name}');
  } else {
    print('Session ended');
    navigateToLogin();
  }
});'''),
    heading2('4.5 Change Password'),
    codeBlock('''await client.changePassword('oldPass', 'newPass');'''),
    heading2('4.6 Switch Company'),
    para('For multi-company Odoo setups:'),
    codeBlock('''// session.allowedCompanies contains available companies
final updated = await client.switchCompany(otherCompanyId);
print(updated.companyId); // now the new company'''),
    heading2('4.7 Session Properties'),
    codeBlock('''final s = client.session!;
s.uid           // 2
s.db            // "mydb"
s.name          // "Mitchell Admin"
s.username      // "admin@example.com"
s.companyId     // 1
s.partnerId     // 3
s.isAdmin       // true
s.isSystem      // true
s.serverVersion // "19.0+e-20251222"
s.sessionId     // cookie value
s.userContext   // {'lang':'en_US','tz':'Asia/Damascus'}
s.timezone      // "Asia/Damascus" (shortcut)
s.language      // "en_US" (shortcut)'''),
  ]));

  // ============================================================
  //  5. USER TYPE  &  6. TIMEZONE
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('5. User Type Detection'),
    para('After authentication, the session contains user type flags directly from Odoo:'),
    codeBlock('''final session = await client.authenticate('user', 'pass');

// Enum-based type
switch (session.userType) {
  case OdooUserType.internal:
    print('Employee / Internal user');
    break;
  case OdooUserType.portal:
    print('Portal user (customer/vendor)');
    break;
  case OdooUserType.public:
    print('Public / unauthenticated');
    break;
}

// Boolean flags
session.isInternalUser  // true for employees
session.isPortalUser    // true for portal users
session.isPublic        // true for public users
session.isAdmin         // true for admin
session.isSystem        // true for superuser'''),
    apiTable([
      ['Flag', 'Type', 'Description'],
      ['isInternalUser', 'bool', 'Employee with full backend access'],
      ['isPortalUser', 'bool', 'Customer/vendor with portal access'],
      ['isPublic', 'bool', 'Unauthenticated / public user'],
      ['isAdmin', 'bool', 'Has administration rights'],
      ['isSystem', 'bool', 'Superuser / technical admin'],
      ['userType', 'OdooUserType', 'Enum: internal, portal, or public'],
    ]),
    divider(),
    heading1('6. Timezone Handling'),
    heading2('6.1 The Problem'),
    para('Odoo stores all datetime fields in UTC. When connecting via JSON-RPC, other packages often forget to send the timezone in the request context, causing all dates to display in UTC instead of the user\'s local time.'),
    heading2('6.2 The Fix (Automatic)'),
    para('odoo_rest_ov automatically reads the user\'s timezone from their Odoo profile during authentication and applies it to every subsequent request:'),
    codeBlock('''final session = await client.authenticate('admin', 'pass');
// session.timezone == "Asia/Damascus" (from user settings)
// client.buildContext()['tz'] == "Asia/Damascus" (auto-applied)

// All ORM calls now include the correct timezone
final orders = await client.searchRead('sale.order', [],
    fields: ['name', 'date_order']); // dates in user's TZ'''),
    heading2('6.3 Manual Override'),
    para('Override the timezone when the device TZ differs from Odoo settings:'),
    codeBlock('''// Use device timezone instead
client.setTimezone('America/New_York');

// Or disable auto-detection
await client.authenticate('admin', 'pass',
    autoDetectTimezone: false);
client.setTimezone(deviceTimezone);'''),
    tipBox('How it works', 'The tz value is sent in the "context" parameter of every JSON-RPC call. Odoo uses this to convert UTC datetimes to the user\'s local time in computed fields, reports, and views.'),
  ]));

  // ============================================================
  //  7. ORM METHODS
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('7. ORM Methods'),
    para('All ORM methods are available directly on the client. They call Odoo\'s call_kw endpoint under the hood.'),
    heading2('7.1 Search & Read'),
    codeBlock('''// Search + Read in one call (most common)
final records = await client.searchRead(
  'res.partner',
  [['is_company', '=', true]],  // domain
  fields: ['name', 'email', 'country_id'],
  limit: 20,
  offset: 0,
  order: 'name asc',
);

for (final r in records) {
  print(r.name);                          // extension
  print(r.many2oneName('country_id'));     // "United States"
  print(r.many2oneId('country_id'));       // 233
  print(r.x2manyIds('tag_ids'));           // [1, 5, 8]
}'''),
    heading2('7.2 Search (IDs only)'),
    codeBlock('''final ids = await client.search(
  'res.partner',
  [['customer_rank', '>', 0]],
  limit: 100,
  order: 'id desc',
);
// ids = [42, 38, 25, ...]'''),
    heading2('7.3 Read (by IDs)'),
    codeBlock('''final records = await client.read(
  'res.partner',
  [1, 2, 3],
  fields: ['name', 'email'],
);'''),
    heading2('7.4 Count'),
    codeBlock('''final count = await client.searchCount(
  'res.partner',
  [['is_company', '=', true]],
);
print('Total companies: \$count');'''),
    heading2('7.5 Create'),
    codeBlock('''// Single record
final id = await client.create('res.partner', {
  'name': 'ACME Corp',
  'email': 'info@acme.com',
  'is_company': true,
});

// Multiple records
final ids = await client.createMulti('res.partner', [
  {'name': 'Alice', 'email': 'alice@acme.com'},
  {'name': 'Bob', 'email': 'bob@acme.com'},
]);'''),
  ]));

  // ============================================================
  //  7 continued - Update, Delete, More
  // ============================================================
  pdf.addPage(_contentPage([
    heading2('7.6 Update'),
    codeBlock('''final ok = await client.write(
  'res.partner',
  [42, 43],              // IDs to update
  {'phone': '+1234567890', 'city': 'New York'},
);
print(ok); // true'''),
    heading2('7.7 Delete'),
    codeBlock('''final ok = await client.unlink('res.partner', [42, 43]);
print(ok); // true'''),
    heading2('7.8 Field Metadata'),
    codeBlock('''final fields = await client.fieldsGet(
  'res.partner',
  attributes: ['string', 'type', 'required'],
);
// {'name': {'string':'Name','type':'char','required':true}, ...}'''),
    heading2('7.9 Name Search & Name Get'),
    codeBlock('''// Search by display name (autocomplete)
final results = await client.nameSearch(
  'res.partner', 'Admin',
  domain: [['is_company', '=', false]],
  limit: 5,
);

// Get display names for IDs
final names = await client.nameGet('res.partner', [1, 2, 3]);'''),
    heading2('7.10 Default Values'),
    codeBlock('''final defaults = await client.defaultGet(
  'sale.order',
  ['partner_id', 'date_order', 'currency_id'],
);'''),
    heading2('7.11 Call Any Method'),
    codeBlock('''// Call any model method
final result = await client.callMethod(
  'res.partner',
  'check_access_rights',
  args: ['write'],
  kwargs: {'raise_exception': false},
);

// Low-level call_kw
final raw = await client.callKw(
  model: 'stock.picking',
  method: 'button_validate',
  args: [[pickingId]],
);'''),
    heading2('7.12 ORM Methods Reference'),
    apiTable([
      ['Method', 'Returns', 'Description'],
      ['searchRead()', 'List<OdooRecord>', 'Search + read fields'],
      ['search()', 'List<int>', 'Search for record IDs'],
      ['read()', 'List<OdooRecord>', 'Read records by IDs'],
      ['searchCount()', 'int', 'Count matching records'],
      ['create()', 'int', 'Create one record'],
      ['createMulti()', 'List<int>', 'Create multiple records'],
      ['write()', 'bool', 'Update records'],
      ['unlink()', 'bool', 'Delete records'],
      ['fieldsGet()', 'Map', 'Get field metadata'],
      ['nameGet()', 'List', 'Get display names'],
      ['nameSearch()', 'List', 'Search by name'],
      ['defaultGet()', 'Map', 'Get default values'],
      ['callMethod()', 'dynamic', 'Call any model method'],
      ['callKw()', 'dynamic', 'Low-level call_kw'],
    ]),
  ]));

  // ============================================================
  //  8. DOMAIN BUILDER
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('8. Domain Builder'),
    para('Build type-safe Odoo domain filters with a fluent API. No more typos in operator strings!'),
    heading2('8.1 Basic Usage'),
    codeBlock('''final domain = OdooDomain()
  .where('is_company').equals(true)
  .where('customer_rank').greaterThan(0)
  .build();
// Result: [['is_company','=',true], ['customer_rank','>',0]]

final partners = await client.searchRead('res.partner', domain);'''),
    heading2('8.2 OR Conditions'),
    codeBlock('''final domain = OdooDomain()
  .or()
  .where('email').ilike('%@gmail.com')
  .where('email').ilike('%@yahoo.com')
  .build();
// Result: ['|', ['email','ilike','%@gmail.com'],
//                ['email','ilike','%@yahoo.com']]'''),
    heading2('8.3 NOT Conditions'),
    codeBlock('''final domain = OdooDomain()
  .not()
  .where('active').equals(false)
  .build();
// Result: ['!', ['active','=',false]]'''),
    heading2('8.4 Raw Domains (backward compatible)'),
    codeBlock('''// You can always pass raw lists directly
final partners = await client.searchRead('res.partner', [
  ['name', 'ilike', 'test'],
  ['active', '=', true],
]);'''),
    heading2('8.5 All Operators'),
    apiTable([
      ['Method', 'Odoo Op', 'Example'],
      ['.equals(v)', '=', ".where('state').equals('draft')"],
      ['.notEquals(v)', '!=', ".where('state').notEquals('cancelled')"],
      ['.greaterThan(v)', '>', ".where('amount').greaterThan(100)"],
      ['.greaterOrEqual(v)', '>=', ".where('qty').greaterOrEqual(1)"],
      ['.lessThan(v)', '<', ".where('qty').lessThan(5)"],
      ['.lessOrEqual(v)', '<=', ".where('date').lessOrEqual('2026-01-01')"],
      ['.like(v)', 'like', ".where('ref').like('SO%')"],
      ['.ilike(v)', 'ilike', ".where('name').ilike('%test%')"],
      ['.notLike(v)', 'not like', ".where('name').notLike('TEMP%')"],
      ['.notIlike(v)', 'not ilike', ".where('name').notIlike('%test%')"],
      ['.isIn(list)', 'in', ".where('state').isIn(['draft','sent'])"],
      ['.notIn(list)', 'not in', ".where('id').notIn([1,2,3])"],
      ['.childOf(v)', 'child_of', ".where('parent_id').childOf(1)"],
      ['.parentOf(v)', 'parent_of', ".where('categ_id').parentOf(5)"],
      ['.isSet()', '!= false', ".where('email').isSet()"],
      ['.isNotSet()', '= false', ".where('phone').isNotSet()"],
    ]),
  ]));

  // ============================================================
  //  9. ERROR HANDLING
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('9. Error Handling'),
    para('Every exception has two messages: the raw Odoo error for logging, and a clean user-friendly message safe to display in the UI.'),
    heading2('9.1 Exception Hierarchy'),
    codeBlock('''OdooException (base)
  |-- OdooSessionException
  |     |-- OdooAccessDeniedException    (bad credentials)
  |     |-- OdooSessionExpiredException  (session expired)
  |-- OdooRpcException
  |     |-- OdooAccessErrorException     (no permission)
  |     |-- OdooValidationException      (validation failed)
  |     |-- OdooMissingErrorException    (record not found)
  |     |-- OdooUserErrorException       (business rule error)
  |-- OdooNetworkException              (timeout, DNS, etc.)
  |-- OdooProtocolException             (invalid JSON-RPC)'''),
    heading2('9.2 Two Messages: Raw vs User-Friendly'),
    codeBlock('''try {
  await client.create('res.partner', {'email': 'test'});
} on OdooValidationException catch (e) {
  // For the UI (clean, no technical details)
  showSnackbar(e.userMessage);
  // -> "Contacts require a name."

  // For logging/debugging (raw Odoo message)
  log.error(e.message);
  // -> "Odoo Server Error"

  // Full error data including Python traceback
  log.debug(e.errorData?['debug']);
}'''),
    heading2('9.3 Catch by Type'),
    codeBlock('''try {
  await client.searchRead('sale.order', []);
} on OdooAccessDeniedException catch (e) {
  showDialog(e.userMessage);
  // -> "Invalid username or password."
} on OdooSessionExpiredException catch (e) {
  showDialog(e.userMessage);
  // -> "Your session has expired. Please log in again."
  navigateToLogin();
} on OdooAccessErrorException catch (e) {
  showDialog(e.userMessage);
  // -> "You do not have permission to perform this action."
} on OdooValidationException catch (e) {
  showDialog(e.userMessage);
  // -> Clean validation message (prefix stripped)
} on OdooMissingErrorException catch (e) {
  showDialog(e.userMessage);
  // -> "The record you are looking for no longer exists."
} on OdooNetworkException catch (e) {
  showDialog('No internet connection');
} on OdooException catch (e) {
  showDialog(e.userMessage);
  // -> "An unexpected error occurred. Please try again."
}'''),
    heading2('9.4 What Gets Cleaned'),
    bullet('"The operation cannot be completed: X" -> "X."'),
    bullet('"Record does not exist...\\n(Record: res.partner(999,), User: 2)" -> "Record does not exist..."'),
    bullet('"Odoo Server Error" -> type-specific default message'),
    bullet('Python tracebacks and SQL errors are stripped from userMessage'),
    bullet('Generic "Odoo Server Error" gets a friendly default per error type'),
  ]));

  // ============================================================
  //  10. CONTROLLER CALLS
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('10. Controller Calls'),
    para('Call any Odoo web controller (custom endpoints, REST APIs, etc.) with a structured response.'),
    heading2('10.1 JSON-RPC Controller (default)'),
    codeBlock('''final resp = await client.callController(
  '/web/webclient/version_info',
  params: {},
);

print(resp.statusCode);   // 200
print(resp.isSuccess);    // true
print(resp.method);       // "POST"
print(resp.requestPath);  // "/web/webclient/version_info"
print(resp.dataAsMap);    // {'server_version': '19.0+e', ...}'''),
    heading2('10.2 REST-style GET'),
    codeBlock('''final resp = await client.callController(
  '/api/v1/partners',
  method: 'GET',
  params: {'limit': '10', 'offset': '0'},
  isJsonRpc: false,
);
final partners = resp.dataAsList;'''),
    heading2('10.3 POST with Custom Headers'),
    codeBlock('''final resp = await client.callController(
  '/api/v1/webhook',
  method: 'POST',
  params: {'event': 'order_created', 'order_id': 42},
  headers: {'X-API-Key': 'secret'},
  isJsonRpc: false,
);'''),
    heading2('10.4 Other HTTP Methods'),
    codeBlock('''// PUT
await client.callController('/api/v1/partner/42',
    method: 'PUT', params: {'name': 'Updated'}, isJsonRpc: false);

// DELETE
await client.callController('/api/v1/partner/42',
    method: 'DELETE', isJsonRpc: false);

// PATCH
await client.callController('/api/v1/partner/42',
    method: 'PATCH', params: {'phone': '+123'}, isJsonRpc: false);'''),
    heading2('10.5 Response Object'),
    apiTable([
      ['Property', 'Type', 'Description'],
      ['statusCode', 'int', 'HTTP status code (200, 404, etc.)'],
      ['isSuccess', 'bool', 'True if status is 2xx'],
      ['data', 'dynamic', 'Parsed response body'],
      ['dataAsMap', 'Map<String,dynamic>', 'Cast data to Map'],
      ['dataAsList', 'List<dynamic>', 'Cast data to List'],
      ['headers', 'Map<String,List>', 'Response headers'],
      ['requestPath', 'String', 'The endpoint path'],
      ['method', 'String', 'HTTP method used'],
    ]),
  ]));

  // ============================================================
  //  11. REPORTS & BINARY  &  12. FLUTTER
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('11. Reports & Binary Fields'),
    heading2('11.1 Download Report'),
    codeBlock('''final pdfBytes = await client.getReport(
  'account.report_invoice',    // report XML ID
  [1, 2, 3],                   // record IDs
  format: 'pdf',               // 'pdf' or 'html'
);

// Save to file
File('invoice.pdf').writeAsBytesSync(pdfBytes);'''),
    heading2('11.2 Upload Binary'),
    codeBlock('''final imageBytes = File('photo.jpg').readAsBytesSync();
await client.uploadBinary(
  'res.partner', 42, 'image_1920', imageBytes,
  filename: 'photo.jpg',
);'''),
    heading2('11.3 Download Binary'),
    codeBlock('''final bytes = await client.downloadBinary(
  'res.partner', 42, 'image_1920',
);
if (bytes != null) {
  File('avatar.jpg').writeAsBytesSync(bytes);
}'''),
    divider(),
    heading1('12. Flutter Integration'),
    heading2('12.1 Persistent Cookies'),
    para('In Flutter, use the flutter import for cookies that survive app restarts:'),
    codeBlock('''import 'package:odoo_rest_ov/odoo_rest_ov_flutter.dart';
import 'package:path_provider/path_provider.dart';

final dir = await getApplicationDocumentsDirectory();

// Option A: Quick factory
final client = OdooFlutter.createClient(
  baseUrl: 'https://odoo.example.com',
  database: 'mydb',
  documentsPath: dir.path,
);

// Option B: Manual cookie jar
final cookieJar = OdooFlutter.createPersistentCookieJar(dir.path);
final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://odoo.example.com',
  database: 'mydb',
  cookieJar: cookieJar,
));'''),
    heading2('12.2 State Management Pattern'),
    codeBlock('''class OdooService {
  late final OdooClient _client;

  OdooService() {
    _client = OdooClient(OdooClientOptions(
      baseUrl: 'https://odoo.example.com',
      database: 'mydb',
      onSessionChanged: (session) {
        // Update your state management (Riverpod, Bloc, etc.)
        if (session == null) emit(UnauthenticatedState());
      },
    ));
  }

  Future<bool> isLoggedIn() => _client.checkSession();
  void dispose() => _client.close();
}'''),
    warnBox('Remember', 'Always call client.close() in your widget\'s dispose() or service teardown to prevent resource leaks.'),
  ]));

  // ============================================================
  //  13. API REFERENCE TABLES
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('13. API Reference'),
    heading2('13.1 OdooClient Methods'),
    apiTable([
      ['Method', 'Returns', 'Description'],
      ['authenticate(user, pass)', 'OdooSession', 'Login with credentials'],
      ['logout()', 'void', 'Destroy session'],
      ['setApiKey(key)', 'void', 'Use API key auth'],
      ['checkSession()', 'bool', 'Verify session is valid'],
      ['refreshSession()', 'OdooSession', 'Re-fetch session info'],
      ['changePassword(old, new)', 'void', 'Change user password'],
      ['switchCompany(id)', 'OdooSession', 'Switch active company'],
      ['getServerInfo()', 'ServerInfo', 'Get server version'],
      ['getSessionInfo()', 'OdooSession', 'Get session details'],
      ['callController(route)', 'ControllerResponse', 'Call web endpoint'],
      ['getReport(name, ids)', 'Uint8List', 'Download report PDF'],
      ['uploadBinary(...)', 'bool', 'Upload file to field'],
      ['downloadBinary(...)', 'Uint8List?', 'Download field data'],
      ['setLanguage(lang)', 'void', 'Set context language'],
      ['setTimezone(tz)', 'void', 'Set context timezone'],
      ['updateContext(values)', 'void', 'Merge into context'],
      ['close()', 'void', 'Release resources'],
    ]),
    pw.SizedBox(height: 10),
    heading2('13.2 OdooSession Properties'),
    apiTable([
      ['Property', 'Type', 'Description'],
      ['uid', 'int', 'User database ID'],
      ['db', 'String', 'Database name'],
      ['name', 'String', 'User display name'],
      ['username', 'String', 'Login (email)'],
      ['companyId', 'int', 'Active company ID'],
      ['partnerId', 'int', 'Related partner ID'],
      ['isAdmin', 'bool', 'Has admin rights'],
      ['isSystem', 'bool', 'Is superuser'],
      ['isInternalUser', 'bool', 'Is employee'],
      ['isPortalUser', 'bool', 'Is portal user'],
      ['isPublic', 'bool', 'Is public user'],
      ['userType', 'OdooUserType', 'internal/portal/public'],
      ['timezone', 'String?', 'User timezone'],
      ['language', 'String?', 'User language'],
      ['serverVersion', 'String', 'Odoo version string'],
      ['allowedCompanies', 'Map', 'Multi-company list'],
    ]),
  ]));

  // ============================================================
  //  13 continued - Exceptions Table
  // ============================================================
  pdf.addPage(_contentPage([
    heading2('13.3 Exception Types'),
    apiTable([
      ['Exception', 'Odoo Error', 'Default userMessage'],
      ['OdooAccessDeniedException', 'AccessDenied', 'Invalid username or password.'],
      ['OdooSessionExpiredException', 'SessionExpired', 'Your session has expired. Please log in again.'],
      ['OdooAccessErrorException', 'AccessError', 'You do not have permission to perform this action.'],
      ['OdooValidationException', 'ValidationError', 'The data you entered is not valid.'],
      ['OdooMissingErrorException', 'MissingError', 'The record you are looking for no longer exists.'],
      ['OdooUserErrorException', 'UserError', 'The operation could not be completed.'],
      ['OdooNetworkException', '(transport)', 'Network error message.'],
      ['OdooProtocolException', '(protocol)', 'An unexpected error occurred.'],
    ]),
    pw.SizedBox(height: 10),
    heading2('13.4 OdooRecord Extensions'),
    apiTable([
      ['Extension', 'Returns', 'Usage'],
      ['.id', 'int', 'record.id'],
      ['.name', 'String', 'record.name'],
      ['.many2oneId(field)', 'int?', "record.many2oneId('country_id')"],
      ['.many2oneName(field)', 'String?', "record.many2oneName('country_id')"],
      ['.x2manyIds(field)', 'List<int>', "record.x2manyIds('tag_ids')"],
    ]),
    pw.SizedBox(height: 10),
    heading2('13.5 OdooControllerResponse'),
    apiTable([
      ['Property', 'Type', 'Description'],
      ['statusCode', 'int', 'HTTP status code'],
      ['isSuccess', 'bool', 'True for 2xx status'],
      ['data', 'dynamic', 'Response body (auto-unwrapped from JSON-RPC)'],
      ['dataAsMap', 'Map', 'Convenience cast to Map'],
      ['dataAsList', 'List', 'Convenience cast to List'],
      ['headers', 'Map<String,List>', 'Response headers'],
      ['requestPath', 'String', 'Endpoint URL path'],
      ['method', 'String', 'HTTP method (GET, POST, etc.)'],
    ]),
  ]));

  // ============================================================
  //  14. PACKAGE STRUCTURE
  // ============================================================
  pdf.addPage(_contentPage([
    heading1('14. Package Structure'),
    codeBlock('''odoo_rest_ov/
  lib/
    odoo_rest_ov.dart               # Main import (pure Dart)
    odoo_rest_ov_flutter.dart       # Flutter import (+ persistent cookies)
    src/
      client/
        odoo_client.dart            # Main client class
        odoo_client_options.dart     # Configuration options
        odoo_session.dart            # Session model + OdooUserType enum
      orm/
        odoo_orm.dart                # ORM method wrappers (mixin)
        domain_builder.dart          # Fluent domain filter builder
      network/
        dio_config.dart              # Dio factory
        json_rpc.dart                # JSON-RPC 2.0 helpers
        interceptors/
          session_interceptor.dart   # Session expiry detection
          logging_interceptor.dart   # Request/response logging
      exceptions/
        odoo_exceptions.dart         # Exception hierarchy
      models/
        odoo_response.dart           # JSON-RPC request/response
        odoo_record.dart             # Record typedef + extensions
        controller_response.dart     # Controller response model
        server_info.dart             # Server version info
      flutter/
        odoo_flutter.dart            # Persistent cookies helper
  test/                              # Unit + integration tests
  example/
    example.dart                     # Comprehensive usage example'''),
    divider(),
    heading2('Design Decisions'),
    bullet('Pure Dart core - works in CLI, server, and Flutter'),
    bullet('Single client class - no client.orm.method(), just client.method()'),
    bullet('No code generation - no freezed or build_runner required'),
    bullet('Typed exceptions - catch OdooValidationException specifically'),
    bullet('Dual error messages - raw for devs, clean for users'),
    bullet('Auto timezone - fixes the most common Odoo integration pain point'),
    bullet('Domain accepts both raw List and fluent OdooDomain builder'),
    bullet('Session stream - reactive state management integration'),
    pw.SizedBox(height: 16),
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightBg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: _primary, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Compatibility',
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: _primary)),
          pw.SizedBox(height: 6),
          pw.Text('Dart SDK: >= 3.0.0', style: _body()),
          pw.Text('Odoo versions: 14, 15, 16, 17, 18, 19+', style: _body()),
          pw.Text('Platforms: iOS, Android, Web, macOS, Linux, Windows, CLI',
              style: _body()),
        ],
      ),
    ),
  ]));

  // ============================================================
  //  SAVE
  // ============================================================
  final file = File('doc/odoo_rest_ov_manual.pdf');
  await file.writeAsBytes(await pdf.save());
  print('PDF generated: ${file.absolute.path}');
  print('Size: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB');
}

// ─── Page builder ───

pw.Page _contentPage(List<pw.Widget> children) {
  return pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(50, 50, 50, 50),
    header: (context) => context.pageNumber > 1
        ? pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('odoo_rest_ov Developer Manual',
                    style: pw.TextStyle(
                        fontSize: 9, color: _primary, fontWeight: pw.FontWeight.bold)),
                pw.Text('v0.1.0', style: const pw.TextStyle(fontSize: 9, color: _gray)),
              ],
            ),
          )
        : pw.SizedBox.shrink(),
    footer: (context) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Nexxa Group', style: _small()),
          pw.Text('${context.pageNumber}', style: _small()),
        ],
      ),
    ),
    build: (context) => children,
  );
}

pw.Widget _tocEntry(String num, String title, String page) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.SizedBox(
            width: 28,
            child: pw.Text(num,
                style: pw.TextStyle(
                    fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primary))),
        pw.Expanded(
          child: pw.Text(title, style: const pw.TextStyle(fontSize: 11, color: _dark)),
        ),
        pw.Container(
          width: 30,
          alignment: pw.Alignment.centerRight,
          child: pw.Text(page, style: const pw.TextStyle(fontSize: 11, color: _gray)),
        ),
      ],
    ),
  );
}
