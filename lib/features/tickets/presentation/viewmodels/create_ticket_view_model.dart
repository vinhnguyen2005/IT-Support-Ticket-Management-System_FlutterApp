import 'package:flutter/foundation.dart';

import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../application/services/i_ticket_service.dart';
import '../../domain/entities/ticket.dart';

class CreateTicketViewModel extends ChangeNotifier {
  CreateTicketViewModel(this._ticketService);

  final ITicketService _ticketService;

  bool _isLoading = false;
  String? _errorMessage;
  Ticket? _createdTicket;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Ticket? get createdTicket => _createdTicket;

  Future<bool> createTicket({
    required String title,
    required String description,
    String issueType = IssueType.defaultValue,
    String priority = PriorityLevel.defaultValue,
    int? requesterId,
    int? categoryId,
    String? attachmentUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _createdTicket = null;
    notifyListeners();

    try {
      _createdTicket = await _ticketService.createTicket(
        title: title,
        description: description,
        issueType: issueType,
        priority: priority,
        requesterId: requesterId,
        categoryId: categoryId,
        attachmentUrl: attachmentUrl,
      );
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
