import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/errors/exceptions.dart';
import 'package:it_ticket_support_management/features/auth/application/services/auth_service_impl.dart';
import 'package:it_ticket_support_management/features/auth/domain/entities/user.dart';
import 'package:it_ticket_support_management/features/auth/domain/repositories/i_auth_repository.dart';

void main() {
  group('AuthServiceImpl.login', () {
    test(
      'given_blank_username_when_login_then_rejects_without_calling_repository',
      () async {
        final repository = _AuthRepositorySpy();
        final service = AuthServiceImpl(repository);

        expect(
          () => service.login(username: ' \t\n ', password: 'Password@123'),
          throwsA(
            isA<AuthException>().having(
              (error) => error.message,
              'message',
              'Username or email is required.',
            ),
          ),
        );
        expect(repository.loginCalls, 0);
      },
    );

    test('given_empty_password_when_login_then_rejects_before_repository', () {
      final repository = _AuthRepositorySpy();
      final service = AuthServiceImpl(repository);

      expect(
        () => service.login(username: 'admin', password: ''),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            'Password is required.',
          ),
        ),
      );
      expect(repository.loginCalls, 0);
    });

    test(
      'given_username_with_outer_spaces_when_login_then_trims_username_but_preserves_password',
      () async {
        final repository = _AuthRepositorySpy(loginResult: _user());
        final service = AuthServiceImpl(repository);

        final user = await service.login(
          username: '  ADMIN@example.com  ',
          password: '  pass with spaces  ',
        );

        expect(user.id, 1);
        expect(repository.loginCalls, 1);
        expect(repository.lastUsername, 'ADMIN@example.com');
        expect(repository.lastPassword, '  pass with spaces  ');
      },
    );
  });

  group('AuthServiceImpl.changePassword', () {
    test('given_short_password_when_change_password_then_rejects', () {
      final repository = _AuthRepositorySpy();
      final service = AuthServiceImpl(repository);

      expect(
        () => service.changePassword(
          user: _user(),
          newPassword: '1234567',
          confirmPassword: '1234567',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            'Password must have at least 8 characters.',
          ),
        ),
      );
      expect(repository.changePasswordCalls, 0);
    });

    test('given_mismatched_confirmation_when_change_password_then_rejects', () {
      final repository = _AuthRepositorySpy();
      final service = AuthServiceImpl(repository);

      expect(
        () => service.changePassword(
          user: _user(),
          newPassword: 'Password@123',
          confirmPassword: 'Password@124',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.message,
            'message',
            'Password confirmation does not match.',
          ),
        ),
      );
      expect(repository.changePasswordCalls, 0);
    });

    test(
      'given_valid_password_when_change_password_then_delegates_raw_password_once',
      () async {
        final repository = _AuthRepositorySpy();
        final service = AuthServiceImpl(repository);

        await service.changePassword(
          user: _user(id: 42),
          newPassword: 'Password@123',
          confirmPassword: 'Password@123',
        );

        expect(repository.changePasswordCalls, 1);
        expect(repository.lastChangedUserId, 42);
        expect(repository.lastNewPassword, 'Password@123');
      },
    );
  });
}

User _user({int id = 1}) {
  return User(
    id: id,
    fullName: 'System Administrator',
    username: 'admin',
    email: 'admin@example.com',
    role: 'admin',
    isActive: true,
    mustChangePassword: false,
    createdAt: DateTime(2026),
  );
}

class _AuthRepositorySpy implements IAuthRepository {
  _AuthRepositorySpy({User? loginResult})
    : loginResult = loginResult ?? _user();

  final User loginResult;
  int loginCalls = 0;
  String? lastUsername;
  String? lastPassword;
  int changePasswordCalls = 0;
  int? lastChangedUserId;
  String? lastNewPassword;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    lastUsername = username;
    lastPassword = password;
    return loginResult;
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    lastChangedUserId = userId;
    lastNewPassword = newPassword;
  }

  @override
  Future<User?> getCurrentUser() => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();
}
