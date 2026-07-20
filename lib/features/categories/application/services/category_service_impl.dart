import 'i_category_service.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/entities/issue_category.dart';
import '../../data/dtos/category_dto.dart';

class CategoryServiceImpl implements ICategoryService {
  final ICategoryRepository repository;

  CategoryServiceImpl({required this.repository});

  @override
  Future<List<IssueCategory>> getAllCategories() async {
    return await repository.getCategories();
  }

  @override
  Future<void> createCategory(
    String name,
    String defaultPriority,
    bool isActive,
  ) async {
    if (name.trim().isEmpty) throw Exception('Category name cannot be empty');

    final dto = CategoryDto(
      id: 0, // SQLite auto-increments
      categoryName: name.trim(),
      description: defaultPriority,
      isActive: isActive ? 1 : 0,
    );
    await repository.addCategory(dto);
  }

  @override
  Future<void> editCategory(
    int id,
    String name,
    String defaultPriority,
    bool isActive,
  ) async {
    if (name.trim().isEmpty) throw Exception('Category name cannot be empty');

    final dto = CategoryDto(
      id: id,
      categoryName: name.trim(),
      description: defaultPriority,
      isActive: isActive ? 1 : 0,
    );
    await repository.updateCategory(dto);
  }

  @override
  Future<void> removeCategory(int id) async {
    await repository.deleteCategory(id);
  }
}
