import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/errors/exceptions.dart';
import 'package:it_ticket_support_management/features/auth/application/services/i_auth_service.dart';
import 'package:it_ticket_support_management/features/auth/domain/entities/user.dart';
import 'package:it_ticket_support_management/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/change_password_page.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/home_page.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/login_page.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LoginPage widget', () {
    testWidgets(
      'given_login_page_when_rendered_then_username_password_and_button_are_visible',
      (tester) async {
        final viewModel = LoginViewModel(_AuthUiServiceFake());

        await tester.pumpWidget(_app(LoginPage(viewModel: viewModel)));

        expect(find.text('Sign in'), findsWidgets);
        expect(find.text('Username or email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets(
      'given_failed_login_when_submit_then_error_message_is_rendered_and_password_is_not_leaked',
      (tester) async {
        final service = _AuthUiServiceFake(
          loginError: const AuthException('Username or password is incorrect.'),
        );
        final viewModel = LoginViewModel(service);

        await tester.pumpWidget(_app(LoginPage(viewModel: viewModel)));
        await _replaceFieldText(tester, 'Username or email', 'admin');
        await _replaceFieldText(tester, 'Password', 'WrongPassword@123');

        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pumpAndSettle();

        expect(service.loginCalls, 1);
        expect(find.text('Username or password is incorrect.'), findsOneWidget);
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );

    testWidgets(
      'given_login_is_pending_when_submit_then_button_is_disabled_and_spinner_is_visible',
      (tester) async {
        final pendingLogin = Completer<User>();
        final service = _AuthUiServiceFake(loginFuture: pendingLogin.future);
        final viewModel = LoginViewModel(service);

        await _useLargeViewport(tester);
        await tester.pumpWidget(_app(LoginPage(viewModel: viewModel)));

        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pump();

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        pendingLogin.complete(_user());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'given_user_must_change_password_when_login_succeeds_then_navigates_to_change_password_page',
      (tester) async {
        final service = _AuthUiServiceFake(
          loginUser: _user(mustChangePassword: true),
        );
        final viewModel = LoginViewModel(service);

        await tester.pumpWidget(_app(LoginPage(viewModel: viewModel)));
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pumpAndSettle();

        expect(find.byType(ChangePasswordPage), findsOneWidget);
        expect(find.text('Set a new password'), findsOneWidget);
      },
    );

    testWidgets(
      'given_user_does_not_need_password_change_when_login_succeeds_then_navigates_to_home_page',
      (tester) async {
        final service = _AuthUiServiceFake(loginUser: _user());
        final viewModel = LoginViewModel(service);

        await _useLargeViewport(tester);
        await tester.pumpWidget(_app(LoginPage(viewModel: viewModel)));
        await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.text('System Administrator'), findsOneWidget);
      },
    );
  });

  group('ChangePasswordPage widget', () {
    testWidgets(
      'given_change_password_failure_when_submit_then_error_is_rendered_without_navigation',
      (tester) async {
        final service = _AuthUiServiceFake(
          loginUser: _user(mustChangePassword: true),
          changePasswordError: const AuthException(
            'Password confirmation does not match.',
          ),
        );
        final viewModel = LoginViewModel(service);
        await viewModel.login(username: 'admin', password: 'Temp@1234');

        await _useLargeViewport(tester);
        await tester.pumpWidget(_app(ChangePasswordPage(viewModel: viewModel)));
        await _replaceFieldText(tester, 'New password', 'Password@123');
        await _replaceFieldText(tester, 'Confirm password', 'Password@124');

        await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
        await tester.pumpAndSettle();

        expect(service.changePasswordCalls, 1);
        expect(
          find.text('Password confirmation does not match.'),
          findsOneWidget,
        );
        expect(find.byType(ChangePasswordPage), findsOneWidget);
      },
    );

    testWidgets(
      'given_change_password_success_when_submit_then_refreshes_user_and_navigates_home',
      (tester) async {
        final service = _AuthUiServiceFake(
          loginUser: _user(mustChangePassword: true),
          currentUser: _user(mustChangePassword: false),
        );
        final viewModel = LoginViewModel(service);
        await viewModel.login(username: 'admin', password: 'Temp@1234');

        await _useLargeViewport(tester);
        await tester.pumpWidget(_app(ChangePasswordPage(viewModel: viewModel)));
        await _replaceFieldText(tester, 'New password', 'Password@123');
        await _replaceFieldText(tester, 'Confirm password', 'Password@123');

        await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
        await tester.pumpAndSettle();

        expect(service.changePasswordCalls, 1);
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.text('System Administrator'), findsOneWidget);
      },
    );
  });
}

Widget _app(Widget home) {
  return MaterialApp(home: home);
}

Future<void> _useLargeViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _replaceFieldText(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextField, label);
  await tester.tap(field);
  await tester.enterText(field, value);
  await tester.pump();
}

User _user({bool mustChangePassword = false}) {
  return User(
    id: 1,
    fullName: 'System Administrator',
    username: 'admin',
    email: 'admin@example.com',
    role: 'admin',
    isActive: true,
    mustChangePassword: mustChangePassword,
    createdAt: DateTime(2026),
  );
}

class _AuthUiServiceFake implements IAuthService {
  _AuthUiServiceFake({
    User? loginUser,
    this.loginFuture,
    this.loginError,
    this.changePasswordError,
    this.currentUser,
  }) : loginUser = loginUser ?? _user();

  final User loginUser;
  final Future<User>? loginFuture;
  final Object? loginError;
  final Object? changePasswordError;
  User? currentUser;
  int loginCalls = 0;
  int logoutCalls = 0;
  int changePasswordCalls = 0;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    if (loginError != null) throw loginError!;
    return loginFuture ?? Future.value(loginUser);
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  @override
  Future<User?> getCurrentUser() async => currentUser ?? loginUser;

  @override
  Future<void> changePassword({
    required User user,
    required String newPassword,
    required String confirmPassword,
  }) async {
    changePasswordCalls++;
    if (changePasswordError != null) throw changePasswordError!;
  }
}
