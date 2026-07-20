import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/managed_user.dart';
import '../viewmodels/update_user_view_model.dart';

class UpdateUserPage extends StatefulWidget {
  const UpdateUserPage({
    super.key,
    required this.user,
    required this.currentUserRole,
  });

  final ManagedUser user;
  final String currentUserRole;

  @override
  State<UpdateUserPage> createState() => _UpdateUserPageState();
}

class _UpdateUserPageState extends State<UpdateUserPage> {
  late final Future<UpdateUserViewModel> _viewModelFuture;

  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late String _role;
  late int? _departmentId;
  late bool _isActive;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModelFuture = ServiceLocator.updateUserViewModel;
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _role = widget.user.role;
    _departmentId = widget.user.departmentId;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit(UpdateUserViewModel viewModel) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await viewModel.updateUser(
      id: widget.user.id,
      fullName: _fullNameController.text,
      email: _emailController.text,
      role: _role,
      departmentId: _departmentId,
      phoneNumber: _phoneController.text,
      isActive: _isActive,
    );

    if (!mounted || !success) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UpdateUserViewModel>(
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
              appBar: AppBar(title: const Text('Edit user')),
              body: SafeArea(
                child: AppContent(
                  maxWidth: 800,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        Text(
                          'User information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _fullNameController,
                          enabled: !viewModel.isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Full name is required.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          enabled: !viewModel.isLoading,
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
                          controller: _phoneController,
                          enabled: !viewModel.isLoading,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                          ),
                          items: _availableRoles.map((role) {
                            return DropdownMenuItem(
                              value: role.value,
                              child: Text(role.value),
                            );
                          }).toList(),
                          onChanged: viewModel.isLoading
                              ? null
                              : (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    _role = value;
                                    if (_role != UserRole.staff.value) {
                                      _departmentId = null;
                                    }
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _departmentId ?? 0,
                          decoration: const InputDecoration(
                            labelText: 'Department',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text('None'),
                            ),
                            ...viewModel.departments.map(
                              (department) => DropdownMenuItem(
                                value: department.id,
                                child: Text(department.name),
                              ),
                            ),
                          ],
                          onChanged: viewModel.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _departmentId = value == 0 ? null : value;
                                  });
                                },
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: _isActive,
                          title: const Text('Active account'),
                          onChanged: viewModel.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _isActive = value;
                                  });
                                },
                        ),
                        if (viewModel.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            viewModel.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: viewModel.isLoading
                              ? null
                              : () => _submit(viewModel),
                          icon: const Icon(Icons.save),
                          label: const Text('Save changes'),
                        ),
                      ],
                    ),
                  ),
                ),
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
