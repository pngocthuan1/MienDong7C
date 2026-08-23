import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementDetailEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementUserEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationReadStatusEntity.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';

abstract class PortalRepository {
  Future<Result<NotificationSummaryEntity>> loadNotificationSummary(
    UserRole role,
  );

  Future<Result<List<NotificationItemEntity>>> loadNotifications(UserRole role);

  Future<Result<String>> markNotificationAsRead(
    UserRole role,
    String notificationId,
  );

  Future<Result<String>> markAllNotificationsAsRead(UserRole role);

  Future<Result<String>> downloadNotificationAttachment(
    UserRole role,
    String notificationId,
    String customFileName,
  );

  Future<Result<String>> respondToNotification({
    required UserRole role,
    required String notificationId,
    required bool approved,
  });

  Future<Result<NotificationItemEntity>> createNotification({
    required UserRole role,
    required String content,
    required List<String> attachments,
    List<String>? attachmentPaths,
    required String targetMode,
    required List<String> recipientIds,
    List<String>? recipientNames,
    required String senderName,
    required String senderDepartment,
  });

  Future<Result<MedicalTicketEntity>> loadSampleMedicalTicket(
    UserRole role,
    String patientName,
  );

  Future<Result<MedicalTicketEntity>> createMedicalTicket(
    UserRole role,
    PatientProfileDraftEntity draft, {
    String? department,
    String? selectedDate,
    String? selectedTime,
    String? symptom,
  });

  Future<Result<List<MedicalTicketEntity>>> loadMedicalTickets(UserRole role);

  Future<Result<void>> softDeleteMedicalTicket(String id);

  Future<Result<void>> restoreMedicalTicket(String id);

  Future<Result<List<PatientProfileDraftEntity>>> loadPatientProfiles();

  Future<Result<void>> savePatientProfile(PatientProfileDraftEntity profile);

  Future<Result<void>> softDeletePatientProfile(PatientProfileDraftEntity profile);

  Future<Result<List<UserManagementUserEntity>>> loadManagedUsers(
    UserRole role,
  );

  Future<Result<UserManagementDetailEntity>> loadManagedUserDetail(
    UserRole role,
    String userId,
  );

  Future<Result<void>> addTestNotification(
    UserRole role,
    NotificationItemEntity item,
  );

  Future<Result<void>> deleteNotification(
    UserRole role,
    String notificationId,
  );

  Future<Result<void>> toggleImportant(
    UserRole role,
    String notificationId,
  );

  // --- Real Backend DatLichKham API Integration ---
  Future<Result<DkkThongTinKhamListMasterDto>> fetchNgayGioKham();
  Future<Result<List<DkkHoSoBenhNhanDto>>> fetchHoSoByMaHS(String maHS);
  Future<Result<DkkSoKhamDto>> fetchPhieuSoKham(int id);

  Future<Result<List<NotificationReadStatusEntity>>> loadNotificationReadStatus(
    String notificationId,
  );
}
