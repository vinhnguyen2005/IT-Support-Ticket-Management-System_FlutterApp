import 'package:flutter/material.dart';

import '../viewmodels/ticket_assignment_view_model.dart';
import 'ticket_assignment_widgets.dart';

class AdminTicketAssignmentPage extends StatelessWidget {
  const AdminTicketAssignmentPage({super.key, required this.viewModel});

  final TicketAssignmentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return TicketAssignmentListScaffold(
      title: 'All tickets',
      emptyMessage: 'No tickets found.',
      viewModel: viewModel,
    );
  }
}
