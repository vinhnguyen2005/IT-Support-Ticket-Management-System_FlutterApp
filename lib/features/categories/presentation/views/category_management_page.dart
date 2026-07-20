import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/issue_category.dart';
import '../viewmodels/category_view_model.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryViewModel>().loadCategories();
    });
  }

  Future<void> _showCategoryDialog([IssueCategory? category]) async {
    final viewModel = context.read<CategoryViewModel>();
    final nameController = TextEditingController(
      text: category?.categoryName ?? '',
    );
    final descriptionController = TextEditingController(
      text: category?.description ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var isActive = category?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: Icon(
            category == null
                ? Icons.create_new_folder_outlined
                : Icons.edit_outlined,
          ),
          title: Text(category == null ? 'Add category' : 'Edit category'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Category name is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Detailed description',
                      alignLabelWithHint: true,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active category'),
                    subtitle: const Text(
                      'Available for new ticket classification',
                    ),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final success = await viewModel.saveCategory(
                  category?.id,
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                  isActive,
                );
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CategoryViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: viewModel.isLoading ? null : viewModel.loadCategories,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _body(viewModel),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isLoading ? null : _showCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }

  Widget _body(CategoryViewModel viewModel) {
    if (viewModel.isLoading && viewModel.categories.isEmpty) {
      return const AppListSkeleton();
    }
    if (viewModel.errorMessage != null && viewModel.categories.isEmpty) {
      return AppErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadCategories,
      );
    }
    if (viewModel.categories.isEmpty) {
      return const AppEmptyState(
        title: 'No categories yet',
        message: 'Add categories to organize incoming support requests.',
        icon: Icons.category_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        final horizontal = constraints.maxWidth > 1232
            ? (constraints.maxWidth - 1200) / 2
            : 16.0;
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 96),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 190,
          ),
          itemCount: viewModel.categories.length,
          itemBuilder: (context, index) {
            final category = viewModel.categories[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category.categoryName,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _showCategoryDialog(category),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        category.description.isEmpty
                            ? 'No description provided.'
                            : category.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            category.isActive ? 'Active' : 'Inactive',
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: category.isActive,
                          onChanged: (value) => viewModel.saveCategory(
                            category.id,
                            category.categoryName,
                            category.description,
                            value,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
