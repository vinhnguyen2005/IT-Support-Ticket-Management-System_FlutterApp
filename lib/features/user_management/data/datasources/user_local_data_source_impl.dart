import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../dtos/create_user_request_dto.dart';
import '../dtos/update_user_request_dto.dart';
import '../dtos/user_dto.dart';
import 'i_user_local_data_source.dart';

class UserLocalDataSourceImpl implements IUserLocalDataSource {
  UserLocalDataSourceImpl(this._database);

  final Database _database;

  @override
  Future<List<UserDto>> getUsers() async {
    final rows = await _database.query(
      AppDatabase.usersTable,
      orderBy: 'isActive DESC, role ASC, fullName ASC',
    );

    return rows.map(UserDto.fromMap).toList();
  }

  @override
  Future<UserDto?> getUserById(int id) async {
    final rows = await _database.query(
      AppDatabase.usersTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserDto.fromMap(rows.first);
  }

  @override
  Future<int> createUser(CreateUserRequestDto request) {
    return _database.insert(
      AppDatabase.usersTable,
      request.toMap(DateTime.now()),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<int> updateUser(UpdateUserRequestDto request) {
    return _database.update(
      AppDatabase.usersTable,
      request.toMap(DateTime.now()),
      where: 'id = ?',
      whereArgs: [request.id],
    );
  }

  @override
  Future<int> setUserActive({required int id, required bool isActive}) {
    return _database.update(
      AppDatabase.usersTable,
      {
        'isActive': isActive ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> resetTemporaryPassword({
    required int id,
    required String temporaryPasswordHash,
  }) {
    return _database.update(
      AppDatabase.usersTable,
      {
        'passwordHash': temporaryPasswordHash,
        'mustChangePassword': 1,
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
