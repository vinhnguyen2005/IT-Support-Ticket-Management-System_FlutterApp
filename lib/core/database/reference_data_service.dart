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

class PriorityReference {
  const PriorityReference({
    required this.id,
    required this.name,
    required this.level,
    this.slaHours,
  });

  final int id;
  final String name;
  final int level;
  final int? slaHours;

  factory PriorityReference.fromMap(Map<String, Object?> map) {
    return PriorityReference(
      id: map['id'] as int,
      name: map['name'] as String,
      level: map['level'] as int,
      slaHours: map['slaHours'] as int?,
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
      columns: ['id', 'name', 'level', 'slaHours'],
      where: 'isActive = 1',
      orderBy: 'level ASC',
    );
    return rows.map(PriorityReference.fromMap).toList(growable: false);
  }
}
