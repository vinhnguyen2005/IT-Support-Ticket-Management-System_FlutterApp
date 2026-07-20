import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../enums/ticket_status.dart';

class TicketStatusBadge extends StatelessWidget {
  const TicketStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final parsed = TicketStatus.fromValue(status);
    final color = AppColors.ticketStatus(status);
    final icon = switch (parsed) {
      TicketStatus.submitted => Icons.inbox_outlined,
      TicketStatus.assigned => Icons.assignment_ind_outlined,
      TicketStatus.processing => Icons.sync,
      TicketStatus.resolved => Icons.task_alt,
      TicketStatus.closed => Icons.lock_outline,
      TicketStatus.cancelled => Icons.cancel_outlined,
    };
    return _Badge(label: status, color: color, icon: icon);
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    return _Badge(
      label: priority,
      color: AppColors.priority(priority),
      icon: Icons.flag_outlined,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 30),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
