import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/department.dart';
import '../viewmodels/department_view_model.dart';

class DepartmentManagementPage extends StatefulWidget {
  const DepartmentManagementPage({super.key});

  @override
  State<DepartmentManagementPage> createState() =>
      _DepartmentManagementPageState();
}

class _DepartmentManagementPageState extends State<DepartmentManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DepartmentViewModel>().loadDepartments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DepartmentViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Department management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isLoading
            ? null
            : () => _showEditor(context, viewModel),
        icon: const Icon(Icons.add),
        label: const Text('New department'),
      ),
      body: AppContent(maxWidth: 1100, child: _buildBody(context, viewModel)),
    );
  }

  Widget _buildBody(BuildContext context, DepartmentViewModel viewModel) {
    if (viewModel.isLoading && viewModel.departments.isEmpty) {
      return const AppListSkeleton(itemCount: 5);
    }
    if (viewModel.errorMessage != null && viewModel.departments.isEmpty) {
      return AppErrorState(
        message: viewModel.errorMessage!,
        onRetry: viewModel.loadDepartments,
      );
    }
    if (viewModel.departments.isEmpty) {
      return AppEmptyState(
        icon: Icons.corporate_fare_outlined,
        title: 'No departments yet',
        message: 'Create a department to organize staff and ticket routing.',
        action: FilledButton.icon(
          onPressed: () => _showEditor(context, viewModel),
          icon: const Icon(Icons.add),
          label: const Text('Create department'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.loadDepartments,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 820 ? 2 : 1;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 96),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 172,
            ),
            itemCount: viewModel.departments.length,
            itemBuilder: (context, index) => _DepartmentCard(
              department: viewModel.departments[index],
              onEdit: () => _showEditor(
                context,
                viewModel,
                department: viewModel.departments[index],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    DepartmentViewModel viewModel, {
    Department? department,
  }) async {
    final result = await showDialog<_DepartmentFormValue>(
      context: context,
      builder: (_) => _DepartmentDialog(department: department),
    );
    if (result == null || !context.mounted) return;
    final success = await viewModel.saveDepartment(
      id: department?.id,
      name: result.name,
      description: result.description,
      isActive: result.isActive,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? department == null
                    ? 'Department created.'
                    : 'Department updated.'
              : viewModel.errorMessage ?? 'Unable to save department.',
        ),
      ),
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department, required this.onEdit});

  final Department department;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.corporate_fare_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      department.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Chip(
                    avatar: Icon(
                      department.isActive
                          ? Icons.check_circle_outline
                          : Icons.pause_circle_outline,
                      size: 18,
                    ),
                    label: Text(department.isActive ? 'Active' : 'Inactive'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  department.description?.trim().isNotEmpty == true
                      ? department.description!
                      : 'No description',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Row(
                children: [
                  Text('Department #${department.id}'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentDialog extends StatefulWidget {
  const _DepartmentDialog({this.department});

  final Department? department;

  @override
  State<_DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends State<_DepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.department?.name);
    _descriptionController = TextEditingController(
      text: widget.department?.description,
    );
    _isActive = widget.department?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _DepartmentFormValue(
        name: _nameController.text,
        description: _descriptionController.text,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.department == null ? 'New department' : 'Edit department',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Department name',
                    prefixIcon: Icon(Icons.corporate_fare_outlined),
                  ),
                  validator: (value) => value?.trim().isEmpty ?? true
                      ? 'Department name is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('Active department'),
                  subtitle: const Text(
                    'Inactive departments cannot be selected for new staff.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _DepartmentFormValue {
  const _DepartmentFormValue({
    required this.name,
    required this.description,
    required this.isActive,
  });

  final String name;
  final String description;
  final bool isActive;
}
