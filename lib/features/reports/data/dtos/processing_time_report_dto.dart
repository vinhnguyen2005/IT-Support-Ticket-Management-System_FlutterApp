class ProcessingTimeReportDto {
  const ProcessingTimeReportDto({
    required this.categoryName,
    required this.completedTickets,
    required this.averageHours,
  });

  factory ProcessingTimeReportDto.fromMap(Map<String, Object?> map) {
    return ProcessingTimeReportDto(
      categoryName: map['category_name'] as String? ?? 'Unknown',
      completedTickets: (map['completed_tickets'] as num?)?.toInt() ?? 0,
      averageHours: (map['average_hours'] as num?)?.toDouble() ?? 0,
    );
  }

  final String categoryName;
  final int completedTickets;
  final double averageHours;
}
