import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/security/password_hasher.dart';
import '../dtos/login_request_dto.dart';
import '../dtos/login_response_dto.dart';
import '../dtos/user_dto.dart';
import 'i_auth_local_data_source.dart';

class AuthLocalDataSourceImpl implements IAuthLocalDataSource {
  AuthLocalDataSourceImpl(this._database);

  final Database _database;

  int? _currentUserId;

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final username = request.username.trim();
    final rows = await _database.query(
      AppDatabase.usersTable,
      where: 'LOWER(username) = LOWER(?)',
      whereArgs: [username],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AuthException('Username or password is incorrect.');
    }

    final user = UserDto.fromMap(rows.first);
    if (!user.isActive) {
      throw const AuthException('This account is disabled.');
    }

    final passwordHash = user.passwordHash;
    if (passwordHash == null ||
        !PasswordHasher.verify(
          password: request.password,
          passwordHash: passwordHash,
        )) {
      throw const AuthException('Username or password is incorrect.');
    }

    await _database.update(
      AppDatabase.usersTable,
      {'lastLoginAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );

    await saveCurrentUser(user);
    return LoginResponseDto(user: user);
  }

  @override
  Future<void> logout() async {
    _currentUserId = null;
  }

  @override
  Future<UserDto?> getCurrentUser() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return null;
    }

    final rows = await _database.query(
      AppDatabase.usersTable,
      where: 'id = ?',
      whereArgs: [currentUserId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return UserDto.fromMap(rows.first);
  }

  @override
  Future<void> saveCurrentUser(UserDto user) async {
    _currentUserId = user.id;
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String newPasswordHash,
  }) async {
    final updatedRows = await _database.update(
      AppDatabase.usersTable,
      {
        'passwordHash': newPasswordHash,
        'mustChangePassword': 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (updatedRows == 0) {
      throw const AuthException('User account was not found.');
    }
  }
}
