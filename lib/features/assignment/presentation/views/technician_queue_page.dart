import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../tickets/presentation/views/ticket_detail_page.dart';
import '../../domain/entities/assignment.dart';
import '../viewmodels/technician_queue_view_model.dart';
import '../viewmodels/update_progress_view_model.dart';
import 'update_progress_page.dart';

class TechnicianQueuePage extends StatefulWidget {
  const TechnicianQueuePage({super.key, required this.viewModel});

  final TechnicianQueueViewModel viewModel;

  @override
  State<TechnicianQueuePage> createState() => _TechnicianQueuePageState();
}

class _TechnicianQueuePageState extends State<TechnicianQueuePage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    widget.viewModel.loadAssignments();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
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
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.assignments.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            viewModel.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      );
    }

    if (viewModel.assignments.isEmpty) {
      return ListView(
        padding: EdgeInsets.all(24),
        children: [Center(child: Text('No tickets are assigned to you.'))],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.assignments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assignment = viewModel.assignments[index];
        return _AssignmentTile(
          assignment: assignment,
          onTap: () => _openAssignment(assignment),
          onViewDetails: () => _openTicketDetails(assignment),
        );
      },
    );
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
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(assignment.priority),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(assignment.status),
                  ),
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
