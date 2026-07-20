import 'package:flutter/material.dart';

import '../../../../core/widgets/app_badges.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/views/ticket_detail_page.dart';
import '../../../tickets/presentation/widgets/sla_status_badge.dart';
import '../../../user_management/domain/entities/managed_user.dart';
import '../../../tickets/presentation/models/ticket_list_filter.dart';
import '../viewmodels/ticket_assignment_view_model.dart';
import 'ticket_queue_filter_bar.dart';

class TicketAssignmentListScaffold extends StatefulWidget {
  const TicketAssignmentListScaffold({
    super.key,
    required this.title,
    required this.emptyMessage,
    required this.viewModel,
  });

  final String title;
  final String emptyMessage;
  final TicketAssignmentViewModel viewModel;

  @override
  State<TicketAssignmentListScaffold> createState() =>
      _TicketAssignmentListScaffoldState();
}

class _TicketAssignmentListScaffoldState
    extends State<TicketAssignmentListScaffold> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = '';
  String _priorityFilter = '';
  String _slaFilter = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
    final message = widget.viewModel.successMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _assign(Ticket ticket) async {
    final ticketId = ticket.id;
    if (ticketId == null) {
      return;
    }

    final request = await showDialog<_AssignTicketRequest>(
      context: context,
      builder: (_) => _AssignTicketDialog(
        currentUserId: widget.viewModel.currentUserId,
        staffUsers: widget.viewModel.staffUsers,
      ),
    );

    if (request == null) {
      return;
    }

    await widget.viewModel.assignTicket(
      ticketId: ticketId,
      staffId: request.staffId,
      note: request.note,
    );
  }

  Future<void> _openTicket(Ticket ticket) async {
    final ticketId = ticket.id;
    if (ticketId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailPage(ticketId: ticketId)),
    );
    if (mounted) {
      await widget.viewModel.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: viewModel.isLoading ? null : viewModel.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.load,
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TicketAssignmentViewModel viewModel) {
    if (viewModel.isLoading && viewModel.tickets.isEmpty) {
      return const AppListSkeleton();
    }

    if (viewModel.errorMessage != null && viewModel.tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 520,
            child: AppErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load,
            ),
          ),
        ],
      );
    }

    if (viewModel.tickets.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 520,
            child: AppEmptyState(
              title: widget.emptyMessage,
              message: 'Tickets will appear here when they are available.',
              icon: Icons.assignment_outlined,
            ),
          ),
        ],
      );
    }

    final filteredTickets = TicketListFilter(
      query: _searchController.text,
      status: _statusFilter,
      priority: _priorityFilter,
    ).apply(viewModel.tickets);
    final now = DateTime.now();
    final tickets = _slaFilter.isEmpty
        ? filteredTickets
        : filteredTickets
              .where(
                (ticket) =>
                    ticket.resolutionSlaStatusAt(now).name == _slaFilter,
              )
              .toList(growable: false);

    final children = <Widget>[
      TicketQueueFilterBar(
        searchController: _searchController,
        status: _statusFilter,
        priority: _priorityFilter,
        slaStatus: _slaFilter,
        resultCount: tickets.length,
        totalCount: viewModel.tickets.length,
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

    if (tickets.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text('No tickets match your search or filters.'),
          ),
        ),
      );
    } else {
      children.add(
        _TicketAssignmentGrid(
          tickets: tickets,
          isLoading: viewModel.isLoading,
          canAssign: viewModel.canAssign,
          onAssign: _assign,
          onOpen: _openTicket,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > 1232
            ? (constraints.maxWidth - 1200) / 2
            : 16.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32),
          children: children,
        );
      },
    );
  }
}

class _TicketAssignmentTile extends StatelessWidget {
  const _TicketAssignmentTile({
    required this.ticket,
    required this.canAssign,
    required this.onAssign,
    required this.onOpen,
  });

  final Ticket ticket;
  final bool canAssign;
  final VoidCallback onAssign;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TicketStatusBadge(status: ticket.status),
                  PriorityBadge(priority: ticket.priority),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(ticket.issueType),
                  ),
                  if (ticket.assignedId != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Staff #${ticket.assignedId}'),
                    ),
                  SlaStatusBadge(
                    status: ticket.resolutionSlaStatus,
                    dueAt: ticket.resolutionDueAt,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: canAssign ? onAssign : null,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('Assign'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketAssignmentGrid extends StatelessWidget {
  const _TicketAssignmentGrid({
    required this.tickets,
    required this.isLoading,
    required this.canAssign,
    required this.onAssign,
    required this.onOpen,
  });

  final List<Ticket> tickets;
  final bool isLoading;
  final bool Function(Ticket) canAssign;
  final ValueChanged<Ticket> onAssign;
  final ValueChanged<Ticket> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 920 ? 2 : 1;
        if (columns == 1) {
          return Column(
            children: [
              for (var index = 0; index < tickets.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                _tile(tickets[index]),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 260,
          ),
          itemCount: tickets.length,
          itemBuilder: (context, index) => _tile(tickets[index]),
        );
      },
    );
  }

  Widget _tile(Ticket ticket) {
    return _TicketAssignmentTile(
      ticket: ticket,
      canAssign: canAssign(ticket) && !isLoading,
      onAssign: () => onAssign(ticket),
      onOpen: () => onOpen(ticket),
    );
  }
}

class _AssignTicketDialog extends StatefulWidget {
  const _AssignTicketDialog({
    required this.currentUserId,
    required this.staffUsers,
  });

  final int currentUserId;
  final List<ManagedUser> staffUsers;

  @override
  State<_AssignTicketDialog> createState() => _AssignTicketDialogState();
}

class _AssignTicketDialogState extends State<_AssignTicketDialog> {
  final _noteController = TextEditingController();
  int? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    if (widget.staffUsers.isNotEmpty) {
      final currentStaff = widget.staffUsers.where(
        (staff) => staff.id == widget.currentUserId,
      );
      _selectedStaffId = currentStaff.isNotEmpty
          ? currentStaff.first.id
          : widget.staffUsers.first.id;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign ticket'),
      content: SizedBox(
        width: 420,
        child: widget.staffUsers.isEmpty
            ? const Text('No active staff accounts are available.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedStaffId,
                    decoration: const InputDecoration(
                      labelText: 'Technician',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.staffUsers
                        .map(
                          (staff) => DropdownMenuItem<int>(
                            value: staff.id,
                            child: Text(
                              staff.id == widget.currentUserId
                                  ? '${staff.fullName} (you)'
                                  : staff.fullName,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStaffId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedStaffId == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _AssignTicketRequest(
                      staffId: _selectedStaffId!,
                      note: _noteController.text,
                    ),
                  );
                },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

class _AssignTicketRequest {
  const _AssignTicketRequest({required this.staffId, required this.note});

  final int staffId;
  final String note;
}
