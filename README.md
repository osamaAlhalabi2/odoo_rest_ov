# odoo_rest_ov

![odoo_rest_ov banner](https://raw.githubusercontent.com/nexxa-group/odoo_rest_ov/main/doc/banner.png)

[![pub package](https://img.shields.io/pub/v/odoo_rest_ov.svg)](https://pub.dev/packages/odoo_rest_ov)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Dart package for interacting with Odoo servers via **JSON-RPC 2.0**. Provides typed ORM methods, a fluent domain builder, session management, error handling with user-friendly messages, and more.

**Works on Android, iOS, Web, macOS, Linux, and Windows.**

---

## Features

- **Simple ORM methods** — `searchRead`, `create`, `write`, `unlink`, and more
- **Fluent domain builder** — type-safe filter construction
- **Typed exceptions** — mapped from Odoo error types with clean user-facing messages
- **Session management** — login, logout, session stream, auto-refresh
- **Timezone auto-detection** — fixes the common timezone mismatch issue
- **User type detection** — internal, portal, or public user
- **Controller calls** — call any Odoo endpoint (JSON-RPC or REST)
- **Report download** — PDF and other report formats
- **Binary fields** — upload/download attachments
- **Flutter helpers** — persistent cookie jar for mobile apps

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

---

## Domain Builder

Build Odoo domains with a fluent, type-safe API instead of raw lists:

```dart
// Simple conditions (AND by default)
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

**Available operators:**

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

Raw lists still work for backward compatibility:

```dart
final raw = [['name', 'ilike', 'test'], ['active', '=', true]];
await client.searchRead('res.partner', raw);
```

---

## ORM Methods

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

// Create
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

// Any model method
final result = await client.callMethod('res.partner', 'my_method',
    args: [1], kwargs: {'key': 'value'});
```

---

## Record Helpers

Records come with convenient extension methods:

```dart
final partner = partners.first;

partner.id;                          // int
partner.name;                        // String
partner['email'];                    // dynamic field access
partner.many2oneId('country_id');    // int? — related record ID
partner.many2oneName('country_id');  // String? — related record name
partner.x2manyIds('tag_ids');        // List<int> — many2many IDs
```

---

## Error Handling

Errors are auto-mapped to typed exceptions with **user-friendly messages** (safe for UI display):

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
├── OdooAccessDeniedException     — invalid credentials
├── OdooSessionExpiredException   — session no longer valid
├── OdooAccessErrorException      — permission denied
├── OdooValidationException       — validation failed
├── OdooMissingErrorException     — record not found
├── OdooUserErrorException        — business logic error
├── OdooNetworkException          — connectivity issues
└── OdooProtocolException         — malformed response
```

---

## Session Management

```dart
// Check session validity (non-throwing)
final isValid = await client.checkSession();

// Refresh session data
final updated = await client.refreshSession();

// Listen to session changes
client.sessionStream.listen((session) {
  if (session == null) {
    // Navigate to login screen
  }
});

// Session callback (set in options)
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

## User Type Detection

```dart
final session = await client.authenticate('admin', 'admin');

session.userType;        // OdooUserType.internal
session.isInternalUser;  // true
session.isPortalUser;    // false
session.isPublic;        // false
session.isAdmin;         // true
session.isSystem;        // true
```

---

## Timezone Handling

Timezone is **auto-detected** from the user's Odoo settings after login — no manual fix needed:

```dart
final session = await client.authenticate('admin', 'admin');
print(session.timezone); // "Asia/Damascus"

// Override if needed (e.g. device timezone)
client.setTimezone('America/New_York');
```

---

## Controller Calls

Call any Odoo endpoint — JSON-RPC or REST:

```dart
// JSON-RPC endpoint (auto-wrapped)
final resp = await client.callController(
  '/web/webclient/version_info',
  params: {},
);
print(resp.data);          // response data
print(resp.statusCode);    // 200
print(resp.isSuccess);     // true

// REST-style GET
final rest = await client.callController(
  '/api/v1/partners',
  method: 'GET',
  params: {'limit': '10'},
  isJsonRpc: false,
);
print(rest.dataAsList);
```

---

## Reports & Binary Fields

```dart
// Download PDF report
final pdfBytes = await client.getReport(
  'account.report_invoice',
  [invoiceId],
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

---

## Flutter Setup

For persistent sessions across app restarts, use the Flutter helper:

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

> **Note:** The Flutter helper uses `PersistCookieJar` for disk-based cookie storage.
> On web, cookies are managed by the browser automatically — no extra setup needed.

---

## Web Support

The package works on web out of the box. The browser handles cookies automatically with `withCredentials: true`. No `cookie_jar` setup is needed for web.

```dart
// Same API on web — no special configuration
final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://mycompany.odoo.com',
  database: 'mydb',
));

await client.authenticate('admin', 'admin');
```

> **CORS note:** Your Odoo server must allow cross-origin requests from your web app's domain.

---

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | Supported | Cookie persistence via `OdooFlutter` |
| iOS      | Supported | Cookie persistence via `OdooFlutter` |
| Web      | Supported | Browser-managed cookies |
| macOS    | Supported | — |
| Linux    | Supported | — |
| Windows  | Supported | — |

---

## API Key Authentication

For Odoo 14+ API key authentication:

```dart
final client = OdooClient(OdooClientOptions(
  baseUrl: 'https://mycompany.odoo.com',
  database: 'mydb',
));

client.setApiKey('your-api-key-here');
// Now use ORM methods directly — no authenticate() needed
```

---

## Additional Resources

- [API Reference](https://pub.dev/documentation/odoo_rest_ov/latest/)
- [GitHub Repository](https://github.com/nexxa-group/odoo_rest_ov)
- [Issue Tracker](https://github.com/nexxa-group/odoo_rest_ov/issues)
- [Changelog](https://github.com/nexxa-group/odoo_rest_ov/blob/main/CHANGELOG.md)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
