import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/widgets/app_badges.dart';
import '../../../../core/widgets/app_states.dart';
import '../../application/services/i_ticket_service.dart';
import '../../application/services/ticket_service_impl.dart';
import '../../data/mappers/ticket_mapper.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket.dart';
import '../models/ticket_list_filter.dart';
import '../viewmodels/ticket_list_view_model.dart';
import '../widgets/sla_status_badge.dart';
import 'create_ticket_page.dart';
import 'ticket_detail_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({
    super.key,
    this.requesterId,
    this.assigneeId,
    this.viewModel,
  });

  final int? requesterId;
  final int? assigneeId;
  final TicketListViewModel? viewModel;

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
    return widget.viewModel ??
        TicketListViewModel(await _createTicketService());
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
      MaterialPageRoute(
        builder: (_) => TicketDetailPage(
          ticketId: ticketId,
          currentUserId: widget.requesterId ?? widget.assigneeId,
        ),
      ),
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
          return const Scaffold(body: AppListSkeleton());
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
                usePagination: widget.requesterId != null,
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
    required this.usePagination,
    required this.onLoad,
    required this.onOpenTicket,
  });

  final TicketListViewModel viewModel;
  final bool usePagination;
  final Future<void> Function() onLoad;
  final ValueChanged<Ticket> onOpenTicket;

  @override
  State<_TicketListBody> createState() => _TicketListBodyState();
}

class _TicketListBodyState extends State<_TicketListBody> {
  static const int _ticketsPerPage = 5;

  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  _TicketSortOption _sortOption = _TicketSortOption.newestFirst;
  String _statusFilter = '';
  String _priorityFilter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoad();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    if (viewModel.isLoading && viewModel.tickets.isEmpty) {
      return const AppListSkeleton();
    }

    if (viewModel.errorMessage != null && viewModel.tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onLoad,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.7,
              child: AppErrorState(
                message: viewModel.errorMessage!,
                onRetry: () => widget.onLoad(),
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onLoad,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 520,
              child: AppEmptyState(
                title: 'No tickets found.',
                message: 'New support requests will appear here.',
                icon: Icons.confirmation_number_outlined,
              ),
            ),
          ],
        ),
      );
    }

    final tickets = _sortTickets(_filterTickets(viewModel.tickets));
    final visibleTickets = widget.usePagination
        ? _paginatedTickets(tickets)
        : tickets;
    final pageCount = _pageCount(tickets.length);
    final showPagination = widget.usePagination && pageCount > 1;
    final children = <Widget>[
      _TicketListControls(
        controller: _searchController,
        sortOption: _sortOption,
        statusFilter: _statusFilter,
        priorityFilter: _priorityFilter,
        resultCount: tickets.length,
        totalCount: viewModel.tickets.length,
        onSearchChanged: (_) => _resetPage(),
        onClearSearch: _searchController.text.isEmpty
            ? null
            : () {
                _searchController.clear();
                _resetPage();
              },
        onSortChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            _sortOption = value;
            _currentPage = 0;
          });
        },
        onStatusFilterChanged: (value) {
          setState(() {
            _statusFilter = value ?? '';
            _currentPage = 0;
          });
        },
        onPriorityFilterChanged: (value) {
          setState(() {
            _priorityFilter = value ?? '';
            _currentPage = 0;
          });
        },
        onClearFilters: _statusFilter.isEmpty && _priorityFilter.isEmpty
            ? null
            : () {
                setState(() {
                  _statusFilter = '';
                  _priorityFilter = '';
                  _currentPage = 0;
                });
              },
      ),
      const SizedBox(height: 12),
    ];

    if (visibleTickets.isEmpty) {
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
        _ResponsiveTicketCollection(
          tickets: visibleTickets,
          onOpenTicket: widget.onOpenTicket,
        ),
      );
    }

    if (showPagination) {
      children
        ..add(const SizedBox(height: 8))
        ..add(
          _TicketPaginationControls(
            currentPage: _effectiveCurrentPage(pageCount),
            pageCount: pageCount,
            totalItems: tickets.length,
            startItem: _pageStartIndex(tickets.length) + 1,
            endItem: _pageEndIndex(tickets.length),
            onFirst: () => _setPage(0),
            onPrevious: () => _setPage(_currentPage - 1),
            onNext: () => _setPage(_currentPage + 1),
            onLast: () => _setPage(pageCount - 1),
          ),
        );
    }

    return RefreshIndicator(
      onRefresh: widget.onLoad,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: children,
      ),
    );
  }

  List<Ticket> _filterTickets(List<Ticket> tickets) {
    return TicketListFilter(
      query: _searchController.text,
      status: _statusFilter,
      priority: _priorityFilter,
    ).apply(tickets);
  }

  List<Ticket> _sortTickets(List<Ticket> tickets) {
    final sortedTickets = [...tickets];
    sortedTickets.sort((a, b) {
      return switch (_sortOption) {
        _TicketSortOption.newestFirst => b.createdAt.compareTo(a.createdAt),
        _TicketSortOption.oldestFirst => a.createdAt.compareTo(b.createdAt),
        _TicketSortOption.priorityHighFirst => _priorityRank(
          b.priority,
        ).compareTo(_priorityRank(a.priority)),
        _TicketSortOption.status => TicketStatus.fromValue(
          a.status,
        ).index.compareTo(TicketStatus.fromValue(b.status).index),
        _TicketSortOption.slaDeadline => _compareDeadline(a, b),
      };
    });

    return sortedTickets;
  }

  int _compareDeadline(Ticket a, Ticket b) {
    final aDue = a.resolutionDueAt;
    final bDue = b.resolutionDueAt;
    if (aDue == null) return bDue == null ? 0 : 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  int _priorityRank(String priority) {
    return PriorityLevel.fromValue(priority).index;
  }

  List<Ticket> _paginatedTickets(List<Ticket> tickets) {
    final start = _pageStartIndex(tickets.length);
    final end = _pageEndIndex(tickets.length);
    return tickets.sublist(start, end);
  }

  int _pageCount(int itemCount) {
    if (itemCount == 0) {
      return 1;
    }

    return (itemCount / _ticketsPerPage).ceil();
  }

  int _effectiveCurrentPage(int pageCount) {
    if (_currentPage < 0) {
      return 0;
    }

    if (_currentPage >= pageCount) {
      return pageCount - 1;
    }

    return _currentPage;
  }

  int _pageStartIndex(int itemCount) {
    final page = _effectiveCurrentPage(_pageCount(itemCount));
    return page * _ticketsPerPage;
  }

  int _pageEndIndex(int itemCount) {
    final end = _pageStartIndex(itemCount) + _ticketsPerPage;
    return end > itemCount ? itemCount : end;
  }

  void _setPage(int page) {
    final itemCount = _filterTickets(widget.viewModel.tickets).length;
    final lastPage = _pageCount(itemCount) - 1;
    final nextPage = page.clamp(0, lastPage);
    if (nextPage == _currentPage) {
      return;
    }

    setState(() {
      _currentPage = nextPage;
    });
  }

  void _resetPage() {
    setState(() {
      _currentPage = 0;
    });
  }
}

enum _TicketSortOption {
  newestFirst('Newest first'),
  oldestFirst('Oldest first'),
  priorityHighFirst('Priority: high first'),
  status('Status'),
  slaDeadline('SLA deadline');

  const _TicketSortOption(this.label);

  final String label;
}

class _TicketListControls extends StatelessWidget {
  const _TicketListControls({
    required this.controller,
    required this.sortOption,
    required this.statusFilter,
    required this.priorityFilter,
    required this.resultCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortChanged,
    required this.onStatusFilterChanged,
    required this.onPriorityFilterChanged,
    required this.onClearFilters,
  });

  final TextEditingController controller;
  final _TicketSortOption sortOption;
  final String statusFilter;
  final String priorityFilter;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClearSearch;
  final ValueChanged<_TicketSortOption?> onSortChanged;
  final ValueChanged<String?> onStatusFilterChanged;
  final ValueChanged<String?> onPriorityFilterChanged;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Search tickets',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              onPressed: onClearSearch,
              icon: const Icon(Icons.clear),
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('ticket-status-filter'),
                isExpanded: true,
                initialValue: statusFilter,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.filter_alt),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All statuses'),
                  ),
                  ...TicketStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status.value,
                      child: Text(status.value),
                    ),
                  ),
                ],
                onChanged: onStatusFilterChanged,
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('ticket-priority-filter'),
                isExpanded: true,
                initialValue: priorityFilter,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All priorities'),
                  ),
                  ...PriorityLevel.values.map(
                    (priority) => DropdownMenuItem(
                      value: priority.value,
                      child: Text(priority.value),
                    ),
                  ),
                ],
                onChanged: onPriorityFilterChanged,
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<_TicketSortOption>(
                isExpanded: true,
                initialValue: sortOption,
                decoration: const InputDecoration(
                  labelText: 'Sort by',
                  prefixIcon: Icon(Icons.sort),
                  border: OutlineInputBorder(),
                ),
                items: _TicketSortOption.values.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option.label),
                  );
                }).toList(),
                onChanged: onSortChanged,
              ),
            ),
            Chip(label: Text('$resultCount/$totalCount tickets')),
            if (onClearFilters != null)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ],
    );
  }
}

class _TicketPaginationControls extends StatelessWidget {
  const _TicketPaginationControls({
    required this.currentPage,
    required this.pageCount,
    required this.totalItems,
    required this.startItem,
    required this.endItem,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
  });

  final int currentPage;
  final int pageCount;
  final int totalItems;
  final int startItem;
  final int endItem;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLast;

  @override
  Widget build(BuildContext context) {
    final isFirstPage = currentPage == 0;
    final isLastPage = currentPage == pageCount - 1;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            'Showing $startItem-$endItem of $totalItems tickets',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              IconButton(
                tooltip: 'First page',
                onPressed: isFirstPage ? null : onFirst,
                icon: const Icon(Icons.first_page),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: isFirstPage ? null : onPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Page ${currentPage + 1} of $pageCount',
                  style: textTheme.bodyMedium,
                ),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: isLastPage ? null : onNext,
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton(
                tooltip: 'Last page',
                onPressed: isLastPage ? null : onLast,
                icon: const Icon(Icons.last_page),
              ),
            ],
          ),
        ],
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
    final statusColor = AppColors.ticketStatus(ticket.status);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: colorScheme.primary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TicketStatusBadge(status: ticket.status),
                          PriorityBadge(priority: ticket.priority),
                          _TicketInfoChip(label: ticket.issueType),
                          SlaStatusBadge(
                            status: ticket.resolutionSlaStatus,
                            dueAt: ticket.resolutionDueAt,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Created ${_formatDate(ticket.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TicketInfoChip extends StatelessWidget {
  const _TicketInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ResponsiveTicketCollection extends StatelessWidget {
  const _ResponsiveTicketCollection({
    required this.tickets,
    required this.onOpenTicket,
  });

  final List<Ticket> tickets;
  final ValueChanged<Ticket> onOpenTicket;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        if (columns == 1) {
          return Column(
            children: [
              for (var index = 0; index < tickets.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                _TicketTile(
                  ticket: tickets[index],
                  onTap: () => onOpenTicket(tickets[index]),
                ),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 276,
          ),
          itemCount: tickets.length,
          itemBuilder: (context, index) => _TicketTile(
            ticket: tickets[index],
            onTap: () => onOpenTicket(tickets[index]),
          ),
        );
      },
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
