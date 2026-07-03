import '../../domain/entities/assignment.dart';
import '../../domain/entities/progress_update.dart';
import '../../domain/repositories/i_assignment_repository.dart';
import '../datasources/i_assignment_local_data_source.dart';
import '../dtos/progress_update_dto.dart';
import '../mappers/assignment_mapper.dart';
import '../mappers/progress_update_mapper.dart';

class AssignmentRepositoryImpl implements IAssignmentRepository {
  const AssignmentRepositoryImpl({
    required IAssignmentLocalDataSource localDataSource,
    required AssignmentMapper assignmentMapper,
    required ProgressUpdateMapper progressUpdateMapper,
  }) : _localDataSource = localDataSource,
       _assignmentMapper = assignmentMapper,
       _progressUpdateMapper = progressUpdateMapper;

  final IAssignmentLocalDataSource _localDataSource;
  final AssignmentMapper _assignmentMapper;
  final ProgressUpdateMapper _progressUpdateMapper;

  @override
  Future<List<Assignment>> getAssignmentsForStaff(int staffId) async {
    final assignments = await _localDataSource.getAssignmentsForStaff(staffId);
    return assignments.map(_assignmentMapper.mapToEntity).toList();
  }

  @override
  Future<Assignment?> getAssignmentByTicket({
    required int ticketId,
    required int staffId,
  }) async {
    final assignment = await _localDataSource.getAssignmentByTicket(
      ticketId: ticketId,
      staffId: staffId,
    );
    if (assignment == null) {
      return null;
    }

    return _assignmentMapper.mapToEntity(assignment);
  }

  @override
  Future<List<ProgressUpdate>> getProgressUpdates(int ticketId) async {
    final updates = await _localDataSource.getProgressUpdates(ticketId);
    return updates.map(_progressUpdateMapper.mapToEntity).toList();
  }

  @override
  Future<void> assignTicket({
    required int ticketId,
    required int staffId,
    required int assignedByUserId,
    String? note,
  }) {
    return _localDataSource.assignTicket(
      ticketId: ticketId,
      staffId: staffId,
      assignedByUserId: assignedByUserId,
      note: note,
    );
  }

  @override
  Future<ProgressUpdate> addProgressUpdate({
    required int ticketId,
    required int staffId,
    required String message,
  }) async {
    final now = DateTime.now();
    final id = await _localDataSource.addProgressUpdate(
      ProgressUpdateDto(
        ticketId: ticketId,
        staffId: staffId,
        message: message,
        createdAt: now,
      ),
    );

    return ProgressUpdate(
      id: id,
      ticketId: ticketId,
      staffId: staffId,
      message: message,
      createdAt: now,
    );
  }

  @override
  Future<void> updateTicketStatus({
    required int ticketId,
    required int staffId,
    required String status,
    String? note,
    String? solutionSummary,
  }) {
    return _localDataSource.updateTicketStatus(
      ticketId: ticketId,
      staffId: staffId,
      status: status,
      note: note,
      solutionSummary: solutionSummary,
    );
  }
}
