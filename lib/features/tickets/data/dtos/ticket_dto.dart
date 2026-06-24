class TicketDto {
  const TicketDto({
    this.id,
    required this.title,
    required this.description,
    required this.issueType,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String title;
  final String description;
  final String issueType;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory TicketDto.fromMap(Map<String, Object?> map) {
    return TicketDto(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      issueType: map['issueType'] as String,
      priority: map['priority'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] == null
          ? null
          : DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
