import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../assignment/presentation/viewmodels/technician_queue_view_model.dart';
import '../../../assignment/presentation/viewmodels/ticket_assignment_view_model.dart';
import '../../../assignment/presentation/views/admin_ticket_assignment_page.dart';
import '../../../assignment/presentation/views/staff_submitted_tickets_page.dart';
import '../../../assignment/presentation/views/technician_queue_page.dart';
import '../../../categories/presentation/views/category_management_page.dart';
import '../../../departments/presentation/viewmodels/department_view_model.dart';
import '../../../departments/presentation/views/department_management_page.dart';
import '../../../reports/presentation/views/admin_dashboard_page.dart';
import '../../../tickets/presentation/views/ticket_list_page.dart';
import '../../../user_management/presentation/views/user_list_page.dart';
import '../../domain/entities/user.dart';
import '../viewmodels/login_view_model.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.viewModel});

  final LoginViewModel viewModel;

  Future<void> _logout(BuildContext context) async {
    await viewModel.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(viewModel: viewModel)),
      (route) => false,
    );
  }

  Future<void> _openAdminDashboard(BuildContext context) async {
    final dashboardVm = await ServiceLocator.adminDashboardViewModel;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: dashboardVm,
          child: const AdminDashboardPage(),
        ),
      ),
    );
  }

  Future<void> _openCategories(BuildContext context) async {
    final categoryVm = await ServiceLocator.categoryViewModel;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: categoryVm,
          child: const CategoryManagementPage(),
        ),
      ),
    );
  }

  Future<void> _openDepartments(BuildContext context) async {
    final departmentVm = await ServiceLocator.departmentViewModel;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<DepartmentViewModel>.value(
          value: departmentVm,
          child: const DepartmentManagementPage(),
        ),
      ),
    );
  }

  Future<void> _openAssignedTickets(BuildContext context) async {
    final user = viewModel.currentUser;
    if (user == null || !_hasRole(user.role, UserRole.staff)) return;
    final service = await ServiceLocator.assignmentService;
    if (!context.mounted) return;
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
    if (user == null || !_hasRole(user.role, UserRole.staff)) return;
    final assignmentService = await ServiceLocator.assignmentService;
    final ticketService = await ServiceLocator.ticketService;
    final userManagementService = await ServiceLocator.userManagementService;
    if (!context.mounted) return;
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
    if (user == null || !_hasRole(user.role, UserRole.admin)) return;
    final assignmentService = await ServiceLocator.assignmentService;
    final ticketService = await ServiceLocator.ticketService;
    final userManagementService = await ServiceLocator.userManagementService;
    if (!context.mounted) return;
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
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketListPage(requesterId: user.id)),
    );
  }

  void _openUsers(BuildContext context) {
    final role = viewModel.currentUser?.role;
    if (role == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserListPage(currentUserRole: role)),
    );
  }

  List<_HomeAction> _actions(BuildContext context) {
    final role = viewModel.currentUser?.role;
    if (_hasRole(role, UserRole.admin)) {
      return [
        _HomeAction(
          title: 'All tickets',
          subtitle: 'Review, assign and manage every request',
          icon: Icons.rule_folder_outlined,
          onTap: () => _openAdminTicketAssignment(context),
        ),
        _HomeAction(
          title: 'Reports & dashboard',
          subtitle: 'Monitor service volume and team performance',
          icon: Icons.analytics_outlined,
          onTap: () => _openAdminDashboard(context),
        ),
        _HomeAction(
          title: 'User management',
          subtitle: 'Create accounts and manage access',
          icon: Icons.manage_accounts_outlined,
          onTap: () => _openUsers(context),
        ),
        _HomeAction(
          title: 'Categories',
          subtitle: 'Maintain ticket classification options',
          icon: Icons.category_outlined,
          onTap: () => _openCategories(context),
        ),
        _HomeAction(
          title: 'Departments',
          subtitle: 'Manage organizational routing and staff groups',
          icon: Icons.corporate_fare_outlined,
          onTap: () => _openDepartments(context),
        ),
      ];
    }
    if (_hasRole(role, UserRole.staff)) {
      return [
        _HomeAction(
          title: 'Submitted tickets',
          subtitle: 'Triage and assign newly submitted requests',
          icon: Icons.assignment_returned_outlined,
          onTap: () => _openStaffSubmittedTickets(context),
        ),
        _HomeAction(
          title: 'Assigned tickets',
          subtitle: 'Work through your active support queue',
          icon: Icons.assignment_ind_outlined,
          onTap: () => _openAssignedTickets(context),
        ),
      ];
    }
    return [
      _HomeAction(
        title: 'My tickets',
        subtitle: 'Create requests and follow their progress',
        icon: Icons.confirmation_number_outlined,
        onTap: () => _openMyTickets(context),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = viewModel.currentUser;
    final actions = _actions(context);
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent_rounded),
            SizedBox(width: 10),
            Text(AppStrings.appName),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Sign out',
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: AppContent(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _WelcomePanel(user: user)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workspace',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose an area to continue',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    avatar: const Icon(Icons.verified_user_outlined, size: 18),
                    label: Text(_roleLabel(user?.role)),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1000
                    ? 3
                    : width >= 640
                    ? 2
                    : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 176,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _ActionCard(action: actions[index]),
                    childCount: actions.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _hasRole(String? role, UserRole expectedRole) {
    return role != null && UserRole.fromValue(role.trim()) == expectedRole;
  }

  String _roleLabel(String? role) {
    return switch (UserRole.fromValue(role ?? '')) {
      UserRole.admin => 'Administrator',
      UserRole.staff => 'Support staff',
      UserRole.user => 'Requester',
    };
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = user?.fullName ?? 'User';
    final email = user?.email ?? '';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.76)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colors.onPrimary.withValues(alpha: 0.16),
            foregroundColor: colors.onPrimary,
            child: Text(
              name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: colors.onPrimary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: colors.onPrimary),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.dashboard_customize_outlined,
            color: colors.onPrimary.withValues(alpha: 0.35),
            size: 72,
          ),
        ],
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: colors.onPrimaryContainer),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 20, color: colors.primary),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
