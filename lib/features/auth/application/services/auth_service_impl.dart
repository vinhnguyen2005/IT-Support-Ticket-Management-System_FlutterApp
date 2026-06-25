import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'i_auth_service.dart';

class AuthServiceImpl implements IAuthService {
  const AuthServiceImpl(this._authRepository);

  final IAuthRepository _authRepository;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      throw const AuthException('Username is required.');
    }

    if (password.isEmpty) {
      throw const AuthException('Password is required.');
    }

    return _authRepository.login(
      username: normalizedUsername,
      password: password,
    );
  }

  @override
  Future<void> logout() {
    return _authRepository.logout();
  }

  @override
  Future<User?> getCurrentUser() {
    return _authRepository.getCurrentUser();
  }

  @override
  Future<void> changePassword({
    required User user,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (newPassword.length < 8) {
      throw const AuthException('Password must have at least 8 characters.');
    }

    if (newPassword != confirmPassword) {
      throw const AuthException('Password confirmation does not match.');
    }

    return _authRepository.changePassword(
      userId: user.id,
      newPassword: newPassword,
    );
  }
}
