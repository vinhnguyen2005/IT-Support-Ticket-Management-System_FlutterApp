import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_badges.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../tickets/presentation/views/ticket_detail_page.dart';
import '../../../tickets/presentation/widgets/sla_status_badge.dart';
import '../../domain/entities/assignment.dart';
import '../models/assignment_list_filter.dart';
import '../viewmodels/technician_queue_view_model.dart';
import '../viewmodels/update_progress_view_model.dart';
import 'update_progress_page.dart';
import 'ticket_queue_filter_bar.dart';

class TechnicianQueuePage extends StatefulWidget {
  const TechnicianQueuePage({super.key, required this.viewModel});

  final TechnicianQueueViewModel viewModel;

  @override
  State<TechnicianQueuePage> createState() => _TechnicianQueuePageState();
}

class _TechnicianQueuePageState extends State<TechnicianQueuePage> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = '';
  String _priorityFilter = '';
  String _slaFilter = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    widget.viewModel.loadAssignments();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openAssignment(Assignment assignment) async {
    final service = await ServiceLocator.assignmentService;
    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateProgressPage(
          viewModel: UpdateProgressViewModel(
            assignmentService: service,
            staffId: widget.viewModel.staffId,
            ticketId: assignment.ticketId,
          ),
        ),
      ),
    );

    await widget.viewModel.loadAssignments();
  }

  Future<void> _openTicketDetails(Assignment assignment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TicketDetailPage(ticketId: assignment.ticketId),
      ),
    );
    await widget.viewModel.loadAssignments();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned tickets'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: viewModel.isLoading ? null : viewModel.loadAssignments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.loadAssignments,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TechnicianQueueViewModel viewModel) {
    if (viewModel.isLoading && viewModel.assignments.isEmpty) {
      return const AppListSkeleton();
    }

    if (viewModel.errorMessage != null && viewModel.assignments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 520,
            child: AppErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.loadAssignments,
            ),
          ),
        ],
      );
    }

    if (viewModel.assignments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 520,
            child: AppEmptyState(
              title: 'No tickets are assigned to you.',
              message: 'Tickets assigned to you will appear in this queue.',
              icon: Icons.assignment_turned_in_outlined,
            ),
          ),
        ],
      );
    }

    final filteredAssignments = AssignmentListFilter(
      query: _searchController.text,
      status: _statusFilter,
      priority: _priorityFilter,
    ).apply(viewModel.assignments);
    final now = DateTime.now();
    final assignments = _slaFilter.isEmpty
        ? filteredAssignments
        : filteredAssignments
              .where(
                (assignment) =>
                    assignment.resolutionSlaStatusAt(now).name == _slaFilter,
              )
              .toList(growable: false);

    final children = <Widget>[
      TicketQueueFilterBar(
        searchController: _searchController,
        status: _statusFilter,
        priority: _priorityFilter,
        slaStatus: _slaFilter,
        resultCount: assignments.length,
        totalCount: viewModel.assignments.length,
        onSearchChanged: (_) => setState(() {}),
        onStatusChanged: (value) => setState(() => _statusFilter = value ?? ''),
        onPriorityChanged: (value) =>
            setState(() => _priorityFilter = value ?? ''),
        onSlaStatusChanged: (value) => setState(() => _slaFilter = value ?? ''),
        onClearFilters:
            _statusFilter.isEmpty &&
                _priorityFilter.isEmpty &&
                _slaFilter.isEmpty
            ? null
            : () => setState(() {
                _statusFilter = '';
                _priorityFilter = '';
                _slaFilter = '';
              }),
      ),
      const SizedBox(height: 12),
    ];

    if (assignments.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('No tickets match your search or filters.'),
          ),
        ),
      );
    } else {
      for (var index = 0; index < assignments.length; index++) {
        if (index > 0) {
          children.add(const SizedBox(height: 12));
        }
        final assignment = assignments[index];
        children.add(
          _AssignmentTile(
            assignment: assignment,
            onTap: () => _openAssignment(assignment),
            onViewDetails: () => _openTicketDetails(assignment),
          ),
        );
      }
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({
    required this.assignment,
    required this.onTap,
    required this.onViewDetails,
  });

  final Assignment assignment;
  final VoidCallback onTap;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(assignment.ticketTitle),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(assignment.ticketDescription),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PriorityBadge(priority: assignment.priority),
                  SlaStatusBadge(
                    status: assignment.resolutionSlaStatusAt(DateTime.now()),
                    dueAt: assignment.resolutionDueAt,
                  ),
                  TicketStatusBadge(status: assignment.status),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(assignment.issueType),
                  ),
                ],
              ),
              if (assignment.lastProgressMessage != null) ...[
                const SizedBox(height: 8),
                Text('Latest: ${assignment.lastProgressMessage}'),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'View ticket details',
              onPressed: onViewDetails,
              icon: const Icon(Icons.visibility_outlined),
            ),
            Icon(Icons.chevron_right, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
