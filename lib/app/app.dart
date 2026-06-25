import 'package:flutter/material.dart';

import '../core/di/service_locator.dart';
import '../features/auth/presentation/viewmodels/login_view_model.dart';
import '../features/auth/presentation/views/login_page.dart';

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
    return FutureBuilder<LoginViewModel>(
      future: _loginViewModelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final loginViewModel = snapshot.data!;
        return MaterialApp(
          title: 'IT Support Ticket Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          home: LoginPage(viewModel: loginViewModel),
        );
      },
    );
  }
}
