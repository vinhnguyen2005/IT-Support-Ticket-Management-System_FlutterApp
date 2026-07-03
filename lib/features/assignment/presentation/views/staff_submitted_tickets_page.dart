import 'package:flutter/material.dart';

import '../viewmodels/ticket_assignment_view_model.dart';
import 'ticket_assignment_widgets.dart';

class StaffSubmittedTicketsPage extends StatelessWidget {
  const StaffSubmittedTicketsPage({super.key, required this.viewModel});

  final TicketAssignmentViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return TicketAssignmentListScaffold(
      title: 'Submitted tickets',
      emptyMessage: 'No Submitted tickets are waiting for assignment.',
      viewModel: viewModel,
    );
  }
}
