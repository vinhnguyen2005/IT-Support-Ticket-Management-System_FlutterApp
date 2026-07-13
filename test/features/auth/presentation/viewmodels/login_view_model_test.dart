import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/errors/exceptions.dart';
import 'package:it_ticket_support_management/features/auth/application/services/i_auth_service.dart';
import 'package:it_ticket_support_management/features/auth/domain/entities/user.dart';
import 'package:it_ticket_support_management/features/auth/presentation/viewmodels/login_view_model.dart';

const _testPassword = '<test-password>';
const _replacementPassword = '<new-test-password>';

void main() {
  group('LoginViewModel.login state transitions', () {
    test(
      'given_valid_credentials_when_login_then_emits_loading_then_success',
      () async {
        final service = _AuthServiceFake(loginResults: [_user()]);
        final viewModel = LoginViewModel(service);
        final states = _recordStates(viewModel);

        final success = await viewModel.login(
          username: 'admin',
          password: _testPassword,
        );

        expect(success, isTrue);
        expect(service.loginCalls, 1);
        expect(service.lastUsername, 'admin');
        expect(service.lastPassword, _testPassword);
        expect(viewModel.currentUser?.username, 'admin');
        expect(viewModel.errorMessage, isNull);
        expect(states, [
          _StateSnapshot.loading(),
          _StateSnapshot.success(username: 'admin'),
        ]);
      },
    );

    test(
      'given_previous_error_when_next_login_starts_then_error_is_cleared_before_success',
      () async {
        final service = _AuthServiceFake(
          loginResults: [
            _LoginFailure(
              const AuthException('Username or password is incorrect.'),
            ),
            _user(),
          ],
        );
        final viewModel = LoginViewModel(service);

        final firstSuccess = await viewModel.login(
          username: 'admin',
          password: 'bad',
        );
        expect(firstSuccess, isFalse);
        expect(viewModel.errorMessage, 'Username or password is incorrect.');

        final states = _recordStates(viewModel);
        final secondSuccess = await viewModel.login(
          username: 'admin',
          password: _testPassword,
        );

        expect(secondSuccess, isTrue);
        expect(states.first.errorMessage, isNull);
        expect(states.first.status, LoginStatus.loading);
        expect(states.last.status, LoginStatus.success);
        expect(states.last.errorMessage, isNull);
      },
    );

    test(
      'given_repository_exception_when_login_then_loading_is_reset_and_error_is_safe',
      () async {
        final service = _AuthServiceFake(
          loginResults: [
            _LoginFailure(
              const AuthException('Username or password is incorrect.'),
            ),
          ],
        );
        final viewModel = LoginViewModel(service);

        final success = await viewModel.login(
          username: 'admin',
          password: _testPassword,
        );

        expect(success, isFalse);
        expect(viewModel.status, LoginStatus.failure);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.currentUser, isNull);
        expect(viewModel.errorMessage, 'Username or password is incorrect.');
        expect(viewModel.errorMessage, isNot(contains(_testPassword)));
      },
    );

    test(
      'given_authenticated_user_when_next_login_fails_then_stale_user_is_cleared',
      () async {
        final service = _AuthServiceFake(
          loginResults: [
            _user(username: 'admin'),
            _LoginFailure(
              const AuthException('Username or password is incorrect.'),
            ),
          ],
        );
        final viewModel = LoginViewModel(service);

        expect(
          await viewModel.login(username: 'admin', password: _testPassword),
          isTrue,
        );

        expect(
          await viewModel.login(username: 'admin', password: 'wrong'),
          isFalse,
        );

        expect(viewModel.status, LoginStatus.failure);
        expect(
          viewModel.currentUser,
          isNull,
          reason: 'A failed login must not leave a stale authenticated user.',
        );
      },
    );
  });

  group('LoginViewModel.login concurrency', () {
    test(
      'given_double_tap_login_when_first_request_is_loading_then_second_request_is_ignored',
      () async {
        final pendingLogin = Completer<User>();
        final service = _AuthServiceFake(
          loginResults: [pendingLogin.future, _user()],
        );
        final viewModel = LoginViewModel(service);

        final first = viewModel.login(
          username: 'admin',
          password: _testPassword,
        );
        await _flushMicrotasks();
        final second = viewModel.login(
          username: 'admin',
          password: _testPassword,
        );
        await _flushMicrotasks();

        expect(
          service.loginCalls,
          1,
          reason: 'Duplicate login taps should not create parallel requests.',
        );

        pendingLogin.complete(_user());
        expect(await first, isTrue);
        expect(await second, isFalse);
      },
    );

    test(
      'given_second_login_finishes_first_when_old_request_finishes_then_old_result_does_not_overwrite_new_state',
      () async {
        final oldRequest = Completer<User>();
        final service = _AuthServiceFake(
          loginResults: [
            oldRequest.future,
            _LoginFailure(
              const AuthException('Username or password is incorrect.'),
            ),
          ],
        );
        final viewModel = LoginViewModel(service);

        final first = viewModel.login(username: 'old', password: 'old-pass');
        await _flushMicrotasks();
        final second = await viewModel.login(username: 'new', password: 'bad');
        expect(second, isFalse);
        expect(viewModel.status, LoginStatus.failure);

        oldRequest.complete(_user(username: 'old'));
        final firstResult = await first;

        expect(firstResult, isFalse);
        expect(viewModel.status, LoginStatus.failure);
        expect(
          viewModel.currentUser,
          isNull,
          reason: 'Stale success from an older request must not authenticate.',
        );
      },
    );

    test(
      'given_logout_while_login_pending_when_login_completes_then_logout_state_wins',
      () async {
        final pendingLogin = Completer<User>();
        final service = _AuthServiceFake(loginResults: [pendingLogin.future]);
        final viewModel = LoginViewModel(service);

        final loginFuture = viewModel.login(
          username: 'admin',
          password: _testPassword,
        );
        await _flushMicrotasks();
        await viewModel.logout();

        pendingLogin.complete(_user());
        final loginResult = await loginFuture;

        expect(loginResult, isFalse);
        expect(viewModel.status, LoginStatus.initial);
        expect(viewModel.currentUser, isNull);
      },
    );
  });

  group('LoginViewModel.logout and changePassword', () {
    test(
      'given_authenticated_user_when_logout_then_clears_user_error_and_state',
      () async {
        final service = _AuthServiceFake(loginResults: [_user()]);
        final viewModel = LoginViewModel(service);

        await viewModel.login(username: 'admin', password: _testPassword);
        await viewModel.logout();

        expect(service.logoutCalls, 1);
        expect(viewModel.status, LoginStatus.initial);
        expect(viewModel.currentUser, isNull);
        expect(viewModel.errorMessage, isNull);
      },
    );

    test(
      'given_no_current_user_when_change_password_then_fails_without_service_call',
      () async {
        final service = _AuthServiceFake();
        final viewModel = LoginViewModel(service);

        final success = await viewModel.changePassword(
          newPassword: _replacementPassword,
          confirmPassword: _replacementPassword,
        );

        expect(success, isFalse);
        expect(viewModel.status, LoginStatus.failure);
        expect(viewModel.errorMessage, 'No signed-in user was found.');
        expect(service.changePasswordCalls, 0);
      },
    );

    test(
      'given_authenticated_user_when_change_password_succeeds_then_refreshes_current_user',
      () async {
        final service = _AuthServiceFake(
          loginResults: [_user(mustChangePassword: true)],
          currentUserResult: _user(mustChangePassword: false),
        );
        final viewModel = LoginViewModel(service);

        await viewModel.login(username: 'admin', password: _testPassword);
        final success = await viewModel.changePassword(
          newPassword: _replacementPassword,
          confirmPassword: _replacementPassword,
        );

        expect(success, isTrue);
        expect(service.changePasswordCalls, 1);
        expect(viewModel.currentUser?.mustChangePassword, isFalse);
      },
    );
  });
}

List<_StateSnapshot> _recordStates(LoginViewModel viewModel) {
  final states = <_StateSnapshot>[];
  viewModel.addListener(() {
    states.add(_StateSnapshot.from(viewModel));
  });
  return states;
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

User _user({String username = 'admin', bool mustChangePassword = false}) {
  return User(
    id: username == 'admin' ? 1 : 2,
    fullName: 'User $username',
    username: username,
    email: '$username@example.com',
    role: 'admin',
    isActive: true,
    mustChangePassword: mustChangePassword,
    createdAt: DateTime(2026),
  );
}

class _StateSnapshot {
  const _StateSnapshot({
    required this.status,
    required this.isLoading,
    required this.username,
    required this.errorMessage,
  });

  factory _StateSnapshot.from(LoginViewModel viewModel) {
    return _StateSnapshot(
      status: viewModel.status,
      isLoading: viewModel.isLoading,
      username: viewModel.currentUser?.username,
      errorMessage: viewModel.errorMessage,
    );
  }

  factory _StateSnapshot.loading() {
    return const _StateSnapshot(
      status: LoginStatus.loading,
      isLoading: true,
      username: null,
      errorMessage: null,
    );
  }

  factory _StateSnapshot.success({required String username}) {
    return _StateSnapshot(
      status: LoginStatus.success,
      isLoading: false,
      username: username,
      errorMessage: null,
    );
  }

  final LoginStatus status;
  final bool isLoading;
  final String? username;
  final String? errorMessage;

  @override
  bool operator ==(Object other) {
    return other is _StateSnapshot &&
        other.status == status &&
        other.isLoading == isLoading &&
        other.username == username &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, isLoading, username, errorMessage);

  @override
  String toString() {
    return 'State(status: $status, isLoading: $isLoading, '
        'username: $username, errorMessage: $errorMessage)';
  }
}

class _AuthServiceFake implements IAuthService {
  _AuthServiceFake({List<Object>? loginResults, this.currentUserResult})
    : _loginResults = List<Object>.from(loginResults ?? const []);

  final List<Object> _loginResults;
  User? currentUserResult;
  int loginCalls = 0;
  int logoutCalls = 0;
  int changePasswordCalls = 0;
  String? lastUsername;
  String? lastPassword;

  @override
  Future<User> login({required String username, required String password}) {
    loginCalls++;
    lastUsername = username;
    lastPassword = password;
    if (_loginResults.isEmpty) {
      throw StateError('No login result was configured.');
    }

    final result = _loginResults.removeAt(0);
    if (result is Future<User>) return result;
    if (result is User) return Future.value(result);
    if (result is _LoginFailure) throw result.error;
    throw StateError('Unsupported login result: $result');
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<User?> getCurrentUser() async => currentUserResult;

  @override
  Future<void> changePassword({
    required User user,
    required String newPassword,
    required String confirmPassword,
  }) async {
    changePasswordCalls++;
  }
}

class _LoginFailure {
  const _LoginFailure(this.error);

  final Object error;
}
