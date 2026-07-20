import 'package:sqflite/sqflite.dart';
import '../dtos/category_dto.dart';

class CategoryLocalDataSource {
  final Database database;

  CategoryLocalDataSource({required this.database});

  // Lấy danh sách (Lấy toàn bộ từ bảng 'categories' chữ thường)
  Future<List<CategoryDto>> getCategories() async {
    final result = await database.query('categories');
    return result.map((map) => CategoryDto.fromMap(map)).toList();
  }

  // Thêm mới
  Future<int> insertCategory(CategoryDto category) async {
    return await database.insert('categories', category.toMap());
  }

  // Cập nhật
  Future<int> updateCategory(CategoryDto category) async {
    return await database.update(
      'categories',
      {
        'name': category.categoryName, // Khớp với cột name của nhóm
        'description': category.description, // Khớp với cột description
        'isActive': category.isActive, // Khớp với cột isActive
        'updatedAt': DateTime.now().toIso8601String(), // Cập nhật thời gian sửa
      },
      where: 'id = ?', // Dùng 'id' chữ thường
      whereArgs: [category.id],
    );
  }

  // Xóa mềm (Tắt trạng thái hoạt động isActive = 0)
  Future<int> softDeleteCategory(int id) async {
    return await database.update(
      'categories',
      {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
