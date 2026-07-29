import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

enum OtpPurpose {
  registration,
  passwordReset,
}

class OtpViewArgs {
  const OtpViewArgs({
    required this.phoneNumber,
    this.purpose = OtpPurpose.passwordReset,
  });

  final String phoneNumber;
  final OtpPurpose purpose;
}

class ResetPasswordViewArgs {
  const ResetPasswordViewArgs({
    required this.phoneNumber,
    required this.otpCode,
  });

  final String phoneNumber;
  final String otpCode;
}

class MedicalTicketViewArgs {
  final MedicalTicketEntity ticket;

  const MedicalTicketViewArgs({required this.ticket});
}

class UserManagementDetailViewArgs {
  final String userId;

  const UserManagementDetailViewArgs({required this.userId});
}
