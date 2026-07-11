import 'package:flutter/material.dart';

import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/views/ticket_detail_page.dart';
import '../../../user_management/domain/entities/managed_user.dart';
import '../viewmodels/ticket_assignment_view_model.dart';

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
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
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
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.tickets.isEmpty) {
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

    if (viewModel.tickets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [Center(child: Text(widget.emptyMessage))],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.tickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ticket = viewModel.tickets[index];
        return _TicketAssignmentTile(
          ticket: ticket,
          canAssign: viewModel.canAssign(ticket) && !viewModel.isLoading,
          onAssign: () => _assign(ticket),
          onOpen: () => _openTicket(ticket),
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
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(ticket.status),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(ticket.priority),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(ticket.issueType),
                  ),
                  if (ticket.assignedId != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text('Staff #${ticket.assignedId}'),
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
