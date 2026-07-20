import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/viewmodels/login_view_model.dart';
import '../features/auth/presentation/views/change_password_page.dart';
import '../features/auth/presentation/views/home_page.dart';
import '../features/auth/presentation/views/login_page.dart';
import 'routes/app_routes.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final Future<LoginViewModel> _loginViewModelFuture;

  @override
  void initState() {
    super.initState();
    _loginViewModelFuture = ServiceLocator.loginViewModel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );

    return FutureBuilder<LoginViewModel>(
      future: _loginViewModelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final loginViewModel = snapshot.data!;
        final currentUser = loginViewModel.currentUser;
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: theme,
          onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
            settings,
            loginViewModel: loginViewModel,
          ),
          home: currentUser == null
              ? LoginPage(viewModel: loginViewModel)
              : currentUser.mustChangePassword
              ? ChangePasswordPage(viewModel: loginViewModel)
              : HomePage(viewModel: loginViewModel),
        );
      },
    );
  }
}
