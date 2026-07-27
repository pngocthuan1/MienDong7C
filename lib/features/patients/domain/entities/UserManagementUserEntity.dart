import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';

class UserManagementUserEntity {
  const UserManagementUserEntity({
    required this.id,
    required this.patientCode,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.gender,
    required this.birthYear,
    required this.currentStatus,
    required this.lastVisitText,
    required this.totalVisits,
    required this.currentDepartmentName,
  });

  final String id;
  final String patientCode;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String gender;
  final String birthYear;
  final UserManagementVisitStatus currentStatus;
  final String lastVisitText;
  final int totalVisits;
  final String currentDepartmentName;
}
