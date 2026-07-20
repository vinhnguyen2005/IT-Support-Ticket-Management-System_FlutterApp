import '../../domain/entities/issue_category.dart';

class CategoryDto {
  final int id;
  final String categoryName;
  final String description; // Đổi ở đây
  final int isActive;

  CategoryDto({
    required this.id,
    required this.categoryName,
    required this.description, // Đổi ở đây
    required this.isActive,
  });

  factory CategoryDto.fromMap(Map<String, dynamic> map) {
    return CategoryDto(
      id: map['id'] as int,
      categoryName: map['name'] as String,
      description: map['description'] as String? ?? '', // Trả lại đúng bản chất
      isActive: map['isActive'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': categoryName,
      'description': description,
      'isActive': isActive,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

extension CategoryMapper on CategoryDto {
  IssueCategory toEntity() {
    return IssueCategory(
      id: id,
      categoryName: categoryName,
      description: description, // Đổi ở đây
      isActive: isActive == 1,
    );
  }
}

extension CategoryListMapper on List<CategoryDto> {
  List<IssueCategory> toEntityList() {
    return map((dto) => dto.toEntity()).toList();
  }
}
