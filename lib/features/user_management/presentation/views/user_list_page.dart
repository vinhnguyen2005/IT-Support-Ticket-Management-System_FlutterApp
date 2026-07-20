import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/managed_user.dart';
import '../viewmodels/user_list_view_model.dart';
import 'create_user_page.dart';
import 'update_user_page.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key, required this.currentUserRole});

  final String currentUserRole;

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
        builder: (_) => CreateUserPage(currentUserRole: widget.currentUserRole),
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
        builder: (_) =>
            UpdateUserPage(user: user, currentUserRole: widget.currentUserRole),
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
    var copiedPassword = false;
    final password = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void copyPassword() {
              Clipboard.setData(ClipboardData(text: controller.text));
              setDialogState(() {
                copiedPassword = true;
              });
            }

            return AlertDialog(
              title: Text('Reset password for ${user.username}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Temporary password',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Copy password',
                            onPressed: copyPassword,
                            icon: const Icon(Icons.copy_outlined),
                          ),
                          IconButton(
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
                        ],
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 96,
                        minHeight: 48,
                      ),
                    ),
                    onChanged: (_) {
                      if (copiedPassword) {
                        setDialogState(() {
                          copiedPassword = false;
                        });
                      }
                    },
                  ),
                  if (copiedPassword) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Temporary password copied.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.pop(context, controller.text);
                  },
                  child: const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
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
      SnackBar(content: Text('Temporary password reset for ${user.username}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserListViewModel>(
      future: _viewModelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: AppListSkeleton());
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
                currentUserRole: widget.currentUserRole,
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
    required this.currentUserRole,
    required this.onEdit,
    required this.onToggleActive,
    required this.onResetPassword,
  });

  final UserListViewModel viewModel;
  final String currentUserRole;
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
      return const AppListSkeleton();
    }

    if (viewModel.errorMessage != null && viewModel.users.isEmpty) {
      return AppErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadUsers,
      );
    }

    if (viewModel.users.isEmpty) {
      return const AppEmptyState(
        title: 'No users found.',
        message: 'Create an account to add someone to the support workspace.',
        icon: Icons.group_off_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 680
            ? 2
            : 1;
        final horizontal = constraints.maxWidth > 1232
            ? (constraints.maxWidth - 1200) / 2
            : 16.0;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 230,
          ),
          itemCount: viewModel.users.length,
          itemBuilder: (context, index) {
            final user = viewModel.users[index];
            return _UserTile(
              user: user,
              currentUserRole: widget.currentUserRole,
              onEdit: () => widget.onEdit(user),
              onToggleActive: () => widget.onToggleActive(user),
              onResetPassword: () => widget.onResetPassword(user),
            );
          },
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.currentUserRole,
    required this.onEdit,
    required this.onToggleActive,
    required this.onResetPassword,
  });

  final ManagedUser user;
  final String currentUserRole;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    final canManageUser = _canManageUser();
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        minVerticalPadding: 16,
        leading: CircleAvatar(
          child: Text(
            user.fullName.isEmpty
                ? '?'
                : user.fullName.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(
          user.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '${user.username} • ${user.email}\n'
          'Role: ${user.role}'
          '${user.departmentId == null ? '' : ' • Department #${user.departmentId}'}'
          '${user.mustChangePassword ? ' • Must change password' : ''}',
        ),
        isThreeLine: true,
        trailing: canManageUser
            ? PopupMenuButton<_UserAction>(
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
              )
            : null,
      ),
    );
  }

  bool _canManageUser() {
    final actorRole = UserRole.fromValue(currentUserRole);
    final targetRole = UserRole.fromValue(user.role);

    return actorRole == UserRole.admin &&
        (targetRole == UserRole.admin ||
            targetRole == UserRole.staff ||
            targetRole == UserRole.user);
  }
}

enum _UserAction { edit, toggleActive, resetPassword }
