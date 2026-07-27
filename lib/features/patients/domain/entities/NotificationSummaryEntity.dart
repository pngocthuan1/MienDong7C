import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';

class NotificationSummaryEntity {
  const NotificationSummaryEntity({
    required this.total,
    required this.unread,
    required this.important,
    this.lastUpdatedLabel,
  });

  final int total;
  final int unread;
  final int important;
  final String? lastUpdatedLabel;

  NotificationSummaryEntity copyWith({
    int? total,
    int? unread,
    int? important,
    String? lastUpdatedLabel,
  }) {
    return NotificationSummaryEntity(
      total: total ?? this.total,
      unread: unread ?? this.unread,
      important: important ?? this.important,
      lastUpdatedLabel: lastUpdatedLabel ?? this.lastUpdatedLabel,
    );
  }

  factory NotificationSummaryEntity.fromNotifications(
    List<NotificationItemEntity> items,
  ) {
    final total = items.length;
    final unread = items.where((item) => !item.isRead).length;
    final important = items.where((item) => item.isImportant).length;

    return NotificationSummaryEntity(
      total: total,
      unread: unread,
      important: important,
      lastUpdatedLabel: items.isEmpty ? null : items.first.timeLabel,
    );
  }
}
