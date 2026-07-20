import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../features/auth/presentation/viewmodels/login_view_model.dart';
import '../../features/auth/presentation/views/change_password_page.dart';
import '../../features/auth/presentation/views/home_page.dart';
import '../../features/auth/presentation/views/login_page.dart';
import '../../features/errors/presentation/views/status_error_page.dart';
import '../../features/feedback/presentation/viewmodels/feedback_view_model.dart';
import '../../features/feedback/presentation/views/feedback_page.dart';

class StatusErrorRouteArguments {
  const StatusErrorRouteArguments({required this.statusCode, this.message});

  final int statusCode;
  final String? message;
}

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String changePassword = '/change-password';
  static const String home = '/home';
  static const String feedback = '/feedback';
  static const String clientError = '/error/4xx';
  static const String serverError = '/error/5xx';

  static bool redirectForStatus(
    BuildContext context, {
    required int statusCode,
    String? message,
    bool replace = false,
  }) {
    final route = switch (statusCode) {
      >= 400 && < 500 => clientError,
      >= 500 && < 600 => serverError,
      _ => null,
    };
    if (route == null) {
      return false;
    }

    final arguments = StatusErrorRouteArguments(
      statusCode: statusCode,
      message: message,
    );
    if (replace) {
      Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
    } else {
      Navigator.of(context).pushNamed(route, arguments: arguments);
    }
    return true;
  }

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
      case clientError:
        final args = settings.arguments as StatusErrorRouteArguments?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ClientErrorPage(
            statusCode: args?.statusCode ?? 400,
            message: args?.message,
            fallbackRoute: _fallbackRoute(loginViewModel),
          ),
        );
      case serverError:
        final args = settings.arguments as StatusErrorRouteArguments?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ServerErrorPage(
            statusCode: args?.statusCode ?? 500,
            message: args?.message,
            fallbackRoute: _fallbackRoute(loginViewModel),
          ),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ClientErrorPage(
            statusCode: 404,
            fallbackRoute: _fallbackRoute(loginViewModel),
          ),
        );
    }
  }

  static String _fallbackRoute(LoginViewModel loginViewModel) {
    return loginViewModel.currentUser == null ? login : home;
  }
}
