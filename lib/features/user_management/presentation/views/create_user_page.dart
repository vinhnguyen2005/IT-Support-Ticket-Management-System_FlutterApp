import 'package:flutter/material.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/app_states.dart';
import '../viewmodels/create_user_view_model.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key, required this.currentUserRole});

  final String currentUserRole;

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  late final Future<CreateUserViewModel> _viewModelFuture;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(
    text: 'Temp@1234',
  );

  String _role = UserRole.user.value;
  int? _departmentId;
  bool _obscureTemporaryPassword = true;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModelFuture = ServiceLocator.createUserViewModel;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(CreateUserViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await viewModel.createUser(
      fullName: _fullNameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      temporaryPassword: _passwordController.text,
      role: _role,
      departmentId: _departmentId,
      phoneNumber: _phoneController.text,
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CreateUserViewModel>(
      future: _viewModelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: AppListSkeleton(itemCount: 4));
        }

        final viewModel = snapshot.data!;
        return AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(title: const Text('Create user')),
              body: _UserForm(
                formKey: _formKey,
                fullNameController: _fullNameController,
                usernameController: _usernameController,
                emailController: _emailController,
                phoneController: _phoneController,
                passwordController: _passwordController,
                departments: viewModel.departments,
                role: _role,
                availableRoles: _availableRoles,
                departmentId: _departmentId,
                errorMessage: viewModel.errorMessage,
                isLoading: viewModel.isLoading,
                isCreateMode: true,
                obscureTemporaryPassword: _obscureTemporaryPassword,
                onRoleChanged: (role) {
                  setState(() {
                    _role = role;
                    if (_role != UserRole.staff.value) {
                      _departmentId = null;
                    }
                  });
                },
                onDepartmentChanged: (departmentId) {
                  setState(() {
                    _departmentId = departmentId;
                  });
                },
                onToggleTemporaryPasswordVisibility: () {
                  setState(() {
                    _obscureTemporaryPassword = !_obscureTemporaryPassword;
                  });
                },
                onSubmit: () => _submit(viewModel),
              ),
            );
          },
        );
      },
    );
  }

  List<UserRole> get _availableRoles {
    return const [UserRole.staff, UserRole.user];
  }
}

class _UserForm extends StatelessWidget {
  const _UserForm({
    required this.formKey,
    required this.fullNameController,
    required this.usernameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.departments,
    required this.role,
    required this.availableRoles,
    required this.departmentId,
    required this.errorMessage,
    required this.isLoading,
    required this.isCreateMode,
    required this.obscureTemporaryPassword,
    required this.onRoleChanged,
    required this.onDepartmentChanged,
    required this.onToggleTemporaryPasswordVisibility,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final List<DepartmentReference> departments;
  final String role;
  final List<UserRole> availableRoles;
  final int? departmentId;
  final String? errorMessage;
  final bool isLoading;
  final bool isCreateMode;
  final bool obscureTemporaryPassword;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<int?> onDepartmentChanged;
  final VoidCallback onToggleTemporaryPasswordVisibility;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AppContent(
        maxWidth: 800,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Text(
                isCreateMode ? 'Account information' : 'User information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Required fields are validated before the account is saved.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: fullNameController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Full name is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: usernameController,
                enabled: isCreateMode && !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Username is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email is required.';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                enabled: !isLoading,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: availableRoles.map((role) {
                  return DropdownMenuItem(
                    value: role.value,
                    child: Text(role.value),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          onRoleChanged(value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: departmentId ?? 0,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('None')),
                  ...departments.map(
                    (department) => DropdownMenuItem(
                      value: department.id,
                      child: Text(department.name),
                    ),
                  ),
                ],
                onChanged: isLoading
                    ? null
                    : (value) {
                        onDepartmentChanged(value == 0 ? null : value);
                      },
              ),
              if (isCreateMode) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  enabled: !isLoading,
                  obscureText: obscureTemporaryPassword,
                  decoration: InputDecoration(
                    labelText: 'Temporary password',
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                      tooltip: obscureTemporaryPassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: onToggleTemporaryPasswordVisibility,
                      icon: Icon(
                        obscureTemporaryPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 8
                      ? 'Temporary password must contain at least 8 characters.'
                      : null,
                ),
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: isLoading ? null : onSubmit,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isCreateMode ? 'Create user' : 'Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
