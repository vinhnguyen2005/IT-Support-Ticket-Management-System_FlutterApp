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

  static const int _maxFailedLoginAttempts = 5;
  static const Duration _lockDuration = Duration(minutes: 15);

  final Database _database;

  int? _currentUserId;

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final login = request.username.trim();
    final rows = await _database.query(
      AppDatabase.usersTable,
      where: 'LOWER(username) = LOWER(?) OR LOWER(email) = LOWER(?)',
      whereArgs: [login, login],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AuthException('Username or password is incorrect.');
    }

    final user = UserDto.fromMap(rows.first);
    if (!user.isActive) {
      throw const AuthException('This account is disabled.');
    }

    final isAdmin = user.role.toLowerCase() == 'admin';
    final now = DateTime.now();
    final lockedUntil = user.lockedUntil;
    if (!isAdmin && lockedUntil != null && lockedUntil.isAfter(now)) {
      throw const AuthException(
        'This account is temporarily locked. Please try again later or contact an administrator.',
      );
    }

    final failedLoginAttempts = lockedUntil == null
        ? user.failedLoginAttempts
        : 0;
    final passwordHash = user.passwordHash;
    if (passwordHash == null ||
        !PasswordHasher.verify(
          password: request.password,
          passwordHash: passwordHash,
        )) {
      if (!isAdmin) {
        final isLocked = await _recordFailedLogin(
          userId: user.id,
          failedLoginAttempts: failedLoginAttempts,
          now: now,
        );
        if (isLocked) {
          throw const AuthException(
            'Too many failed login attempts. Please try again after 15 minutes or contact an administrator.',
          );
        }
      }
      throw const AuthException('Username or password is incorrect.');
    }

    await _database.update(
      AppDatabase.usersTable,
      {
        'lastLoginAt': now.toIso8601String(),
        'failedLoginAttempts': 0,
        'lockedUntil': null,
      },
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

  Future<bool> _recordFailedLogin({
    required int userId,
    required int failedLoginAttempts,
    required DateTime now,
  }) async {
    final failedAttempts = failedLoginAttempts + 1;
    final lockedUntil = failedAttempts >= _maxFailedLoginAttempts
        ? now.add(_lockDuration).toIso8601String()
        : null;

    await _database.update(
      AppDatabase.usersTable,
      {
        'failedLoginAttempts': failedAttempts,
        'lockedUntil': lockedUntil,
        'updatedAt': now.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );

    return lockedUntil != null;
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
        'failedLoginAttempts': 0,
        'lockedUntil': null,
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
