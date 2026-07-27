enum UserManagementVisitStatus {
  pendingApproval,
  scheduled,
  waitingForExamination,
  inProgress,
  completed,
  rejected,
  canceled,
  noShow,
}

extension UserManagementVisitStatusX on UserManagementVisitStatus {
  String get label => switch (this) {
        UserManagementVisitStatus.pendingApproval => 'Chờ xác nhận',
        UserManagementVisitStatus.scheduled => 'Đã đặt lịch',
        UserManagementVisitStatus.waitingForExamination => 'Chờ khám',
        UserManagementVisitStatus.inProgress => 'Đang khám',
        UserManagementVisitStatus.completed => 'Đã khám',
        UserManagementVisitStatus.rejected => 'Bị từ chối',
        UserManagementVisitStatus.canceled => 'Đã hủy',
        UserManagementVisitStatus.noShow => 'Vắng khám',
      };

  bool get isActiveFlow => switch (this) {
        UserManagementVisitStatus.pendingApproval ||
        UserManagementVisitStatus.scheduled ||
        UserManagementVisitStatus.waitingForExamination ||
        UserManagementVisitStatus.inProgress => true,
        UserManagementVisitStatus.completed ||
        UserManagementVisitStatus.rejected ||
        UserManagementVisitStatus.canceled ||
        UserManagementVisitStatus.noShow => false,
      };
}
