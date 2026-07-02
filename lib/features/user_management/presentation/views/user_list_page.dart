import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/managed_user.dart';
import '../viewmodels/user_list_view_model.dart';
import 'create_user_page.dart';
import 'update_user_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late final Future<UserListViewModel> _viewModelFuture;

  @override
  void initState() {
    super.initState();
    _viewModelFuture = ServiceLocator.userListViewModel;
  }

  Future<void> _openCreateUser(UserListViewModel viewModel) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateUserPage(),
      ),
    );

    if (created == true) {
      await viewModel.loadUsers();
    }
  }

  Future<void> _openUpdateUser(
    UserListViewModel viewModel,
    ManagedUser user,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateUserPage(user: user),
      ),
    );

    if (updated == true) {
      await viewModel.loadUsers();
    }
  }

  Future<void> _resetPassword(
    UserListViewModel viewModel,
    ManagedUser user,
  ) async {
    final controller = TextEditingController(text: 'Temp@1234');
    var obscurePassword = true;
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Reset password for ${user.username}'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Temporary password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                obscureText: obscurePassword,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();

    if (password == null) {
      return;
    }

    await viewModel.resetTemporaryPassword(
      id: user.id,
      temporaryPassword: password,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Temporary password reset for ${user.username}.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserListViewModel>(
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
              appBar: AppBar(
                title: const Text('User management'),
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: viewModel.loadUsers,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _openCreateUser(viewModel),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Create user'),
              ),
              body: _UserListBody(
                viewModel: viewModel,
                onEdit: (user) => _openUpdateUser(viewModel, user),
                onToggleActive: (user) {
                  viewModel.setUserActive(
                    id: user.id,
                    isActive: !user.isActive,
                  );
                },
                onResetPassword: (user) => _resetPassword(viewModel, user),
              ),
            );
          },
        );
      },
    );
  }
}

class _UserListBody extends StatefulWidget {
  const _UserListBody({
    required this.viewModel,
    required this.onEdit,
    required this.onToggleActive,
    required this.onResetPassword,
  });

  final UserListViewModel viewModel;
  final ValueChanged<ManagedUser> onEdit;
  final ValueChanged<ManagedUser> onToggleActive;
  final ValueChanged<ManagedUser> onResetPassword;

  @override
  State<_UserListBody> createState() => _UserListBodyState();
}

class _UserListBodyState extends State<_UserListBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    if (viewModel.isLoading && viewModel.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.users.isEmpty) {
      return Center(child: Text(viewModel.errorMessage!));
    }

    if (viewModel.users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemBuilder: (context, index) {
        final user = viewModel.users[index];
        return _UserTile(
          user: user,
          onEdit: () => widget.onEdit(user),
          onToggleActive: () => widget.onToggleActive(user),
          onResetPassword: () => widget.onResetPassword(user),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: viewModel.users.length,
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.onEdit,
    required this.onToggleActive,
    required this.onResetPassword,
  });

  final ManagedUser user;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.fullName.substring(0, 1).toUpperCase()),
        ),
        title: Text(user.fullName),
        subtitle: Text(
          '${user.username} • ${user.email}\n'
          'Role: ${user.role}'
          '${user.departmentId == null ? '' : ' • Department #${user.departmentId}'}'
          '${user.mustChangePassword ? ' • Must change password' : ''}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_UserAction>(
          onSelected: (action) {
            switch (action) {
              case _UserAction.edit:
                onEdit();
                break;
              case _UserAction.toggleActive:
                onToggleActive();
                break;
              case _UserAction.resetPassword:
                onResetPassword();
                break;
            }
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem(
                value: _UserAction.edit,
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: _UserAction.toggleActive,
                child: Text(user.isActive ? 'Disable' : 'Reactivate'),
              ),
              const PopupMenuItem(
                value: _UserAction.resetPassword,
                child: Text('Reset password'),
              ),
            ];
          },
        ),
      ),
    );
  }
}

enum _UserAction {
  edit,
  toggleActive,
  resetPassword,
}
