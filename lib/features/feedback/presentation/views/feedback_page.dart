import 'package:flutter/material.dart';

import '../../domain/entities/feedback.dart' as entities;
import '../../../../core/widgets/app_states.dart';
import '../viewmodels/feedback_view_model.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({
    super.key,
    required this.ticketId,
    required this.reviewerUserId,
    required this.revieweeUserId,
    this.existingFeedback,
    required this.viewModel,
  });

  final int ticketId;
  final int reviewerUserId;
  final int revieweeUserId;
  final entities.Feedback? existingFeedback;
  final FeedbackViewModel viewModel;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const int _maxCommentLength = 1000;
  late int _staffRating;
  late int _supportRating;
  late TextEditingController _commentController;
  bool _hasSubmitted = false;
  bool _hasSyncedLoadedFeedback = false;

  @override
  void initState() {
    super.initState();
    _staffRating = widget.existingFeedback?.staffRating ?? 0;
    _supportRating = widget.existingFeedback?.supportRating ?? 0;
    _commentController = TextEditingController(
      text: widget.existingFeedback?.comment ?? '',
    );
    _hasSubmitted = widget.existingFeedback != null;
    widget.viewModel.loadFeedbackByTicketId(widget.ticketId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_staffRating == 0 || _supportRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both ratings')),
      );
      return;
    }

    final existingFeedback =
        widget.viewModel.feedback ?? widget.existingFeedback;
    final wasSubmitted = existingFeedback != null || _hasSubmitted;
    final comment = _commentController.text.trim().isEmpty
        ? null
        : _commentController.text.trim();

    bool success;
    if (existingFeedback?.id != null) {
      success = await widget.viewModel.updateFeedback(
        feedbackId: existingFeedback!.id!,
        ticketId: widget.ticketId,
        reviewerUserId: widget.reviewerUserId,
        revieweeUserId: widget.revieweeUserId,
        staffRating: _staffRating,
        supportRating: _supportRating,
        comment: comment,
        createdAt: existingFeedback.createdAt,
      );
    } else {
      success = await widget.viewModel.submitFeedback(
        ticketId: widget.ticketId,
        reviewerUserId: widget.reviewerUserId,
        revieweeUserId: widget.revieweeUserId,
        staffRating: _staffRating,
        supportRating: _supportRating,
        comment: comment,
      );
    }

    if (!mounted) return;

    if (success) {
      setState(() => _hasSubmitted = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSubmitted ? 'Feedback updated!' : 'Feedback submitted!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage ?? 'An error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final isLoading = widget.viewModel.isLoading;
        _syncLoadedFeedback();

        return Scaffold(
          appBar: AppBar(title: const Text('Feedback')),
          body: AppContent(
            maxWidth: 680,
            child: SingleChildScrollView(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.viewModel.errorMessage != null &&
                          !isLoading) ...[
                        Material(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(widget.viewModel.errorMessage!),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        'Rate the assigned staff member',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RatingSelector(
                        rating: _staffRating,
                        enabled: !isLoading,
                        onChanged: (value) =>
                            setState(() => _staffRating = value),
                      ),
                      if (_staffRating > 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getRatingLabel(_staffRating),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Rate your overall ticket support experience',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RatingSelector(
                        rating: _supportRating,
                        enabled: !isLoading,
                        onChanged: (value) =>
                            setState(() => _supportRating = value),
                      ),
                      if (_supportRating > 0) ...[
                        const SizedBox(height: 8),
                        Center(child: Text(_getRatingLabel(_supportRating))),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _commentController,
                        enabled: !isLoading,
                        maxLines: 4,
                        maxLength: _maxCommentLength,
                        decoration: const InputDecoration(
                          labelText: 'Comment (optional)',
                          hintText: 'Share your experience...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _hasSubmitted
                                      ? 'Update Feedback'
                                      : 'Submit Feedback',
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _syncLoadedFeedback() {
    if (_hasSyncedLoadedFeedback) {
      return;
    }

    final loadedFeedback = widget.viewModel.feedback;
    if (loadedFeedback == null) {
      return;
    }

    _staffRating = loadedFeedback.staffRating;
    _supportRating = loadedFeedback.supportRating;
    _commentController.text = loadedFeedback.comment ?? '';
    _hasSubmitted = true;
    _hasSyncedLoadedFeedback = true;
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Average';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
    required this.rating,
    required this.enabled,
    required this.onChanged,
  });

  final int rating;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Center(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final value = index + 1;
        return IconButton(
          icon: Icon(
            value <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 40,
            color: value <= rating ? Colors.amber : Colors.grey[400],
          ),
          onPressed: enabled ? () => onChanged(value) : null,
        );
      }),
    ),
  );
}
