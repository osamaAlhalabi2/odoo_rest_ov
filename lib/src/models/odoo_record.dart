/// Type alias and extensions for Odoo records.
library;

/// An Odoo record represented as a map of field names to values.
typedef OdooRecord = Map<String, dynamic>;

/// Convenience extensions on [OdooRecord].
extension OdooRecordExtension on OdooRecord {
  /// The record's database ID.
  int get id => this['id'] as int;

  /// The record's display name (`name` field).
  String get name => this['name'] as String? ?? '';

  /// Extracts the ID from a Many2one field (returned as `[id, name]`).
  ///
  /// Returns `null` if the field is `false` (Odoo's way of saying empty).
  int? many2oneId(String field) {
    final value = this[field];
    if (value is List && value.isNotEmpty) {
      return value[0] as int;
    }
    if (value is int) return value;
    return null;
  }

  /// Extracts the display name from a Many2one field (returned as `[id, name]`).
  ///
  /// Returns `null` if the field is `false`.
  String? many2oneName(String field) {
    final value = this[field];
    if (value is List && value.length >= 2) {
      return value[1] as String;
    }
    return null;
  }

  /// Extracts the list of IDs from a Many2many / One2many field.
  ///
  /// Returns an empty list if the field is `false`.
  List<int> x2manyIds(String field) {
    final value = this[field];
    if (value is List) {
      return value.cast<int>();
    }
    return [];
  }
}
