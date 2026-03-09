import 'package:odoo_rest_ov/odoo_rest_ov.dart';
import 'package:test/test.dart';

void main() {
  group('OdooDomain', () {
    test('builds simple equality condition', () {
      final domain = OdooDomain().where('name').equals('John').build();

      expect(domain, [
        ['name', '=', 'John'],
      ]);
    });

    test('builds multiple AND conditions (implicit)', () {
      final domain = OdooDomain()
          .where('name').equals('John')
          .where('age').greaterThan(18)
          .build();

      expect(domain, [
        ['name', '=', 'John'],
        ['age', '>', 18],
      ]);
    });

    test('builds OR conditions', () {
      final domain = OdooDomain()
          .or()
          .where('email').ilike('%@gmail.com')
          .where('email').ilike('%@yahoo.com')
          .build();

      expect(domain, [
        '|',
        ['email', 'ilike', '%@gmail.com'],
        ['email', 'ilike', '%@yahoo.com'],
      ]);
    });

    test('builds complex domain with OR and AND', () {
      final domain = OdooDomain()
          .where('name').equals('John')
          .where('age').greaterThan(18)
          .or()
          .where('email').ilike('%@gmail.com')
          .where('email').ilike('%@yahoo.com')
          .build();

      expect(domain, [
        '|',
        ['name', '=', 'John'],
        ['age', '>', 18],
        ['email', 'ilike', '%@gmail.com'],
        ['email', 'ilike', '%@yahoo.com'],
      ]);
    });

    test('builds NOT condition', () {
      final domain = OdooDomain()
          .not()
          .where('active').equals(false)
          .build();

      expect(domain, [
        '!',
        ['active', '=', false],
      ]);
    });

    test('supports notEquals operator', () {
      final domain = OdooDomain().where('state').notEquals('draft').build();
      expect(domain, [
        ['state', '!=', 'draft'],
      ]);
    });

    test('supports greaterOrEqual operator', () {
      final domain = OdooDomain().where('amount').greaterOrEqual(100).build();
      expect(domain, [
        ['amount', '>=', 100],
      ]);
    });

    test('supports lessThan operator', () {
      final domain = OdooDomain().where('qty').lessThan(5).build();
      expect(domain, [
        ['qty', '<', 5],
      ]);
    });

    test('supports lessOrEqual operator', () {
      final domain = OdooDomain().where('qty').lessOrEqual(5).build();
      expect(domain, [
        ['qty', '<=', 5],
      ]);
    });

    test('supports like operator', () {
      final domain = OdooDomain().where('name').like('Test%').build();
      expect(domain, [
        ['name', 'like', 'Test%'],
      ]);
    });

    test('supports notLike operator', () {
      final domain = OdooDomain().where('name').notLike('Test%').build();
      expect(domain, [
        ['name', 'not like', 'Test%'],
      ]);
    });

    test('supports notIlike operator', () {
      final domain = OdooDomain().where('name').notIlike('test%').build();
      expect(domain, [
        ['name', 'not ilike', 'test%'],
      ]);
    });

    test('supports in operator', () {
      final domain =
          OdooDomain().where('state').isIn(['draft', 'confirmed']).build();
      expect(domain, [
        ['state', 'in', ['draft', 'confirmed']],
      ]);
    });

    test('supports not in operator', () {
      final domain =
          OdooDomain().where('state').notIn(['cancelled']).build();
      expect(domain, [
        ['state', 'not in', ['cancelled']],
      ]);
    });

    test('supports child_of operator', () {
      final domain = OdooDomain().where('parent_id').childOf(1).build();
      expect(domain, [
        ['parent_id', 'child_of', 1],
      ]);
    });

    test('supports parent_of operator', () {
      final domain = OdooDomain().where('parent_id').parentOf(1).build();
      expect(domain, [
        ['parent_id', 'parent_of', 1],
      ]);
    });

    test('supports isSet', () {
      final domain = OdooDomain().where('email').isSet().build();
      expect(domain, [
        ['email', '!=', false],
      ]);
    });

    test('supports isNotSet', () {
      final domain = OdooDomain().where('email').isNotSet().build();
      expect(domain, [
        ['email', '=', false],
      ]);
    });

    test('raw domain pass-through', () {
      final raw = [
        ['name', '=', 'test'],
        ['active', '=', true],
      ];
      expect(OdooDomain.raw(raw), raw);
    });

    test('empty domain', () {
      final domain = OdooDomain().build();
      expect(domain, isEmpty);
    });
  });
}
