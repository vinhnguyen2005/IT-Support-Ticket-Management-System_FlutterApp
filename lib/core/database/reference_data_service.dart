import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class DepartmentReference {
  const DepartmentReference({required this.id, required this.name});

  final int id;
  final String name;

  factory DepartmentReference.fromMap(Map<String, Object?> map) {
    return DepartmentReference(
      id: map['id'] as int,
      name: map['name'] as String,
    );
  }
}

class CategoryReference {
  const CategoryReference({required this.id, required this.name});

  final int id;
  final String name;

  factory CategoryReference.fromMap(Map<String, Object?> map) {
    return CategoryReference(id: map['id'] as int, name: map['name'] as String);
  }
}

class StaffReference {
  const StaffReference({required this.id, required this.name});

  final int id;
  final String name;

  factory StaffReference.fromMap(Map<String, Object?> map) {
    return StaffReference(
      id: map['id'] as int,
      name: map['fullName'] as String,
    );
  }
}

class PriorityReference {
  const PriorityReference({
    required this.id,
    required this.name,
    required this.level,
    this.slaHours,
    this.responseSlaHours,
  });

  final int id;
  final String name;
  final int level;
  final int? slaHours;
  final int? responseSlaHours;

  factory PriorityReference.fromMap(Map<String, Object?> map) {
    return PriorityReference(
      id: map['id'] as int,
      name: map['name'] as String,
      level: map['level'] as int,
      slaHours: map['slaHours'] as int?,
      responseSlaHours: map['responseSlaHours'] as int?,
    );
  }
}

class ReferenceDataService {
  const ReferenceDataService(this._database);

  final Database _database;

  Future<List<DepartmentReference>> getActiveDepartments() async {
    final rows = await _database.query(
      AppDatabase.departmentsTable,
      columns: ['id', 'name'],
      where: 'isActive = 1',
      orderBy: 'name ASC',
    );
    return rows.map(DepartmentReference.fromMap).toList(growable: false);
  }

  Future<List<PriorityReference>> getActivePriorities() async {
    final rows = await _database.query(
      AppDatabase.prioritiesTable,
      columns: ['id', 'name', 'level', 'slaHours', 'responseSlaHours'],
      where: 'isActive = 1',
      orderBy: 'level ASC',
    );
    return rows.map(PriorityReference.fromMap).toList(growable: false);
  }

  Future<List<CategoryReference>> getActiveCategories() async {
    final rows = await _database.query(
      AppDatabase.categoriesTable,
      columns: ['id', 'name'],
      where: 'isActive = 1',
      orderBy: 'name ASC',
    );
    return rows.map(CategoryReference.fromMap).toList(growable: false);
  }

  Future<List<StaffReference>> getActiveStaff() async {
    final rows = await _database.query(
      AppDatabase.usersTable,
      columns: ['id', 'fullName'],
      where: "LOWER(role) = 'staff' AND isActive = 1",
      orderBy: 'fullName ASC',
    );
    return rows.map(StaffReference.fromMap).toList(growable: false);
  }

  Future<void> updatePrioritySla({
    required int priorityId,
    required int responseHours,
    required int resolutionHours,
  }) async {
    if (priorityId <= 0 ||
        responseHours <= 0 ||
        resolutionHours <= 0 ||
        responseHours > resolutionHours) {
      throw ArgumentError(
        'SLA hours must be positive and response SLA cannot exceed resolution SLA.',
      );
    }
    final updated = await _database.update(
      AppDatabase.prioritiesTable,
      {
        'responseSlaHours': responseHours,
        'slaHours': resolutionHours,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND isActive = 1',
      whereArgs: [priorityId],
    );
    if (updated == 0) {
      throw ArgumentError('Priority was not found or is inactive.');
    }
  }
}
