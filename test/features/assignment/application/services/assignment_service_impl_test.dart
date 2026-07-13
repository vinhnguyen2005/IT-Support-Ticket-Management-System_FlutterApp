import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/assignment/application/services/assignment_service_impl.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/assignment.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/progress_update.dart';
import 'package:it_ticket_support_management/features/assignment/domain/repositories/i_assignment_repository.dart';

void main() {
  group('AssignmentServiceImpl.assignTicket', () {
    test('delegates assignment with trimmed note', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Submitted'),
      );
      final service = AssignmentServiceImpl(repository);

      await service.assignTicket(
        ticketId: 10,
        staffId: 7,
        assignedByUserId: 1,
        note: '  Handle first thing today.  ',
      );

      expect(repository.assignedTicketId, 10);
      expect(repository.assignedStaffId, 7);
      expect(repository.assignedByUserId, 1);
      expect(repository.assignmentNote, 'Handle first thing today.');
    });

    test('rejects missing assignment ids', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Submitted'),
      );
      final service = AssignmentServiceImpl(repository);

      expect(
        () =>
            service.assignTicket(ticketId: 0, staffId: 7, assignedByUserId: 1),
        throwsException,
      );
    });
  });

  group('AssignmentServiceImpl.updateTicketStatus', () {
    test('allows an SRS staff transition', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Assigned'),
      );
      final service = AssignmentServiceImpl(repository);

      await service.updateTicketStatus(
        ticketId: 10,
        staffId: 7,
        status: 'Processing',
      );

      expect(repository.updatedStatus, 'Processing');
    });

    test('rejects the removed pending transition', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Processing'),
      );
      final service = AssignmentServiceImpl(repository);

      expect(
        () => service.updateTicketStatus(
          ticketId: 10,
          staffId: 7,
          status: 'Pending',
        ),
        throwsException,
      );
    });

    test('does not allow an assigned ticket to skip processing', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Assigned'),
      );
      final service = AssignmentServiceImpl(repository);

      expect(
        () => service.updateTicketStatus(
          ticketId: 10,
          staffId: 7,
          status: 'Resolved',
          solutionSummary: 'Attempted shortcut',
        ),
        throwsException,
      );
    });

    test('requires solution summary when resolving', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Processing'),
      );
      final service = AssignmentServiceImpl(repository);

      expect(
        () => service.updateTicketStatus(
          ticketId: 10,
          staffId: 7,
          status: 'Resolved',
        ),
        throwsException,
      );
    });

    test('passes solution summary when resolving', () async {
      final repository = _FakeAssignmentRepository(
        assignment: _assignment(status: 'Processing'),
      );
      final service = AssignmentServiceImpl(repository);

      await service.updateTicketStatus(
        ticketId: 10,
        staffId: 7,
        status: 'Resolved',
        solutionSummary: 'Recreated VPN profile and verified connection.',
      );

      expect(repository.updatedStatus, 'Resolved');
      expect(
        repository.solutionSummary,
        'Recreated VPN profile and verified connection.',
      );
    });
  });
}

Assignment _assignment({required String status}) {
  return Assignment(
    id: 1,
    ticketId: 10,
    staffId: 7,
    assignedAt: DateTime(2026),
    isActive: true,
    ticketTitle: 'VPN issue',
    ticketDescription: 'VPN disconnects repeatedly.',
    issueType: 'Network',
    priority: 'High',
    status: status,
    ticketCreatedAt: DateTime(2026),
  );
}

class _FakeAssignmentRepository implements IAssignmentRepository {
  _FakeAssignmentRepository({required this.assignment});

  final Assignment? assignment;
  String? updatedStatus;
  String? solutionSummary;
  int? assignedTicketId;
  int? assignedStaffId;
  int? assignedByUserId;
  String? assignmentNote;

  @override
  Future<ProgressUpdate> addProgressUpdate({
    required int ticketId,
    required int staffId,
    required String message,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> assignTicket({
    required int ticketId,
    required int staffId,
    required int assignedByUserId,
    String? note,
  }) async {
    assignedTicketId = ticketId;
    assignedStaffId = staffId;
    this.assignedByUserId = assignedByUserId;
    assignmentNote = note;
  }

  @override
  Future<Assignment?> getAssignmentByTicket({
    required int ticketId,
    required int staffId,
  }) async {
    return assignment;
  }

  @override
  Future<List<Assignment>> getAssignmentsForStaff(int staffId) {
    throw UnimplementedError();
  }

  @override
  Future<List<ProgressUpdate>> getProgressUpdates(int ticketId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateTicketStatus({
    required int ticketId,
    required int staffId,
    required String status,
    String? note,
    String? solutionSummary,
  }) async {
    updatedStatus = status;
    this.solutionSummary = solutionSummary;
  }
}
