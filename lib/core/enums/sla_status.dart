enum SlaStatus {
  onTrack('On track'),
  atRisk('At risk'),
  breached('Breached'),
  met('Met'),
  breachedResolved('Breached resolved'),
  exempt('Exempt');

  const SlaStatus(this.label);

  final String label;

  bool get isWarning => this == SlaStatus.atRisk;

  bool get isBreach =>
      this == SlaStatus.breached || this == SlaStatus.breachedResolved;
}
