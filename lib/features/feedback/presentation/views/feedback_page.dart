import 'package:flutter/material.dart';

import '../../domain/entities/feedback.dart' as entities;
import '../viewmodels/feedback_view_model.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({
    super.key,
    required this.ticketId,
    required this.userId,
    this.existingFeedback,
    required this.viewModel,
  });

  final int ticketId;
  final int userId;
  final entities.Feedback? existingFeedback;
  final FeedbackViewModel viewModel;

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late int _rating;
  late TextEditingController _commentController;
  bool _hasSubmitted = false;
  bool _hasSyncedLoadedFeedback = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingFeedback?.rating ?? 0;
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
    if (_rating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
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
        userId: widget.userId,
        rating: _rating,
        comment: comment,
        createdAt: existingFeedback.createdAt,
      );
    } else {
      success = await widget.viewModel.submitFeedback(
        ticketId: widget.ticketId,
        userId: widget.userId,
        rating: _rating,
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How was your experience?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 40,
                          color: starValue <= _rating
                              ? Colors.amber
                              : Colors.grey[400],
                        ),
                        onPressed: isLoading
                            ? null
                            : () => setState(() => _rating = starValue),
                      );
                    }),
                  ),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _getRatingLabel(_rating),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextField(
                  controller: _commentController,
                  enabled: !isLoading,
                  maxLines: 4,
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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

    _rating = loadedFeedback.rating;
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
