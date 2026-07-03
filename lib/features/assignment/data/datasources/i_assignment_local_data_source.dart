import '../dtos/assignment_dto.dart';
import '../dtos/progress_update_dto.dart';

abstract interface class IAssignmentLocalDataSource {
  Future<List<AssignmentDto>> getAssignmentsForStaff(int staffId);

  Future<AssignmentDto?> getAssignmentByTicket({
    required int ticketId,
    required int staffId,
  });

  Future<List<ProgressUpdateDto>> getProgressUpdates(int ticketId);

  Future<void> assignTicket({
    required int ticketId,
    required int staffId,
    required int assignedByUserId,
    String? note,
  });

  Future<int> addProgressUpdate(ProgressUpdateDto update);

  Future<void> updateTicketStatus({
    required int ticketId,
    required int staffId,
    required String status,
    String? note,
    String? solutionSummary,
  });
}
