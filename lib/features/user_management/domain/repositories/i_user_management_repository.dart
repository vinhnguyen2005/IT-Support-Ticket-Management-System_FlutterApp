import '../entities/managed_user.dart';

abstract interface class IUserManagementRepository {
  Future<List<ManagedUser>> getUsers();

  Future<ManagedUser?> getUserById(int id);

  Future<void> createUser({
    required String fullName,
    required String username,
    required String email,
    required String temporaryPassword,
    required String role,
    int? departmentId,
    String? phoneNumber,
  });

  Future<void> updateUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
    int? departmentId,
    String? phoneNumber,
    required bool isActive,
  });

  Future<void> setUserActive({required int id, required bool isActive});

  Future<void> resetTemporaryPassword({
    required int id,
    required String temporaryPassword,
  });
}
