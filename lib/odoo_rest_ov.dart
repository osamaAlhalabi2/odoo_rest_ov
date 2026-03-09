/// A Dart package for interacting with Odoo servers via JSON-RPC 2.0.
///
/// Provides typed ORM methods, a fluent domain builder, session management,
/// report downloads, binary field handling, and more.
///
/// ```dart
/// import 'package:odoo_rest_ov/odoo_rest_ov.dart';
///
/// final client = OdooClient(OdooClientOptions(
///   baseUrl: 'https://mycompany.odoo.com',
///   database: 'mydb',
/// ));
///
/// await client.authenticate('admin', 'admin');
/// final partners = await client.searchRead('res.partner', []);
/// ```
library;

// Client
export 'src/client/odoo_client.dart';
export 'src/client/odoo_client_options.dart';
export 'src/client/odoo_session.dart';

// ORM
export 'src/orm/domain_builder.dart';
export 'src/orm/odoo_orm.dart';

// Models
export 'src/models/controller_response.dart';
export 'src/models/odoo_record.dart';
export 'src/models/odoo_response.dart';
export 'src/models/server_info.dart';

// Exceptions
export 'src/exceptions/odoo_exceptions.dart';

// Network (selective — only what consumers might need)
export 'src/network/json_rpc.dart';
