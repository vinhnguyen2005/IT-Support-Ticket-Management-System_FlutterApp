import 'package:flutter/material.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final viewModel = snapshot.data!;
        return AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(title: const Text('Create user')),
              body: _UserForm(
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
    final actorRole = UserRole.fromValue(widget.currentUserRole);
    if (actorRole == UserRole.admin) {
      return const [UserRole.admin, UserRole.staff, UserRole.user];
    }

    return const [UserRole.staff, UserRole.user];
  }
}

class _UserForm extends StatelessWidget {
  const _UserForm({
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: fullNameController,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: usernameController,
            enabled: isCreateMode && !isLoading,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            enabled: !isLoading,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: const InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(),
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
            value: departmentId ?? 0,
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
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
            TextField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: obscureTemporaryPassword,
              decoration: InputDecoration(
                labelText: 'Temporary password',
                border: const OutlineInputBorder(),
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
    );
  }
}
