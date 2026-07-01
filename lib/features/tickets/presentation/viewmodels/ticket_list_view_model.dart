import 'package:flutter/foundation.dart';

import '../../application/services/i_ticket_service.dart';
import '../../domain/entities/ticket.dart';

enum TicketListStatus { initial, loading, success, failure }

class TicketListViewModel extends ChangeNotifier {
  TicketListViewModel(this._ticketService);

  final ITicketService _ticketService;

  TicketListStatus _status = TicketListStatus.initial;
  String? _errorMessage;
  List<Ticket> _tickets = const [];

  TicketListStatus get status => _status;

  bool get isLoading => _status == TicketListStatus.loading;

  String? get errorMessage => _errorMessage;

  List<Ticket> get tickets => List.unmodifiable(_tickets);

  Future<void> loadTickets() async {
    await _load(() => _ticketService.getTickets());
  }

  Future<void> loadTicketsByRequester(int requesterId) async {
    await _load(() => _ticketService.getTicketsByRequester(requesterId));
  }

  Future<void> loadTicketsByAssignee(int assigneeId) async {
    await _load(() => _ticketService.getTicketsByAssignee(assigneeId));
  }

  Future<bool> deleteTicket(int id) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _ticketService.deleteTicket(id);
      _tickets = _tickets.where((ticket) => ticket.id != id).toList();
      _status = TicketListStatus.success;
      notifyListeners();
      return true;
    } catch (error) {
      _status = TicketListStatus.failure;
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _load(Future<List<Ticket>> Function() loader) async {
    _status = TicketListStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _tickets = await loader();
      _status = TicketListStatus.success;
    } catch (error) {
      _status = TicketListStatus.failure;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }
}
