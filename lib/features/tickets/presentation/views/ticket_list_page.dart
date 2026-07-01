import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../application/services/i_ticket_service.dart';
import '../../application/services/ticket_service_impl.dart';
import '../../data/mappers/ticket_mapper.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket.dart';
import '../viewmodels/ticket_list_view_model.dart';
import 'create_ticket_page.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key, this.requesterId, this.assigneeId});

  final int? requesterId;
  final int? assigneeId;

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  late final Future<TicketListViewModel> _viewModelFuture;

  @override
  void initState() {
    super.initState();
    _viewModelFuture = _createViewModel();
  }

  Future<TicketListViewModel> _createViewModel() async {
    return TicketListViewModel(await _createTicketService());
  }

  Future<void> _loadTickets(TicketListViewModel viewModel) {
    final requesterId = widget.requesterId;
    final assigneeId = widget.assigneeId;

    if (requesterId != null) {
      return viewModel.loadTicketsByRequester(requesterId);
    }

    if (assigneeId != null) {
      return viewModel.loadTicketsByAssignee(assigneeId);
    }

    return viewModel.loadTickets();
  }

  Future<void> _openCreateTicket(TicketListViewModel viewModel) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTicketPage(requesterId: widget.requesterId),
      ),
    );

    if (created == true) {
      await _loadTickets(viewModel);
    }
  }

  Future<void> _openTicket(TicketListViewModel viewModel, Ticket ticket) async {
    final ticketId = ticket.id;
    if (ticketId == null) {
      return;
    }

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TicketDetailPage(ticketId: ticketId)),
    );

    if (updated == true) {
      await _loadTickets(viewModel);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TicketListViewModel>(
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
                title: const Text('Tickets'),
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: viewModel.isLoading
                        ? null
                        : () => _loadTickets(viewModel),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: viewModel.isLoading
                    ? null
                    : () => _openCreateTicket(viewModel),
                icon: const Icon(Icons.add),
                label: const Text('Create ticket'),
              ),
              body: _TicketListBody(
                viewModel: viewModel,
                onLoad: () => _loadTickets(viewModel),
                onOpenTicket: (ticket) => _openTicket(viewModel, ticket),
              ),
            );
          },
        );
      },
    );
  }
}

class _TicketListBody extends StatefulWidget {
  const _TicketListBody({
    required this.viewModel,
    required this.onLoad,
    required this.onOpenTicket,
  });

  final TicketListViewModel viewModel;
  final Future<void> Function() onLoad;
  final ValueChanged<Ticket> onOpenTicket;

  @override
  State<_TicketListBody> createState() => _TicketListBodyState();
}

class _TicketListBodyState extends State<_TicketListBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    if (viewModel.isLoading && viewModel.tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && viewModel.tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onLoad,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      );
    }

    if (viewModel.tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onLoad,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [Center(child: Text('No tickets found.'))],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onLoad,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: viewModel.tickets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ticket = viewModel.tickets[index];
          return _TicketTile(
            ticket: ticket,
            onTap: () => widget.onOpenTicket(ticket),
          );
        },
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});

  final Ticket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(ticket.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                ],
              ),
              const SizedBox(height: 4),
              Text('Created ${_formatDate(ticket.createdAt)}'),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
      ),
    );
  }
}

Future<ITicketService> _createTicketService() async {
  return TicketServiceImpl(
    TicketRepositoryImpl(
      localDataSource: await ServiceLocator.ticketLocalDataSource,
      mapper: const TicketMapper(),
    ),
  );
}

String _formatDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
