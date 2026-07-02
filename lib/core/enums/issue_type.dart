enum IssueType {
  general('General'),
  hardware('Hardware'),
  software('Software'),
  network('Network');

  const IssueType(this.value);

  static const String defaultValue = 'General';

  final String value;

  static IssueType fromValue(String value) {
    final key = value.trim().toLowerCase();
    return IssueType.values.firstWhere(
      (issueType) => issueType.value.toLowerCase() == key,
      orElse: () => IssueType.general,
    );
  }
}
