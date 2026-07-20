class DepartmentDto {
  const DepartmentDto({
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

  factory DepartmentDto.fromMap(Map<String, Object?> map) {
    return DepartmentDto(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      isActive: (map['isActive'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.tryParse(map['updatedAt'] as String),
    );
  }
}
