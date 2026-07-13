import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/errors/exceptions.dart';
import 'package:it_ticket_support_management/core/security/password_hasher.dart';
import 'package:it_ticket_support_management/features/auth/data/datasources/i_auth_local_data_source.dart';
import 'package:it_ticket_support_management/features/auth/data/dtos/login_request_dto.dart';
import 'package:it_ticket_support_management/features/auth/data/dtos/login_response_dto.dart';
import 'package:it_ticket_support_management/features/auth/data/dtos/user_dto.dart';
import 'package:it_ticket_support_management/features/auth/data/mappers/user_mapper.dart';
import 'package:it_ticket_support_management/features/auth/data/repositories/auth_repository_impl.dart';

const _testLogin = '<test-login>';
const _testPassword = '<test-password>';
const _replacementPassword = '<new-test-password>';

void main() {
  group('AuthRepositoryImpl.login', () {
    test(
      'given_valid_credentials_when_login_then_passes_exact_request_and_maps_user_without_password_hash',
      () async {
        final source = _AuthLocalDataSourceSpy(loginUser: _userDto());
        final repository = _repository(source);

        final user = await repository.login(
          username: _testLogin,
          password: _testPassword,
        );

        expect(source.loginCalls, 1);
        expect(source.lastLoginRequest?.username, _testLogin);
        expect(source.lastLoginRequest?.password, _testPassword);
        expect(user.id, 1);
        expect(user.username, 'admin');
        expect(user.email, 'admin@example.com');
      },
    );

    test(
      'given_local_auth_exception_when_login_then_propagates_same_exception',
      () async {
        const exception = AuthException('Username or password is incorrect.');
        final source = _AuthLocalDataSourceSpy(loginError: exception);
        final repository = _repository(source);

        expect(
          () => repository.login(username: 'admin', password: 'wrong'),
          throwsA(same(exception)),
        );
        expect(source.savedUsers, isEmpty);
      },
    );
  });

  group('AuthRepositoryImpl.session', () {
    test(
      'given_no_current_user_when_get_current_user_then_returns_null',
      () async {
        final source = _AuthLocalDataSourceSpy(currentUser: null);
        final repository = _repository(source);

        final user = await repository.getCurrentUser();

        expect(user, isNull);
        expect(source.getCurrentUserCalls, 1);
      },
    );

    test('given_current_user_when_get_current_user_then_maps_user', () async {
      final source = _AuthLocalDataSourceSpy(currentUser: _userDto(id: 5));
      final repository = _repository(source);

      final user = await repository.getCurrentUser();

      expect(user?.id, 5);
      expect(user?.username, 'admin');
    });

    test('given_logout_when_called_then_delegates_once', () async {
      final source = _AuthLocalDataSourceSpy();
      final repository = _repository(source);

      await repository.logout();

      expect(source.logoutCalls, 1);
    });
  });

  group('AuthRepositoryImpl.changePassword', () {
    test(
      'given_new_password_when_change_password_then_hashes_password_before_storage',
      () async {
        final source = _AuthLocalDataSourceSpy();
        final repository = _repository(source);

        await repository.changePassword(
          userId: 9,
          newPassword: _replacementPassword,
        );

        expect(source.changePasswordCalls, 1);
        expect(source.lastChangedUserId, 9);
        expect(
          source.lastNewPasswordHash,
          PasswordHasher.hash(_replacementPassword),
        );
        expect(source.lastNewPasswordHash, isNot(_replacementPassword));
      },
    );
  });
}

AuthRepositoryImpl _repository(_AuthLocalDataSourceSpy source) {
  return AuthRepositoryImpl(
    localDataSource: source,
    userMapper: const UserMapper(),
  );
}

UserDto _userDto({int id = 1}) {
  return UserDto(
    id: id,
    fullName: 'System Administrator',
    username: 'admin',
    email: 'admin@example.com',
    passwordHash: PasswordHasher.hash(_testPassword),
    role: 'admin',
    isActive: true,
    mustChangePassword: false,
    failedLoginAttempts: 0,
    createdAt: DateTime(2026),
  );
}

class _AuthLocalDataSourceSpy implements IAuthLocalDataSource {
  _AuthLocalDataSourceSpy({
    UserDto? loginUser,
    this.loginError,
    this.currentUser,
  }) : loginUser = loginUser ?? _userDto();

  final UserDto loginUser;
  final Object? loginError;
  final UserDto? currentUser;
  int loginCalls = 0;
  int logoutCalls = 0;
  int getCurrentUserCalls = 0;
  int changePasswordCalls = 0;
  LoginRequestDto? lastLoginRequest;
  int? lastChangedUserId;
  String? lastNewPasswordHash;
  final List<UserDto> savedUsers = [];

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    loginCalls++;
    lastLoginRequest = request;
    if (loginError != null) throw loginError!;
    return LoginResponseDto(user: loginUser);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<UserDto?> getCurrentUser() async {
    getCurrentUserCalls++;
    return currentUser;
  }

  @override
  Future<void> saveCurrentUser(UserDto user) async {
    savedUsers.add(user);
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String newPasswordHash,
  }) async {
    changePasswordCalls++;
    lastChangedUserId = userId;
    lastNewPasswordHash = newPasswordHash;
  }
}
