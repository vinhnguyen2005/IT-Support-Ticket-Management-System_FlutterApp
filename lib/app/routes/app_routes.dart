import 'package:flutter/material.dart';

import '../../features/auth/presentation/viewmodels/login_view_model.dart';
import '../../features/auth/presentation/views/change_password_page.dart';
import '../../features/auth/presentation/views/home_page.dart';
import '../../features/auth/presentation/views/login_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String home = '/home';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required LoginViewModel loginViewModel,
  }) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(viewModel: loginViewModel),
        );
      case changePassword:
        return MaterialPageRoute(
          builder: (_) => ChangePasswordPage(viewModel: loginViewModel),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => HomePage(viewModel: loginViewModel),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => LoginPage(viewModel: loginViewModel),
        );
    }
  }
}
