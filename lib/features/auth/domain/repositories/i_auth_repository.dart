import '../entities/user.dart';

abstract interface class IAuthRepository {
  Future<User> login({required String username, required String password});

  Future<void> logout();

  Future<User?> getCurrentUser();

  Future<void> changePassword({
    required int userId,
    required String newPassword,
  });
}
