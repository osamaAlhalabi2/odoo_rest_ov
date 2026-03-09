/// Flutter-specific extensions for odoo_rest_ov.
///
/// Provides persistent cookie storage and convenience client creation
/// for Flutter apps.
///
/// ```dart
/// import 'package:odoo_rest_ov/odoo_rest_ov_flutter.dart';
/// import 'package:path_provider/path_provider.dart';
///
/// final dir = await getApplicationDocumentsDirectory();
/// final client = OdooFlutter.createClient(
///   baseUrl: 'https://mycompany.odoo.com',
///   database: 'mydb',
///   documentsPath: dir.path,
/// );
/// ```
library;

export 'odoo_rest_ov.dart';
export 'src/flutter/odoo_flutter.dart';
