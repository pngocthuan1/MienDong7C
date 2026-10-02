import 'package:flutter/material.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/entities/DkkThongTinKhamModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';

/// ViewModel cho màn hình đối chiếu thông tin trước khi đăng ký (Luồng 3).
class DkkCompareViewModel extends ChangeNotifier {
  DkkCompareViewModel({
    required this.compareModel,
    required this.userDraft,
    required this.repository,
    required this.role,
    required this.department,
    this.departmentId,
    this.provinceCode,
    this.provinceName,
    this.wardCode,
    this.wardName,
    required this.selectedDate,
    required this.selectedTime,
    required this.symptom,
  });

  final DkkThongTinKhamModel compareModel;
  final PatientProfileDraftEntity userDraft;
  final PortalRepository repository;
  final UserRole role;
  final String? department;
  final String? departmentId;
  final String? provinceCode;
  final String? provinceName;
  final String? wardCode;
  final String? wardName;
  final String? selectedDate;
  final String? selectedTime;
  final String? symptom;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  /// Gửi đăng ký khám.
  /// [useSystemData] = true  → dùng thông tin hệ thống bệnh viện (Thẻ 1)
  /// [useSystemData] = false → dùng thông tin người dùng nhập/hồ sơ đã lưu (Thẻ 2)
  Future<Result<MedicalTicketEntity>> submit(bool useSystemData) async {
    if (_isSubmitting) {
      return Error(Exception('Đang xử lý'), 'Đang xử lý, vui lòng chờ.');
    }
    _isSubmitting = true;
    _errorMessage = null;
    _notifySafe();

    try {
      final PatientProfileDraftEntity draftToUse;
      final sys = compareModel.systemSnapshot;
      if (useSystemData) {
        // Dùng thông tin hệ thống → xây draft từ systemSnapshot
        final effectiveCccd = (sys.soCcHc != null && sys.soCcHc!.trim().isNotEmpty)
            ? sys.soCcHc!.trim()
            : (sys.maBhytHoacMaBn.trim().isNotEmpty
                ? sys.maBhytHoacMaBn.trim()
                : userDraft.identifier.trim());

        final effectiveNgayCap = (sys.ngayCap != null && sys.ngayCap!.trim().isNotEmpty)
            ? sys.ngayCap!.trim()
            : (userDraft.cccdIssueDate != null && userDraft.cccdIssueDate!.trim().isNotEmpty
                ? userDraft.cccdIssueDate!.trim()
                : null);

        final effectiveNgaySinh = (sys.ngaySinh != null && sys.ngaySinh!.trim().isNotEmpty)
            ? sys.ngaySinh!.trim()
            : (userDraft.dateOfBirth != null && userDraft.dateOfBirth!.trim().isNotEmpty
                ? userDraft.dateOfBirth!.trim()
                : null);

        final effectivePhone = (sys.soDienThoai != null && sys.soDienThoai!.trim().isNotEmpty)
            ? sys.soDienThoai!.trim()
            : userDraft.phoneNumber.trim();

        draftToUse = PatientProfileDraftEntity(
          identifier: effectiveCccd,
          fullName: sys.hoTen.isNotEmpty ? sys.hoTen : userDraft.fullName,
          birthYear: _extractBirthYear(effectiveNgaySinh).isNotEmpty ? _extractBirthYear(effectiveNgaySinh) : userDraft.birthYear,
          gender: _normalizeGender((sys.gioiTinh != null && sys.gioiTinh!.trim().isNotEmpty) ? sys.gioiTinh! : userDraft.gender),
          phoneNumber: effectivePhone,
          dateOfBirth: effectiveNgaySinh,
          cccdIssueDate: effectiveNgayCap,
          province: sys.tinhTpTen ?? sys.tinhTp ?? userDraft.province,
          ward: sys.phuongXaTen ?? sys.phuongXa ?? userDraft.ward,
          maSo: sys.maBN.isNotEmpty ? sys.maBN : userDraft.maSo,
          maHS: '',
          maBN: sys.maBN.isNotEmpty ? sys.maBN : userDraft.maBN,
          clinic: userDraft.clinic,
        );
      } else {
        // Dùng thông tin người dùng
        // Bảo lưu an toàn: nếu người dùng để trống Ngày cấp hoặc CCCD mà hệ thống có, fallback lấy từ hệ thống
        final effectiveNgayCap = (userDraft.cccdIssueDate != null && userDraft.cccdIssueDate!.trim().isNotEmpty)
            ? userDraft.cccdIssueDate!.trim()
            : (sys.ngayCap != null && sys.ngayCap!.trim().isNotEmpty ? sys.ngayCap!.trim() : null);

        final effectiveIdentifier = userDraft.identifier.trim().isNotEmpty
            ? userDraft.identifier.trim()
            : ((sys.soCcHc != null && sys.soCcHc!.trim().isNotEmpty)
                ? sys.soCcHc!.trim()
                : sys.maBhytHoacMaBn.trim());

        draftToUse = userDraft.copyWith(
          identifier: effectiveIdentifier,
          cccdIssueDate: effectiveNgayCap,
          gender: _normalizeGender(userDraft.gender),
        );
      }

      final String? reqDeptId = departmentId;
      final String? reqDept = department;
      final String? reqProvCode;
      final String? reqProvName;
      final String? reqWardCode;
      final String? reqWardName;

      if (useSystemData) {
        final sys = compareModel.systemSnapshot;
        reqProvCode = sys.tinhTp;
        reqProvName = sys.tinhTpTen;
        reqWardCode = sys.phuongXa;
        reqWardName = sys.phuongXaTen;
      } else {
        reqProvCode = provinceCode ?? (compareModel.userTinhTp.isNotEmpty ? compareModel.userTinhTp : null);
        reqProvName = provinceName ?? (compareModel.userTinhTpTen.isNotEmpty ? compareModel.userTinhTpTen : null);
        reqWardCode = wardCode ?? (compareModel.userPhuongXa.isNotEmpty ? compareModel.userPhuongXa : null);
        reqWardName = wardName ?? (compareModel.userPhuongXaTen.isNotEmpty ? compareModel.userPhuongXaTen : null);
      }

      final result = await repository.createMedicalTicket(
        role,
        draftToUse,
        department: reqDept,
        departmentId: reqDeptId,
        provinceCode: reqProvCode,
        provinceName: reqProvName,
        wardCode: reqWardCode,
        wardName: reqWardName,
        selectedDate: selectedDate,
        selectedTime: selectedTime,
        symptom: symptom,
      );

      if (!_isDisposed) {
        result.when(
          ok: (_) {
            _errorMessage = null;
          },
          error: (_, message) {
            _errorMessage = message;
          },
        );
      }
      return result;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (!_isDisposed) {
        _errorMessage = msg;
      }
      return Error(Exception(msg), msg);
    } finally {
      if (!_isDisposed) {
        _isSubmitting = false;
        _notifySafe();
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    _notifySafe();
  }

  void _notifySafe() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Khi dispose (app tắt / navigate back), isSubmitting sẽ không còn
    // block UI — form cũ giữ nguyên, không tự đăng ký lặp.
    super.dispose();
  }

  static String _extractBirthYear(String? ngaySinh) {
    if (ngaySinh == null || ngaySinh.isEmpty) return '';
    final iso = DateTime.tryParse(ngaySinh);
    if (iso != null) return iso.year.toString();
    final parts = ngaySinh.split('/');
    if (parts.length == 3) return parts[2];
    return ngaySinh;
  }

  static String _normalizeGender(String? s) {
    if (s == null) return 'Nam';
    final lower = s.trim().toLowerCase();
    if (lower == 'nữ' || lower == 'nu' || lower == 'female' || lower == '1') return 'Nữ';
    return 'Nam';
  }
}
