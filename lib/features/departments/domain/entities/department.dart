class Department {
  const Department({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    this.description,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
