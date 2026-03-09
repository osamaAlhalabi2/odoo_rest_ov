# odoo_rest_ov

![odoo_rest_ov banner](https://raw.githubusercontent.com/osamaAlhalabi2/odoo_rest_ov/main/doc/banner.png)

[![pub package](https://img.shields.io/pub/v/odoo_rest_ov.svg)](https://pub.dev/packages/odoo_rest_ov)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart 3+](https://img.shields.io/badge/Dart-3%2B-0175C2.svg?logo=dart)](https://dart.dev)
[![Odoo 14+](https://img.shields.io/badge/Odoo-14%2B-714B67.svg?logo=odoo&logoColor=white)](https://www.odoo.com)
[![style: lints](https://img.shields.io/badge/style-lints-4BC0F5.svg)](https://pub.dev/packages/lints)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Linux%20%7C%20Windows-brightgreen.svg)](https://pub.dev/packages/odoo_rest_ov)

**Connect your Dart or Flutter app to Odoo without losing your mind.**

Tired of wrapping JSON-RPC envelopes by hand, parsing cryptic error responses, and writing the same `callKw` boilerplate in every project? Yeah, us too. That's why this package exists.

`odoo_rest_ov` gives you typed ORM methods, a fluent domain builder, session management, report downloads, binary field handling, and error messages you can actually show to users — all in a single import.

---

## Demo

<!-- Replace with your actual demo GIF -->
<p align="center">
  <img src="https://raw.githubusercontent.com/osamaAlhalabi2/odoo_rest_ov/main/doc/demo.gif" alt="odoo_rest_ov demo" width="300" />
</p>

> *Demo app built with Flutter + odoo_rest_ov. Source available in the [playground repo](https://github.com/osamaAlhalabi2/odoo_rest_ov).*

---

## Why This Package?

| What you get | What you'd do without it |
|---|---|
| `client.searchRead(...)` | Build JSON-RPC envelope, post it, extract result, cast types |
| `OdooDomain().where('name').ilike('%test%')` | `[['name', 'ilike', '%test%']]` and hope you didn't typo an operator |
| `catch OdooValidationException` | `catch (e)` and pray the message makes sense |
| `session.timezone` auto-detected | Every date shows in UTC and your users are confused |
| `client.getReport(...)` | Manual HTTP call to a URL you found on a forum post from 2019 |

---

## Features

- **Typed ORM methods** — `searchRead`, `create`, `write`, `unlink`, `fieldsGet`, `nameSearch`, and more. No more `callKw` wrappers.
- **Fluent domain builder** — Stop writing raw lists. Build filters with `.where('field').equals(value)`.
- **Typed exceptions** — Odoo errors mapped to specific exception classes with user-friendly messages safe for your UI.
- **Session management** — Login, logout, session stream, auto-refresh. Plug into Riverpod/Bloc/whatever.
- **Timezone auto-detection** — Reads the user's timezone from their Odoo profile. Dates just work.
- **User type detection** — Know if the user is internal, portal, or public. Check admin/system status.
- **Controller calls** — Hit any Odoo endpoint. JSON-RPC or REST. Custom routes included.
- **Report download** — PDF invoices in one method call.
- **Binary fields** — Upload photos, download attachments. No base64 gymnastics.
- **Flutter helpers** — Persistent cookies for mobile. Browser handles web automatically.
- **Cross-platform** — Android, iOS, Web, macOS, Linux, Windows. Pure Dart core.

---

## Installation

```yaml
dependencies:
  odoo_rest_ov: ^0.1.0
```

```bash
dart pub get
```

---

## Quick Start

```dart
import 'package:odoo_rest_ov/odoo_rest_ov.dart';

final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://mycompany.odoo.com',
  database: 'mydb',
));

// Login
final session = await client.authenticate('admin', 'admin');
print('Hello ${session.name}!');

// Search partners
final partners = await client.searchRead(
  'res.partner',
  [['is_company', '=', true]],
  fields: ['name', 'email'],
  limit: 10,
);

for (final p in partners) {
  print('${p.name} — ${p['email']}');
}

// Cleanup
client.close();
```

That's it. No JSON-RPC envelopes. No result extraction. No manual error parsing.

---

## Domain Builder

Writing raw domain lists is fine... until you mistype `'ilike'` as `'ilke'` and spend 20 minutes debugging.

```dart
// Fluent and type-safe
final domain = OdooDomain()
    .where('is_company').equals(true)
    .where('customer_rank').greaterThan(0)
    .build();

// OR conditions
final orDomain = OdooDomain()
    .or()
    .where('email').ilike('%@gmail.com')
    .where('email').ilike('%@yahoo.com')
    .build();

// NOT condition
final notDomain = OdooDomain()
    .not()
    .where('active').equals(false)
    .build();
```

<details>
<summary><strong>All available operators</strong></summary>

| Method | Odoo Operator |
|--------|--------------|
| `equals(value)` | `=` |
| `notEquals(value)` | `!=` |
| `greaterThan(value)` | `>` |
| `greaterOrEqual(value)` | `>=` |
| `lessThan(value)` | `<` |
| `lessOrEqual(value)` | `<=` |
| `like(value)` | `like` |
| `ilike(value)` | `ilike` |
| `notLike(value)` | `not like` |
| `notIlike(value)` | `not ilike` |
| `isIn(list)` | `in` |
| `notIn(list)` | `not in` |
| `childOf(value)` | `child_of` |
| `parentOf(value)` | `parent_of` |
| `isSet()` | `!=` false |
| `isNotSet()` | `=` false |

</details>

Raw lists still work. You don't have to rewrite existing code:

```dart
await client.searchRead('res.partner', [['name', 'ilike', 'test']]);
```

---

## ORM Methods

Everything you need, typed and ready:

```dart
// Search & Read
final records = await client.searchRead('res.partner', domain,
    fields: ['name', 'email'], limit: 10, order: 'name asc');

// Search IDs only
final ids = await client.search('res.partner', domain);

// Read by IDs
final partners = await client.read('res.partner', [1, 2, 3],
    fields: ['name']);

// Count
final total = await client.searchCount('res.partner', domain);

// Create — returns the new ID
final newId = await client.create('res.partner', {
  'name': 'New Partner',
  'email': 'new@example.com',
});

// Update
await client.write('res.partner', [newId], {'phone': '+123456'});

// Delete
await client.unlink('res.partner', [newId]);

// Field metadata
final fields = await client.fieldsGet('res.partner',
    attributes: ['string', 'type']);

// Name search
final results = await client.nameSearch('res.partner', 'Admin');

// Any custom model method
final result = await client.callMethod('res.partner', 'my_method',
    args: [1], kwargs: {'key': 'value'});
```

---

## Record Helpers

Odoo records come as `Map<String, dynamic>`. These extensions make them less painful:

```dart
final partner = partners.first;

partner.id;                          // int
partner.name;                        // String
partner['email'];                    // dynamic field access
partner.many2oneId('country_id');    // int? — extracts the ID
partner.many2oneName('country_id');  // String? — extracts the display name
partner.x2manyIds('tag_ids');        // List<int> — many2many IDs
```

---

## Error Handling

Odoo error messages are... not great for users. This package fixes that.

Errors are auto-mapped to typed exceptions with **user-friendly messages** you can safely display in your UI:

```dart
try {
  await client.write('res.partner', [999999], {'name': 'test'});
} on OdooMissingErrorException catch (e) {
  print(e.userMessage); // "Record does not exist or has been deleted."
  print(e.message);     // Raw Odoo error (for logging)
}

try {
  await client.create('res.partner', {'email': 'no-name'});
} on OdooValidationException catch (e) {
  print(e.userMessage); // "Contacts require a name."
}
```

**Exception hierarchy:**

```
OdooException (base)
+-- OdooAccessDeniedException     // wrong credentials
+-- OdooSessionExpiredException   // session gone
+-- OdooAccessErrorException      // no permission
+-- OdooValidationException       // validation failed
+-- OdooMissingErrorException     // record not found
+-- OdooUserErrorException        // business logic error
+-- OdooNetworkException          // no internet, timeout, etc.
+-- OdooProtocolException         // response doesn't make sense
```

---

## Session Management

Sessions that manage themselves:

```dart
// Check validity (non-throwing)
final isValid = await client.checkSession();

// Refresh session data
final updated = await client.refreshSession();

// Listen to changes — plug into your state management
client.sessionStream.listen((session) {
  if (session == null) {
    // Navigate to login
  }
});

// Callback style
OdooClientOptions(
  baseUrl: '...',
  database: '...',
  onSessionChanged: (session) {
    print(session?.name ?? 'logged out');
  },
);

// Logout
await client.logout();
```

---

## User Type & Timezone

```dart
final session = await client.authenticate('admin', 'admin');

// User type
session.userType;        // OdooUserType.internal
session.isInternalUser;  // true
session.isPortalUser;    // false
session.isPublic;        // false
session.isAdmin;         // true

// Timezone — auto-detected from user's Odoo settings
session.timezone;        // "Asia/Damascus"

// Override if needed
client.setTimezone('America/New_York');
```

No more dates showing in UTC because someone forgot to send the timezone context.

---

## Controller Calls

Call any Odoo endpoint — not just ORM methods:

```dart
// JSON-RPC endpoint (auto-wrapped)
final resp = await client.callController(
  '/web/webclient/version_info',
  params: {},
);
print(resp.data);        // response data
print(resp.statusCode);  // 200
print(resp.isSuccess);   // true

// REST-style GET
final rest = await client.callController(
  '/api/v1/partners',
  method: 'GET',
  params: {'limit': '10'},
  isJsonRpc: false,
);
```

---

## Reports & Binary Fields

```dart
// Download PDF report
final pdfBytes = await client.getReport(
  'account.report_invoice', [invoiceId],
);

// Upload attachment
await client.uploadBinary(
  'res.partner', partnerId, 'image_1920', imageBytes,
  filename: 'photo.png',
);

// Download attachment
final bytes = await client.downloadBinary(
  'res.partner', partnerId, 'image_1920',
);
```

No manual base64. No guessing the endpoint.

---

## Flutter Setup

For persistent sessions across app restarts:

```dart
import 'package:odoo_rest_ov/odoo_rest_ov_flutter.dart';
import 'package:path_provider/path_provider.dart';

final dir = await getApplicationDocumentsDirectory();
final client = OdooFlutter.createClient(
  baseUrl: 'https://mycompany.odoo.com',
  database: 'mydb',
  documentsPath: dir.path,
);
```

On web, cookies are managed by the browser automatically. Same code, zero config.

> **CORS note:** Your Odoo server must allow cross-origin requests from your web app's domain.

---

## API Key Authentication

For Odoo 14+ API key auth (no login needed):

```dart
final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://mycompany.odoo.com',
  database: 'mydb',
));

client.setApiKey('your-api-key-here');
// Use ORM methods directly — no authenticate() call needed
```

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android | Supported | Cookie persistence via `OdooFlutter` |
| iOS | Supported | Cookie persistence via `OdooFlutter` |
| Web | Supported | Browser-managed cookies |
| macOS | Supported | Pure Dart |
| Linux | Supported | Pure Dart |
| Windows | Supported | Pure Dart |

---

## Odoo Version Support

Tested with **Odoo 14, 15, 16, 17, 18, and 19**. If Odoo speaks JSON-RPC 2.0, this package speaks back.

---

## Resources

- [API Reference](https://pub.dev/documentation/odoo_rest_ov/latest/)
- [GitHub Repository](https://github.com/osamaAlhalabi2/odoo_rest_ov)
- [Issue Tracker](https://github.com/osamaAlhalabi2/odoo_rest_ov/issues)
- [Changelog](https://github.com/osamaAlhalabi2/odoo_rest_ov/blob/main/CHANGELOG.md)

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  Built by <strong>Osama Al-Halabi</strong>
</p>
