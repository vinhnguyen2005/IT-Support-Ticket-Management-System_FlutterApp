import '../../domain/entities/user.dart';

abstract interface class IAuthService {
  Future<User> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<User?> getCurrentUser();

  Future<void> changePassword({
    required User user,
    required String newPassword,
    required String confirmPassword,
  });
}
