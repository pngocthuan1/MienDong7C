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
    required this.selectedDate,
    required this.selectedTime,
    required this.symptom,
  });

  final DkkThongTinKhamModel compareModel;
  final PatientProfileDraftEntity userDraft;
  final PortalRepository repository;
  final UserRole role;
  final String? department;
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
      // Chọn draft phù hợp theo lựa chọn của người dùng
      final PatientProfileDraftEntity draftToUse;
      if (useSystemData) {
        // Dùng thông tin hệ thống → xây draft từ systemSnapshot
        final sys = compareModel.systemSnapshot;
        draftToUse = PatientProfileDraftEntity(
          identifier: sys.maBhytHoacMaBn.isNotEmpty ? sys.maBhytHoacMaBn : sys.maBN,
          fullName: sys.hoTen,
          birthYear: _extractBirthYear(sys.ngaySinh),
          gender: _normalizeGender(sys.gioiTinh),
          phoneNumber: sys.soDienThoai ?? '',
          dateOfBirth: sys.ngaySinh,
          cccdIssueDate: sys.ngayCap,
          province: sys.tinhTpTen ?? sys.tinhTp,
          ward: sys.phuongXaTen ?? sys.phuongXa,
          maSo: sys.maBN,
        );
      } else {
        // Dùng thông tin người dùng
        draftToUse = userDraft;
      }

      final result = await repository.createMedicalTicket(
        role,
        draftToUse,
        department: department,
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
