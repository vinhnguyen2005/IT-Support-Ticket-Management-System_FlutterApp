enum PriorityLevel {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical');

  const PriorityLevel(this.value);

  static const String defaultValue = 'Medium';

  final String value;

  static PriorityLevel fromValue(String value) {
    final key = value.trim().toLowerCase();
    return PriorityLevel.values.firstWhere(
      (priority) => priority.value.toLowerCase() == key,
      orElse: () => PriorityLevel.medium,
    );
  }
}
