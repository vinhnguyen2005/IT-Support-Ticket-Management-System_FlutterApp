import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
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
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final viewModel = snapshot.data!;
        return AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit user')),
              body: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _fullNameController,
                      enabled: !viewModel.isLoading,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      enabled: !viewModel.isLoading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      enabled: !viewModel.isLoading,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
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
                      value: _departmentId ?? 0,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('None')),
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
