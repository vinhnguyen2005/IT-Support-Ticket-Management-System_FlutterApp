import 'package:flutter/foundation.dart';

import '../../application/services/i_user_management_service.dart';
import '../../domain/entities/managed_user.dart';

class UserListViewModel extends ChangeNotifier {
  UserListViewModel(this._service);

  final IUserManagementService _service;

  bool _isLoading = false;
  String? _errorMessage;
  List<ManagedUser> _users = const [];

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<ManagedUser> get users => _users;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.getUsers();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setUserActive({required int id, required bool isActive}) async {
    try {
      await _service.setUserActive(id: id, isActive: isActive);
      await loadUsers();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> resetTemporaryPassword({
    required int id,
    required String temporaryPassword,
  }) async {
    try {
      await _service.resetTemporaryPassword(
        id: id,
        temporaryPassword: temporaryPassword,
      );
      await loadUsers();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }
}
