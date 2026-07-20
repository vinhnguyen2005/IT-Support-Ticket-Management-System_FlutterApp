import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../viewmodels/login_view_model.dart';
import 'change_password_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController(
    text: 'admin',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'Vinh2005',
  );

  bool _obscurePassword = true;
  String? _usernameError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _usernameError = username.isEmpty
          ? 'Username or email is required.'
          : null;
      _passwordError = password.isEmpty ? 'Password is required.' : null;
    });
    return _usernameError == null && _passwordError == null;
  }

  Future<void> _submitLogin() async {
    if (!_validate()) return;

    final success = await widget.viewModel.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted || !success) return;

    final user = widget.viewModel.currentUser;
    if (user == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user.mustChangePassword
            ? ChangePasswordPage(viewModel: widget.viewModel)
            : HomePage(viewModel: widget.viewModel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                final form = _LoginForm(
                  viewModel: widget.viewModel,
                  usernameController: _usernameController,
                  passwordController: _passwordController,
                  usernameError: _usernameError,
                  passwordError: _passwordError,
                  obscurePassword: _obscurePassword,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onUsernameChanged: (_) {
                    if (_usernameError != null) {
                      setState(() => _usernameError = null);
                    }
                  },
                  onPasswordChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  onSubmit: _submitLogin,
                );

                if (!isDesktop) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          children: [
                            const _CompactBrand(),
                            const SizedBox(height: 32),
                            form,
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    const Expanded(flex: 5, child: _BrandPanel()),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(48),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: form,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.viewModel,
    required this.usernameController,
    required this.passwordController,
    required this.usernameError,
    required this.passwordError,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onUsernameChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
  });

  final LoginViewModel viewModel;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final String? usernameError;
  final String? passwordError;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final ValueChanged<String> onUsernameChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Access your support operations workspace.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: usernameController,
              enabled: !viewModel.isLoading,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Username or email',
                hintText: 'Enter your account',
                errorText: usernameError,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              onChanged: onUsernameChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              enabled: !viewModel.isLoading,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                errorText: passwordError,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              onChanged: onPasswordChanged,
              onSubmitted: (_) {
                if (!viewModel.isLoading) onSubmit();
              },
            ),
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorMessage(message: viewModel.errorMessage!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: viewModel.isLoading ? null : onSubmit,
              child: viewModel.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Demo admin: admin or admin@example.com / Vinh2005',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _BrandMark(size: 48),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              AppStrings.appDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primary.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BrandMark(size: 64, inverse: true),
          const SizedBox(height: 32),
          Text(
            'Support operations,\norganized in one place.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Track requests, coordinate assignments and keep every resolution visible to the team.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.82),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          const _BrandFeature(
            icon: Icons.bolt_outlined,
            text: 'Faster ticket handling',
          ),
          const SizedBox(height: 16),
          const _BrandFeature(
            icon: Icons.groups_outlined,
            text: 'Clear team ownership',
          ),
          const SizedBox(height: 16),
          const _BrandFeature(
            icon: Icons.insights_outlined,
            text: 'Operational visibility',
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, this.inverse = false});

  final double size;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverse ? colors.onPrimary : colors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.support_agent_rounded,
        size: size * 0.56,
        color: inverse ? colors.primary : colors.onPrimary,
      ),
    );
  }
}

class _BrandFeature extends StatelessWidget {
  const _BrandFeature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
