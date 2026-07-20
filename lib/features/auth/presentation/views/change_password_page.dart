import 'package:flutter/material.dart';

import 'home_page.dart';
import '../viewmodels/login_view_model.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmation = _confirmPasswordController.text;
    setState(() {
      _newPasswordError = newPassword.isEmpty
          ? 'New password is required.'
          : newPassword.length < 8
          ? 'Use at least 8 characters.'
          : null;
      _confirmPasswordError = confirmation.isEmpty
          ? 'Please confirm your password.'
          : null;
    });
    if (_newPasswordError != null || _confirmPasswordError != null) return;

    final success = await widget.viewModel.changePassword(
      newPassword: newPassword,
      confirmPassword: confirmation,
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(viewModel: widget.viewModel)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final viewModel = widget.viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Change password'),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Set a new password',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This account is using a temporary password. Create a secure password before continuing.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 20),
                          const _PasswordGuidance(),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _newPasswordController,
                            enabled: !viewModel.isLoading,
                            obscureText: _obscureNewPassword,
                            decoration: InputDecoration(
                              labelText: 'New password',
                              prefixIcon: const Icon(Icons.password_outlined),
                              errorText: _newPasswordError,
                              suffixIcon: IconButton(
                                tooltip: _obscureNewPassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_newPasswordError != null) {
                                setState(() => _newPasswordError = null);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            enabled: !viewModel.isLoading,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: const Icon(
                                Icons.verified_user_outlined,
                              ),
                              errorText: _confirmPasswordError,
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            onChanged: (_) {
                              if (_confirmPasswordError != null) {
                                setState(() => _confirmPasswordError = null);
                              }
                            },
                          ),
                          if (viewModel.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _PasswordError(message: viewModel.errorMessage!),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : _submitChangePassword,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: viewModel.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Save password'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordGuidance extends StatelessWidget {
  const _PasswordGuidance();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use at least 8 characters with uppercase, lowercase, number and symbol.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordError extends StatelessWidget {
  const _PasswordError({required this.message});

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
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}
