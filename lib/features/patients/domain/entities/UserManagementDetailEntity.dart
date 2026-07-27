import 'package:benhvien7c/features/patients/domain/entities/UserManagementHistoryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementUserEntity.dart';

class UserManagementDetailEntity {
  const UserManagementDetailEntity({
    required this.user,
    required this.address,
    required this.insuranceCode,
    required this.createdAtText,
    required this.emergencyContact,
    required this.note,
    required this.histories,
  });

  final UserManagementUserEntity user;
  final String address;
  final String insuranceCode;
  final String createdAtText;
  final String emergencyContact;
  final String note;
  final List<UserManagementHistoryEntity> histories;
}
