class ProcessingTimeReport {
  const ProcessingTimeReport({
    required this.categoryName,
    required this.completedTickets,
    required this.averageHours,
  });

  final String categoryName;
  final int completedTickets;
  final double averageHours;
}
