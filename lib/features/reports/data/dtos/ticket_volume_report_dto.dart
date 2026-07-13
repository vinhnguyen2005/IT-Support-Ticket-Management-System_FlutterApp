class TicketVolumeReportDto {
  const TicketVolumeReportDto({
    required this.date,
    required this.totalTickets,
    required this.submittedTickets,
    required this.assignedTickets,
    required this.processingTickets,
    required this.resolvedTickets,
    required this.closedTickets,
    required this.cancelledTickets,
  });

  factory TicketVolumeReportDto.fromMap(Map<String, Object?> map) {
    return TicketVolumeReportDto(
      date: map['date'] as String? ?? '',
      totalTickets: (map['total_tickets'] as num?)?.toInt() ?? 0,
      submittedTickets: (map['submitted_tickets'] as num?)?.toInt() ?? 0,
      assignedTickets: (map['assigned_tickets'] as num?)?.toInt() ?? 0,
      processingTickets: (map['processing_tickets'] as num?)?.toInt() ?? 0,
      resolvedTickets: (map['resolved_tickets'] as num?)?.toInt() ?? 0,
      closedTickets: (map['closed_tickets'] as num?)?.toInt() ?? 0,
      cancelledTickets: (map['cancelled_tickets'] as num?)?.toInt() ?? 0,
    );
  }

  final String date;
  final int totalTickets;
  final int submittedTickets;
  final int assignedTickets;
  final int processingTickets;
  final int resolvedTickets;
  final int closedTickets;
  final int cancelledTickets;
}
