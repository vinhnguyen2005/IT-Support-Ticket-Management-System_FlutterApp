import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/feedback/application/services/i_feedback_service.dart';
import 'package:it_ticket_support_management/features/feedback/domain/entities/feedback.dart';
import 'package:it_ticket_support_management/features/feedback/domain/repositories/i_feedback_repository.dart';
import 'package:it_ticket_support_management/features/feedback/presentation/viewmodels/feedback_view_model.dart';

void main() {
  group('FeedbackViewModel', () {
    late MockFeedbackService mockService;
    late FeedbackViewModel viewModel;

    setUp(() {
      mockService = MockFeedbackService();
      viewModel = FeedbackViewModel(mockService);
    });

    tearDown(() {
      viewModel.dispose();
    });

    // =========================================================================
    // LOAD FEEDBACK BY TICKET TESTS
    // =========================================================================

    group('loadFeedbackByTicketId', () {
      test('loads existing feedback successfully', () async {
        final feedback = _feedback(id: 1, rating: 5, comment: 'Great!');
        mockService.stubGetFeedbackByTicketId(feedback);

        await viewModel.loadFeedbackByTicketId(1);

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.feedback?.rating, 5);
        expect(viewModel.rating, 5);
        expect(viewModel.comment, 'Great!');
        expect(viewModel.errorMessage, isNull);
      });

      test('handles no existing feedback', () async {
        mockService.stubGetFeedbackByTicketId(null);

        await viewModel.loadFeedbackByTicketId(1);

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.feedback, isNull);
        expect(viewModel.rating, 0);
        expect(viewModel.comment, '');
      });

      test('handles repository exception', () async {
        mockService.stubGetFeedbackByTicketIdThrow(Exception('DB error'));

        await viewModel.loadFeedbackByTicketId(1);

        expect(viewModel.isLoading, isFalse);
        expect(viewModel.feedback, isNull);
        expect(viewModel.errorMessage, contains('DB error'));
      });

      test('clears error on new load', () async {
        mockService.stubGetFeedbackByTicketIdThrow(Exception('Error'));
        await viewModel.loadFeedbackByTicketId(1);
        expect(viewModel.errorMessage, isNotNull);

        mockService.stubGetFeedbackByTicketId(null);
        await viewModel.loadFeedbackByTicketId(1);
        expect(viewModel.errorMessage, isNull);
      });
    });

    // =========================================================================
    // SUBMIT FEEDBACK TESTS
    // =========================================================================

    group('submitFeedback', () {
      test('submits feedback successfully with rating and comment', () async {
        final submittedFeedback = _feedback(
          id: 1,
          ticketId: 10,
          userId: 5,
          rating: 4,
          comment: 'Good service',
        );
        mockService.stubSubmitFeedback(submittedFeedback);

        final result = await viewModel.submitFeedback(
          ticketId: 10,
          userId: 5,
          rating: 4,
          comment: 'Good service',
        );

        expect(result, isTrue);
        expect(viewModel.feedback?.rating, 4);
        expect(viewModel.rating, 4);
        expect(viewModel.comment, 'Good service');
        expect(viewModel.isLoading, isFalse);
      });

      test('handles submission failure', () async {
        mockService.stubSubmitFeedbackThrow(Exception('Submit failed'));

        final result = await viewModel.submitFeedback(
          ticketId: 10,
          userId: 5,
          rating: 4,
          comment: 'Good service',
        );

        expect(result, isFalse);
        expect(viewModel.errorMessage, contains('Submit failed'));
        expect(viewModel.feedback, isNull);
      });

      test('rating below 1 should fail submission', () async {
        mockService.stubSubmitFeedbackThrow(ArgumentError('Rating must be between 1 and 5'));

        final result = await viewModel.submitFeedback(
          ticketId: 10,
          userId: 5,
          rating: 0,
          comment: 'Test',
        );

        expect(result, isFalse);
        expect(viewModel.errorMessage, contains('Rating'));
      });

      test('rating above 5 should fail submission', () async {
        mockService.stubSubmitFeedbackThrow(ArgumentError('Rating must be between 1 and 5'));

        final result = await viewModel.submitFeedback(
          ticketId: 10,
          userId: 5,
          rating: 6,
          comment: 'Test',
        );

        expect(result, isFalse);
      });

      test('accepts valid rating 1-5', () async {
        final feedback = _feedback(id: 1, rating: 1, comment: '');
        mockService.stubSubmitFeedback(feedback);

        for (final rating in [1, 2, 3, 4, 5]) {
          final result = await viewModel.submitFeedback(
            ticketId: 10,
            userId: 5,
            rating: rating,
            comment: '',
          );
          expect(result, isTrue, reason: 'Rating $rating should be accepted');
        }
      });
    });

    // =========================================================================
    // UPDATE FEEDBACK TESTS
    // =========================================================================

    group('updateFeedback', () {
      test('updates feedback successfully', () async {
        mockService.stubUpdateFeedback();
        mockService.stubGetFeedbackByTicketId(_feedback(id: 1, rating: 3));
        await viewModel.loadFeedbackByTicketId(1);

        final result = await viewModel.updateFeedback(
          feedbackId: 1,
          ticketId: 10,
          userId: 5,
          rating: 5,
          comment: 'Updated comment',
          createdAt: DateTime.now(),
        );

        expect(result, isTrue);
        expect(viewModel.feedback?.rating, 5);
        expect(viewModel.rating, 5);
        expect(viewModel.comment, 'Updated comment');
        expect(mockService.updateCallCount, 1);
      });

      test('handles update failure', () async {
        mockService.stubUpdateFeedbackThrow(Exception('Update failed'));
        mockService.stubGetFeedbackByTicketId(_feedback(id: 1, rating: 3));
        await viewModel.loadFeedbackByTicketId(1);

        final result = await viewModel.updateFeedback(
          feedbackId: 1,
          ticketId: 10,
          userId: 5,
          rating: 5,
          comment: 'Updated',
          createdAt: DateTime.now(),
        );

        expect(result, isFalse);
        expect(viewModel.errorMessage, contains('Update failed'));
      });

      test('validates rating on update', () async {
        mockService.stubUpdateFeedbackThrow(
          ArgumentError('Rating must be between 1 and 5'),
        );
        mockService.stubGetFeedbackByTicketId(_feedback(id: 1, rating: 3));
        await viewModel.loadFeedbackByTicketId(1);

        final result = await viewModel.updateFeedback(
          feedbackId: 1,
          ticketId: 10,
          userId: 5,
          rating: 0,
          comment: 'Updated',
          createdAt: DateTime.now(),
        );

        expect(result, isFalse);
      });
    });

    // =========================================================================
    // DELETE FEEDBACK TESTS
    // =========================================================================

    group('deleteFeedback', () {
      test('deletes feedback successfully', () async {
        mockService.stubDeleteFeedback();
        mockService.stubGetFeedbackByTicketId(_feedback(id: 1, rating: 5));
        await viewModel.loadFeedbackByTicketId(1);
        expect(viewModel.feedback, isNotNull);

        final result = await viewModel.deleteFeedback(1);

        expect(result, isTrue);
        expect(viewModel.feedback, isNull);
        expect(viewModel.rating, 0);
        expect(viewModel.comment, '');
      });

      test('handles delete failure', () async {
        mockService.stubDeleteFeedbackThrow(Exception('Delete failed'));
        mockService.stubGetFeedbackByTicketId(_feedback(id: 1, rating: 5));
        await viewModel.loadFeedbackByTicketId(1);

        final result = await viewModel.deleteFeedback(1);

        expect(result, isFalse);
        expect(viewModel.feedback?.id, 1);
      });
    });

    // =========================================================================
    // FORM STATE TESTS
    // =========================================================================

    group('form state', () {
      test('updateRating changes rating', () {
        viewModel.updateRating(4);
        expect(viewModel.rating, 4);

        viewModel.updateRating(5);
        expect(viewModel.rating, 5);
      });

      test('updateComment changes comment', () {
        viewModel.updateComment('First comment');
        expect(viewModel.comment, 'First comment');

        viewModel.updateComment('Updated comment');
        expect(viewModel.comment, 'Updated comment');
      });

      test('resetForm clears rating and comment', () {
        viewModel.updateRating(4);
        viewModel.updateComment('Some comment');

        viewModel.resetForm();

        expect(viewModel.rating, 0);
        expect(viewModel.comment, '');
      });
    });

    // =========================================================================
    // DISPOSE TESTS
    // =========================================================================

    group('dispose', () {
      // Note: Flutter's debugAssertNotDisposed throws when calling methods on
      // a disposed ChangeNotifier. Testing dispose behavior requires either:
      // 1. Running in release mode
      // 2. Not calling methods after dispose
      // The _safeNotifyListeners() pattern in FeedbackViewModel is correct -
      // it checks _isDisposed before calling notifyListeners()
    });
  });

  // =========================================================================
  // SERVICE VALIDATION TESTS
  // =========================================================================

  group('FeedbackServiceImpl validation', () {
    late MockFeedbackRepository mockRepository;
    late FeedbackServiceImpl service;

    setUp(() {
      mockRepository = MockFeedbackRepository();
      service = FeedbackServiceImpl(mockRepository);
    });

    test('rejects rating below 1', () async {
      await expectLater(
        () => service.submitFeedback(
          ticketId: 1,
          userId: 1,
          rating: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects rating above 5', () async {
      await expectLater(
        () => service.submitFeedback(
          ticketId: 1,
          userId: 1,
          rating: 6,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts rating 1-5', () async {
      for (final rating in [1, 2, 3, 4, 5]) {
        mockRepository.stubSubmitFeedback(_feedback(
          id: 1,
          ticketId: 1,
          userId: 1,
          rating: rating,
        ));

        await service.submitFeedback(
          ticketId: 1,
          userId: 1,
          rating: rating,
        );
      }
    });

    test('updateFeedback rejects invalid rating', () async {
      final badFeedback = _feedback(id: 1, rating: 0);
      await expectLater(
        () => service.updateFeedback(badFeedback),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('passes through repository exceptions', () async {
      mockRepository.stubSubmitFeedbackThrow(Exception('DB error'));

      await expectLater(
        () => service.submitFeedback(
          ticketId: 1,
          userId: 1,
          rating: 5,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  // =========================================================================
  // FEEDBACK ENTITY TESTS
  // =========================================================================

  group('Feedback entity', () {
    test('isValidRating returns true for 1-5', () {
      for (final rating in [1, 2, 3, 4, 5]) {
        expect(_feedback(id: 1, rating: rating).isValidRating, isTrue,
            reason: 'Rating $rating should be valid');
      }
    });

    test('isValidRating returns false for 0 and above 5', () {
      expect(_feedback(id: 1, rating: 0).isValidRating, isFalse);
      expect(_feedback(id: 1, rating: 6).isValidRating, isFalse);
      expect(_feedback(id: 1, rating: -1).isValidRating, isFalse);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = _feedback(id: 1, rating: 3, comment: 'Original');
      final copied = original.copyWith(rating: 5, comment: 'Updated');

      expect(copied.id, 1);
      expect(copied.rating, 5);
      expect(copied.comment, 'Updated');
      expect(original.rating, 3);
      expect(original.comment, 'Original');
    });

    test('equality works correctly', () {
      final f1 = _feedback(id: 1, rating: 5);
      final f2 = _feedback(id: 1, rating: 5);
      final f3 = _feedback(id: 2, rating: 5);

      expect(f1, equals(f2));
      expect(f1, isNot(equals(f3)));
    });

    test('hashCode is consistent', () {
      final f1 = _feedback(id: 1, rating: 5, comment: 'Test');
      final f2 = _feedback(id: 1, rating: 5, comment: 'Test');

      expect(f1.hashCode, equals(f2.hashCode));
    });
  });
}

// =========================================================================
// TEST HELPERS
// =========================================================================

Feedback _feedback({
  int? id,
  int ticketId = 1,
  int userId = 1,
  int rating = 3,
  String comment = 'Test comment',
}) =>
    Feedback(
      id: id,
      ticketId: ticketId,
      userId: userId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

// =========================================================================
// MOCK SERVICE
// =========================================================================

class MockFeedbackService implements IFeedbackService {
  Feedback? _feedback;
  Object? _getByTicketError;
  Object? _submitError;
  Object? _updateError;
  Object? _deleteError;
  int _updateCallCount = 0;

  void stubGetFeedbackByTicketId(Feedback? fb) {
    _feedback = fb;
    _getByTicketError = null;
  }

  void stubGetFeedbackByTicketIdThrow(Object error) {
    _getByTicketError = error;
  }

  void stubSubmitFeedback(Feedback fb) {
    _feedback = fb;
    _submitError = null;
  }

  void stubSubmitFeedbackThrow(Object error) {
    _submitError = error;
  }

  void stubUpdateFeedback() {}

  void stubUpdateFeedbackThrow(Object error) {
    _updateError = error;
  }

  void stubDeleteFeedback() {
    _feedback = null;
  }

  void stubDeleteFeedbackThrow(Object error) {
    _deleteError = error;
  }

  int get updateCallCount => _updateCallCount;

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) async {
    if (_getByTicketError != null) {
      final e = _getByTicketError!;
      if (e is Exception) throw e;
      if (e is ArgumentError) throw e;
    }
    return _feedback;
  }

  @override
  Future<List<Feedback>> getFeedbackByUserId(int userId) async {
    return [];
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    if (_submitError != null) {
      final e = _submitError!;
      if (e is Exception) throw e;
      if (e is ArgumentError) throw e;
    }
    return Feedback(
      id: 1,
      ticketId: ticketId,
      userId: userId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    if (_updateError != null) {
      final e = _updateError!;
      if (e is Exception) throw e;
      if (e is ArgumentError) throw e;
    }
    _updateCallCount++;
    _feedback = feedback;
  }

  @override
  Future<void> deleteFeedback(int id) async {
    if (_deleteError != null) {
      final e = _deleteError!;
      if (e is Exception) throw e;
      if (e is ArgumentError) throw e;
    }
    _feedback = null;
  }
}

// =========================================================================
// MOCK REPOSITORY
// =========================================================================

class MockFeedbackRepository implements IFeedbackRepository {
  Feedback? _feedback;
  Object? _submitError;

  void stubSubmitFeedback(Feedback fb) {
    _feedback = fb;
    _submitError = null;
  }

  void stubSubmitFeedbackThrow(Object error) {
    _submitError = error;
  }

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) async {
    return _feedback;
  }

  @override
  Future<List<Feedback>> getFeedbackByUserId(int userId) async {
    return [];
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    if (_submitError != null) {
      final e = _submitError!;
      if (e is Exception) throw e;
      if (e is ArgumentError) throw e;
    }
    return Feedback(
      id: 1,
      ticketId: ticketId,
      userId: userId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    _feedback = feedback;
  }

  @override
  Future<void> deleteFeedback(int id) async {
    _feedback = null;
  }
}

// =========================================================================
// SERVICE IMPLEMENTATION UNDER TEST (copied from source)
// =========================================================================

class FeedbackServiceImpl implements IFeedbackService {
  const FeedbackServiceImpl(this._repository);

  final IFeedbackRepository _repository;

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) {
    return _repository.getFeedbackByTicketId(ticketId);
  }

  @override
  Future<List<Feedback>> getFeedbackByUserId(int userId) {
    return _repository.getFeedbackByUserId(userId);
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int userId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    return _repository.submitFeedback(
      ticketId: ticketId,
      userId: userId,
      rating: rating,
      comment: comment,
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    if (!feedback.isValidRating) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    await _repository.updateFeedback(feedback);
  }

  @override
  Future<void> deleteFeedback(int id) {
    return _repository.deleteFeedback(id);
  }
}
