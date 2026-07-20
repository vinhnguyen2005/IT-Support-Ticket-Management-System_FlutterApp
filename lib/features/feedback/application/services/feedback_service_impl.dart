import '../../domain/entities/feedback.dart';
import '../../domain/repositories/i_feedback_repository.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../tickets/application/services/i_ticket_service.dart';
import 'i_feedback_service.dart';

class FeedbackServiceImpl implements IFeedbackService {
  const FeedbackServiceImpl(this._repository, {ITicketService? ticketService})
    : _ticketService = ticketService;

  final IFeedbackRepository _repository;
  final ITicketService? _ticketService;

  static const int maxCommentLength = 1000;

  @override
  Future<Feedback?> getFeedbackByTicketId(int ticketId) {
    _validatePositiveId(ticketId, 'Ticket');
    return _repository.getFeedbackByTicketId(ticketId);
  }

  @override
  Future<List<Feedback>> getFeedbackByReviewerUserId(int reviewerUserId) {
    _validatePositiveId(reviewerUserId, 'Reviewer');
    return _repository.getFeedbackByReviewerUserId(reviewerUserId);
  }

  @override
  Future<Feedback> submitFeedback({
    required int ticketId,
    required int reviewerUserId,
    required int revieweeUserId,
    required int staffRating,
    required int supportRating,
    String? comment,
  }) async {
    _validatePositiveId(ticketId, 'Ticket');
    _validatePositiveId(reviewerUserId, 'Reviewer');
    _validatePositiveId(revieweeUserId, 'Reviewee');
    if (reviewerUserId == revieweeUserId) {
      throw ArgumentError('Reviewer and reviewee must be different users');
    }
    _validateRating(staffRating);
    _validateRating(supportRating);
    final normalizedComment = _normalizeComment(comment);
    await _validateTicketCanReceiveFeedback(
      ticketId,
      reviewerUserId,
      revieweeUserId,
    );

    return _repository.submitFeedback(
      ticketId: ticketId,
      reviewerUserId: reviewerUserId,
      revieweeUserId: revieweeUserId,
      staffRating: staffRating,
      supportRating: supportRating,
      comment: normalizedComment,
    );
  }

  @override
  Future<void> updateFeedback(Feedback feedback) async {
    final feedbackId = feedback.id;
    if (feedbackId == null || feedbackId <= 0) {
      throw ArgumentError('Feedback id must be greater than 0');
    }
    _validatePositiveId(feedback.ticketId, 'Ticket');
    _validatePositiveId(feedback.reviewerUserId, 'Reviewer');
    _validatePositiveId(feedback.revieweeUserId, 'Reviewee');
    _validateRating(feedback.staffRating);
    _validateRating(feedback.supportRating);
    final normalizedComment = _normalizeComment(feedback.comment);
    await _validateTicketCanReceiveFeedback(
      feedback.ticketId,
      feedback.reviewerUserId,
      feedback.revieweeUserId,
    );

    final stored = await _repository.getFeedbackByTicketId(feedback.ticketId);
    if (stored == null || stored.id != feedbackId) {
      throw const AppException('Feedback not found.');
    }
    if (stored.reviewerUserId != feedback.reviewerUserId) {
      throw const AppException('You can only update your own feedback.');
    }
    if (stored.revieweeUserId != feedback.revieweeUserId) {
      throw const AppException('The rated staff member cannot be changed.');
    }

    await _repository.updateFeedback(
      feedback.copyWith(comment: normalizedComment),
    );
  }

  @override
  Future<void> deleteFeedback(int id) {
    _validatePositiveId(id, 'Feedback');
    return _repository.deleteFeedback(id);
  }

  Future<void> _validateTicketCanReceiveFeedback(
    int ticketId,
    int reviewerUserId,
    int revieweeUserId,
  ) async {
    final ticketService = _ticketService;
    if (ticketService == null) return;

    final ticket = await ticketService.getTicketById(ticketId);
    if (ticket == null || ticket.isDeleted) {
      throw const AppException('Ticket not found.');
    }
    if (TicketStatus.fromValue(ticket.status) != TicketStatus.closed) {
      throw const AppException(
        'Feedback can only be submitted after the ticket is closed.',
      );
    }
    if (ticket.requestedId != reviewerUserId) {
      throw const AppException(
        'Only the ticket requester can submit feedback.',
      );
    }
    if (ticket.assignedId == null) {
      throw const AppException('Ticket has no assigned staff member.');
    }
    if (ticket.assignedId != revieweeUserId) {
      throw const AppException('Feedback must rate the assigned staff member.');
    }
  }

  static void _validatePositiveId(int id, String name) {
    if (id <= 0) {
      throw ArgumentError('$name id must be greater than 0');
    }
  }

  static void _validateRating(int rating) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }
  }

  static String? _normalizeComment(String? comment) {
    final normalized = comment?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    if (normalized.length > maxCommentLength) {
      throw ArgumentError(
        'Comment must not exceed $maxCommentLength characters',
      );
    }
    return normalized;
  }
}
