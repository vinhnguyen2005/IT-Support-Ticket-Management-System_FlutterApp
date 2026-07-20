import 'package:flutter/material.dart';

import '../../../../core/enums/priority_level.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../../core/enums/sla_status.dart';

class TicketQueueFilterBar extends StatelessWidget {
  const TicketQueueFilterBar({
    super.key,
    required this.searchController,
    required this.status,
    required this.priority,
    required this.slaStatus,
    required this.resultCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onSlaStatusChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final String status;
  final String priority;
  final String slaStatus;
  final int resultCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final ValueChanged<String?> onSlaStatusChanged;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('queue-ticket-search'),
          controller: searchController,
          textInputAction: TextInputAction.search,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Search tickets',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('queue-ticket-status-filter'),
                isExpanded: true,
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.filter_alt),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All statuses'),
                  ),
                  ...TicketStatus.values.map(
                    (item) => DropdownMenuItem(
                      value: item.value,
                      child: Text(item.value),
                    ),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('queue-ticket-sla-filter'),
                isExpanded: true,
                initialValue: slaStatus,
                decoration: const InputDecoration(
                  labelText: 'Resolution SLA',
                  prefixIcon: Icon(Icons.timer_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All SLA states'),
                  ),
                  ...SlaStatus.values.map(
                    (item) => DropdownMenuItem(
                      value: item.name,
                      child: Text(item.label),
                    ),
                  ),
                ],
                onChanged: onSlaStatusChanged,
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('queue-ticket-priority-filter'),
                isExpanded: true,
                initialValue: priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  prefixIcon: Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All priorities'),
                  ),
                  ...PriorityLevel.values.map(
                    (item) => DropdownMenuItem(
                      value: item.value,
                      child: Text(item.value),
                    ),
                  ),
                ],
                onChanged: onPriorityChanged,
              ),
            ),
            Chip(label: Text('$resultCount/$totalCount tickets')),
            if (onClearFilters != null)
              TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      ],
    );
  }
}
