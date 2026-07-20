import 'package:flutter/foundation.dart';

import '../../application/services/i_feedback_service.dart';
import '../../domain/entities/feedback.dart';

class FeedbackViewModel extends ChangeNotifier {
  FeedbackViewModel(this._service);

  final IFeedbackService _service;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  Feedback? _feedback;
  List<Feedback> _userFeedbacks = [];
  int _rating = 0;
  String _comment = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Feedback? get feedback => _feedback;
  List<Feedback> get userFeedbacks => List.unmodifiable(_userFeedbacks);
  int get rating => _rating;
  String get comment => _comment;

  Future<void> loadFeedbackByTicketId(int ticketId) async {
    _isLoading = true;
    _errorMessage = null;
    _feedback = null;
    _rating = 0;
    _comment = '';
    _safeNotifyListeners();

    try {
      _feedback = await _service.getFeedbackByTicketId(ticketId);
      final feedback = _feedback;
      if (feedback != null) {
        _rating = feedback.rating;
        _comment = feedback.comment ?? '';
      }
    } catch (e) {
      _feedback = null;
      _errorMessage = 'Failed to load feedback: $e';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> loadFeedbackByUserId(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    _userFeedbacks = [];
    _safeNotifyListeners();

    try {
      _userFeedbacks = await _service.getFeedbackByUserId(userId);
    } catch (e) {
      _userFeedbacks = [];
      _errorMessage = 'Failed to load feedback: $e';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _feedback = await _service.submitFeedback(
        ticketId: ticketId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
      _rating = _feedback?.rating ?? rating;
      _comment = _feedback?.comment ?? comment ?? '';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit feedback: $e';
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> updateFeedback({
    required int feedbackId,
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
    required DateTime createdAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final feedback = Feedback(
        id: feedbackId,
        ticketId: ticketId,
        userId: userId,
        rating: rating,
        comment: comment,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
      await _service.updateFeedback(feedback);
      _feedback = feedback;
      _rating = rating;
      _comment = comment ?? '';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update feedback: $e';
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> deleteFeedback(int id) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      await _service.deleteFeedback(id);
      _feedback = null;
      _rating = 0;
      _comment = '';
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete feedback: $e';
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void updateRating(int value) {
    _rating = value;
    _safeNotifyListeners();
  }

  void updateComment(String value) {
    _comment = value;
    _safeNotifyListeners();
  }

  void resetForm() {
    _rating = 0;
    _comment = '';
    _safeNotifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
