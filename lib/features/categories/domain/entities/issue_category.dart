class IssueCategory {
  final int id;
  final String categoryName;
  final String description; // ĐỔI TÊN Ở ĐÂY
  final bool isActive;

  IssueCategory({
    required this.id,
    required this.categoryName,
    required this.description, // VÀ Ở ĐÂY
    required this.isActive,
  });
}
