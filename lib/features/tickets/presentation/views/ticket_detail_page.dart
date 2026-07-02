import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../application/services/i_ticket_service.dart';
import '../../application/services/ticket_service_impl.dart';
import '../../data/mappers/ticket_mapper.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket.dart';
import '../viewmodels/ticket_detail_view_model.dart';

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  late final Future<TicketDetailViewModel> _viewModelFuture;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();

  String _issueType = IssueType.defaultValue;
  String _priority = PriorityLevel.defaultValue;
  int? _categoryId;
  bool _hasLoadedTicket = false;

  @override
  void initState() {
    super.initState();
    _viewModelFuture = _createViewModel();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<TicketDetailViewModel> _createViewModel() async {
    return TicketDetailViewModel(await _createTicketService());
  }

  void _populateForm(Ticket ticket) {
    if (_hasLoadedTicket) {
      return;
    }

    _titleController.text = ticket.title;
    _descriptionController.text = ticket.description;
    _attachmentController.text = ticket.attachmentUrl ?? '';
    _issueType = _knownIssueTypes.contains(ticket.issueType)
        ? ticket.issueType
        : IssueType.defaultValue;
    _priority = _knownPriorities.contains(ticket.priority)
        ? ticket.priority
        : PriorityLevel.defaultValue;
    _categoryId = ticket.categoryId;
    _hasLoadedTicket = true;
  }

  Future<void> _save(TicketDetailViewModel viewModel, Ticket ticket) async {
    final success = await viewModel.updateTicket(
      Ticket(
        id: ticket.id,
        title: _titleController.text,
        description: _descriptionController.text,
        status: ticket.status,
        priority: _priority,
        issueType: _issueType,
        attachmentUrl: _attachmentController.text,
        requestedId: ticket.requestedId,
        assignedId: ticket.assignedId,
        categoryId: _categoryId,
        solutionSummary: ticket.solutionSummary,
        resolvedAt: ticket.resolvedAt,
        createdAt: ticket.createdAt,
        updatedAt: ticket.updatedAt,
        createdByUserId: ticket.createdByUserId,
        updatedByUserId: ticket.updatedByUserId,
        isDeleted: ticket.isDeleted,
      ),
    );

    if (!mounted || !success) {
      return;
    }

    _hasLoadedTicket = false;
    final updatedTicket = viewModel.ticket;
    if (updatedTicket != null) {
      _populateForm(updatedTicket);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ticket saved.')));
  }

  Future<void> _changeStatus(
    TicketDetailViewModel viewModel,
    Ticket ticket,
  ) async {
    final result = await showDialog<_StatusChangeResult>(
      context: context,
      builder: (context) {
        return _StatusChangeDialog(currentStatus: ticket.status);
      },
    );

    if (result == null) {
      return;
    }

    final ticketId = ticket.id;
    if (ticketId == null) {
      return;
    }

    final success = await viewModel.updateTicketStatus(
      ticketId: ticketId,
      status: result.status,
      note: result.note,
      solutionSummary: result.solutionSummary,
    );

    if (!mounted || !success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status changed to ${result.status}.')),
    );
  }

  Future<void> _delete(TicketDetailViewModel viewModel, Ticket ticket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete ticket'),
          content: Text('Delete "${ticket.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final ticketId = ticket.id;
    if (ticketId == null) {
      return;
    }

    final success = await viewModel.deleteTicket(ticketId);
    if (!mounted || !success) {
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TicketDetailViewModel>(
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
            final ticket = viewModel.ticket;
            if (ticket != null) {
              _populateForm(ticket);
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Ticket details'),
                actions: [
                  if (ticket != null)
                    PopupMenuButton<_TicketAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _TicketAction.changeStatus:
                            _changeStatus(viewModel, ticket);
                            break;
                          case _TicketAction.delete:
                            _delete(viewModel, ticket);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: _TicketAction.changeStatus,
                            child: Text('Change status'),
                          ),
                          PopupMenuItem(
                            value: _TicketAction.delete,
                            child: Text('Delete'),
                          ),
                        ];
                      },
                    ),
                ],
              ),
              body: _TicketDetailBody(
                viewModel: viewModel,
                ticketId: widget.ticketId,
                ticket: ticket,
                titleController: _titleController,
                descriptionController: _descriptionController,
                attachmentController: _attachmentController,
                issueType: _issueType,
                priority: _priority,
                categoryId: _categoryId,
                onIssueTypeChanged: (value) {
                  setState(() {
                    _issueType = value;
                  });
                },
                onPriorityChanged: (value) {
                  setState(() {
                    _priority = value;
                  });
                },
                onCategoryChanged: (value) {
                  setState(() {
                    _categoryId = value;
                  });
                },
                onSave: ticket == null ? null : () => _save(viewModel, ticket),
              ),
            );
          },
        );
      },
    );
  }
}

class _TicketDetailBody extends StatefulWidget {
  const _TicketDetailBody({
    required this.viewModel,
    required this.ticketId,
    required this.ticket,
    required this.titleController,
    required this.descriptionController,
    required this.attachmentController,
    required this.issueType,
    required this.priority,
    required this.categoryId,
    required this.onIssueTypeChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onSave,
  });

  final TicketDetailViewModel viewModel;
  final int ticketId;
  final Ticket? ticket;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController attachmentController;
  final String issueType;
  final String priority;
  final int? categoryId;
  final ValueChanged<String> onIssueTypeChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback? onSave;

  @override
  State<_TicketDetailBody> createState() => _TicketDetailBodyState();
}

class _TicketDetailBodyState extends State<_TicketDetailBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadTicket(widget.ticketId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    if (viewModel.isLoading && widget.ticket == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && widget.ticket == null) {
      return Center(
        child: Text(
          viewModel.errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    final ticket = widget.ticket;
    if (ticket == null) {
      return const Center(child: Text('Ticket not found.'));
    }

    final categoryValue = widget.categoryId ?? _defaultCategoryId;
    final categoryItems = _categoryDropdownItems(widget.categoryId);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(ticket.status)),
              Chip(label: Text(ticket.priority)),
              Chip(label: Text(ticket.issueType)),
              Chip(label: Text('Created ${_formatDate(ticket.createdAt)}')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.titleController,
            enabled: !viewModel.isLoading,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.descriptionController,
            enabled: !viewModel.isLoading,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.issueType,
            decoration: const InputDecoration(
              labelText: 'Issue type',
              border: OutlineInputBorder(),
            ),
            items: _knownIssueTypes.map((issueType) {
              return DropdownMenuItem(value: issueType, child: Text(issueType));
            }).toList(),
            onChanged: viewModel.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      widget.onIssueTypeChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: widget.priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: _knownPriorities.map((priority) {
              return DropdownMenuItem(value: priority, child: Text(priority));
            }).toList(),
            onChanged: viewModel.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      widget.onPriorityChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: categoryValue,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: categoryItems,
            onChanged: viewModel.isLoading
                ? null
                : (value) {
                    widget.onCategoryChanged(value);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.attachmentController,
            enabled: !viewModel.isLoading,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Attachment URL',
              border: OutlineInputBorder(),
            ),
          ),
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              viewModel.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: viewModel.isLoading ? null : widget.onSave,
            icon: viewModel.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}

class _StatusChangeDialog extends StatefulWidget {
  const _StatusChangeDialog({required this.currentStatus});

  final String currentStatus;

  @override
  State<_StatusChangeDialog> createState() => _StatusChangeDialogState();
}

class _StatusChangeDialogState extends State<_StatusChangeDialog> {
  late String _status;
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = _statusLabel(widget.currentStatus);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: _knownStatuses.map((status) {
                return DropdownMenuItem(value: status, child: Text(status));
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _status = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            if (_status == TicketStatus.resolved.value) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _solutionController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Solution summary',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _StatusChangeResult(
                status: _status,
                note: _noteController.text,
                solutionSummary: _solutionController.text,
              ),
            );
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class _StatusChangeResult {
  const _StatusChangeResult({
    required this.status,
    required this.note,
    required this.solutionSummary,
  });

  final String status;
  final String note;
  final String solutionSummary;
}

enum _TicketAction { changeStatus, delete }

final List<String> _knownIssueTypes = IssueType.values
    .map((issueType) => issueType.value)
    .toList(growable: false);

final List<String> _knownPriorities = PriorityLevel.values
    .map((priority) => priority.value)
    .toList(growable: false);

final List<String> _knownStatuses = TicketStatus.values
    .map((status) => status.value)
    .toList(growable: false);

const int _defaultCategoryId = 4;

const Map<int, String> _knownCategoryLabels = {
  4: 'General Support',
  1: 'Network Issue',
  2: 'Hardware Issue',
  3: 'Software Issue',
};

List<DropdownMenuItem<int>> _categoryDropdownItems(int? selectedCategoryId) {
  final labels = <int, String>{
    if (selectedCategoryId != null &&
        !_knownCategoryLabels.containsKey(selectedCategoryId))
      selectedCategoryId: 'Current category #$selectedCategoryId',
    ..._knownCategoryLabels,
  };

  return labels.entries.map((entry) {
    return DropdownMenuItem(value: entry.key, child: Text(entry.value));
  }).toList(growable: false);
}

String _statusLabel(String status) {
  return TicketStatus.fromValue(status).value;
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
