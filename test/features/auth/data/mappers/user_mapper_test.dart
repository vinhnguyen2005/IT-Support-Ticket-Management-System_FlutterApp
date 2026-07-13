import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/security/password_hasher.dart';
import 'package:it_ticket_support_management/features/auth/data/dtos/user_dto.dart';
import 'package:it_ticket_support_management/features/auth/data/mappers/user_mapper.dart';

void main() {
  group('UserDto.fromMap', () {
    test(
      'given_complete_database_row_when_from_map_then_parses_auth_fields',
      () {
        final row = {
          'id': 1,
          'fullName': 'System Administrator',
          'username': 'admin',
          'email': 'admin@example.com',
          'passwordHash': PasswordHasher.hash('Admin@123'),
          'role': 'admin',
          'departmentId': null,
          'phoneNumber': null,
          'avatarUrl': null,
          'isActive': 1,
          'mustChangePassword': 1,
          'lastLoginAt': '2026-07-13T08:00:00.000',
          'failedLoginAttempts': 4,
          'lockedUntil': '2026-07-13T08:15:00.000',
          'createdAt': '2026-07-13T07:00:00.000',
          'updatedAt': null,
        };

        final dto = UserDto.fromMap(row);

        expect(dto.id, 1);
        expect(dto.isActive, isTrue);
        expect(dto.mustChangePassword, isTrue);
        expect(dto.failedLoginAttempts, 4);
        expect(dto.lockedUntil, DateTime.parse('2026-07-13T08:15:00.000'));
      },
    );

    test('given_corrupt_dates_when_from_map_then_throws_format_exception', () {
      final row = _row()..['createdAt'] = 'not-a-date';

      expect(() => UserDto.fromMap(row), throwsA(isA<FormatException>()));
    });
  });

  group('UserMapper', () {
    test(
      'given_user_dto_when_map_to_entity_then_does_not_expose_password_hash',
      () {
        final dto = UserDto.fromMap(_row());
        const mapper = UserMapper();

        final user = mapper.mapToEntity(dto);

        expect(user.id, dto.id);
        expect(user.username, dto.username);
        expect(user.email, dto.email);
        expect(user.role, dto.role);
        expect(user.mustChangePassword, dto.mustChangePassword);
        expect(user.toString(), isNot(contains(dto.passwordHash!)));
      },
    );
  });
}

Map<String, Object?> _row() {
  return {
    'id': 1,
    'fullName': 'System Administrator',
    'username': 'admin',
    'email': 'admin@example.com',
    'passwordHash': PasswordHasher.hash('Admin@123'),
    'role': 'admin',
    'departmentId': null,
    'phoneNumber': null,
    'avatarUrl': null,
    'isActive': 1,
    'mustChangePassword': 0,
    'lastLoginAt': null,
    'failedLoginAttempts': null,
    'lockedUntil': null,
    'createdAt': '2026-07-13T07:00:00.000',
    'updatedAt': null,
  };
}
