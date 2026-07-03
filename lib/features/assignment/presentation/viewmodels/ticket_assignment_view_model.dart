import 'package:flutter/foundation.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../tickets/application/services/i_ticket_service.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../user_management/application/services/i_user_management_service.dart';
import '../../../user_management/domain/entities/managed_user.dart';
import '../../application/services/i_assignment_service.dart';

enum TicketAssignmentMode { staffSubmitted, adminAll }

enum TicketAssignmentStatus { initial, loading, success, failure }

class TicketAssignmentViewModel extends ChangeNotifier {
  TicketAssignmentViewModel({
    required IAssignmentService assignmentService,
    required ITicketService ticketService,
    required IUserManagementService userManagementService,
    required this.currentUserId,
    required this.currentUserRole,
    required this.mode,
  }) : _assignmentService = assignmentService,
       _ticketService = ticketService,
       _userManagementService = userManagementService;

  final IAssignmentService _assignmentService;
  final ITicketService _ticketService;
  final IUserManagementService _userManagementService;
  final int currentUserId;
  final String currentUserRole;
  final TicketAssignmentMode mode;

  TicketAssignmentStatus _status = TicketAssignmentStatus.initial;
  String? _errorMessage;
  String? _successMessage;
  List<Ticket> _tickets = const [];
  List<ManagedUser> _staffUsers = const [];

  TicketAssignmentStatus get status => _status;

  bool get isLoading => _status == TicketAssignmentStatus.loading;

  String? get errorMessage => _errorMessage;

  String? get successMessage => _successMessage;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  List<ManagedUser> get staffUsers => List.unmodifiable(_staffUsers);

  Future<void> load() async {
    _status = TicketAssignmentStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _loadData();
      _status = TicketAssignmentStatus.success;
    } catch (error) {
      _status = TicketAssignmentStatus.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<void> assignTicket({
    required int ticketId,
    required int staffId,
    String? note,
  }) async {
    _status = TicketAssignmentStatus.loading;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _validateAccess();
      await _assignmentService.assignTicket(
        ticketId: ticketId,
        staffId: staffId,
        assignedByUserId: currentUserId,
        note: note,
      );
      await _loadData();
      _status = TicketAssignmentStatus.success;
      _successMessage = 'Ticket assigned successfully.';
      notifyListeners();
    } catch (error) {
      _status = TicketAssignmentStatus.failure;
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  bool canAssign(Ticket ticket) {
    return _isSubmitted(ticket.status);
  }

  Future<void> _loadData() async {
    _validateAccess();
    final tickets = await _ticketService.getTickets();
    final users = await _userManagementService.getUsers();

    _tickets = mode == TicketAssignmentMode.staffSubmitted
        ? tickets.where((ticket) => _isSubmitted(ticket.status)).toList()
        : tickets;
    _staffUsers = users
        .where(
          (user) =>
              user.isActive &&
              UserRole.fromValue(user.role.trim()) == UserRole.staff,
        )
        .toList();
  }

  void _validateAccess() {
    final role = UserRole.fromValue(currentUserRole.trim());
    if (mode == TicketAssignmentMode.staffSubmitted && role != UserRole.staff) {
      throw const AppException('Only staff can assign submitted tickets.');
    }

    if (mode == TicketAssignmentMode.adminAll && role != UserRole.admin) {
      throw const AppException('Only admin can view all system tickets.');
    }
  }

  bool _isSubmitted(String status) {
    return status.trim().toLowerCase() == 'submitted';
  }
}
