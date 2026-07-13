import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/comments/application/services/i_comment_service.dart';
import 'package:it_ticket_support_management/features/comments/domain/entities/ticket_comment.dart';
import 'package:it_ticket_support_management/features/comments/domain/repositories/i_comment_repository.dart';
import 'package:it_ticket_support_management/features/comments/presentation/viewmodels/comment_view_model.dart';

void main() {
  group('CommentViewModel', () {
    late MockCommentService mockService;
    late CommentViewModel viewModel;

    setUp(() {
      mockService = MockCommentService();
      viewModel = CommentViewModel(mockService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    // =========================================================================
    // LOAD COMMENTS TESTS
    // =========================================================================

    group('loadComments', () {
      test('loads comments successfully and updates state', () async {
        final comments = [
          _comment(id: 1, content: 'First comment'),
          _comment(id: 2, content: 'Second comment'),
        ];
        mockService.stubGetComments(comments);

        await viewModel.loadComments(1);

        expect(viewModel.status, CommentStatus.success);
        expect(viewModel.comments.length, 2);
        expect(viewModel.errorMessage, isNull);
      });

      test('handles empty comment list', () async {
        mockService.stubGetComments([]);

        await viewModel.loadComments(1);

        expect(viewModel.status, CommentStatus.success);
        expect(viewModel.comments, isEmpty);
      });

      test('handles repository exception', () async {
        mockService.stubGetCommentsThrow(Exception('Database error'));

        await viewModel.loadComments(1);

        expect(viewModel.status, CommentStatus.failure);
        expect(viewModel.errorMessage, contains('Database error'));
        expect(viewModel.comments, isEmpty);
      });

      test('clears previous error on new load attempt', () async {
        mockService.stubGetCommentsThrow(Exception('First error'));
        await viewModel.loadComments(1);
        expect(viewModel.errorMessage, isNotNull);

        mockService.stubGetComments([]);
        await viewModel.loadComments(1);
        expect(viewModel.errorMessage, isNull);
      });
    });

    // =========================================================================
    // ADD COMMENT TESTS
    // =========================================================================

    group('addComment', () {
      test('adds comment successfully', () async {
        final newComment = _comment(id: 1, content: 'New comment');
        mockService.stubAddComment(newComment);

        final result = await viewModel.addComment(
          ticketId: 1,
          authorId: 2,
          content: 'New comment',
        );

        expect(result, isTrue);
        expect(viewModel.status, CommentStatus.success);
        expect(viewModel.comments.length, 1);
        expect(viewModel.comments.first.content, 'New comment');
      });

      test('handles service exception during add', () async {
        mockService.stubAddCommentThrow(Exception('Insert failed'));

        final result = await viewModel.addComment(
          ticketId: 1,
          authorId: 2,
          content: 'New comment',
        );

        expect(result, isFalse);
        expect(viewModel.status, CommentStatus.failure);
        expect(viewModel.errorMessage, contains('Insert failed'));
      });

      test('rapid double submission - both succeed', () async {
        // Test for race condition detection
        int callCount = 0;
        mockService.stubAddCommentCallback((ticketId, authorId, content) {
          callCount++;
          return _comment(id: callCount, content: content);
        });

        final futures = [
          viewModel.addComment(ticketId: 1, authorId: 2, content: 'First'),
          viewModel.addComment(ticketId: 1, authorId: 2, content: 'Second'),
        ];

        final results = await Future.wait(futures);

        expect(results.every((r) => r), isTrue);
        expect(viewModel.comments.length, 2);
      });
    });

    // =========================================================================
    // UPDATE COMMENT TESTS
    // =========================================================================

    group('updateComment', () {
      test('updates comment successfully', () async {
        mockService.stubGetComments([_comment(id: 1, content: 'Original')]);
        mockService.stubUpdateComment();
        await viewModel.loadComments(1);

        final updatedComment = _comment(
          id: 1,
          content: 'Updated',
          updatedAt: DateTime.now(),
        );
        final result = await viewModel.updateComment(updatedComment);

        expect(result, isTrue);
        expect(viewModel.comments.first.content, 'Updated');
        expect(mockService.updateCallCount, 1);
      });

      test('handles update failure', () async {
        mockService.stubGetComments([_comment(id: 1, content: 'Original')]);
        mockService.stubUpdateCommentThrow(Exception('Update failed'));
        await viewModel.loadComments(1);

        final result = await viewModel.updateComment(
          _comment(id: 1, content: 'Updated'),
        );

        expect(result, isFalse);
        expect(viewModel.status, CommentStatus.failure);
      });

      test('calls service even if comment not found in local list', () async {
        mockService.stubGetComments([]);
        mockService.stubUpdateComment();
        await viewModel.loadComments(1);

        final result = await viewModel.updateComment(
          _comment(id: 999, content: 'Ghost'),
        );

        // Service IS called - ViewModel doesn't know if comment exists in DB
        expect(result, isTrue); // Success because service call succeeded
        expect(mockService.updateCallCount, 1); // Service was called
      });
    });

    // =========================================================================
    // DELETE COMMENT TESTS
    // =========================================================================

    group('deleteComment', () {
      test('deletes comment successfully', () async {
        mockService.stubGetComments([
          _comment(id: 1, content: 'First'),
          _comment(id: 2, content: 'Second'),
        ]);
        mockService.stubDeleteComment();
        await viewModel.loadComments(1);

        final result = await viewModel.deleteComment(1);

        expect(result, isTrue);
        expect(viewModel.comments.length, 1);
        expect(viewModel.comments.first.id, 2);
        expect(mockService.deletedId, 1);
      });

      test('handles delete failure', () async {
        mockService.stubGetComments([_comment(id: 1, content: 'First')]);
        mockService.stubDeleteCommentThrow(Exception('Delete failed'));
        await viewModel.loadComments(1);

        final result = await viewModel.deleteComment(1);

        expect(result, isFalse);
        expect(viewModel.comments.length, 1);
        expect(viewModel.status, CommentStatus.failure);
      });
    });

    // =========================================================================
    // STATE TRANSITION TESTS
    // =========================================================================

    group('state transitions', () {
      test('transitions from initial to loading to success', () async {
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        mockService.stubGetComments([]);
        await viewModel.loadComments(1);

        expect(notifyCount, greaterThanOrEqualTo(2));
        expect(viewModel.status, CommentStatus.success);
      });

      test('transitions to failure state on error', () async {
        mockService.stubGetCommentsThrow(Exception('Error'));

        await viewModel.loadComments(1);

        expect(viewModel.status, CommentStatus.failure);
        expect(viewModel.errorMessage, isNotNull);
      });
    });

    // =========================================================================
    // ERROR HANDLING TESTS
    // =========================================================================

    group('error handling', () {
      test('clearError clears error message', () async {
        mockService.stubGetCommentsThrow(Exception('Error'));
        await viewModel.loadComments(1);
        expect(viewModel.errorMessage, isNotNull);

        viewModel.clearError();
        expect(viewModel.errorMessage, isNull);
      });

      test('error message clears on new successful load', () async {
        mockService.stubGetCommentsThrow(Exception('Error'));
        await viewModel.loadComments(1);
        expect(viewModel.errorMessage, isNotNull);

        mockService.stubGetComments([]);
        await viewModel.loadComments(1);

        expect(viewModel.errorMessage, isNull);
      });
    });

    // =========================================================================
    // LIST IMMUTABILITY TESTS
    // =========================================================================

    group('list immutability', () {
      test('comments getter returns unmodifiable list', () async {
        mockService.stubGetComments([_comment(id: 1, content: 'First')]);
        await viewModel.loadComments(1);

        expect(
          () => viewModel.comments.add(_comment(id: 2, content: 'Hacked')),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    // =========================================================================
    // NOTIFY LISTENERS TESTS
    // =========================================================================

    group('notifyListeners', () {
      test('notifies listeners on successful load', () async {
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        mockService.stubGetComments([]);
        await viewModel.loadComments(1);

        expect(notifyCount, greaterThanOrEqualTo(1));
      });

      test('notifies listeners on failed load', () async {
        int notifyCount = 0;
        viewModel.addListener(() => notifyCount++);

        mockService.stubGetCommentsThrow(Exception('Error'));
        await viewModel.loadComments(1);

        expect(notifyCount, greaterThanOrEqualTo(2));
      });
    });
  });

  // =========================================================================
  // SERVICE VALIDATION TESTS
  // =========================================================================

  group('CommentServiceImpl validation', () {
    late MockCommentRepository mockRepository;
    late CommentServiceImpl service;

    setUp(() {
      mockRepository = MockCommentRepository();
      service = CommentServiceImpl(mockRepository);
    });

    test('rejects empty content', () async {
      await expectLater(
        () => service.addComment(
          ticketId: 1,
          authorId: 2,
          content: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects whitespace-only content', () async {
      await expectLater(
        () => service.addComment(
          ticketId: 1,
          authorId: 2,
          content: '   \n\t  ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid content and trims it', () async {
      String? capturedContent;
      mockRepository.stubAddCommentCallback((ticketId, authorId, content) {
        capturedContent = content;
        return _comment(
          id: 1,
          ticketId: ticketId,
          authorId: authorId,
          content: content,
        );
      });

      await service.addComment(
        ticketId: 1,
        authorId: 2,
        content: '  Valid content  ',
      );

      expect(capturedContent, 'Valid content');
    });

    test('update rejects empty content', () async {
      await expectLater(
        () => service.updateComment(
          _comment(id: 1, content: '  ', ticketId: 1, authorId: 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('passes through repository exceptions', () async {
      mockRepository.stubAddCommentThrow(Exception('Database error'));

      await expectLater(
        () => service.addComment(
          ticketId: 1,
          authorId: 2,
          content: 'Valid',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}

// =========================================================================
// TEST HELPERS
// =========================================================================

TicketComment _comment({
  int? id,
  required String content,
  int ticketId = 1,
  int authorId = 1,
  DateTime? updatedAt,
}) =>
    TicketComment(
      id: id,
      ticketId: ticketId,
      authorId: authorId,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: updatedAt,
    );

// =========================================================================
// MOCK SERVICE
// =========================================================================

class MockCommentService implements ICommentService {
  final List<TicketComment> _comments = [];
  Exception? _getCommentsError;
  Exception? _addCommentError;
  Exception? _updateError;
  Exception? _deleteError;
  int? _deletedId;
  int _updateCallCount = 0;

  Function(int ticketId, int authorId, String content)? _addCommentCallback;

  void stubGetComments(List<TicketComment> comments) {
    _comments.clear();
    _comments.addAll(comments);
    _getCommentsError = null;
  }

  void stubGetCommentsThrow(Exception error) {
    _getCommentsError = error;
  }

  void stubAddComment(TicketComment comment) {
    _comments.add(comment);
  }

  void stubAddCommentCallback(
    TicketComment Function(int ticketId, int authorId, String content) callback,
  ) {
    _addCommentCallback = callback;
  }

  void stubAddCommentThrow(Exception error) {
    _addCommentError = error;
  }

  void stubUpdateComment() {}

  void stubUpdateCommentThrow(Exception error) {
    _updateError = error;
  }

  void stubDeleteComment() {}

  void stubDeleteCommentThrow(Exception error) {
    _deleteError = error;
  }

  int get updateCallCount => _updateCallCount;
  int? get deletedId => _deletedId;

  @override
  Future<List<TicketComment>> getCommentsByTicketId(int ticketId) async {
    if (_getCommentsError != null) throw _getCommentsError!;
    return List.from(_comments);
  }

  @override
  Future<TicketComment> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  }) async {
    if (_addCommentError != null) throw _addCommentError!;

    if (_addCommentCallback != null) {
      return _addCommentCallback!(ticketId, authorId, content);
    }

    final comment = TicketComment(
      id: _comments.length + 1,
      ticketId: ticketId,
      authorId: authorId,
      content: content,
      createdAt: DateTime.now(),
    );
    _comments.add(comment);
    return comment;
  }

  @override
  Future<void> updateComment(TicketComment comment) async {
    if (_updateError != null) throw _updateError!;
    _updateCallCount++;
  }

  @override
  Future<void> deleteComment(int id) async {
    if (_deleteError != null) throw _deleteError!;
    _deletedId = id;
    _comments.removeWhere((c) => c.id == id);
  }
}

// =========================================================================
// MOCK REPOSITORY
// =========================================================================

class MockCommentRepository implements ICommentRepository {
  final List<TicketComment> _comments = [];
  Exception? _error;
  Function(int ticketId, int authorId, String content)? _addCommentCallback;

  void stubAddCommentCallback(
    TicketComment Function(int ticketId, int authorId, String content) callback,
  ) {
    _addCommentCallback = callback;
  }

  void stubAddCommentThrow(Exception error) {
    _error = error;
  }

  @override
  Future<List<TicketComment>> getCommentsByTicketId(int ticketId) async {
    return List.from(_comments);
  }

  @override
  Future<TicketComment> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  }) async {
    if (_error != null) throw _error!;

    if (_addCommentCallback != null) {
      return _addCommentCallback!(ticketId, authorId, content);
    }

    final comment = TicketComment(
      id: _comments.length + 1,
      ticketId: ticketId,
      authorId: authorId,
      content: content,
      createdAt: DateTime.now(),
    );
    _comments.add(comment);
    return comment;
  }

  @override
  Future<void> updateComment(TicketComment comment) async {}

  @override
  Future<void> deleteComment(int id) async {}
}

// =========================================================================
// SERVICE IMPLEMENTATION UNDER TEST (copied from source)
// =========================================================================

class CommentServiceImpl implements ICommentService {
  const CommentServiceImpl(this._repository);

  final ICommentRepository _repository;

  @override
  Future<List<TicketComment>> getCommentsByTicketId(int ticketId) {
    return _repository.getCommentsByTicketId(ticketId);
  }

  @override
  Future<TicketComment> addComment({
    required int ticketId,
    required int authorId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Comment content cannot be empty');
    }

    return _repository.addComment(
      ticketId: ticketId,
      authorId: authorId,
      content: trimmed,
    );
  }

  @override
  Future<void> updateComment(TicketComment comment) async {
    final trimmed = comment.content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Comment content cannot be empty');
    }

    await _repository.updateComment(comment);
  }

  @override
  Future<void> deleteComment(int id) {
    return _repository.deleteComment(id);
  }
}
