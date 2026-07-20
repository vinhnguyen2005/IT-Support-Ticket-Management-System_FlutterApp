import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../dtos/department_dto.dart';
import 'i_department_local_data_source.dart';

class DepartmentLocalDataSourceImpl implements IDepartmentLocalDataSource {
  const DepartmentLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<List<DepartmentDto>> getDepartments() async {
    final rows = await _database.query(
      AppDatabase.departmentsTable,
      orderBy: 'isActive DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(DepartmentDto.fromMap).toList(growable: false);
  }

  @override
  Future<DepartmentDto?> findByName(String name, {int? excludeId}) async {
    final rows = await _database.query(
      AppDatabase.departmentsTable,
      where: excludeId == null
          ? 'LOWER(name) = LOWER(?)'
          : 'LOWER(name) = LOWER(?) AND id <> ?',
      whereArgs: excludeId == null ? [name] : [name, excludeId],
      limit: 1,
    );
    return rows.isEmpty ? null : DepartmentDto.fromMap(rows.first);
  }

  @override
  Future<void> createDepartment({
    required String name,
    String? description,
    required bool isActive,
  }) async {
    await _database.insert(AppDatabase.departmentsTable, {
      'name': name,
      'description': description,
      'isActive': isActive ? 1 : 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateDepartment({
    required int id,
    required String name,
    String? description,
    required bool isActive,
  }) async {
    final updated = await _database.update(
      AppDatabase.departmentsTable,
      {
        'name': name,
        'description': description,
        'isActive': isActive ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) throw const AppException('Department was not found.');
  }

  @override
  Future<int> countActiveReferences(int departmentId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT
        (SELECT COUNT(*) FROM ${AppDatabase.usersTable}
          WHERE departmentId = ? AND isActive = 1) +
        (SELECT COUNT(*) FROM ${AppDatabase.categoriesTable}
          WHERE departmentId = ? AND isActive = 1) AS reference_count
      ''',
      [departmentId, departmentId],
    );
    return (rows.first['reference_count'] as num?)?.toInt() ?? 0;
  }
}
