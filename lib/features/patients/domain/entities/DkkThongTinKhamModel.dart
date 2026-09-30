import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';

/// Model so sánh thông tin giữa hồ sơ gốc hệ thống bệnh viện và thông tin
/// người dùng nhập/hồ sơ đã lưu. Dùng cho màn hình đối chiếu (Luồng 3).
///
/// Mỗi field thông tin bệnh nhân có một cờ *Diff = true nếu hai bên khác nhau.
class DkkThongTinKhamModel {
  final String maBN;           // MaBN từ hệ thống — luôn readonly
  final String maBhytHoacMaBn; // Mã BHYT hoặc mã BN

  // --- Họ tên ---
  final String systemHoTen;
  final String userHoTen;
  final bool hoTenDiff;

  // --- Giới tính ---
  final String systemGioiTinh;
  final String userGioiTinh;
  final bool gioiTinhDiff;

  // --- Ngày sinh ---
  final String systemNgaySinh;
  final String userNgaySinh;
  final bool ngaySinhDiff;

  // --- Ngày cấp CCCD/HC ---
  final String systemNgayCap;
  final String userNgayCap;
  final bool ngayCapDiff;

  // --- Số điện thoại ---
  final String systemSoDienThoai;
  final String userSoDienThoai;
  final bool soDienThoaiDiff;

  // --- Tỉnh/Thành (so theo mã, hiển thị theo tên) ---
  final String systemTinhTp;
  final String systemTinhTpTen;
  final String userTinhTp;
  final String userTinhTpTen;
  final bool tinhTpDiff;

  // --- Phường/Xã (so theo mã, hiển thị theo tên) ---
  final String systemPhuongXa;
  final String systemPhuongXaTen;
  final String userPhuongXa;
  final String userPhuongXaTen;
  final bool phuongXaDiff;

  /// Nguồn dữ liệu người dùng: true = hồ sơ đã lưu, false = nhập tay từ Luồng 1
  final bool isFromSavedProfile;

  /// Snapshot gốc từ server (để submit khi user chọn "dùng thông tin hệ thống")
  final DkkTimBenhNhanResponseDto systemSnapshot;

  const DkkThongTinKhamModel({
    required this.maBN,
    required this.maBhytHoacMaBn,
    required this.systemHoTen,
    required this.userHoTen,
    required this.hoTenDiff,
    required this.systemGioiTinh,
    required this.userGioiTinh,
    required this.gioiTinhDiff,
    required this.systemNgaySinh,
    required this.userNgaySinh,
    required this.ngaySinhDiff,
    required this.systemNgayCap,
    required this.userNgayCap,
    required this.ngayCapDiff,
    required this.systemSoDienThoai,
    required this.userSoDienThoai,
    required this.soDienThoaiDiff,
    required this.systemTinhTp,
    required this.systemTinhTpTen,
    required this.userTinhTp,
    required this.userTinhTpTen,
    required this.tinhTpDiff,
    required this.systemPhuongXa,
    required this.systemPhuongXaTen,
    required this.userPhuongXa,
    required this.userPhuongXaTen,
    required this.phuongXaDiff,
    required this.isFromSavedProfile,
    required this.systemSnapshot,
  });

  /// true nếu bất kỳ field nào có sự khác biệt
  bool get hasDiff =>
      hoTenDiff ||
      gioiTinhDiff ||
      ngaySinhDiff ||
      ngayCapDiff ||
      soDienThoaiDiff ||
      tinhTpDiff ||
      phuongXaDiff;

  /// Danh sách các trường khác nhau (dùng cho khung cảnh báo vàng).
  /// Mỗi phần tử: (tên trường, giá trị người dùng, giá trị hệ thống)
  List<(String label, String userVal, String sysVal)> get diffSummary {
    final list = <(String, String, String)>[];
    if (hoTenDiff) list.add(('Họ tên', userHoTen, systemHoTen));
    if (gioiTinhDiff) list.add(('Giới tính', userGioiTinh, systemGioiTinh));
    if (ngaySinhDiff) list.add(('Ngày sinh', userNgaySinh, systemNgaySinh));
    if (ngayCapDiff) list.add(('Ngày cấp', userNgayCap, systemNgayCap));
    if (soDienThoaiDiff) list.add(('Điện thoại', userSoDienThoai, systemSoDienThoai));
    if (tinhTpDiff) list.add(('Tỉnh/Thành', userTinhTpTen.isNotEmpty ? userTinhTpTen : userTinhTp, systemTinhTpTen.isNotEmpty ? systemTinhTpTen : systemTinhTp));
    if (phuongXaDiff) list.add(('Phường/Xã', userPhuongXaTen.isNotEmpty ? userPhuongXaTen : userPhuongXa, systemPhuongXaTen.isNotEmpty ? systemPhuongXaTen : systemPhuongXa));
    return list;
  }

  /// Factory: tự động tính 9 cờ Diff từ systemSnapshot và userDraft.
  factory DkkThongTinKhamModel.compare({
    required DkkTimBenhNhanResponseDto system,
    required PatientProfileDraftEntity user,
    required bool isFromSavedProfile,
  }) {
    final sHoTen = _normalizeStr(system.hoTen);
    final uHoTen = _normalizeStr(user.fullName);

    final sGioiTinh = _normalizeGender(system.gioiTinh);
    final uGioiTinh = _normalizeGender(user.gender);

    final sNgaySinh = _normalizeDateStr(system.ngaySinh);
    final uNgaySinh = _normalizeDateStr(user.dateOfBirth ?? user.birthYear);

    final sNgayCap = _normalizeDateStr(system.ngayCap);
    final uNgayCap = _normalizeDateStr(user.cccdIssueDate);

    final sSdt = _normalizePhone(system.soDienThoai);
    final uSdt = _normalizePhone(user.phoneNumber);

    final sTinhTp = (system.tinhTp ?? '').trim();
    final uTinhTp = (user.province ?? '').trim();

    final sPhuongXa = (system.phuongXa ?? '').trim();
    final uPhuongXa = (user.ward ?? '').trim();

    return DkkThongTinKhamModel(
      maBN: system.maBN,
      maBhytHoacMaBn: system.maBhytHoacMaBn,
      systemHoTen: system.hoTen,
      userHoTen: user.fullName,
      hoTenDiff: _strDiff(sHoTen, uHoTen),
      systemGioiTinh: sGioiTinh,
      userGioiTinh: uGioiTinh,
      gioiTinhDiff: _strDiff(sGioiTinh, uGioiTinh),
      systemNgaySinh: _displayDate(system.ngaySinh),
      userNgaySinh: _displayDate(user.dateOfBirth ?? user.birthYear),
      ngaySinhDiff: _strDiff(sNgaySinh, uNgaySinh),
      systemNgayCap: _displayDate(system.ngayCap),
      userNgayCap: _displayDate(user.cccdIssueDate),
      ngayCapDiff: _strDiff(sNgayCap, uNgayCap),
      systemSoDienThoai: system.soDienThoai ?? '',
      userSoDienThoai: user.phoneNumber,
      soDienThoaiDiff: _strDiff(sSdt, uSdt),
      systemTinhTp: sTinhTp,
      systemTinhTpTen: system.tinhTpTen ?? sTinhTp,
      userTinhTp: uTinhTp,
      userTinhTpTen: uTinhTp, // user lưu tên, không có mã riêng
      tinhTpDiff: _tinhTpDiff(sTinhTp, system.tinhTpTen, uTinhTp),
      systemPhuongXa: sPhuongXa,
      systemPhuongXaTen: system.phuongXaTen ?? sPhuongXa,
      userPhuongXa: uPhuongXa,
      userPhuongXaTen: uPhuongXa,
      phuongXaDiff: _phuongXaDiff(sPhuongXa, system.phuongXaTen, uPhuongXa),
      isFromSavedProfile: isFromSavedProfile,
      systemSnapshot: system,
    );
  }

  /// Factory: kết hợp kết quả kiểm tra sai lệch từ API KiemTraBenhNhan của server
  factory DkkThongTinKhamModel.fromServerCheck({
    required DkkTimBenhNhanResponseDto system,
    required PatientProfileDraftEntity user,
    required bool isFromSavedProfile,
    DkkKiemTraBenhNhanResponseDto? serverDiff,
  }) {
    final clientCompare = DkkThongTinKhamModel.compare(
      system: system,
      user: user,
      isFromSavedProfile: isFromSavedProfile,
    );
    if (serverDiff == null) return clientCompare;

    return DkkThongTinKhamModel(
      maBN: serverDiff.maBN ?? system.maBN,
      maBhytHoacMaBn: system.maBhytHoacMaBn,
      systemHoTen: system.hoTen,
      userHoTen: user.fullName,
      hoTenDiff: serverDiff.hoTenDiff ?? clientCompare.hoTenDiff,
      systemGioiTinh: clientCompare.systemGioiTinh,
      userGioiTinh: clientCompare.userGioiTinh,
      gioiTinhDiff: serverDiff.gioiTinhDiff ?? clientCompare.gioiTinhDiff,
      systemNgaySinh: clientCompare.systemNgaySinh,
      userNgaySinh: clientCompare.userNgaySinh,
      ngaySinhDiff: serverDiff.ngaySinhDiff ?? clientCompare.ngaySinhDiff,
      systemNgayCap: clientCompare.systemNgayCap,
      userNgayCap: clientCompare.userNgayCap,
      ngayCapDiff: serverDiff.ngayCapDiff ?? clientCompare.ngayCapDiff,
      systemSoDienThoai: clientCompare.systemSoDienThoai,
      userSoDienThoai: clientCompare.userSoDienThoai,
      soDienThoaiDiff: serverDiff.soDienThoaiDiff ?? clientCompare.soDienThoaiDiff,
      systemTinhTp: clientCompare.systemTinhTp,
      systemTinhTpTen: clientCompare.systemTinhTpTen,
      userTinhTp: clientCompare.userTinhTp,
      userTinhTpTen: clientCompare.userTinhTpTen,
      tinhTpDiff: serverDiff.tinhTpDiff ?? clientCompare.tinhTpDiff,
      systemPhuongXa: clientCompare.systemPhuongXa,
      systemPhuongXaTen: clientCompare.systemPhuongXaTen,
      userPhuongXa: clientCompare.userPhuongXa,
      userPhuongXaTen: clientCompare.userPhuongXaTen,
      phuongXaDiff: serverDiff.phuongXaDiff ?? clientCompare.phuongXaDiff,
      isFromSavedProfile: isFromSavedProfile,
      systemSnapshot: system,
    );
  }


  // ---------------------------------------------------------------------------
  // Helper so sánh nội bộ
  // ---------------------------------------------------------------------------

  /// So chuỗi: trim + lowercase + collapse whitespace
  static String _normalizeStr(String? s) {
    if (s == null) return '';
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Chuẩn hóa giới tính về "nam" / "nữ"
  static String _normalizeGender(String? s) {
    if (s == null) return '';
    final lower = s.trim().toLowerCase();
    if (lower == 'nữ' || lower == 'nu' || lower == 'female' || lower == '1') return 'nữ';
    if (lower == 'nam' || lower == 'male' || lower == '0') return 'nam';
    return lower;
  }

  /// Chuẩn hóa ngày về YYYY-MM-DD (chỉ date, bỏ giờ)
  static String _normalizeDateStr(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    final clean = s.trim();
    // Thử parse ISO
    final iso = DateTime.tryParse(clean);
    if (iso != null) {
      return '${iso.year.toString().padLeft(4, '0')}-${iso.month.toString().padLeft(2, '0')}-${iso.day.toString().padLeft(2, '0')}';
    }
    // Thử parse dd/MM/yyyy
    final parts = clean.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      }
    }
    // Nếu chỉ là năm (birthYear)
    if (RegExp(r'^\d{4}$').hasMatch(clean)) return clean;
    return clean.toLowerCase();
  }

  static String _displayDate(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    // Nếu ISO → chuyển sang dd/MM/yyyy
    final iso = DateTime.tryParse(s.trim());
    if (iso != null) {
      return '${iso.day.toString().padLeft(2, '0')}/${iso.month.toString().padLeft(2, '0')}/${iso.year}';
    }
    return s.trim();
  }

  /// Chuẩn hóa SĐT: chỉ giữ chữ số
  static String _normalizePhone(String? s) {
    if (s == null) return '';
    return s.replaceAll(RegExp(r'\D'), '');
  }

  static bool _strDiff(String a, String b) {
    // null/rỗng ở cả 2 phía → không khác
    if (a.isEmpty && b.isEmpty) return false;
    return a != b;
  }

  /// So tỉnh/thành: ưu tiên so mã nếu có, fallback so tên
  static bool _tinhTpDiff(String sysMa, String? sysTen, String userVal) {
    if (sysMa.isEmpty && (userVal.isEmpty)) return false;
    if (sysMa.isEmpty && userVal.isEmpty) return false;
    // Nếu user lưu mã
    if (sysMa.isNotEmpty && sysMa.toLowerCase() == userVal.toLowerCase()) return false;
    // Nếu user lưu tên
    if (sysTen != null && sysTen.isNotEmpty && _normalizeStr(sysTen) == _normalizeStr(userVal)) return false;
    if (sysMa.isEmpty && userVal.isEmpty) return false;
    if (sysMa.isEmpty || userVal.isEmpty) return true;
    return true;
  }

  /// So phường/xã: tương tự tỉnh
  static bool _phuongXaDiff(String sysMa, String? sysTen, String userVal) {
    if (sysMa.isEmpty && userVal.isEmpty) return false;
    if (sysMa.isNotEmpty && sysMa.toLowerCase() == userVal.toLowerCase()) return false;
    if (sysTen != null && sysTen.isNotEmpty && _normalizeStr(sysTen) == _normalizeStr(userVal)) return false;
    if (sysMa.isEmpty || userVal.isEmpty) return true;
    return true;
  }
}
