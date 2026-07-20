import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/feedback/application/services/i_feedback_service.dart';
import 'package:it_ticket_support_management/features/feedback/domain/entities/feedback.dart';
import 'package:it_ticket_support_management/features/feedback/presentation/viewmodels/feedback_view_model.dart';

void main() {
  group('FeedbackViewModel', () {
    late _FakeFeedbackService service;
    late FeedbackViewModel viewModel;

    setUp(() {
      service = _FakeFeedbackService();
      viewModel = FeedbackViewModel(service);
    });

    tearDown(() => viewModel.dispose());

    test('loads both staff and support ratings', () async {
      service.persisted = _feedback(staffRating: 4, supportRating: 5);

      await viewModel.loadFeedbackByTicketId(10);

      expect(viewModel.feedback, isNotNull);
      expect(viewModel.staffRating, 4);
      expect(viewModel.supportRating, 5);
      expect(viewModel.comment, 'Helpful');
      expect(viewModel.errorMessage, isNull);
    });

    test('submits immutable identities and both ratings', () async {
      final succeeded = await viewModel.submitFeedback(
        ticketId: 10,
        reviewerUserId: 2,
        revieweeUserId: 7,
        staffRating: 5,
        supportRating: 4,
        comment: 'Resolved quickly',
      );

      expect(succeeded, isTrue);
      expect(service.lastSubmitted?.ticketId, 10);
      expect(service.lastSubmitted?.reviewerUserId, 2);
      expect(service.lastSubmitted?.revieweeUserId, 7);
      expect(service.lastSubmitted?.staffRating, 5);
      expect(service.lastSubmitted?.supportRating, 4);
    });

    test('reports service validation errors', () async {
      service.submitError = ArgumentError('Ratings must be between 1 and 5');

      final succeeded = await viewModel.submitFeedback(
        ticketId: 10,
        reviewerUserId: 2,
        revieweeUserId: 7,
        staffRating: 0,
        supportRating: 6,
      );

      expect(succeeded, isFalse);
      expect(
        viewModel.errorMessage,
        contains('Ratings must be between 1 and 5'),
      );
    });

    test('updates both editable ratings and comment', () async {
      service.persisted = _feedback(staffRating: 3, supportRating: 3);

      final succeeded = await viewModel.updateFeedback(
        feedbackId: 1,
        ticketId: 10,
        reviewerUserId: 2,
        revieweeUserId: 7,
        staffRating: 4,
        supportRating: 5,
        comment: 'Updated',
        createdAt: service.persisted!.createdAt,
      );

      expect(succeeded, isTrue);
      expect(service.lastUpdated?.reviewerUserId, 2);
      expect(service.lastUpdated?.revieweeUserId, 7);
      expect(service.lastUpdated?.staffRating, 4);
      expect(service.lastUpdated?.supportRating, 5);
    });

    test('maintains independent form ratings', () {
      viewModel.updateStaffRating(5);
      viewModel.updateSupportRating(2);

      expect(viewModel.staffRating, 5);
      expect(viewModel.supportRating, 2);

      viewModel.resetForm();
      expect(viewModel.staffRating, 0);
      expect(viewModel.supportRating, 0);
    });
  });
}

Feedback _feedback({int staffRating = 5, int supportRating = 5}) {
  return Feedback(
    id: 1,
    ticketId: 10,
    reviewerUserId: 2,
    revieweeUserId: 7,
    staffRating: staffRating,
    supportRating: supportRating,
    comment: 'Helpful',
    createdAt: DateTime(2026, 7, 20),
    updatedAt: DateTime(2026, 7, 20),
  );
}

class _FakeFeedbackService implements IFeedbackService {
  Feedback? persisted;
  Feedback? lastSubmitted;
  Feedback? lastUpdated;
  Object? submitError;

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) async => persisted;

  @override
  Future<List<Feedback>> getFeedbackByReviewerUserId(
    int reviewerUserId,
  ) async => persisted == null ? [] : [persisted!];

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int reviewerUserId,
    required int revieweeUserId,
    required int staffRating,
    required int supportRating,
    String? comment,
  }) async {
    if (submitError case final error?) {
      throw error;
    }
    lastSubmitted = Feedback(
      id: 1,
      ticketId: ticketId,
      reviewerUserId: reviewerUserId,
      revieweeUserId: revieweeUserId,
      staffRating: staffRating,
      supportRating: supportRating,
      comment: comment,
      createdAt: DateTime(2026, 7, 20),
      updatedAt: DateTime(2026, 7, 20),
    );
    return lastSubmitted!;
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    lastUpdated = feedback;
    persisted = feedback;
  }

  @override
  Future<void> deleteFeedback(int id) async {
    persisted = null;
  }
}
