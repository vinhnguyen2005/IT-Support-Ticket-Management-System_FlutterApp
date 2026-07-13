import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/storage/ticket_attachment_storage.dart';
import '../../application/services/i_ticket_service.dart';
import '../../application/services/ticket_service_impl.dart';
import '../../data/mappers/ticket_mapper.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_status_note.dart';
import '../viewmodels/ticket_detail_view_model.dart';
import '../widgets/ticket_attachment_field.dart';
import '../../../comments/presentation/viewmodels/comment_view_model.dart';
import '../../../comments/presentation/views/comment_section.dart';
import '../../../feedback/presentation/viewmodels/feedback_view_model.dart';
import '../../../feedback/presentation/views/feedback_page.dart';
import '../../../feedback/domain/entities/feedback.dart' as feedback_entity;

class TicketDetailPage extends StatefulWidget {
  const TicketDetailPage({
    super.key,
    required this.ticketId,
    this.currentUserId,
  });

  final int ticketId;
  final int? currentUserId;

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage>
    with SingleTickerProviderStateMixin {
  late final Future<TicketDetailViewModel> _viewModelFuture;
  late final Future<CommentViewModel> _commentViewModelFuture;
  late final Future<FeedbackViewModel> _feedbackViewModelFuture;
  late final Future<_TicketViewer> _viewerFuture;
  late final TabController _tabController;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _issueType = IssueType.defaultValue;
  String _priority = PriorityLevel.defaultValue;
  int? _categoryId;
  String? _attachmentPath;
  String? _originalAttachmentPath;
  bool _ownsAttachment = false;
  bool _hasLoadedTicket = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModelFuture = _createViewModel();
    _commentViewModelFuture = _createCommentViewModel();
    _feedbackViewModelFuture = _createFeedbackViewModel();
    _viewerFuture = _loadViewer();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    if (_ownsAttachment) {
      unawaited(TicketAttachmentStorage.deleteManagedFile(_attachmentPath));
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<TicketDetailViewModel> _createViewModel() async {
    final viewModel = TicketDetailViewModel(
      await _createTicketService(),
      await ServiceLocator.referenceDataService,
    );
    await viewModel.loadPriorities();
    await viewModel.loadTicket(widget.ticketId);
    return viewModel;
  }

  Future<CommentViewModel> _createCommentViewModel() async {
    return ServiceLocator.commentViewModelFactory();
  }

  Future<FeedbackViewModel> _createFeedbackViewModel() async {
    final viewModel = await ServiceLocator.feedbackViewModelFactory();
    await viewModel.loadFeedbackByTicketId(widget.ticketId);
    return viewModel;
  }

  Future<_TicketViewer> _loadViewer() async {
    final loginViewModel = await ServiceLocator.loginViewModel;
    final user = loginViewModel.currentUser;
    return _TicketViewer(
      id: user?.id ?? widget.currentUserId ?? 0,
      role: UserRole.fromValue(user?.role ?? UserRole.user.value),
    );
  }

  void _populateForm(Ticket ticket, List<PriorityReference> priorities) {
    if (_hasLoadedTicket) {
      return;
    }

    _titleController.text = ticket.title;
    _descriptionController.text = ticket.description;
    _attachmentPath = ticket.attachmentUrl;
    _originalAttachmentPath = ticket.attachmentUrl;
    _ownsAttachment = false;
    _issueType = _knownIssueTypes.contains(ticket.issueType)
        ? ticket.issueType
        : IssueType.defaultValue;
    final availablePriorities = priorities.isEmpty
        ? _knownPriorities
        : priorities.map((priority) => priority.name).toList(growable: false);
    if (availablePriorities.contains(ticket.priority)) {
      _priority = ticket.priority;
    } else if (availablePriorities.isEmpty) {
      _priority = PriorityLevel.defaultValue;
    } else {
      _priority = availablePriorities.first;
    }
    _categoryId = ticket.categoryId;
    _hasLoadedTicket = true;
  }

  Future<void> _pickFile() async {
    try {
      final attachmentPath = await TicketAttachmentStorage.pickAndStoreImage();
      if (attachmentPath == null) return;
      if (!mounted) {
        await TicketAttachmentStorage.deleteManagedFile(attachmentPath);
        return;
      }

      if (_ownsAttachment) {
        await TicketAttachmentStorage.deleteManagedFile(_attachmentPath);
      }
      if (!mounted) return;
      setState(() {
        _attachmentPath = attachmentPath;
        _ownsAttachment = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select image: $error')));
    }
  }

  Future<void> _clearAttachment() async {
    if (_ownsAttachment) {
      await TicketAttachmentStorage.deleteManagedFile(_attachmentPath);
    }
    if (!mounted) return;
    setState(() {
      _attachmentPath = null;
      _ownsAttachment = false;
    });
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
        attachmentUrl: _attachmentPath,
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

    if (_attachmentPath != _originalAttachmentPath) {
      await TicketAttachmentStorage.deleteManagedFile(_originalAttachmentPath);
    }
    if (!mounted) return;
    _ownsAttachment = false;
    _originalAttachmentPath = _attachmentPath;
    _hasLoadedTicket = false;
    final updatedTicket = viewModel.ticket;
    if (updatedTicket != null) {
      _populateForm(updatedTicket, viewModel.priorities);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ticket saved.')));
    setState(() => _isEditing = false);
  }

  Future<void> _confirmStatusChange(
    TicketDetailViewModel viewModel,
    Ticket ticket,
    _TicketViewer viewer, {
    required TicketStatus status,
    required String title,
    required String message,
  }) async {
    final cancellationReason = await showDialog<String?>(
      context: context,
      builder: (context) => _StatusConfirmationDialog(
        status: status,
        title: title,
        message: message,
      ),
    );

    if (cancellationReason == null) {
      return;
    }

    final ticketId = ticket.id;
    if (ticketId == null) {
      return;
    }

    final success = await viewModel.updateTicketStatus(
      ticketId: ticketId,
      status: status.value,
      changedByUserId: viewer.id,
      changedByRole: viewer.role.value,
      note: status == TicketStatus.closed
          ? 'Requester confirmed the resolution.'
          : cancellationReason,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Status update failed.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status changed to ${status.value}.')),
    );
  }

  void _openFeedbackPage(
    Ticket ticket,
    FeedbackViewModel feedbackVm,
    int userId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedbackPage(
          ticketId: widget.ticketId,
          userId: userId,
          viewModel: feedbackVm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([
        _viewModelFuture,
        _commentViewModelFuture,
        _feedbackViewModelFuture,
        _viewerFuture,
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final viewModel = snapshot.data![0] as TicketDetailViewModel;
        final commentVm = snapshot.data![1] as CommentViewModel;
        final feedbackVm = snapshot.data![2] as FeedbackViewModel;
        final viewer = snapshot.data![3] as _TicketViewer;

        return AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            final ticket = viewModel.ticket;
            if (ticket != null) {
              _populateForm(ticket, viewModel.priorities);
            }
            final ticketStatus = ticket == null
                ? null
                : TicketStatus.fromValue(ticket.status);
            final isClosed = ticketStatus == TicketStatus.closed;
            final isCancelled = ticketStatus == TicketStatus.cancelled;
            final isProcessing = ticketStatus == TicketStatus.processing;
            final isResolved = ticketStatus == TicketStatus.resolved;
            final isRequester =
                ticket?.createdByUserId == viewer.id ||
                ticket?.requestedId == viewer.id;
            final canEdit =
                ticket != null &&
                isRequester &&
                !isProcessing &&
                !isResolved &&
                !isClosed &&
                !isCancelled;
            final canConfirmResolved = ticket != null &&
                isRequester &&
                viewer.role == UserRole.user &&
                isResolved;
            final canGiveFeedback = ticket != null && isRequester && isClosed;
            final canCancel =
                ticket != null &&
                viewer.role == UserRole.admin &&
                ticketStatus != TicketStatus.resolved &&
                ticketStatus != TicketStatus.closed &&
                ticketStatus != TicketStatus.cancelled;
            final canViewFeedback =
                viewer.role == UserRole.admin || viewer.role == UserRole.staff;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Ticket details'),
                actions: [
                  if (canConfirmResolved)
                    IconButton(
                      key: const Key('confirm-resolution-button'),
                      icon: const Icon(Icons.check_circle),
                      tooltip: 'Confirm resolution',
                      onPressed: () => _confirmStatusChange(
                        viewModel,
                        ticket,
                        viewer,
                        status: TicketStatus.closed,
                        title: 'Confirm resolution',
                        message:
                            'The issue has been resolved. Do you want to close this ticket?',
                      ),
                    ),
                  if (canCancel)
                    IconButton(
                      key: const Key('admin-cancel-ticket-button'),
                      icon: const Icon(Icons.cancel),
                      tooltip: 'Cancel ticket',
                      onPressed: () => _confirmStatusChange(
                        viewModel,
                        ticket,
                        viewer,
                        status: TicketStatus.cancelled,
                        title: 'Cancel ticket',
                        message: 'Cancel this ticket request?',
                      ),
                    ),
                  if (canGiveFeedback)
                    IconButton(
                      icon: const Icon(Icons.star),
                      tooltip: 'Feedback',
                      onPressed: () =>
                          _openFeedbackPage(ticket, feedbackVm, viewer.id),
                    ),
                  if (canEdit)
                    PopupMenuButton<_TicketAction>(
                      onSelected: (action) {
                        switch (action) {
                          case _TicketAction.edit:
                            setState(() => _isEditing = true);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        return const [
                          PopupMenuItem(
                            value: _TicketAction.edit,
                            child: Text('Edit ticket'),
                          ),
                        ];
                      },
                    ),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Comments'),
                  ],
                ),
              ),
              body: _TicketDetailBody(
                viewModel: viewModel,
                ticketId: widget.ticketId,
                ticket: ticket,
                statusNotes: viewModel.statusNotes,
                titleController: _titleController,
                descriptionController: _descriptionController,
                attachmentPath: _attachmentPath,
                issueType: _issueType,
                priority: _priority,
                categoryId: _categoryId,
                tabController: _tabController,
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
                onBrowseFile: _pickFile,
                onClearAttachment: _clearAttachment,
                commentVm: commentVm,
                currentUserId: viewer.id,
                isEditing: _isEditing && canEdit,
                isClosed: isClosed || isCancelled,
                feedback: feedbackVm.feedback,
                canViewFeedback: canViewFeedback,
                priorityOptions: viewModel.priorities.isEmpty
                    ? _knownPriorities
                    : viewModel.priorities
                          .map((priority) => priority.name)
                          .toList(growable: false),
              ),
            );
          },
        );
      },
    );
  }
}

class _TicketDetailBody extends StatelessWidget {
  const _TicketDetailBody({
    required this.viewModel,
    required this.ticketId,
    required this.ticket,
    required this.statusNotes,
    required this.titleController,
    required this.descriptionController,
    required this.attachmentPath,
    required this.issueType,
    required this.priority,
    required this.categoryId,
    required this.tabController,
    required this.onIssueTypeChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.onSave,
    required this.onBrowseFile,
    required this.onClearAttachment,
    required this.commentVm,
    required this.currentUserId,
    required this.isEditing,
    required this.isClosed,
    required this.feedback,
    required this.canViewFeedback,
    required this.priorityOptions,
  });

  final TicketDetailViewModel viewModel;
  final int ticketId;
  final Ticket? ticket;
  final List<TicketStatusNote> statusNotes;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? attachmentPath;
  final String issueType;
  final String priority;
  final int? categoryId;
  final TabController tabController;
  final ValueChanged<String> onIssueTypeChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<int?> onCategoryChanged;
  final VoidCallback? onSave;
  final VoidCallback onBrowseFile;
  final VoidCallback onClearAttachment;
  final CommentViewModel commentVm;
  final int currentUserId;
  final bool isEditing;
  final bool isClosed;
  final feedback_entity.Feedback? feedback;
  final bool canViewFeedback;
  final List<String> priorityOptions;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading && ticket == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && ticket == null) {
      return Center(
        child: Text(
          viewModel.errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    final currentTicket = ticket;
    if (currentTicket == null) {
      return const Center(child: Text('Ticket not found.'));
    }

    return TabBarView(
      controller: tabController,
      children: [
        // Tab 1: Details
        _buildDetailsTab(currentTicket, viewModel),
        // Tab 2: Comments
        CommentSection(
          ticketId: ticketId,
          currentUserId: currentUserId,
          viewModel: commentVm,
          isLocked: isClosed,
        ),
      ],
    );
  }

  Widget _buildDetailsTab(Ticket ticket, TicketDetailViewModel viewModel) {
    final statusStyle = _TicketStatusStyle.fromStatus(
      TicketStatus.fromValue(ticket.status),
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusSummaryBanner(
            status: ticket.status,
            color: statusStyle.color,
            icon: statusStyle.icon,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: ticket.status,
                icon: statusStyle.icon,
                color: statusStyle.color,
              ),
              Chip(label: Text(ticket.priority)),
              Chip(label: Text(ticket.issueType)),
              Chip(label: Text('Created ${_formatDate(ticket.createdAt)}')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: titleController,
            enabled: isEditing && !viewModel.isLoading,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            enabled: isEditing && !viewModel.isLoading,
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
            initialValue: issueType,
            decoration: const InputDecoration(
              labelText: 'Issue type',
              border: OutlineInputBorder(),
            ),
            items: _knownIssueTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: !isEditing || viewModel.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      onIssueTypeChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: priority,
            decoration: const InputDecoration(
              labelText: 'Priority',
              border: OutlineInputBorder(),
            ),
            items: priorityOptions.map((p) {
              return DropdownMenuItem(value: p, child: Text(p));
            }).toList(),
            onChanged: !isEditing || viewModel.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      onPriorityChanged(value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _resolveValidCategoryId(categoryId),
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('None')),
              ..._categoryOptions.map(
                (c) =>
                    DropdownMenuItem<int?>(value: c.id, child: Text(c.label)),
              ),
            ],
            onChanged: !isEditing || viewModel.isLoading
                ? null
                : (value) {
                    onCategoryChanged(value);
                  },
          ),
          const SizedBox(height: 12),
          TicketAttachmentField(
            filePath: attachmentPath,
            isEditing: isEditing,
            isBusy: viewModel.isLoading,
            onPick: onBrowseFile,
            onClear: onClearAttachment,
          ),
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(viewModel.errorMessage!, style: TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          _StatusNotesSection(
            status: ticket.status,
            statusStyle: statusStyle,
            statusNotes: statusNotes,
          ),
          if (canViewFeedback && feedback != null) ...[
            const SizedBox(height: 24),
            _FeedbackSummary(feedback: feedback!),
          ],
          if (isEditing) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: viewModel.isLoading ? null : onSave,
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
        ],
      ),
    );
  }
}

enum _TicketAction { edit }

class _StatusSummaryBanner extends StatelessWidget {
  const _StatusSummaryBanner({
    required this.status,
    required this.color,
    required this.icon,
  });

  final String status;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border(left: BorderSide(color: color, width: 5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Status: $status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
    );
  }
}

class _StatusNotesSection extends StatelessWidget {
  const _StatusNotesSection({
    required this.status,
    required this.statusStyle,
    required this.statusNotes,
  });

  final String status;
  final _TicketStatusStyle statusStyle;
  final List<TicketStatusNote> statusNotes;

  @override
  Widget build(BuildContext context) {
    final notesWithText = statusNotes
        .where((note) => note.note?.trim().isNotEmpty ?? false)
        .toList(growable: false);
    final latestNote = notesWithText.isEmpty ? null : notesWithText.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _StatusChip(
          label: status,
          icon: statusStyle.icon,
          color: statusStyle.color,
        ),
        const SizedBox(height: 16),
        Text('Status note', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (latestNote == null)
          const Text('No status note available.')
        else
          _StatusNoteTile(latestNote),
        if (notesWithText.length > 1) ...[
          const SizedBox(height: 8),
          ...notesWithText.skip(1).map((note) => _StatusNoteTile(note)),
        ],
      ],
    );
  }
}

class _StatusNoteTile extends StatelessWidget {
  const _StatusNoteTile(this.note);

  final TicketStatusNote note;

  @override
  Widget build(BuildContext context) {
    final fromStatus = note.fromStatus;
    final transition = fromStatus == null
        ? note.toStatus
        : '$fromStatus to ${note.toStatus}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.notes_outlined),
      title: Text(note.note!.trim()),
      subtitle: Text('$transition - ${_formatDateTime(note.changedAt)}'),
    );
  }
}

class _TicketStatusStyle {
  const _TicketStatusStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static _TicketStatusStyle fromStatus(TicketStatus status) {
    return switch (status) {
      TicketStatus.submitted => const _TicketStatusStyle(
        color: Color(0xFF2563EB),
        icon: Icons.inbox_outlined,
      ),
      TicketStatus.assigned => const _TicketStatusStyle(
        color: Color(0xFF7C3AED),
        icon: Icons.assignment_ind_outlined,
      ),
      TicketStatus.processing => const _TicketStatusStyle(
        color: Color(0xFFD97706),
        icon: Icons.sync,
      ),
      TicketStatus.resolved => const _TicketStatusStyle(
        color: Color(0xFF059669),
        icon: Icons.task_alt,
      ),
      TicketStatus.closed => const _TicketStatusStyle(
        color: Color(0xFF475569),
        icon: Icons.lock_outline,
      ),
      TicketStatus.cancelled => const _TicketStatusStyle(
        color: Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
      ),
    };
  }
}

class _StatusConfirmationDialog extends StatefulWidget {
  const _StatusConfirmationDialog({
    required this.status,
    required this.title,
    required this.message,
  });

  final TicketStatus status;
  final String title;
  final String message;

  @override
  State<_StatusConfirmationDialog> createState() =>
      _StatusConfirmationDialogState();
}

class _StatusConfirmationDialogState extends State<_StatusConfirmationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String? _reasonError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reasonController.text.trim();
    if (widget.status == TicketStatus.cancelled && reason.isEmpty) {
      setState(() => _reasonError = 'Cancellation reason is required.');
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            if (widget.status == TicketStatus.cancelled) ...[
              const SizedBox(height: 16),
              TextField(
                key: const Key('admin-cancel-reason-field'),
                controller: _reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Cancellation reason',
                  errorText: _reasonError,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}

class _TicketViewer {
  const _TicketViewer({required this.id, required this.role});

  final int id;
  final UserRole role;
}

class _FeedbackSummary extends StatelessWidget {
  const _FeedbackSummary({required this.feedback});

  final feedback_entity.Feedback feedback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User feedback', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < feedback.rating ? Icons.star : Icons.star_border,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        if (feedback.comment?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 8),
          Text(feedback.comment!),
        ],
      ],
    );
  }
}

final List<String> _knownIssueTypes = IssueType.values
    .map((issueType) => issueType.value)
    .toList(growable: false);

final List<String> _knownPriorities = PriorityLevel.values
    .map((priority) => priority.value)
    .toList(growable: false);

/// Represents a category option for dropdown display.
class _CategoryOption {
  const _CategoryOption({required this.id, required this.label});
  final int id;
  final String label;
}

/// Category dropdown items - must match exactly with create_ticket_page.dart
final List<_CategoryOption> _categoryOptions = [
  _CategoryOption(id: 4, label: 'General Support'),
  _CategoryOption(id: 1, label: 'Network Issue'),
  _CategoryOption(id: 2, label: 'Hardware Issue'),
  _CategoryOption(id: 3, label: 'Software Issue'),
];

/// Validates that categoryId exists in dropdown options.
/// Returns a valid category ID or null (for "None").
int? _resolveValidCategoryId(int? categoryId) {
  if (categoryId == null) return null;
  if (_categoryOptions.any((c) => c.id == categoryId)) return categoryId;
  // categoryId not found - could be deleted/inactive/invalid
  return null;
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

String _formatDateTime(DateTime value) {
  return '${_formatDate(value)} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
