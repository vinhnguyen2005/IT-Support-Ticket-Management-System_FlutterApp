class SlaSummaryReport {
  const SlaSummaryReport({
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

  double get responseComplianceRate {
    final completed = responseMet + responseBreached;
    return completed == 0 ? 0 : responseMet / completed;
  }

  double get resolutionComplianceRate {
    final completed = resolutionMet + resolutionBreached;
    return completed == 0 ? 0 : resolutionMet / completed;
  }
}
