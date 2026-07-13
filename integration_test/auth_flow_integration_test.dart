import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:it_ticket_support_management/features/auth/application/services/i_auth_service.dart';
import 'package:it_ticket_support_management/features/auth/domain/entities/user.dart';
import 'package:it_ticket_support_management/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/change_password_page.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/home_page.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/login_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'given_temporary_password_account_when_user_logs_in_changes_password_and_signs_out_then_returns_to_login',
    (tester) async {
      final service = _IntegrationAuthService();
      final viewModel = LoginViewModel(service);

      await _useLargeViewport(tester);
      await tester.pumpWidget(
        MaterialApp(home: LoginPage(viewModel: viewModel)),
      );

      expect(find.byType(LoginPage), findsOneWidget);
      await _replaceFieldText(tester, 'Username or email', 'admin');
      await _replaceFieldText(tester, 'Password', 'Temp@1234');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(ChangePasswordPage), findsOneWidget);
      await _replaceFieldText(tester, 'New password', 'Password@123');
      await _replaceFieldText(tester, 'Confirm password', 'Password@123');
      await tester.tap(find.widgetWithText(FilledButton, 'Save password'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('System Administrator'), findsOneWidget);

      await tester.tap(find.byTooltip('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(service.loginCalls, 1);
      expect(service.changePasswordCalls, 1);
      expect(service.logoutCalls, 1);
    },
  );
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

class _IntegrationAuthService implements IAuthService {
  int loginCalls = 0;
  int changePasswordCalls = 0;
  int logoutCalls = 0;
  User? _currentUser;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    loginCalls++;
    _currentUser = _user(mustChangePassword: true);
    return _currentUser!;
  }

  @override
  Future<void> changePassword({
    required User user,
    required String newPassword,
    required String confirmPassword,
  }) async {
    changePasswordCalls++;
    _currentUser = _user(mustChangePassword: false);
  }

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  @override
  Future<void> logout() async {
    logoutCalls++;
    _currentUser = null;
  }
}

User _user({required bool mustChangePassword}) {
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
