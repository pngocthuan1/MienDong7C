import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';

class UserManagementHistoryEntity {
  const UserManagementHistoryEntity({
    required this.id,
    required this.registeredAtText,
    required this.appointmentTimeText,
    required this.statusUpdatedAtText,
    required this.departmentName,
    required this.serviceName,
    required this.doctorName,
    required this.status,
    required this.note,
    this.rejectionReason,
  });

  final String id;
  final String registeredAtText;
  final String appointmentTimeText;
  final String statusUpdatedAtText;
  final String departmentName;
  final String serviceName;
  final String doctorName;
  final UserManagementVisitStatus status;
  final String note;
  final String? rejectionReason;
}
