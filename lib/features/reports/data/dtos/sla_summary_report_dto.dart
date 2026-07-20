import '../../domain/entities/sla_summary_report.dart';

class SlaSummaryReportDto {
  const SlaSummaryReportDto({
    required this.totalActionable,
    required this.responseMet,
    required this.responseBreached,
    required this.resolutionMet,
    required this.resolutionBreached,
    required this.currentlyAtRisk,
    required this.currentlyBreached,
    required this.exempt,
  });

  final int totalActionable;
  final int responseMet;
  final int responseBreached;
  final int resolutionMet;
  final int resolutionBreached;
  final int currentlyAtRisk;
  final int currentlyBreached;
  final int exempt;

  factory SlaSummaryReportDto.fromMap(Map<String, Object?> map) {
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return SlaSummaryReportDto(
      totalActionable: read('total_actionable'),
      responseMet: read('response_met'),
      responseBreached: read('response_breached'),
      resolutionMet: read('resolution_met'),
      resolutionBreached: read('resolution_breached'),
      currentlyAtRisk: read('currently_at_risk'),
      currentlyBreached: read('currently_breached'),
      exempt: read('exempt'),
    );
  }

  SlaSummaryReport toEntity() => SlaSummaryReport(
    totalActionable: totalActionable,
    responseMet: responseMet,
    responseBreached: responseBreached,
    resolutionMet: resolutionMet,
    resolutionBreached: resolutionBreached,
    currentlyAtRisk: currentlyAtRisk,
    currentlyBreached: currentlyBreached,
    exempt: exempt,
  );
}
