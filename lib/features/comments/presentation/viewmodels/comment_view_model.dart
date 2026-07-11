import 'package:flutter/foundation.dart';

import '../../application/services/i_comment_service.dart';
import '../../domain/entities/ticket_comment.dart';

enum CommentStatus { initial, loading, success, failure }

class CommentViewModel extends ChangeNotifier {
  CommentViewModel(this._service);

  final ICommentService _service;

  CommentStatus _status = CommentStatus.initial;
  String? _errorMessage;
  List<TicketComment> _comments = [];

  CommentStatus get status => _status;
  bool get isLoading => _status == CommentStatus.loading;
  String? get errorMessage => _errorMessage;
  List<TicketComment> get comments => List.unmodifiable(_comments);

  Future<void> loadComments(int ticketId) async {
    _status = CommentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _comments = await _service.getCommentsByTicketId(ticketId);
      _status = CommentStatus.success;
    } catch (e) {
      _status = CommentStatus.failure;
      _errorMessage = 'Failed to load comments: $e';
    }

    notifyListeners();
  }

  Future<bool> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  }) async {
    _status = CommentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final comment = await _service.addComment(
        ticketId: ticketId,
        authorId: authorId,
        content: content,
      );
      _comments = [..._comments, comment];
      _status = CommentStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CommentStatus.failure;
      _errorMessage = 'Failed to add comment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateComment(TicketComment comment) async {
    _status = CommentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateComment(comment);
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        _comments = [
          ..._comments.sublist(0, index),
          comment,
          ..._comments.sublist(index + 1),
        ];
      }
      _status = CommentStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CommentStatus.failure;
      _errorMessage = 'Failed to update comment: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(int id) async {
    _status = CommentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteComment(id);
      _comments = _comments.where((c) => c.id != id).toList();
      _status = CommentStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _status = CommentStatus.failure;
      _errorMessage = 'Failed to delete comment: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
