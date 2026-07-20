import 'package:flutter/material.dart';
import '../../application/services/i_category_service.dart';
import '../../domain/entities/issue_category.dart';

class CategoryViewModel extends ChangeNotifier {
  final ICategoryService categoryService;

  CategoryViewModel({required this.categoryService});

  bool isLoading = false;
  String? errorMessage;
  List<IssueCategory> categories = [];

  Future<void> loadCategories() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      categories = await categoryService.getAllCategories();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCategory(
    int? id,
    String name,
    String priority,
    bool isActive,
  ) async {
    try {
      if (id == null) {
        await categoryService.createCategory(name, priority, isActive);
      } else {
        await categoryService.editCategory(id, name, priority, isActive);
      }
      await loadCategories(); // Reload lại list sau khi lưu
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await categoryService.removeCategory(id);
      await loadCategories();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }
}
