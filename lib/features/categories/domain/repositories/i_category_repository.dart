import '../entities/issue_category.dart';
import '../../data/dtos/category_dto.dart';

abstract class ICategoryRepository {
  Future<List<IssueCategory>> getCategories();
  Future<int> addCategory(CategoryDto category);
  Future<int> updateCategory(CategoryDto category);
  Future<int> deleteCategory(int id);
}
