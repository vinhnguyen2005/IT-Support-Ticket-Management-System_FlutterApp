import 'package:flutter/material.dart';

import '../../../../core/enums/ticket_status.dart';
import '../../../../core/widgets/app_badges.dart';
import '../../../../core/widgets/app_states.dart';
import '../viewmodels/update_progress_view_model.dart';

class UpdateProgressPage extends StatefulWidget {
  const UpdateProgressPage({super.key, required this.viewModel});

  final UpdateProgressViewModel viewModel;

  @override
  State<UpdateProgressPage> createState() => _UpdateProgressPageState();
}

class _UpdateProgressPageState extends State<UpdateProgressPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _solutionSummaryController =
      TextEditingController();
  String? _status;
  String? _messageError;
  String? _solutionError;

  static const Map<TicketStatus, List<TicketStatus>> _staffTransitions = {
    TicketStatus.submitted: [TicketStatus.assigned],
    TicketStatus.assigned: [TicketStatus.processing],
    TicketStatus.processing: [TicketStatus.resolved],
  };

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    widget.viewModel.load();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _messageController.dispose();
    _solutionSummaryController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(_syncSelectedStatus);
    }
  }

  Future<void> _submit() async {
    final selectedStatus = _status;
    if (selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid next status is available.')),
      );
      return;
    }

    final message = _messageController.text.trim();
    final solution = _solutionSummaryController.text.trim();
    setState(() {
      _messageError = message.isEmpty ? 'A status note is required.' : null;
      _solutionError =
          selectedStatus == TicketStatus.resolved.value && solution.isEmpty
          ? 'Add a completion summary before resolving the ticket.'
          : null;
    });
    if (_messageError != null || _solutionError != null) return;

    final success = await widget.viewModel.submitUpdate(
      message: message,
      status: selectedStatus,
      solutionSummary: solution,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Ticket status updated.' : 'Update failed.'),
      ),
    );

    if (success) {
      _messageController.clear();
      _solutionSummaryController.clear();
    }
  }

  void _syncSelectedStatus() {
    final assignment = widget.viewModel.assignment;
    if (assignment == null) {
      return;
    }

    final allowedStatuses = _allowedNextStatuses(assignment.status);
    if (allowedStatuses.isEmpty) {
      _status = null;
      return;
    }

    if (_status == null || !allowedStatuses.contains(_status)) {
      _status = allowedStatuses.first;
    }
  }

  List<String> _allowedNextStatuses(String currentStatus) {
    final status = TicketStatus.fromValue(currentStatus);
    return (_staffTransitions[status] ?? const [])
        .map((status) => status.value)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final assignment = viewModel.assignment;
    final allowedStatuses = assignment == null
        ? const <String>[]
        : _allowedNextStatuses(assignment.status);
    final selectedStatus = _status;
    final canSubmit =
        !viewModel.isLoading && assignment != null && selectedStatus != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Update ticket status')),
      body: viewModel.isLoading && assignment == null
          ? const AppListSkeleton(itemCount: 4)
          : assignment == null && viewModel.errorMessage != null
          ? AppErrorState(
              message: viewModel.errorMessage!,
              onRetry: viewModel.load,
            )
          : AppContent(
              maxWidth: 900,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (assignment != null) ...[
                    Text(
                      assignment.ticketTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(assignment.ticketDescription),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PriorityBadge(priority: assignment.priority),
                        Chip(label: Text(assignment.issueType)),
                        TicketStatusBadge(status: assignment.status),
                        Text('Current: ${assignment.status}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (allowedStatuses.isEmpty)
                    const Text(
                      'No status changes are available for this ticket.',
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        '${assignment?.ticketId}-${allowedStatuses.join('|')}-$selectedStatus',
                      ),
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Next status',
                        border: OutlineInputBorder(),
                      ),
                      items: allowedStatuses
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: viewModel.isLoading
                          ? null
                          : (value) => setState(() => _status = value),
                    ),
                  if (selectedStatus == TicketStatus.resolved.value) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _solutionSummaryController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Completion summary',
                        hintText: 'Summarize the fix and outcome',
                      ),
                      maxLength: 1000,
                      onChanged: (_) {
                        if (_solutionError != null) {
                          setState(() => _solutionError = null);
                        }
                      },
                    ),
                    if (_solutionError != null)
                      Text(
                        _solutionError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    minLines: 4,
                    maxLines: 6,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      labelText: 'Status note',
                      hintText:
                          'Describe the work completed or current progress',
                      errorText: _messageError,
                    ),
                    onChanged: (_) {
                      if (_messageError != null) {
                        setState(() => _messageError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: canSubmit ? _submit : null,
                    icon: viewModel.isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save update'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Status note history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.updates.isEmpty)
                    const Text('No status notes yet.')
                  else
                    ...viewModel.updates.map(
                      (update) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notes),
                        title: Text(update.message),
                        subtitle: Text(update.createdAt.toString()),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
