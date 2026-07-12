import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/features/assignment/application/services/i_assignment_service.dart';
import 'package:it_ticket_support_management/features/assignment/domain/entities/assignment.dart';
import 'package:it_ticket_support_management/features/assignment/presentation/viewmodels/technician_queue_view_model.dart';

void main() {
  group('TechnicianQueueViewModel', () {
    test('loads assigned tickets for a staff user', () async {
      final service = _QueueService(assignments: [_assignment()]);
      final viewModel = TechnicianQueueViewModel(
        assignmentService: service,
        staffId: 7,
        userRole: 'staff',
      );

      await viewModel.loadAssignments();

      expect(viewModel.status, TechnicianQueueStatus.success);
      expect(viewModel.assignments, hasLength(1));
      expect(viewModel.assignments.single.ticketTitle, 'VPN issue');
      expect(service.requestedStaffId, 7);
      expect(viewModel.errorMessage, isNull);
    });

    test('rejects a non-staff user before calling the service', () async {
      final service = _QueueService(assignments: [_assignment()]);
      final viewModel = TechnicianQueueViewModel(
        assignmentService: service,
        staffId: 7,
        userRole: 'admin',
      );

      await viewModel.loadAssignments();

      expect(viewModel.status, TechnicianQueueStatus.failure);
      expect(viewModel.assignments, isEmpty);
      expect(viewModel.errorMessage, contains('Only staff'));
      expect(service.requestedStaffId, isNull);
    });

    test('exposes a service failure and leaves the queue empty', () async {
      final service = _QueueService(error: Exception('database unavailable'));
      final viewModel = TechnicianQueueViewModel(
        assignmentService: service,
        staffId: 7,
        userRole: 'staff',
      );

      await viewModel.loadAssignments();

      expect(viewModel.status, TechnicianQueueStatus.failure);
      expect(viewModel.assignments, isEmpty);
      expect(viewModel.errorMessage, contains('database unavailable'));
    });
  });
}

Assignment _assignment() => Assignment(
  id: 1,
  ticketId: 10,
  staffId: 7,
  assignedAt: DateTime(2026),
  isActive: true,
  ticketTitle: 'VPN issue',
  ticketDescription: 'VPN disconnects repeatedly.',
  issueType: 'Network',
  priority: 'High',
  status: 'Assigned',
  ticketCreatedAt: DateTime(2026),
);

class _QueueService implements IAssignmentService {
  _QueueService({this.assignments = const [], this.error});

  final List<Assignment> assignments;
  final Object? error;
  int? requestedStaffId;

  @override
  Future<List<Assignment>> getAssignmentsForStaff(int staffId) async {
    requestedStaffId = staffId;
    if (error != null) throw error!;
    return assignments;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
