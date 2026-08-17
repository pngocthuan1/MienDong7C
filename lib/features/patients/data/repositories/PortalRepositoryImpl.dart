import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
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
  Future<Result<NotificationItemEntity>> createNotification({
    required UserRole role,
    required String content,
    required List<String> attachments,
    required String targetMode,
    required List<String> recipientIds,
    required String senderName,
    required String senderDepartment,
  }) async {
    try {
      final now = DateTime.now();
      final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(now);
      final id = 'NOTIF_${now.millisecondsSinceEpoch}';

      final newItem = NotificationItemEntity(
        id: id,
        title: senderDepartment.isNotEmpty ? senderDepartment : 'Thông báo nội bộ',
        message: content.length > 80 ? '${content.substring(0, 80)}...' : content,
        details: content,
        category: 'Thông báo nội bộ',
        timeLabel: timeStr,
        senderName: senderName.isNotEmpty ? senderName : 'Lê Nguyễn Gia Hưng',
        senderDepartment: senderDepartment.isNotEmpty ? senderDepartment : 'Hệ thống thông báo nội bộ',
        number: now.millisecondsSinceEpoch % 1000,
        createdAt: now,
        isRead: false,
        isImportant: true,
        attachmentName: attachments.isNotEmpty ? attachments.join(', ') : null,
      );

      await _datasource.addTestNotification(role, newItem);
      return Ok(newItem);
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
          dangKyDum: (draft.dangKyGiup != null && draft.dangKyGiup!.trim().isNotEmpty)
              ? draft.dangKyGiup!.trim()
              : (role == UserRole.customer ? '' : draft.fullName),
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

        final patientCodeStr = (serverPhieu?.maBN != null && serverPhieu!.maBN!.trim().isNotEmpty)
            ? serverPhieu.maBN!.trim()
            : '';

        final ticket = MedicalTicketEntity(
          id: bookingId.toString(),
          hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
          hospitalAddress: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
          ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
          roomName: '',
          serviceName: '',
          queueNumber: queueNum,
          scheduleText: _formatScheduleText(serverPhieu?.ngayGioKham, selectedDate, selectedTime),
          patientName: serverPhieu?.hoTen ?? draft.fullName,
          gender: _mapServerGender(serverPhieu?.gioiTinh, draft.gender),
          birthYear: serverPhieu?.namSinh?.toString() ?? draft.birthYear,
          address: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
          insuranceText: draft.identifier.length >= 10 ? 'Có BHYT (${draft.identifier})' : 'Tự túc (Không BHYT)',
          patientCode: patientCodeStr,
          createdAtText: _formatCreatedAtText(serverPhieu?.ngayud),
          note: 'Ghi chú: Phiếu đặt lịch khám chỉ có giá trị trong ngày đặt khám từ 6g30 - 16g30',
          department: department,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
          phoneNumber: serverPhieu?.sdt ?? draft.phoneNumber,
          symptom: serverPhieu?.trieuChung ?? symptom,
          dangKyGiup: serverPhieu?.dangKyDum ?? draft.dangKyGiup,
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
      return Ok(ticket.copyWith(
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        note: 'Ghi chú: Phiếu đặt lịch khám chỉ có giá trị trong ngày đặt khám từ 6g30 - 16g30',
        dangKyGiup: draft.dangKyGiup,
      ));
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
          final entities = listSoKham.map((dto) {
            final serviceNameText = (dto.trieuChung != null && dto.trieuChung!.trim().isNotEmpty)
                ? dto.trieuChung!.trim()
                : 'Khám bệnh';
            return MedicalTicketEntity(
              id: dto.id.toString(),
              hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
              hospitalAddress: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
              ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
              roomName: '',
              serviceName: serviceNameText,
              queueNumber: (dto.soDangKy ?? dto.id).toString().padLeft(3, '0'),
              scheduleText: _formatScheduleText(dto.ngayGioKham, dto.ngayGioKham, ''),
              patientName: dto.hoTen ?? '',
              gender: _mapServerGender(dto.gioiTinh, 'Nam'),
              birthYear: dto.namSinh?.toString() ?? '',
              address: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
              insuranceText: dto.maThe != null && dto.maThe!.isNotEmpty ? 'Có BHYT (${dto.maThe})' : 'Tự túc',
              patientCode: (dto.maBN != null && dto.maBN!.trim().isNotEmpty) ? dto.maBN!.trim() : '',
              createdAtText: _formatCreatedAtText(dto.ngayud ?? dto.ngayGioKham),
              note: 'Ghi chú: Phiếu đặt lịch khám chỉ có giá trị trong ngày đặt khám từ 6g30 - 16g30',
              department: '',
              selectedDate: dto.ngayGioKham,
              selectedTime: '',
              phoneNumber: dto.sdt,
              symptom: dto.trieuChung,
              dangKyGiup: dto.dangKyDum,
            );
          }).toList();
          return Ok(entities);
        } catch (_) {
          // Fallback to mock datasource if network fails
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
      final remote = _remoteDatasource;
      if (remote != null) {
        final ticketId = int.tryParse(id) ?? 0;
        if (ticketId > 0) {
          try {
            await remote.xoaSoKham(ticketId);
          } catch (_) {
          }
        }
      }
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
      final remote = _remoteDatasource;
      if (remote != null) {
        try {
          final listHoSo = await remote.getListHoSo('');
          final List<PatientProfileDraftEntity> remoteProfiles = listHoSo.map((dto) {
            final identifier = (dto.maThe != null && dto.maThe!.trim().isNotEmpty)
                ? dto.maThe!.trim()
                : ((dto.maBhyt != null && dto.maBhyt!.trim().isNotEmpty)
                    ? dto.maBhyt!.trim()
                    : ((dto.maSo != null && dto.maSo!.trim().isNotEmpty)
                        ? dto.maSo!.trim()
                        : (dto.cccd ?? '')));
            return PatientProfileDraftEntity(
              identifier: identifier,
              maSo: dto.maSo,
              fullName: dto.hoTen ?? '',
              birthYear: dto.namSinh ?? '',
              gender: _mapServerGender(dto.gioiTinh, 'Nam'),
              phoneNumber: dto.soDienThoai ?? '',
            );
          }).toList();

          if (remoteProfiles.isNotEmpty) {
            final firstProfileName = remoteProfiles.first.fullName.trim();
            if (firstProfileName.isNotEmpty) {
              AppSessionStore.instance.updateFullName(firstProfileName);
              SharedPreferences.getInstance().then((prefs) {
                final currentPhone = AppSessionStore.instance.currentUser?.phoneNumber ?? '';
                final cleanPhone = currentPhone.replaceAll(RegExp(r'\D'), '');
                if (cleanPhone.isNotEmpty) {
                  prefs.setString('full_name_$cleanPhone', firstProfileName);
                  prefs.setString('saved_full_name', firstProfileName);
                }
              });
            }
          }

          return Ok(remoteProfiles);
        } catch (_) {}
      }

      final localProfiles = await _datasource.loadPatientProfiles();
      final Map<String, PatientProfileDraftEntity> profileMap = {};

      for (var p in localProfiles) {
        if (p.isDeleted) continue;
        final key = (p.maSo != null && p.maSo!.isNotEmpty)
            ? p.maSo!.trim().toLowerCase()
            : '${p.fullName.trim().toLowerCase()}_${p.birthYear.trim()}_${p.identifier.trim().toLowerCase()}';

        if (!profileMap.containsKey(key)) {
          profileMap[key] = p;
        }
      }

      return Ok(profileMap.values.toList());
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
  Future<Result<void>> softDeletePatientProfile(PatientProfileDraftEntity profile) async {
    try {
      final remote = _remoteDatasource;
      final targetMaHs = (profile.maSo != null && profile.maSo!.trim().isNotEmpty)
          ? profile.maSo!.trim()
          : profile.identifier.trim();

      if (remote != null && targetMaHs.isNotEmpty && targetMaHs != 'N/A') {
        try {
          await remote.xoaHoSo(targetMaHs);
        } catch (_) {
        }
      }
      await _datasource.softDeletePatientProfile(profile);
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

  String _mapServerGender(dynamic rawGender, String fallback) {
    if (rawGender == null) return fallback;
    final str = rawGender.toString().trim();
    if (str == '0' || str.toLowerCase() == 'nam') return 'Nam';
    if (str == '1' || str.toLowerCase() == 'nữ' || str.toLowerCase() == 'nu') return 'Nữ';
    if (str.isEmpty || str == '2') return fallback;
    return fallback;
  }

  String _formatScheduleText(String? serverNgayGio, String? date, String? time) {
    if (serverNgayGio != null && serverNgayGio.isNotEmpty) {
      try {
        final clean = serverNgayGio.replaceAll('T', ' ');
        final parts = clean.split(' ');
        if (parts.length >= 2) {
          String datePart = parts[0];
          String timePart = parts[1];
          if (datePart.contains('-')) {
            final d = DateTime.tryParse(datePart);
            if (d != null) datePart = DateFormat('dd/MM/yyyy').format(d);
          }
          final tParts = timePart.split(':');
          if (tParts.length >= 2) {
            timePart = '${tParts[0].padLeft(2, '0')}:${tParts[1].padLeft(2, '0')}';
          }
          return '$datePart $timePart';
        }
      } catch (_) {}
      return serverNgayGio;
    }

    String formattedDate = date ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
    if (formattedDate.contains('-')) {
      final d = DateTime.tryParse(formattedDate);
      if (d != null) formattedDate = DateFormat('dd/MM/yyyy').format(d);
    }

    String formattedTime = time ?? '10:00';
    if (formattedTime.contains('-')) {
      formattedTime = formattedTime.split('-').first.trim();
    }
    formattedTime = formattedTime.replaceAll('g', ':').replaceAll('h', ':').trim();
    if (formattedTime.contains(':')) {
      final tParts = formattedTime.split(':');
      final hh = tParts[0].trim().padLeft(2, '0');
      final mm = tParts.length > 1 ? tParts[1].trim().padLeft(2, '0') : '00';
      formattedTime = '$hh:$mm';
    } else {
      formattedTime = '${formattedTime.padLeft(2, '0')}:00';
    }

    return '$formattedDate $formattedTime';
  }

  String _formatCreatedAtText(String? serverNgayUd) {
    if (serverNgayUd != null && serverNgayUd.isNotEmpty) {
      try {
        final parsed = DateTime.tryParse(serverNgayUd);
        if (parsed != null) {
          return DateFormat('dd/MM/yyyy HH:mm:ss').format(parsed);
        }
        final clean = serverNgayUd.replaceAll('T', ' ');
        final parts = clean.split(' ');
        if (parts.length >= 2) {
          String datePart = parts[0];
          String timePart = parts[1];
          if (datePart.contains('-')) {
            final d = DateTime.tryParse(datePart);
            if (d != null) datePart = DateFormat('dd/MM/yyyy').format(d);
          }
          final tParts = timePart.split(':');
          if (tParts.length >= 3) {
            final ss = tParts[2].split('.').first.trim().padLeft(2, '0');
            final hh = tParts[0].trim().padLeft(2, '0');
            final mm = tParts[1].trim().padLeft(2, '0');
            timePart = '$hh:$mm:$ss';
          } else if (tParts.length == 2) {
            final hh = tParts[0].trim().padLeft(2, '0');
            final mm = tParts[1].trim().padLeft(2, '0');
            timePart = '$hh:$mm:00';
          }
          return '$datePart $timePart';
        }
      } catch (_) {}
      return serverNgayUd;
    }
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
  }
}
