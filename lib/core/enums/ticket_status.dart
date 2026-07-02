enum TicketStatus {
  submitted('Submitted'),
  cancelled('Cancelled'),
  assigned('Assigned'),
  processing('Processing'),
  pending('Pending'),
  resolved('Resolved'),
  closed('Closed');

  const TicketStatus(this.value);

  static const String defaultValue = 'Submitted';

  final String value;

  String get key {
    return value.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  }

  bool get isResolved {
    return this == TicketStatus.resolved || this == TicketStatus.closed;
  }

  static TicketStatus fromValue(String value) {
    return tryParse(value) ?? TicketStatus.submitted;
  }

  static TicketStatus? tryParse(String value) {
    final key = value.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    final normalizedKey = switch (key) {
      'open' => 'submitted',
      'inprogress' => 'processing',
      'reopened' => 'processing',
      _ => key,
    };

    for (final status in TicketStatus.values) {
      if (status.key == normalizedKey) {
        return status;
      }
    }

    return null;
  }
}
