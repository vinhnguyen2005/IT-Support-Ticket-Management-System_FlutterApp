import 'package:flutter/foundation.dart';

import '../../application/services/i_ticket_service.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/ticket_status_note.dart';

enum TicketDetailStatus { initial, loading, success, failure }

class TicketDetailViewModel extends ChangeNotifier {
  TicketDetailViewModel(this._ticketService);

  final ITicketService _ticketService;

  TicketDetailStatus _status = TicketDetailStatus.initial;
  String? _errorMessage;
  Ticket? _ticket;
  List<TicketStatusNote> _statusNotes = const [];

  TicketDetailStatus get status => _status;

  bool get isLoading => _status == TicketDetailStatus.loading;

  String? get errorMessage => _errorMessage;

  Ticket? get ticket => _ticket;

  List<TicketStatusNote> get statusNotes => List.unmodifiable(_statusNotes);

  Future<void> loadTicket(int id) async {
    _status = TicketDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _ticket = await _ticketService.getTicketById(id);
      _statusNotes = await _ticketService.getStatusNotesByTicketId(id);
      _status = TicketDetailStatus.success;
    } catch (error) {
      _status = TicketDetailStatus.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  Future<bool> updateTicket(Ticket ticket) async {
    _status = TicketDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _ticket = await _ticketService.updateTicket(ticket);
      _status = TicketDetailStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      _status = TicketDetailStatus.failure;
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTicketStatus({
    required int ticketId,
    required String status,
    int? changedByUserId,
    String? changedByRole,
    String? note,
    String? solutionSummary,
  }) async {
    _status = TicketDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _ticket = await _ticketService.updateTicketStatus(
        ticketId: ticketId,
        status: status,
        changedByUserId: changedByUserId,
        changedByRole: changedByRole,
        note: note,
        solutionSummary: solutionSummary,
      );
      _statusNotes = await _ticketService.getStatusNotesByTicketId(ticketId);
      _status = TicketDetailStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      _status = TicketDetailStatus.failure;
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTicket(int id) async {
    _status = TicketDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _ticketService.deleteTicket(id);
      _ticket = null;
      _status = TicketDetailStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      _status = TicketDetailStatus.failure;
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
