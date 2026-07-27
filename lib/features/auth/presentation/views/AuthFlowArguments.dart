import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

class MedicalTicketViewArgs {
  final MedicalTicketEntity ticket;

  const MedicalTicketViewArgs({required this.ticket});
}

class UserManagementDetailViewArgs {
  final String userId;

  const UserManagementDetailViewArgs({required this.userId});
}
