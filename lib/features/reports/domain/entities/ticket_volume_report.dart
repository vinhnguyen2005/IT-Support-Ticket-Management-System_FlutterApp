class TicketVolumeReport {
  const TicketVolumeReport({
    required this.date,
    required this.totalTickets,
    required this.submittedTickets,
    required this.assignedTickets,
    required this.processingTickets,
    required this.resolvedTickets,
    required this.closedTickets,
    required this.cancelledTickets,
  });

  final String date;
  final int totalTickets;
  final int submittedTickets;
  final int assignedTickets;
  final int processingTickets;
  final int resolvedTickets;
  final int closedTickets;
  final int cancelledTickets;

  int get openTickets => submittedTickets + assignedTickets + processingTickets;
}
