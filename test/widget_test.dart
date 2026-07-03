import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/auth/application/services/i_auth_service.dart';
import 'package:it_ticket_support_management/features/auth/domain/entities/user.dart';
import 'package:it_ticket_support_management/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:it_ticket_support_management/features/auth/presentation/views/login_page.dart';

void main() {
  testWidgets('Login page renders sign in form', (WidgetTester tester) async {
    final viewModel = LoginViewModel(_FakeAuthService());

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(viewModel: viewModel),
      ),
    );

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Username or email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}

class _FakeAuthService implements IAuthService {
  @override
  Future<void> changePassword({
    required User user,
    required String newPassword,
    required String confirmPassword,
  }) async {}

  @override
  Future<User?> getCurrentUser() async {
    return null;
  }

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    return User(
      id: 1,
      fullName: 'Test User',
      username: username,
      email: 'test@example.com',
      role: 'admin',
      isActive: true,
      mustChangePassword: false,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> logout() async {}
}
