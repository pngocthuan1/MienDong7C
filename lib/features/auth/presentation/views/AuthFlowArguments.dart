import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

enum OtpPurpose {
  registration,
  passwordReset,
}

class OtpViewArgs {
  const OtpViewArgs({
    required this.phoneNumber,
    this.purpose = OtpPurpose.passwordReset,
    this.fullName = '',
    this.password = '',
    this.key = '',
    this.adjustSeconds = 0,
    this.remainingSeconds = 60,
  });

  final String phoneNumber;
  final OtpPurpose purpose;
  final String fullName;
  final String password;
  final String key;
  final int adjustSeconds;
  final int remainingSeconds;
}

class ResetPasswordViewArgs {
  const ResetPasswordViewArgs({
    required this.phoneNumber,
    required this.otpCode,
    this.key = '',
    this.adjustSeconds = 0,
  });

  final String phoneNumber;
  final String otpCode;
  final String key;
  final int adjustSeconds;
}

class MedicalTicketViewArgs {
  final MedicalTicketEntity ticket;

  const MedicalTicketViewArgs({required this.ticket});
}

class UserManagementDetailViewArgs {
  final String userId;

  const UserManagementDetailViewArgs({required this.userId});
}
