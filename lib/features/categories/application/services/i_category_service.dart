import '../../domain/entities/issue_category.dart';
import '../../data/dtos/category_dto.dart';

abstract class ICategoryService {
  Future<List<IssueCategory>> getAllCategories();
  Future<void> createCategory(
    String name,
    String defaultPriority,
    bool isActive,
  );
  Future<void> editCategory(
    int id,
    String name,
    String defaultPriority,
    bool isActive,
  );
  Future<void> removeCategory(int id);
}
