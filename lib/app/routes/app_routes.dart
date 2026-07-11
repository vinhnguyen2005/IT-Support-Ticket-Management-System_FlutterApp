import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../features/auth/presentation/viewmodels/login_view_model.dart';
import '../../features/auth/presentation/views/change_password_page.dart';
import '../../features/auth/presentation/views/home_page.dart';
import '../../features/auth/presentation/views/login_page.dart';
import '../../features/feedback/presentation/viewmodels/feedback_view_model.dart';
import '../../features/feedback/presentation/views/feedback_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String home = '/home';
  static const String feedback = '/feedback';

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
      case feedback:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => FutureBuilder<FeedbackViewModel>(
            future: ServiceLocator.feedbackViewModelFactory(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return FeedbackPage(
                ticketId: args?['ticketId'] ?? 0,
                userId: args?['userId'] ?? 0,
                viewModel: snapshot.data!,
              );
            },
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => LoginPage(viewModel: loginViewModel),
        );
    }
  }
}
