import 'package:flutter/material.dart';

import '../../domain/entities/ticket_comment.dart';
import '../viewmodels/comment_view_model.dart';

class CommentSection extends StatefulWidget {
  const CommentSection({
    super.key,
    required this.ticketId,
    required this.currentUserId,
    required this.viewModel,
    this.isLocked = false,
  });

  final int ticketId;
  final int currentUserId;
  final CommentViewModel viewModel;
  final bool isLocked;

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _controller = TextEditingController();
  int? _editingCommentId;

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadComments(widget.ticketId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    bool success;
    if (_editingCommentId != null) {
      final existing = widget.viewModel.comments.firstWhere(
        (c) => c.id == _editingCommentId,
      );
      success = await widget.viewModel.updateComment(
        TicketComment(
          id: existing.id,
          ticketId: existing.ticketId,
          authorId: existing.authorId,
          authorName: existing.authorName,
          content: text,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      if (success) setState(() => _editingCommentId = null);
    } else {
      success = await widget.viewModel.addComment(
        ticketId: widget.ticketId,
        authorId: widget.currentUserId,
        content: text,
      );
    }

    if (success) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.errorMessage ?? 'Unable to save comment.',
          ),
        ),
      );
    }
  }

  void _startEdit(TicketComment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _controller.text = comment.content;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCommentId = null;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final comments = widget.viewModel.comments;
        final isLoading = widget.viewModel.isLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Comments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _buildCommentList(
                context,
                comments: comments,
                isLoading: isLoading,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !isLoading && !widget.isLocked,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: _editingCommentId != null
                            ? 'Editing comment...'
                            : 'Add a comment...',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_editingCommentId != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: isLoading || widget.isLocked
                          ? null
                          : _cancelEdit,
                    ),
                  IconButton(
                    tooltip: 'Send comment',
                    icon: const Icon(Icons.send),
                    onPressed: isLoading || widget.isLocked ? null : _submit,
                  ),
                ],
              ),
            ),
            if (widget.isLocked)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Comments are closed because this ticket is complete.',
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentList(
    BuildContext context, {
    required List<TicketComment> comments,
    required bool isLoading,
  }) {
    if (isLoading && comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            widget.viewModel.errorMessage ?? 'No comments yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.viewModel.errorMessage == null
                  ? Colors.grey
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _CommentTile(
          comment: comment,
          isOwner: !widget.isLocked && comment.authorId == widget.currentUserId,
          isEditing: _editingCommentId == comment.id,
          onEdit: widget.isLocked ? () {} : () => _startEdit(comment),
          onDelete: comment.id == null
              ? () {}
              : widget.isLocked
              ? () {}
              : () => widget.viewModel.deleteComment(comment.id!),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.isOwner,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
  });

  final TicketComment comment;
  final bool isOwner;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text((comment.authorName ?? 'U')[0].toUpperCase()),
      ),
      title: Row(
        children: [
          Text(
            comment.authorName ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (comment.updatedAt != null) ...[
            const SizedBox(width: 8),
            Icon(Icons.edit, size: 14, color: Colors.grey[600]),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.content),
          const SizedBox(height: 4),
          Text(
            _formatDate(comment.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: isOwner && !isEditing
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
