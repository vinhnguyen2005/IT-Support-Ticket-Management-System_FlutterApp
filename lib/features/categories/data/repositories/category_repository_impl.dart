import '../../domain/repositories/i_category_repository.dart';
import '../../domain/entities/issue_category.dart';
import '../datasources/category_local_data_source.dart';
import '../dtos/category_dto.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl({required this.localDataSource});

  @override
  Future<List<IssueCategory>> getCategories() async {
    final dtos = await localDataSource.getCategories();
    return dtos.toEntityList(); // Sử dụng extension mapper bạn đã viết
  }

  @override
  Future<int> addCategory(CategoryDto category) async {
    return await localDataSource.insertCategory(category);
  }

  @override
  Future<int> updateCategory(CategoryDto category) async {
    return await localDataSource.updateCategory(category);
  }

  @override
  Future<int> deleteCategory(int id) async {
    return await localDataSource.softDeleteCategory(id);
  }
}
