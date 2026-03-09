/// Fluent, type-safe builder for Odoo domain filters.
///
/// Example:
/// ```dart
/// final domain = OdooDomain()
///   .where('name').equals('John')
///   .where('age').greaterThan(18)
///   .or()
///   .where('email').ilike('%@gmail.com')
///   .where('email').ilike('%@yahoo.com')
///   .build();
/// ```
class OdooDomain {
  final List<dynamic> _criteria = [];
  final List<String> _operators = [];

  /// Starts a new condition on [field].
  OdooDomainField where(String field) {
    return OdooDomainField._(this, field);
  }

  /// Inserts an OR operator. The next two conditions will be OR'd together
  /// (prefix notation).
  OdooDomain or() {
    _operators.add('|');
    return this;
  }

  /// Inserts an AND operator explicitly (usually implicit between conditions).
  OdooDomain and() {
    _operators.add('&');
    return this;
  }

  /// Inserts a NOT operator. Negates the next condition.
  OdooDomain not() {
    _operators.add('!');
    return this;
  }

  void _addCondition(String field, String operator, dynamic value) {
    _criteria.add([field, operator, value]);
  }

  /// Builds the domain as a list suitable for Odoo's domain format.
  ///
  /// Returns a `List<dynamic>` where string operators ('|', '&', '!')
  /// appear in prefix position followed by leaf tuples `[field, op, value]`.
  List<dynamic> build() {
    final result = <dynamic>[];

    // Add prefix operators
    for (final op in _operators) {
      result.add(op);
    }

    // Add criteria
    for (final criterion in _criteria) {
      result.add(criterion);
    }

    return result;
  }

  /// Creates an [OdooDomain] from a raw domain list (pass-through).
  static List<dynamic> raw(List<dynamic> domain) => domain;
}

/// Represents a field in a domain expression, providing comparison operators.
class OdooDomainField {
  final OdooDomain _domain;
  final String _field;

  OdooDomainField._(this._domain, this._field);

  /// Field equals [value]. Operator: `=`
  OdooDomain equals(dynamic value) {
    _domain._addCondition(_field, '=', value);
    return _domain;
  }

  /// Field does not equal [value]. Operator: `!=`
  OdooDomain notEquals(dynamic value) {
    _domain._addCondition(_field, '!=', value);
    return _domain;
  }

  /// Field is greater than [value]. Operator: `>`
  OdooDomain greaterThan(dynamic value) {
    _domain._addCondition(_field, '>', value);
    return _domain;
  }

  /// Field is greater than or equal to [value]. Operator: `>=`
  OdooDomain greaterOrEqual(dynamic value) {
    _domain._addCondition(_field, '>=', value);
    return _domain;
  }

  /// Field is less than [value]. Operator: `<`
  OdooDomain lessThan(dynamic value) {
    _domain._addCondition(_field, '<', value);
    return _domain;
  }

  /// Field is less than or equal to [value]. Operator: `<=`
  OdooDomain lessOrEqual(dynamic value) {
    _domain._addCondition(_field, '<=', value);
    return _domain;
  }

  /// Field matches [pattern] (case-sensitive). Operator: `like`
  OdooDomain like(String pattern) {
    _domain._addCondition(_field, 'like', pattern);
    return _domain;
  }

  /// Field does not match [pattern] (case-sensitive). Operator: `not like`
  OdooDomain notLike(String pattern) {
    _domain._addCondition(_field, 'not like', pattern);
    return _domain;
  }

  /// Field matches [pattern] (case-insensitive). Operator: `ilike`
  OdooDomain ilike(String pattern) {
    _domain._addCondition(_field, 'ilike', pattern);
    return _domain;
  }

  /// Field does not match [pattern] (case-insensitive). Operator: `not ilike`
  OdooDomain notIlike(String pattern) {
    _domain._addCondition(_field, 'not ilike', pattern);
    return _domain;
  }

  /// Field value is in [values]. Operator: `in`
  OdooDomain isIn(List<dynamic> values) {
    _domain._addCondition(_field, 'in', values);
    return _domain;
  }

  /// Field value is not in [values]. Operator: `not in`
  OdooDomain notIn(List<dynamic> values) {
    _domain._addCondition(_field, 'not in', values);
    return _domain;
  }

  /// Field is a child of [value] (hierarchical). Operator: `child_of`
  OdooDomain childOf(dynamic value) {
    _domain._addCondition(_field, 'child_of', value);
    return _domain;
  }

  /// Field is a parent of [value] (hierarchical). Operator: `parent_of`
  OdooDomain parentOf(dynamic value) {
    _domain._addCondition(_field, 'parent_of', value);
    return _domain;
  }

  /// Field is set (not false/null). Operator: `!=`
  OdooDomain isSet() {
    _domain._addCondition(_field, '!=', false);
    return _domain;
  }

  /// Field is not set (false/null). Operator: `=`
  OdooDomain isNotSet() {
    _domain._addCondition(_field, '=', false);
    return _domain;
  }
}
