import '../../../../core/enums/sla_status.dart';

class ReportFilter {
  const ReportFilter({
    this.priority,
    this.categoryId,
    this.staffId,
    this.slaStatus,
  });

  final String? priority;
  final int? categoryId;
  final int? staffId;
  final SlaStatus? slaStatus;

  bool get isEmpty =>
      priority == null &&
      categoryId == null &&
      staffId == null &&
      slaStatus == null;

  ReportFilter copyWith({
    Object? priority = _unset,
    Object? categoryId = _unset,
    Object? staffId = _unset,
    Object? slaStatus = _unset,
  }) {
    return ReportFilter(
      priority: identical(priority, _unset)
          ? this.priority
          : priority as String?,
      categoryId: identical(categoryId, _unset)
          ? this.categoryId
          : categoryId as int?,
      staffId: identical(staffId, _unset) ? this.staffId : staffId as int?,
      slaStatus: identical(slaStatus, _unset)
          ? this.slaStatus
          : slaStatus as SlaStatus?,
    );
  }
}

const _unset = Object();
