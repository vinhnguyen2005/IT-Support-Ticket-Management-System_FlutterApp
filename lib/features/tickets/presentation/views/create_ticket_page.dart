import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/storage/ticket_attachment_storage.dart';
import '../../../../core/enums/issue_type.dart';
import '../../../../core/enums/priority_level.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_states.dart';
import '../../application/services/i_ticket_service.dart';
import '../../application/services/ticket_service_impl.dart';
import '../../data/mappers/ticket_mapper.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../viewmodels/create_ticket_view_model.dart';
import '../widgets/ticket_attachment_field.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key, this.requesterId, this.viewModel});

  final int? requesterId;
  final CreateTicketViewModel? viewModel;

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  late final Future<CreateTicketViewModel> _viewModelFuture;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _issueType = IssueType.defaultValue;
  String _priority = PriorityLevel.defaultValue;
  int? _categoryId = 4;
  String? _attachmentPath;
  bool _ownsAttachment = false;
  String? _titleError;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _viewModelFuture = _createViewModel();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    if (_ownsAttachment) {
      unawaited(TicketAttachmentStorage.deleteManagedFile(_attachmentPath));
    }
    super.dispose();
  }

  Future<CreateTicketViewModel> _createViewModel() async {
    final viewModel =
        widget.viewModel ??
        CreateTicketViewModel(
          await _createTicketService(),
          await ServiceLocator.referenceDataService,
        );
    await viewModel.loadPriorities();
    return viewModel;
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<_AttachmentImageSource>(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(
                bottomSheetContext,
                _AttachmentImageSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(
                bottomSheetContext,
                _AttachmentImageSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    await _pickFile(source);
  }

  Future<void> _pickFile(_AttachmentImageSource source) async {
    try {
      final attachmentPath = switch (source) {
        _AttachmentImageSource.camera =>
          await TicketAttachmentStorage.takeAndStorePhoto(),
        _AttachmentImageSource.gallery =>
          await TicketAttachmentStorage.pickAndStoreImage(),
      };
      if (attachmentPath == null) return;
      if (!mounted) {
        await TicketAttachmentStorage.deleteManagedFile(attachmentPath);
        return;
      }

      if (_ownsAttachment) {
        await TicketAttachmentStorage.deleteManagedFile(_attachmentPath);
      }
      if (!mounted) return;
      setState(() {
        _attachmentPath = attachmentPath;
        _ownsAttachment = true;
      });
    } catch (error) {
      if (!mounted) return;
      final action = source == _AttachmentImageSource.camera
          ? 'take photo'
          : 'select image';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not $action: $error')));
    }
  }

  Future<void> _clearAttachment() async {
    if (_ownsAttachment) {
      await TicketAttachmentStorage.deleteManagedFile(_attachmentPath);
    }
    if (!mounted) return;
    setState(() {
      _attachmentPath = null;
      _ownsAttachment = false;
    });
  }

  Future<void> _submit(CreateTicketViewModel viewModel) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? 'Title is required.' : null;
      _descriptionError = description.isEmpty
          ? 'Description is required.'
          : description.length < 10
          ? 'Please provide at least 10 characters.'
          : null;
    });
    if (_titleError != null || _descriptionError != null) return;

    final success = await viewModel.createTicket(
      title: title,
      description: description,
      issueType: _issueType,
      priority: _priority,
      requesterId: widget.requesterId,
      categoryId: _categoryId,
      attachmentUrl: _attachmentPath,
    );

    if (!mounted || !success) {
      return;
    }

    _ownsAttachment = false;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CreateTicketViewModel>(
      future: _viewModelFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final viewModel = snapshot.data!;
        return AnimatedBuilder(
          animation: viewModel,
          builder: (context, _) {
            return Scaffold(
              appBar: AppBar(title: const Text('Create ticket')),
              body: SafeArea(
                child: AppContent(
                  maxWidth: 960,
                  child: SingleChildScrollView(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Ticket information',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Describe the issue clearly so the support team can respond faster.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _titleController,
                              enabled: !viewModel.isLoading,
                              textInputAction: TextInputAction.next,
                              maxLength: 120,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                hintText: 'Short summary of the issue',
                                errorText: _titleError,
                                prefixIcon: const Icon(Icons.title),
                              ),
                              onChanged: (_) {
                                if (_titleError != null) {
                                  setState(() => _titleError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _descriptionController,
                              enabled: !viewModel.isLoading,
                              minLines: 5,
                              maxLines: 8,
                              maxLength: 2000,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText:
                                    'What happened, when it started, and what you already tried',
                                errorText: _descriptionError,
                                alignLabelWithHint: true,
                              ),
                              onChanged: (_) {
                                if (_descriptionError != null) {
                                  setState(() => _descriptionError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 720;
                                final fieldWidth = wide
                                    ? (constraints.maxWidth - 24) / 3
                                    : constraints.maxWidth;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: fieldWidth,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _issueType,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Issue type',
                                          prefixIcon: Icon(
                                            Icons.devices_other_outlined,
                                          ),
                                        ),
                                        items: IssueType.values
                                            .map(
                                              (item) => DropdownMenuItem(
                                                value: item.value,
                                                child: Text(item.value),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: viewModel.isLoading
                                            ? null
                                            : (value) {
                                                if (value != null) {
                                                  setState(
                                                    () => _issueType = value,
                                                  );
                                                }
                                              },
                                      ),
                                    ),
                                    SizedBox(
                                      width: fieldWidth,
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _priority,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Priority',
                                          prefixIcon: Icon(Icons.flag_outlined),
                                        ),
                                        items:
                                            (viewModel.priorities.isEmpty
                                                    ? PriorityLevel.values.map(
                                                        (item) => item.value,
                                                      )
                                                    : viewModel.priorities.map(
                                                        (item) => item.name,
                                                      ))
                                                .map(
                                                  (item) => DropdownMenuItem(
                                                    value: item,
                                                    child: Text(item),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: viewModel.isLoading
                                            ? null
                                            : (value) {
                                                if (value != null) {
                                                  setState(
                                                    () => _priority = value,
                                                  );
                                                }
                                              },
                                      ),
                                    ),
                                    SizedBox(
                                      width: fieldWidth,
                                      child: DropdownButtonFormField<int>(
                                        initialValue: _categoryId,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Category',
                                          prefixIcon: Icon(
                                            Icons.category_outlined,
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 4,
                                            child: Text('General Support'),
                                          ),
                                          DropdownMenuItem(
                                            value: 1,
                                            child: Text('Network Issue'),
                                          ),
                                          DropdownMenuItem(
                                            value: 2,
                                            child: Text('Hardware Issue'),
                                          ),
                                          DropdownMenuItem(
                                            value: 3,
                                            child: Text('Software Issue'),
                                          ),
                                        ],
                                        onChanged: viewModel.isLoading
                                            ? null
                                            : (value) {
                                                setState(
                                                  () => _categoryId = value,
                                                );
                                              },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 20),
                            TicketAttachmentField(
                              filePath: _attachmentPath,
                              isEditing: true,
                              isBusy: viewModel.isLoading,
                              onPick: _showImageSourceOptions,
                              onClear: _clearAttachment,
                            ),
                            if (viewModel.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              _FormError(message: viewModel.errorMessage!),
                            ],
                            const SizedBox(height: 24),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: viewModel.isLoading
                                    ? null
                                    : () => _submit(viewModel),
                                icon: viewModel.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add_task),
                                label: const Text('Create ticket'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

enum _AttachmentImageSource { camera, gallery }

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

Future<ITicketService> _createTicketService() async {
  return TicketServiceImpl(
    TicketRepositoryImpl(
      localDataSource: await ServiceLocator.ticketLocalDataSource,
      mapper: const TicketMapper(),
    ),
  );
}
