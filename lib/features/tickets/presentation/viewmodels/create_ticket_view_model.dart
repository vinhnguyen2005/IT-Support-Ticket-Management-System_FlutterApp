import 'package:flutter/foundation.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../application/services/i_ticket_service.dart';
import '../../domain/entities/ticket.dart';

class CreateTicketViewModel extends ChangeNotifier {
  CreateTicketViewModel(this._ticketService, [this._referenceDataService]);

  final ITicketService _ticketService;
  final ReferenceDataService? _referenceDataService;

  bool _isLoading = false;
  String? _errorMessage;
  Ticket? _createdTicket;
  List<PriorityReference> _priorities = const [];

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Ticket? get createdTicket => _createdTicket;

  List<PriorityReference> get priorities => List.unmodifiable(_priorities);

  Future<void> loadPriorities() async {
    final service = _referenceDataService;
    if (service == null) {
      return;
    }

    try {
      _priorities = await service.getActivePriorities();
    } catch (error) {
      _errorMessage = 'Unable to load priorities: $error';
    }
    notifyListeners();
  }

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
