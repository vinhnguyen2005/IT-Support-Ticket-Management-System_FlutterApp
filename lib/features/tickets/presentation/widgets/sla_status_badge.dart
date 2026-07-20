import 'package:flutter/material.dart';

import '../../../../core/enums/sla_status.dart';

class SlaStatusBadge extends StatelessWidget {
  const SlaStatusBadge({
    super.key,
    required this.status,
    this.dueAt,
    this.now,
    this.prefix = 'SLA',
  });

  final SlaStatus status;
  final DateTime? dueAt;
  final DateTime? now;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Chip(
      key: Key('sla-${status.name}'),
      avatar: Icon(_icon(status), size: 16, color: color),
      label: Text(_label()),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  String _label() {
    final deadline = dueAt;
    if (deadline == null ||
        status == SlaStatus.met ||
        status == SlaStatus.breachedResolved ||
        status == SlaStatus.exempt) {
      return '$prefix: ${status.label}';
    }
    final current = now ?? DateTime.now();
    final difference = deadline.difference(current);
    final duration = difference.isNegative ? -difference : difference;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final time = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    return status == SlaStatus.breached
        ? '$prefix: Overdue $time'
        : '$prefix: $time left';
  }

  static Color _color(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => const Color(0xFF15803D),
    SlaStatus.atRisk => const Color(0xFFD97706),
    SlaStatus.breached || SlaStatus.breachedResolved => const Color(0xFFDC2626),
    SlaStatus.met => const Color(0xFF047857),
    SlaStatus.exempt => const Color(0xFF64748B),
  };

  static IconData _icon(SlaStatus status) => switch (status) {
    SlaStatus.onTrack => Icons.timer_outlined,
    SlaStatus.atRisk => Icons.warning_amber_rounded,
    SlaStatus.breached ||
    SlaStatus.breachedResolved => Icons.timer_off_outlined,
    SlaStatus.met => Icons.check_circle_outline,
    SlaStatus.exempt => Icons.remove_circle_outline,
  };
}
