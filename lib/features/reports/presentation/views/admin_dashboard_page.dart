import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/database/reference_data_service.dart';
import '../../../../core/enums/sla_status.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../tickets/presentation/views/ticket_detail_page.dart';
import '../../domain/entities/low_rating_feedback_report.dart';
import '../../domain/entities/processing_time_report.dart';
import '../../domain/entities/report_filter.dart';
import '../../domain/entities/sla_attention_report.dart';
import '../../domain/entities/staff_performance_report.dart';
import '../../domain/entities/ticket_volume_report.dart';
import '../../domain/entities/user_report.dart';
import '../viewmodels/admin_dashboard_view_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late DateTimeRange _dateRange;
  ReportFilter _filter = const ReportFilter();

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _dateRange = DateTimeRange(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Future<void> _loadReport() {
    return context.read<AdminDashboardViewModel>().loadDashboardData(
      _databaseDate(_dateRange.start),
      _databaseDate(_dateRange.end),
      filter: _filter,
    );
  }

  Future<void> _updateFilter(ReportFilter filter) async {
    setState(() => _filter = filter);
    await _loadReport();
  }

  Future<void> _selectDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      helpText: 'Select report period',
    );
    if (selectedRange == null || !mounted) return;

    setState(() => _dateRange = selectedRange);
    await _loadReport();
  }

  Future<void> _applyPreset(int days) async {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _dateRange = DateTimeRange(
        start: today.subtract(Duration(days: days - 1)),
        end: today,
      );
    });
    await _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AdminDashboardViewModel>();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Admin reports'),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: viewModel.isLoading ? null : _loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(AdminDashboardViewModel viewModel) {
    if (viewModel.isLoading && viewModel.volumeReports.isEmpty) {
      return const AppListSkeleton(itemCount: 6);
    }

    return AppContent(
      maxWidth: 1280,
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: _loadReport,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ReportHero(viewModel: viewModel, dateRange: _dateRange),
            const SizedBox(height: 16),
            _DateFilterCard(
              dateRange: _dateRange,
              isLoading: viewModel.isLoading,
              onSelectDateRange: _selectDateRange,
              onPresetSelected: _applyPreset,
            ),
            const SizedBox(height: 12),
            _ReportFilterCard(
              filter: _filter,
              priorities: viewModel.slaPolicies,
              categories: viewModel.categories,
              staff: viewModel.staff,
              isLoading: viewModel.isLoading,
              onChanged: _updateFilter,
            ),
            if (viewModel.isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorCard(
                message: viewModel.errorMessage!,
                onRetry: _loadReport,
              ),
            ],
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.space_dashboard_outlined,
              title: 'Ticket overview',
              subtitle: 'Status totals for the selected period',
            ),
            const SizedBox(height: 12),
            _SummaryCards(viewModel: viewModel),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.timer_outlined,
              title: 'SLA performance',
              subtitle: 'Compliance for tickets created in the selected period',
            ),
            const SizedBox(height: 12),
            _SlaSummaryCards(viewModel: viewModel),
            if (viewModel.slaPolicies.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SlaPolicyCard(viewModel: viewModel),
            ],
            const SizedBox(height: 24),
            _SectionTitle(
              icon: Icons.crisis_alert_outlined,
              title: 'SLA attention required',
              subtitle:
                  '${viewModel.slaAttention.length} active tickets need admin attention',
            ),
            const SizedBox(height: 12),
            _SlaAttentionTable(reports: viewModel.slaAttention),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.calendar_view_week_outlined,
              title: 'Ticket activity by day',
              subtitle: 'Daily ticket counts separated by status',
            ),
            const SizedBox(height: 12),
            _TicketVolumeTable(reports: viewModel.volumeReports),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.engineering_outlined,
              title: 'Staff performance',
              subtitle: 'Assigned and completed tickets by technician',
            ),
            const SizedBox(height: 12),
            _StaffPerformanceTable(reports: viewModel.performanceReports),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.timer_outlined,
              title: 'Processing time by category',
              subtitle: 'Based on resolvedAt, not the last edited time',
            ),
            const SizedBox(height: 12),
            _ProcessingTimeTable(reports: viewModel.processingTimeReports),
            const SizedBox(height: 24),
            const _SectionTitle(
              icon: Icons.reviews_outlined,
              title: 'Feedback quality',
              subtitle: 'Feedback for tickets closed in the selected period',
            ),
            const SizedBox(height: 12),
            _FeedbackSummaryCards(viewModel: viewModel),
            const SizedBox(height: 12),
            _LowRatingFeedbackTable(reports: viewModel.lowRatingFeedback),
            const SizedBox(height: 24),
            _SectionTitle(
              icon: Icons.group_outlined,
              title: 'User report',
              subtitle:
                  '${viewModel.userReports.length} accounts • '
                  '${viewModel.activeUsers} active • '
                  '${viewModel.inactiveUsers} inactive',
            ),
            const SizedBox(height: 12),
            _UserReportTable(reports: viewModel.userReports),
            const SizedBox(height: 24),
          ],
          /* Replaced by the responsive report sections above.
          _SectionTitle(
            icon: Icons.group_outlined,
            title: 'User report',
            subtitle:
                '${viewModel.userReports.length} accounts • '
                '${viewModel.activeUsers} active • '
                '${viewModel.inactiveUsers} inactive',
          ),
          const SizedBox(height: 12),
          _UserReportTable(reports: viewModel.userReports),
          const SizedBox(height: 24),
        ],
          */
        ),
      ),
    );
  }
}

class _ReportHero extends StatelessWidget {
  const _ReportHero({required this.viewModel, required this.dateRange});

  final AdminDashboardViewModel viewModel;
  final DateTimeRange dateRange;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.insights, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations intelligence',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'A clear view of tickets, staff and users',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _HeroStat(
                label: 'Tickets',
                value: '${viewModel.totalTicketsOverall}',
              ),
              _HeroStat(
                label: 'Completion',
                value:
                    '${(viewModel.completionRate * 100).toStringAsFixed(1)}%',
              ),
              _HeroStat(
                label: 'Active users',
                value: '${viewModel.activeUsers}',
              ),
              _HeroStat(
                label: 'Period',
                value:
                    '${_displayDate(dateRange.start)} – '
                    '${_displayDate(dateRange.end)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 105),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateFilterCard extends StatelessWidget {
  const _DateFilterCard({
    required this.dateRange,
    required this.isLoading,
    required this.onSelectDateRange,
    required this.onPresetSelected,
  });

  final DateTimeRange dateRange;
  final bool isLoading;
  final VoidCallback onSelectDateRange;
  final ValueChanged<int> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final selectedDays = dateRange.duration.inDays + 1;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Report period',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_displayDate(dateRange.start)} – '
                    '${_displayDate(dateRange.end)}',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in const [7, 30, 90])
                  ChoiceChip(
                    label: Text('$days days'),
                    selected: selectedDays == days,
                    onSelected: isLoading
                        ? null
                        : (_) => onPresetSelected(days),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('Custom'),
                  onPressed: isLoading ? null : onSelectDateRange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportFilterCard extends StatelessWidget {
  const _ReportFilterCard({
    required this.filter,
    required this.priorities,
    required this.categories,
    required this.staff,
    required this.isLoading,
    required this.onChanged,
  });

  final ReportFilter filter;
  final List<PriorityReference> priorities;
  final List<CategoryReference> categories;
  final List<StaffReference> staff;
  final bool isLoading;
  final ValueChanged<ReportFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.filter_alt_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Report filters',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!filter.isEmpty)
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => onChanged(const ReportFilter()),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 920
                    ? 4
                    : constraints.maxWidth >= 520
                    ? 2
                    : 1;
                const gap = 12.0;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        key: ValueKey('priority-${filter.priority}'),
                        initialValue: filter.priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All priorities',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...priorities.map(
                            (item) => DropdownMenuItem(
                              value: item.name,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) =>
                                  onChanged(filter.copyWith(priority: value)),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        key: ValueKey('category-${filter.categoryId}'),
                        initialValue: filter.categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All categories',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...categories.map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) =>
                                  onChanged(filter.copyWith(categoryId: value)),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<int?>(
                        isExpanded: true,
                        key: ValueKey('staff-${filter.staffId}'),
                        initialValue: filter.staffId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned staff',
                          prefixIcon: Icon(Icons.engineering_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All staff',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...staff.map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) =>
                                  onChanged(filter.copyWith(staffId: value)),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<SlaStatus?>(
                        isExpanded: true,
                        key: ValueKey('sla-${filter.slaStatus}'),
                        initialValue: filter.slaStatus,
                        decoration: const InputDecoration(
                          labelText: 'Resolution SLA',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text(
                              'All SLA states',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...SlaStatus.values.map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(
                                status.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) =>
                                  onChanged(filter.copyWith(slaStatus: value)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.viewModel});

  final AdminDashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Total',
        viewModel.totalTicketsOverall,
        Icons.confirmation_number,
        Colors.blue,
      ),
      (
        'Open',
        viewModel.totalOpenOverall,
        Icons.pending_actions,
        Colors.orange,
      ),
      (
        'Submitted',
        viewModel.totalSubmittedOverall,
        Icons.inbox_outlined,
        Colors.indigo,
      ),
      (
        'Assigned',
        viewModel.totalAssignedOverall,
        Icons.assignment_ind_outlined,
        Colors.teal,
      ),
      (
        'Processing',
        viewModel.totalProcessingOverall,
        Icons.build_outlined,
        Colors.deepPurple,
      ),
      (
        'Resolved',
        viewModel.totalResolvedOverall,
        Icons.task_alt,
        Colors.green,
      ),
      (
        'Closed',
        viewModel.totalClosedOverall,
        Icons.lock_outline,
        Colors.blueGrey,
      ),
      (
        'Cancelled',
        viewModel.totalCancelledOverall,
        Icons.cancel_outlined,
        Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            ...items.map(
              (item) => _MetricCard(
                width: width,
                label: item.$1,
                value: '${item.$2}',
                icon: item.$3,
                color: item.$4,
              ),
            ),
            _MetricCard(
              width: width,
              label: 'Completion',
              value: '${(viewModel.completionRate * 100).toStringAsFixed(1)}%',
              icon: Icons.percent,
              color: Colors.green,
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        elevation: 0,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: color.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlaSummaryCards extends StatelessWidget {
  const _SlaSummaryCards({required this.viewModel});

  final AdminDashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.slaSummary;
    final items = [
      (
        'Response compliance',
        '${(summary.responseComplianceRate * 100).toStringAsFixed(1)}%',
        Icons.reply_outlined,
        Colors.blue,
      ),
      (
        'Resolution compliance',
        '${(summary.resolutionComplianceRate * 100).toStringAsFixed(1)}%',
        Icons.task_alt,
        Colors.green,
      ),
      (
        'At risk',
        '${summary.currentlyAtRisk}',
        Icons.warning_amber,
        Colors.orange,
      ),
      ('Breached', '${summary.currentlyBreached}', Icons.timer_off, Colors.red),
      (
        'Exempt',
        '${summary.exempt}',
        Icons.remove_circle_outline,
        Colors.blueGrey,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => _MetricCard(
                  width: width,
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                  color: item.$4,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _SlaPolicyCard extends StatelessWidget {
  const _SlaPolicyCard({required this.viewModel});

  final AdminDashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLA policies',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'New deadlines use these values. Existing ticket deadlines are unchanged.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: viewModel.slaPolicies
                  .map(
                    (policy) => ActionChip(
                      avatar: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        '${policy.name}: ${policy.responseSlaHours ?? '—'}h / '
                        '${policy.slaHours ?? '—'}h',
                      ),
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _editPolicy(context, policy),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editPolicy(
    BuildContext context,
    PriorityReference policy,
  ) async {
    final result = await showDialog<(int, int)?>(
      context: context,
      builder: (_) => _SlaPolicyDialog(policy: policy),
    );
    if (result == null || !context.mounted) return;
    final success = await viewModel.updateSlaPolicy(
      priorityId: policy.id,
      responseHours: result.$1,
      resolutionHours: result.$2,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'SLA policy updated.' : 'SLA policy update failed.',
        ),
      ),
    );
  }
}

class _SlaPolicyDialog extends StatefulWidget {
  const _SlaPolicyDialog({required this.policy});

  final PriorityReference policy;

  @override
  State<_SlaPolicyDialog> createState() => _SlaPolicyDialogState();
}

class _SlaPolicyDialogState extends State<_SlaPolicyDialog> {
  late final TextEditingController _responseController;
  late final TextEditingController _resolutionController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _responseController = TextEditingController(
      text: '${widget.policy.responseSlaHours ?? ''}',
    );
    _resolutionController = TextEditingController(
      text: '${widget.policy.slaHours ?? ''}',
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  void _save() {
    final response = int.tryParse(_responseController.text.trim());
    final resolution = int.tryParse(_resolutionController.text.trim());
    if (response == null || resolution == null) {
      setState(() => _errorMessage = 'Enter valid SLA hours.');
      return;
    }
    if (response <= 0 || resolution <= 0 || response > resolution) {
      setState(
        () => _errorMessage =
            'Response SLA must be positive and cannot exceed resolution SLA.',
      );
      return;
    }
    Navigator.pop(context, (response, resolution));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.policy.name} SLA policy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _responseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Response hours'),
            ),
            TextField(
              controller: _resolutionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Resolution hours'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
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

class _SlaAttentionTable extends StatelessWidget {
  const _SlaAttentionTable({required this.reports});

  final List<SlaAttentionReport> reports;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return _ReportTable(
      emptyMessage: 'No active ticket is at risk or breached.',
      isEmpty: reports.isEmpty,
      columns: const [
        DataColumn(label: Text('Ticket')),
        DataColumn(label: Text('Priority')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Staff')),
        DataColumn(label: Text('SLA')),
        DataColumn(label: Text('Deadline')),
        DataColumn(label: Text('Time')),
      ],
      rows: reports
          .map((report) {
            final remaining = report.remainingAt(now);
            final breached = report.slaStatus == SlaStatus.breached;
            return DataRow(
              onSelectChanged: (_) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailPage(ticketId: report.ticketId),
                ),
              ),
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      '#${report.ticketId} ${report.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(Text(report.priority)),
                DataCell(Text(report.categoryName ?? '—')),
                DataCell(Text(report.staffName ?? 'Unassigned')),
                DataCell(
                  _StatusLabel(
                    label: report.slaStatus.label,
                    color: breached ? Colors.red : Colors.orange,
                  ),
                ),
                DataCell(Text(_displayDateTime(report.resolutionDueAt))),
                DataCell(
                  Text(
                    breached
                        ? '${_durationLabel(remaining.abs())} overdue'
                        : '${_durationLabel(remaining)} left',
                    style: TextStyle(
                      color: breached ? Colors.red : Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}

class _FeedbackSummaryCards extends StatelessWidget {
  const _FeedbackSummaryCards({required this.viewModel});

  final AdminDashboardViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final summary = viewModel.feedbackSummary;
    final items = [
      (
        'Average rating',
        '${summary.averageRating.toStringAsFixed(1)} / 5',
        Icons.star_outline,
        Colors.amber.shade800,
      ),
      (
        'Feedback received',
        '${summary.totalFeedback}',
        Icons.rate_review_outlined,
        Colors.blue,
      ),
      (
        'Feedback rate',
        '${(summary.feedbackRate * 100).toStringAsFixed(1)}%',
        Icons.percent,
        Colors.teal,
      ),
      (
        'Low ratings',
        '${summary.lowRatingCount}',
        Icons.sentiment_dissatisfied_outlined,
        Colors.red,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => _MetricCard(
                  width: width,
                  label: item.$1,
                  value: item.$2,
                  icon: item.$3,
                  color: item.$4,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _LowRatingFeedbackTable extends StatelessWidget {
  const _LowRatingFeedbackTable({required this.reports});

  final List<LowRatingFeedbackReport> reports;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      emptyMessage:
          'No one- or two-star feedback belongs to tickets closed in this period.',
      isEmpty: reports.isEmpty,
      columns: const [
        DataColumn(label: Text('Ticket')),
        DataColumn(label: Text('Requester')),
        DataColumn(label: Text('Rating')),
        DataColumn(label: Text('Comment')),
        DataColumn(label: Text('Submitted')),
      ],
      rows: reports
          .map((report) {
            return DataRow(
              onSelectChanged: (_) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TicketDetailPage(ticketId: report.ticketId),
                ),
              ),
              cells: [
                DataCell(
                  SizedBox(
                    width: 220,
                    child: Text(
                      '#${report.ticketId} ${report.ticketTitle}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                DataCell(Text(report.userName)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text('${report.rating}'),
                    ],
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 280,
                    child: Text(
                      report.comment?.trim().isNotEmpty == true
                          ? report.comment!
                          : 'No comment',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(_displayDate(report.createdAt))),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}

class _TicketVolumeTable extends StatelessWidget {
  const _TicketVolumeTable({required this.reports});

  final List<TicketVolumeReport> reports;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      emptyMessage: 'No tickets were created in this period.',
      isEmpty: reports.isEmpty,
      columns: const [
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Total'), numeric: true),
        DataColumn(label: Text('Submitted'), numeric: true),
        DataColumn(label: Text('Assigned'), numeric: true),
        DataColumn(label: Text('Processing'), numeric: true),
        DataColumn(label: Text('Resolved'), numeric: true),
        DataColumn(label: Text('Closed'), numeric: true),
        DataColumn(label: Text('Cancelled'), numeric: true),
      ],
      rows: reports
          .map(
            (report) => DataRow(
              cells: [
                DataCell(Text(report.date)),
                DataCell(Text('${report.totalTickets}')),
                DataCell(Text('${report.submittedTickets}')),
                DataCell(Text('${report.assignedTickets}')),
                DataCell(Text('${report.processingTickets}')),
                DataCell(Text('${report.resolvedTickets}')),
                DataCell(Text('${report.closedTickets}')),
                DataCell(Text('${report.cancelledTickets}')),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _StaffPerformanceTable extends StatelessWidget {
  const _StaffPerformanceTable({required this.reports});

  final List<StaffPerformanceReport> reports;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      emptyMessage: 'No staff accounts are available.',
      isEmpty: reports.isEmpty,
      columns: const [
        DataColumn(label: Text('Staff')),
        DataColumn(label: Text('Assigned'), numeric: true),
        DataColumn(label: Text('Completed'), numeric: true),
        DataColumn(label: Text('Open'), numeric: true),
        DataColumn(label: Text('Completion rate'), numeric: true),
      ],
      rows: reports
          .map((report) {
            final open = report.assignedTickets - report.resolvedTickets;
            final rate = report.assignedTickets == 0
                ? 0.0
                : report.resolvedTickets / report.assignedTickets;
            return DataRow(
              cells: [
                DataCell(Text(report.staffName)),
                DataCell(Text('${report.assignedTickets}')),
                DataCell(Text('${report.resolvedTickets}')),
                DataCell(Text('${open < 0 ? 0 : open}')),
                DataCell(Text('${(rate * 100).toStringAsFixed(1)}%')),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}

class _ProcessingTimeTable extends StatelessWidget {
  const _ProcessingTimeTable({required this.reports});

  final List<ProcessingTimeReport> reports;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      emptyMessage: 'No resolved ticket data is available for this period.',
      isEmpty: reports.isEmpty,
      columns: const [
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Completed tickets'), numeric: true),
        DataColumn(label: Text('Average processing time'), numeric: true),
      ],
      rows: reports
          .map(
            (report) => DataRow(
              cells: [
                DataCell(Text(report.categoryName)),
                DataCell(Text('${report.completedTickets}')),
                DataCell(Text('${report.averageHours.toStringAsFixed(1)} h')),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _UserReportTable extends StatelessWidget {
  const _UserReportTable({required this.reports});

  final List<UserReport> reports;

  @override
  Widget build(BuildContext context) {
    return _ReportTable(
      emptyMessage: 'No user accounts are available.',
      isEmpty: reports.isEmpty,
      columns: const [
        DataColumn(label: Text('User')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Department')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Last login')),
        DataColumn(label: Text('Created tickets'), numeric: true),
        DataColumn(label: Text('Completed tickets'), numeric: true),
      ],
      rows: reports
          .map(
            (report) => DataRow(
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.fullName),
                      Text(
                        '@${report.username}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                DataCell(_RoleLabel(role: report.role)),
                DataCell(Text(report.departmentName ?? '—')),
                DataCell(
                  _StatusLabel(
                    label: report.isActive ? 'Active' : 'Inactive',
                    color: report.isActive ? Colors.green : Colors.red,
                  ),
                ),
                DataCell(
                  Text(
                    report.lastLoginAt == null
                        ? 'Never'
                        : _displayDate(report.lastLoginAt!),
                  ),
                ),
                DataCell(Text('${report.createdTickets}')),
                DataCell(Text('${report.completedTickets}')),
              ],
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({
    required this.emptyMessage,
    required this.isEmpty,
    required this.columns,
    required this.rows,
  });

  final String emptyMessage;
  final bool isEmpty;
  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 36,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(emptyMessage, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.55),
          ),
          headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
          dataRowMinHeight: 56,
          dataRowMaxHeight: 68,
          columnSpacing: 30,
          horizontalMargin: 18,
          dividerThickness: 0.6,
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 21,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color)),
    );
  }
}

class _RoleLabel extends StatelessWidget {
  const _RoleLabel({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role.toLowerCase();
    final color = switch (normalizedRole) {
      'admin' => Colors.deepPurple,
      'staff' => Colors.blue,
      _ => Colors.teal,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
      ),
    );
  }
}

String _databaseDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _displayDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _displayDateTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_displayDate(date)} $hour:$minute';
}

String _durationLabel(Duration duration) {
  final days = duration.inDays;
  final hours = duration.inHours.remainder(24);
  final minutes = duration.inMinutes.remainder(60);
  if (days > 0) return '${days}d ${hours}h';
  if (duration.inHours > 0) return '${duration.inHours}h ${minutes}m';
  return '${minutes.clamp(0, 59)}m';
}
