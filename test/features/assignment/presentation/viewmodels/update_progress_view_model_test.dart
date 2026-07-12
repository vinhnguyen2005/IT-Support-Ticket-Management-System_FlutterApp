import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/assignment/application/services/i_assignment_service.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/assignment.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/progress_update.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/viewmodels/update_progress_view_model.dart';

void main() {
  group('UpdateProgressViewModel', () {
    test('loads the assignment and existing status notes', () async {
      final service = _ProgressService(
        assignment: _assignment(),
        updates: [_update('Initial diagnosis')],
      );
      final viewModel = _viewModel(service);

      await viewModel.load();

      expect(viewModel.status, UpdateProgressStatus.success);
      expect(viewModel.assignment?.ticketTitle, 'VPN issue');
      expect(viewModel.updates.single.message, 'Initial diagnosis');
    });

    test('rejects a blank progress note without calling the service', () async {
      final service = _ProgressService(assignment: _assignment());
      final viewModel = _viewModel(service);

      final success = await viewModel.submitUpdate(
        message: '   ',
        status: 'Processing',
      );

      expect(success, isFalse);
      expect(viewModel.status, UpdateProgressStatus.failure);
      expect(viewModel.errorMessage, 'Progress note is required.');
      expect(service.updatedStatus, isNull);
      expect(service.addedMessage, isNull);
    });

    test(
      'submits a trimmed note then refreshes assignment and history',
      () async {
        final service = _ProgressService(
          assignment: _assignment(status: 'Processing'),
          updates: [_update('VPN profile recreated')],
        );
        final viewModel = _viewModel(service);

        final success = await viewModel.submitUpdate(
          message: '  VPN profile recreated  ',
          status: 'Processing',
        );

        expect(success, isTrue);
        expect(viewModel.status, UpdateProgressStatus.success);
        expect(service.updatedStatus, 'Processing');
        expect(service.updatedNote, 'VPN profile recreated');
        expect(service.addedMessage, 'VPN profile recreated');
        expect(service.assignmentRequests, 1);
        expect(service.updateRequests, 1);
      },
    );

    test('returns false and exposes an update failure', () async {
      final service = _ProgressService(
        assignment: _assignment(),
        updateError: Exception('invalid transition'),
      );
      final viewModel = _viewModel(service);

      final success = await viewModel.submitUpdate(
        message: 'Working on it',
        status: 'Processing',
      );

      expect(success, isFalse);
      expect(viewModel.status, UpdateProgressStatus.failure);
      expect(viewModel.errorMessage, contains('invalid transition'));
      expect(service.addedMessage, isNull);
    });
  });
}

UpdateProgressViewModel _viewModel(_ProgressService service) =>
    UpdateProgressViewModel(
      assignmentService: service,
      staffId: 7,
      ticketId: 10,
    );

Assignment _assignment({String status = 'Assigned'}) => Assignment(
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

ProgressUpdate _update(String message) => ProgressUpdate(
  id: 1,
  ticketId: 10,
  staffId: 7,
  message: message,
  createdAt: DateTime(2026),
);

class _ProgressService implements IAssignmentService {
  _ProgressService({
    required this.assignment,
    this.updates = const [],
    this.updateError,
  });

  final Assignment? assignment;
  final List<ProgressUpdate> updates;
  final Object? updateError;
  String? updatedStatus;
  String? updatedNote;
  String? addedMessage;
  int assignmentRequests = 0;
  int updateRequests = 0;

  @override
  Future<Assignment?> getAssignmentByTicket({
    required int ticketId,
    required int staffId,
  }) async {
    assignmentRequests++;
    return assignment;
  }

  @override
  Future<List<ProgressUpdate>> getProgressUpdates(int ticketId) async =>
      updates;

  @override
  Future<void> updateTicketStatus({
    required int ticketId,
    required int staffId,
    required String status,
    String? note,
    String? solutionSummary,
  }) async {
    updateRequests++;
    if (updateError != null) throw updateError!;
    updatedStatus = status;
    updatedNote = note;
  }

  @override
  Future<ProgressUpdate> addProgressUpdate({
    required int ticketId,
    required int staffId,
    required String message,
  }) async {
    addedMessage = message;
    return _update(message);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
