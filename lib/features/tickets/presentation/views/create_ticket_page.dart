import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../application/services/i_ticket_service.dart';
import '../../application/services/ticket_service_impl.dart';
import '../../data/mappers/ticket_mapper.dart';
import '../../data/repositories/ticket_repository_impl.dart';
import '../viewmodels/create_ticket_view_model.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key, this.requesterId});

  final int? requesterId;

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  late final Future<CreateTicketViewModel> _viewModelFuture;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _attachmentController = TextEditingController();

  String _issueType = 'General';
  String _priority = 'Medium';
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _viewModelFuture = _createViewModel();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<CreateTicketViewModel> _createViewModel() async {
    return CreateTicketViewModel(await _createTicketService());
  }

  Future<void> _submit(CreateTicketViewModel viewModel) async {
    final success = await viewModel.createTicket(
      title: _titleController.text,
      description: _descriptionController.text,
      issueType: _issueType,
      priority: _priority,
      requesterId: widget.requesterId,
      categoryId: _categoryId,
      attachmentUrl: _attachmentController.text,
    );

    if (!mounted || !success) {
      return;
    }

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
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextField(
                      controller: _titleController,
                      enabled: !viewModel.isLoading,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      enabled: !viewModel.isLoading,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _issueType,
                      decoration: const InputDecoration(
                        labelText: 'Issue type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'General',
                          child: Text('General'),
                        ),
                        DropdownMenuItem(
                          value: 'Hardware',
                          child: Text('Hardware'),
                        ),
                        DropdownMenuItem(
                          value: 'Software',
                          child: Text('Software'),
                        ),
                        DropdownMenuItem(
                          value: 'Network',
                          child: Text('Network'),
                        ),
                      ],
                      onChanged: viewModel.isLoading
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _issueType = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'Medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(
                          value: 'Critical',
                          child: Text('Critical'),
                        ),
                      ],
                      onChanged: viewModel.isLoading
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _priority = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _categoryId ?? 0,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('None')),
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
                              setState(() {
                                _categoryId = value == 0 ? null : value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _attachmentController,
                      enabled: !viewModel.isLoading,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Attachment URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (viewModel.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        viewModel.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _submit(viewModel),
                      icon: viewModel.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_task),
                      label: const Text('Create ticket'),
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

Future<ITicketService> _createTicketService() async {
  return TicketServiceImpl(
    TicketRepositoryImpl(
      localDataSource: await ServiceLocator.ticketLocalDataSource,
      mapper: const TicketMapper(),
    ),
  );
}
