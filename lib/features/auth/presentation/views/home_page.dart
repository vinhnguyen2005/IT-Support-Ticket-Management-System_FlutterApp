import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
import '../../../assignment/presentation/viewmodels/technician_queue_view_model.dart';
import '../../../assignment/presentation/viewmodels/ticket_assignment_view_model.dart';
import '../../../assignment/presentation/views/admin_ticket_assignment_page.dart';
import '../../../assignment/presentation/views/staff_submitted_tickets_page.dart';
import '../../../assignment/presentation/views/technician_queue_page.dart';
import '../../../tickets/presentation/views/ticket_list_page.dart';
import 'login_page.dart';
import '../viewmodels/login_view_model.dart';
import '../../../user_management/presentation/views/user_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  Future<void> _logout(BuildContext context) async {
    await viewModel.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(viewModel: viewModel)),
      (route) => false,
    );
  }

  Future<void> _openAssignedTickets(BuildContext context) async {
    final user = viewModel.currentUser;
    if (user == null) {
      return;
    }

    if (!_hasRole(user.role, UserRole.staff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only staff can view assigned tickets.')),
      );
      return;
    }

    final service = await ServiceLocator.assignmentService;
    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TechnicianQueuePage(
          viewModel: TechnicianQueueViewModel(
            assignmentService: service,
            staffId: user.id,
            userRole: user.role,
          ),
        ),
      ),
    );
  }

  Future<void> _openStaffSubmittedTickets(BuildContext context) async {
    final user = viewModel.currentUser;
    if (user == null) {
      return;
    }

    if (!_hasRole(user.role, UserRole.staff)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only staff can assign tickets.')),
      );
      return;
    }

    final assignmentService = await ServiceLocator.assignmentService;
    final ticketService = await ServiceLocator.ticketService;
    final userManagementService = await ServiceLocator.userManagementService;
    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffSubmittedTicketsPage(
          viewModel: TicketAssignmentViewModel(
            assignmentService: assignmentService,
            ticketService: ticketService,
            userManagementService: userManagementService,
            currentUserId: user.id,
            currentUserRole: user.role,
            mode: TicketAssignmentMode.staffSubmitted,
          ),
        ),
      ),
    );
  }

  Future<void> _openAdminTicketAssignment(BuildContext context) async {
    final user = viewModel.currentUser;
    if (user == null) {
      return;
    }

    if (!_hasRole(user.role, UserRole.admin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admin can view all tickets.')),
      );
      return;
    }

    final assignmentService = await ServiceLocator.assignmentService;
    final ticketService = await ServiceLocator.ticketService;
    final userManagementService = await ServiceLocator.userManagementService;
    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminTicketAssignmentPage(
          viewModel: TicketAssignmentViewModel(
            assignmentService: assignmentService,
            ticketService: ticketService,
            userManagementService: userManagementService,
            currentUserId: user.id,
            currentUserRole: user.role,
            mode: TicketAssignmentMode.adminAll,
          ),
        ),
      ),
    );
  }

  void _openMyTickets(BuildContext context) {
    final user = viewModel.currentUser;
    if (user == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketListPage(requesterId: user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      child: Text(
                        user == null || user.fullName.isEmpty
                            ? '?'
                            : user.fullName.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'No user',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.email ?? 'No email',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${user?.role ?? 'unknown'}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (_hasRole(user?.role, UserRole.admin)) ...[
                      FilledButton.icon(
                        onPressed: () => _openAdminTicketAssignment(context),
                        icon: const Icon(Icons.rule_folder_outlined),
                        label: const Text('All tickets'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_canManageUsers(user?.role)) ...[
                      FilledButton.icon(
                        onPressed: () {
                          final currentUserRole = user?.role;
                          if (currentUserRole == null) {
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserListPage(
                                currentUserRole: currentUserRole,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.manage_accounts_outlined),
                        label: const Text('Manage users'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_hasRole(user?.role, UserRole.staff)) ...[
                      FilledButton.icon(
                        onPressed: () => _openStaffSubmittedTickets(context),
                        icon: const Icon(Icons.assignment_returned_outlined),
                        label: const Text('Submitted tickets'),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _openAssignedTickets(context),
                        icon: const Icon(Icons.assignment_ind),
                        label: const Text('Assigned tickets'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_hasRole(user?.role, UserRole.user)) ...[
                      FilledButton.icon(
                        onPressed: () => _openMyTickets(context),
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('My tickets'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasRole(String? role, UserRole expectedRole) {
    if (role == null) {
      return false;
    }

    return UserRole.fromValue(role.trim()) == expectedRole;
  }

  bool _canManageUsers(String? role) {
    if (role == null) {
      return false;
    }

    final parsedRole = UserRole.fromValue(role.trim());
    return parsedRole == UserRole.admin || parsedRole == UserRole.superAdmin;
  }
}
