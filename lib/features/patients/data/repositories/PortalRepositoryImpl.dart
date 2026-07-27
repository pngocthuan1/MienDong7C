import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/data/datasources/PortalMockDatasource.dart';
import 'package:benhvien7c/features/patients/data/datasources/DatLichKhamRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementDetailEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementUserEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';

class PortalRepositoryImpl implements PortalRepository {
  PortalRepositoryImpl(this._datasource, [this._remoteDatasource]);

  final PortalMockDatasource _datasource;
  final DatLichKhamRemoteDataSource? _remoteDatasource;

  @override
  Future<Result<NotificationSummaryEntity>> loadNotificationSummary(
    UserRole role,
  ) async {
    try {
      final summary = await _datasource.loadNotificationSummary(role);
      return Ok(summary);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<List<NotificationItemEntity>>> loadNotifications(
    UserRole role,
  ) async {
    try {
      final notifications = await _datasource.loadNotifications(role);
      return Ok(notifications);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<String>> markNotificationAsRead(
    UserRole role,
    String notificationId,
  ) async {
    try {
      final message = await _datasource.markNotificationAsRead(
        role,
        notificationId,
      );
      return Ok(message);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<String>> markAllNotificationsAsRead(UserRole role) async {
    try {
      final message = await _datasource.markAllNotificationsAsRead(role);
      return Ok(message);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<String>> downloadNotificationAttachment(
    UserRole role,
    String notificationId,
    String customFileName,
  ) async {
    try {
      final message = await _datasource.downloadNotificationAttachment(
        role,
        notificationId,
        customFileName,
      );
      return Ok(message);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<String>> respondToNotification({
    required UserRole role,
    required String notificationId,
    required bool approved,
  }) async {
    try {
      final message = await _datasource.respondToNotification(
        role: role,
        notificationId: notificationId,
        approved: approved,
      );
      return Ok(message);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<MedicalTicketEntity>> loadSampleMedicalTicket(
    UserRole role,
    String patientName,
  ) async {
    try {
      final ticket = await _datasource.loadSampleMedicalTicket(
        role,
        patientName,
      );
      return Ok(ticket);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<MedicalTicketEntity>> createMedicalTicket(
    UserRole role,
    PatientProfileDraftEntity draft, {
    String? department,
    String? selectedDate,
    String? selectedTime,
    String? symptom,
  }) async {
    try {
      final remote = _remoteDatasource;
      if (remote != null) {
        final identifier = draft.identifier.trim();
        String maHS = '';
        String maBN = '';
        String maBhytHoacMaBn = identifier;

        if (identifier.length == 8) {
          maBN = identifier;
          maHS = identifier;
        } else if (identifier.length == 21 || identifier.startsWith('T')) {
          maHS = identifier;
        }

        final formattedNgayKham = _formatNgayKhamForServer(selectedDate ?? '');
        final formattedGioKham = _formatGioKhamForServer(selectedTime ?? '');

        final req = DangKyKhamRequestDto(
          maHS: maHS,
          maBN: maBN,
          maBhytHoacMaBn: maBhytHoacMaBn,
          hoTen: draft.fullName,
          gioiTinh: draft.gender,
          namSinh: draft.birthYear,
          soDienThoai: draft.phoneNumber,
          ngayKham: formattedNgayKham,
          gioKham: formattedGioKham,
          trieuChung: symptom,
          dangKyDum: role == UserRole.customer ? '' : draft.fullName,
        );
        final bookingId = await remote.dangKyKham(req);

        DkkSoKhamDto? serverPhieu;
        if (bookingId > 0) {
          try {
            serverPhieu = await remote.getPhieuSoKham(bookingId);
          } catch (_) {}
        }

        final queueNum = serverPhieu?.soDangKy != null
            ? serverPhieu!.soDangKy!.toString().padLeft(3, '0')
            : (bookingId > 0 ? bookingId : 1).toString().padLeft(3, '0');

        final patientCodeStr = (serverPhieu?.maBN != null && serverPhieu!.maBN!.isNotEmpty)
            ? serverPhieu.maBN!
            : (draft.identifier.isNotEmpty
                ? draft.identifier
                : 'BN${(bookingId > 0 ? bookingId : 1).toString().padLeft(6, '0')}');

        final ticket = MedicalTicketEntity(
          id: bookingId.toString(),
          hospitalName: 'BỆNH VIỆN MIỀN ĐÔNG 7C',
          hospitalAddress: 'TP. Thủ Đức, TP. Hồ Chí Minh',
          ticketTitle: 'PHIẾU ĐĂNG KÝ KHÁM BỆNH',
          roomName: department ?? 'Phòng khám 1',
          serviceName: 'Khám Nội tổng quát',
          queueNumber: queueNum,
          scheduleText: serverPhieu?.ngayGioKham ?? '${selectedTime ?? '07g00'} - ${selectedDate ?? ''}',
          patientName: serverPhieu?.hoTen ?? draft.fullName,
          gender: serverPhieu?.gioiTinh?.toString() == '0' || serverPhieu?.gioiTinh?.toString() == 'Nam'
              ? 'Nam'
              : (serverPhieu?.gioiTinh?.toString() == '1' || serverPhieu?.gioiTinh?.toString() == 'Nữ' ? 'Nữ' : draft.gender),
          birthYear: serverPhieu?.namSinh?.toString() ?? draft.birthYear,
          address: 'TP. Hồ Chí Minh',
          insuranceText: draft.identifier.length >= 10 ? 'Có BHYT (${draft.identifier})' : 'Tự túc (Không BHYT)',
          patientCode: patientCodeStr,
          createdAtText: 'Hôm nay',
          note: 'Vui lòng có mặt trước 15 phút so với giờ hẹn để hoàn tất thủ tục.',
          department: department ?? 'Phòng khám 1 - Nội tổng quát',
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          phoneNumber: serverPhieu?.sdt ?? draft.phoneNumber,
          symptom: serverPhieu?.trieuChung ?? symptom,
        );
        return Ok(ticket);
      }

      final ticket = await _datasource.createMedicalTicket(
        role,
        draft,
        department: department,
        selectedDate: selectedDate,
        selectedTime: selectedTime,
        symptom: symptom,
      );
      return Ok(ticket);
    } on ApiException catch (e) {
      return Error(e, e.message);
    } on Exception catch (exception) {
      return Error(exception, exception.toString().replaceAll('Exception: ', ''));
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<List<MedicalTicketEntity>>> loadMedicalTickets(UserRole role) async {
    try {
      final remote = _remoteDatasource;
      if (remote != null) {
        try {
          final listSoKham = await remote.getListSoKham();
          if (listSoKham.isNotEmpty) {
            final entities = listSoKham.map((dto) {
              return MedicalTicketEntity(
                id: dto.id.toString(),
                hospitalName: 'BỆNH VIỆN MIỀN ĐÔNG 7C',
                hospitalAddress: 'TP. Thủ Đức, TP. Hồ Chí Minh',
                ticketTitle: 'PHIẾU ĐĂNG KÝ KHÁM BỆNH',
                roomName: 'Phòng khám 1',
                serviceName: 'Khám Nội tổng quát',
                queueNumber: (dto.soDangKy ?? dto.id).toString().padLeft(3, '0'),
                scheduleText: dto.ngayGioKham ?? '',
                patientName: dto.hoTen ?? '',
                gender: dto.gioiTinh?.toString() == '1' || dto.gioiTinh?.toString() == 'Nam' ? 'Nam' : 'Nữ',
                birthYear: dto.namSinh?.toString() ?? '',
                address: 'TP. Hồ Chí Minh',
                insuranceText: dto.maThe != null && dto.maThe!.isNotEmpty ? 'Có BHYT (${dto.maThe})' : 'Tự túc',
                patientCode: dto.maBN ?? 'BN${dto.id.toString().padLeft(6, '0')}',
                createdAtText: dto.ngayGioKham ?? '',
                note: 'Vui lòng mang theo CCCD và thẻ BHYT khi đến khám.',
                department: 'Phòng khám 1 - Nội tổng quát',
                selectedDate: dto.ngayGioKham,
                selectedTime: '',
                phoneNumber: dto.sdt,
                symptom: dto.trieuChung,
              );
            }).toList();
            return Ok(entities);
          }
        } catch (_) {
          // Fallback to mock datasource
        }
      }

      final list = await _datasource.loadMedicalTickets(role);
      return Ok(list);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> softDeleteMedicalTicket(String id) async {
    try {
      await _datasource.softDeleteMedicalTicket(id);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> restoreMedicalTicket(String id) async {
    try {
      await _datasource.restoreMedicalTicket(id);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<List<PatientProfileDraftEntity>>> loadPatientProfiles() async {
    try {
      final list = await _datasource.loadPatientProfiles();
      return Ok(list);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> savePatientProfile(PatientProfileDraftEntity profile) async {
    try {
      await _datasource.savePatientProfile(profile);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> softDeletePatientProfile(String identifier) async {
    try {
      await _datasource.softDeletePatientProfile(identifier);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<List<UserManagementUserEntity>>> loadManagedUsers(
    UserRole role,
  ) async {
    try {
      final users = await _datasource.loadManagedUsers(role);
      return Ok(users);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<UserManagementDetailEntity>> loadManagedUserDetail(
    UserRole role,
    String userId,
  ) async {
    try {
      final detail = await _datasource.loadManagedUserDetail(role, userId);
      return Ok(detail);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> addTestNotification(
    UserRole role,
    NotificationItemEntity item,
  ) async {
    try {
      await _datasource.addTestNotification(role, item);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> deleteNotification(
    UserRole role,
    String notificationId,
  ) async {
    try {
      await _datasource.deleteNotification(role, notificationId);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<void>> toggleImportant(
    UserRole role,
    String notificationId,
  ) async {
    try {
      await _datasource.toggleImportant(role, notificationId);
      return const Ok(null);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<DkkThongTinKhamListMasterDto>> fetchNgayGioKham() async {
    try {
      final remote = _remoteDatasource;
      if (remote != null) {
        final master = await remote.getListNgayGioKham();
        return Ok(master);
      }
      return Ok(DkkThongTinKhamListMasterDto(
        listGioKham: [
          DkkGioKhamDto(id: '07:00-07:30', display: '7g - 7g30'),
          DkkGioKhamDto(id: '07:30-08:00', display: '7g30 - 8g'),
          DkkGioKhamDto(id: '08:00-08:30', display: '8g - 8g30'),
          DkkGioKhamDto(id: '08:30-09:00', display: '8g30 - 9g'),
        ],
        listNgayKham: ['Hôm nay', 'Ngày mai', 'Ngày kia'],
        maxNgayKham: 20,
      ));
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<List<DkkHoSoBenhNhanDto>>> fetchHoSoByMaHS(String maHS) async {
    try {
      final remote = _remoteDatasource;
      if (remote != null) {
        final list = await remote.getListHoSo(maHS);
        return Ok(list);
      }
      return Ok([]);
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  @override
  Future<Result<DkkSoKhamDto>> fetchPhieuSoKham(int id) async {
    try {
      final remote = _remoteDatasource;
      if (remote != null) {
        final dto = await remote.getPhieuSoKham(id);
        return Ok(dto);
      }
      return Ok(DkkSoKhamDto(id: id, hoTen: 'Bệnh Nhân', trangThai: 'Chờ khám'));
    } on Exception catch (exception) {
      return Error(exception, exception.toString());
    } catch (error) {
      return Error(Exception(error.toString()), error.toString());
    }
  }

  String _formatNgayKhamForServer(String ngayKham) {
    if (ngayKham.isEmpty) return ngayKham;
    if (ngayKham.contains(', ')) return ngayKham;
    try {
      final parts = ngayKham.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final dayOfWeekStr = _getVietnameseDayOfWeek(date);
        return '$dayOfWeekStr, $ngayKham';
      }
    } catch (_) {}
    return ngayKham;
  }

  String _getVietnameseDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ nhật';
      default:
        return 'Thứ 2';
    }
  }

  String _formatGioKhamForServer(String gioKham) {
    if (gioKham.isEmpty) return gioKham;
    return gioKham.replaceAllMapped(
      RegExp(r'(\d{1,2}):(\d{2})'),
      (match) => '${int.parse(match[1]!)}g${match[2]!}',
    );
  }
}
