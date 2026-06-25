import '../../../../core/security/password_hasher.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/i_auth_local_data_source.dart';
import '../dtos/login_request_dto.dart';
import '../mappers/user_mapper.dart';

class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl({
    required IAuthLocalDataSource localDataSource,
    required UserMapper userMapper,
  })  : _localDataSource = localDataSource,
        _userMapper = userMapper;

  final IAuthLocalDataSource _localDataSource;
  final UserMapper _userMapper;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await _localDataSource.login(
      LoginRequestDto(
        username: username,
        password: password,
      ),
    );

    return _userMapper.mapToEntity(response.user);
  }

  @override
  Future<void> logout() {
    return _localDataSource.logout();
  }

  @override
  Future<User?> getCurrentUser() async {
    final user = await _localDataSource.getCurrentUser();
    if (user == null) {
      return null;
    }

    return _userMapper.mapToEntity(user);
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String newPassword,
  }) {
    return _localDataSource.changePassword(
      userId: userId,
      newPasswordHash: PasswordHasher.hash(newPassword),
    );
  }
}
