import 'package:flutter/material.dart';
import 'package:benhvien7c/core/viewmodels/BaseViewModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';

/// Ánh xạ trạng thái phiếu khám từ field `done` (int) của server.
/// App KHÔNG tự tính trạng thái — chỉ ánh xạ giá trị server trả về.
enum TicketStatus {
  biLoi,           // -1: Bị lỗi đăng ký
  daKhong,         // unknown / fallback
  daKhongHoTro,    // không nhận diện được
  daHuy,           // 3: Hủy đăng ký khám
  daKhamXong,      // 2: Đã khám xong
  dangKyThanhCong, // 1: Đăng ký thành công
  daKhongbiet,     // fallback
  daQuaHan,        // quá hạn
  daKhongbiet2,    // fallback 2
}

class MedicalTicketStatusInfo {
  final String label;
  final Color badgeColor;
  final Color textColor;

  const MedicalTicketStatusInfo({
    required this.label,
    required this.badgeColor,
    required this.textColor,
  });
}

class MedicalTicketViewModel extends BaseViewModel {
  MedicalTicketViewModel(this.ticket, {this.doneStatus, this.coTheXoa, this.lyDoLoi});

  final MedicalTicketEntity ticket;

  /// Giá trị `done` từ server: -1, 0, 1, 2, 3
  final int? doneStatus;

  /// Cờ cho phép xóa từ server (nullable nếu server chưa trả)
  final bool? coTheXoa;

  /// Lý do lỗi khi doneStatus = -1 (từ field TrangThai của server)
  final String? lyDoLoi;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  void toggleExpand() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Badge trạng thái (Luồng 2)
  // ---------------------------------------------------------------------------
  /// Thông tin badge theo `doneStatus`. Nếu phiếu quá hạn → ưu tiên badge quá hạn.
  MedicalTicketStatusInfo get statusInfo {
    // Ưu tiên quá hạn
    if (ticket.isPast && (doneStatus == null || (doneStatus != 2 && doneStatus != 3))) {
      return const MedicalTicketStatusInfo(
        label: 'Quá hạn khám',
        badgeColor: Color(0xFFFCE7F3),
        textColor: Color(0xFFEC4899),
      );
    }
    switch (doneStatus) {
      case -1:
        return const MedicalTicketStatusInfo(
          label: 'Bị lỗi đăng ký',
          badgeColor: Color(0xFFFFECEF),
          textColor: Color(0xFFDC2626),
        );
      case 0:
        return const MedicalTicketStatusInfo(
          label: 'Đã tiếp nhận',
          badgeColor: Color(0xFFFFF3E0),
          textColor: Color(0xFFF97316),
        );
      case 1:
        return const MedicalTicketStatusInfo(
          label: 'Đăng ký thành công',
          badgeColor: Color(0xFFDCFCE7),
          textColor: Color(0xFF16A34A),
        );
      case 2:
        return const MedicalTicketStatusInfo(
          label: 'Đã khám xong',
          badgeColor: Color(0xFFF1F5F9),
          textColor: Color(0xFF64748B),
        );
      case 3:
        return const MedicalTicketStatusInfo(
          label: 'Hủy đăng ký khám',
          badgeColor: Color(0xFFFFECEF),
          textColor: Color(0xFFEF4444),
        );
      default:
        // Không xác định được → hiện badge "Sắp tới" nếu chưa qua hạn
        if (!ticket.isPast) {
          return const MedicalTicketStatusInfo(
            label: 'Đăng ký thành công',
            badgeColor: Color(0xFFDCFCE7),
            textColor: Color(0xFF16A34A),
          );
        }
        return const MedicalTicketStatusInfo(
          label: 'Quá hạn khám',
          badgeColor: Color(0xFFFCE7F3),
          textColor: Color(0xFFEC4899),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Nút Xóa phiếu
  // ---------------------------------------------------------------------------
  /// Hiện nút Xóa hay không.
  /// Ưu tiên cờ `CoTheXoa` từ server; fallback: done=0 hoặc 1 và chưa quá hạn.
  bool get canDelete {
    if (coTheXoa != null) return coTheXoa!;
    // Fallback
    final d = doneStatus;
    return (d == 0 || d == 1) && !ticket.isPast;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> deleteTicket() async {
    if (ticket.id != null && ticket.id!.isNotEmpty) {
      await AppLocator.portalRepository.softDeleteMedicalTicket(ticket.id!);
    }
  }
}
