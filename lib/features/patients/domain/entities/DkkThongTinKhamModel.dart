import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';

/// Model so sánh thông tin giữa hồ sơ gốc hệ thống bệnh viện và thông tin
/// người dùng nhập/hồ sơ đã lưu. Dùng cho màn hình đối chiếu (Luồng 3).
///
/// Mỗi field thông tin bệnh nhân có một cờ *Diff = true nếu hai bên khác nhau.
class DkkThongTinKhamModel {
  final String maBN;           // MaBN từ hệ thống — luôn readonly
  final bool maBNDiff;
  final String maBhytHoacMaBn; // Mã BHYT hoặc mã BN
  final String systemCccd;     // Số CC/HC từ hệ thống
  final String userCccd;       // Số CC/HC người dùng nhập
  final bool maBhytHoacMaBnDiff; // Cờ so sánh Số CC/HC

  // --- Ngày cấp CCCD/HC ---
  final String systemNgayCap;
  final String userNgayCap;
  final bool ngayCapDiff;

  // --- Họ tên ---
  final String systemHoTen;
  final String userHoTen;
  final bool hoTenDiff;

  // --- Ngày sinh ---
  final String systemNgaySinh;
  final String userNgaySinh;
  final bool ngaySinhDiff;

  // --- Giới tính ---
  final String systemGioiTinh;
  final String userGioiTinh;
  final bool gioiTinhDiff;

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
    this.maBNDiff = false,
    required this.maBhytHoacMaBn,
    required this.systemCccd,
    required this.userCccd,
    required this.maBhytHoacMaBnDiff,
    required this.systemNgayCap,
    required this.userNgayCap,
    required this.ngayCapDiff,
    required this.systemHoTen,
    required this.userHoTen,
    required this.hoTenDiff,
    required this.systemNgaySinh,
    required this.userNgaySinh,
    required this.ngaySinhDiff,
    required this.systemGioiTinh,
    required this.userGioiTinh,
    required this.gioiTinhDiff,
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

  /// true nếu bất kỳ field nào có sự khác biệt trong 9 cờ
  bool get hasDiff =>
      maBhytHoacMaBnDiff ||
      ngayCapDiff ||
      hoTenDiff ||
      ngaySinhDiff ||
      gioiTinhDiff ||
      soDienThoaiDiff ||
      tinhTpDiff ||
      phuongXaDiff ||
      maBNDiff;

  /// Danh sách các trường khác nhau (dùng cho khung cảnh báo vàng).
  /// Mỗi phần tử: (tên trường, giá trị người dùng, giá trị hệ thống)
  List<(String label, String userVal, String sysVal)> get diffSummary {
    final list = <(String, String, String)>[];
    if (maBhytHoacMaBnDiff) {
      list.add(('Số CC/HC', userCccd.isNotEmpty ? userCccd : '(Để trống)', systemCccd.isNotEmpty ? systemCccd : '(Chưa có)'));
    }
    if (ngayCapDiff) {
      list.add(('Ngày cấp', userNgayCap.isNotEmpty ? userNgayCap : '(Để trống)', systemNgayCap.isNotEmpty ? systemNgayCap : '(Chưa có)'));
    }
    if (hoTenDiff) {
      list.add(('Họ tên', userHoTen.isNotEmpty ? userHoTen : '(Để trống)', systemHoTen.isNotEmpty ? systemHoTen : '(Chưa có)'));
    }
    if (ngaySinhDiff) {
      list.add(('Ngày sinh', userNgaySinh.isNotEmpty ? userNgaySinh : '(Để trống)', systemNgaySinh.isNotEmpty ? systemNgaySinh : '(Chưa có)'));
    }
    if (gioiTinhDiff) {
      list.add(('Giới tính', userGioiTinh.isNotEmpty ? userGioiTinh : '(Để trống)', systemGioiTinh.isNotEmpty ? systemGioiTinh : '(Chưa có)'));
    }
    if (soDienThoaiDiff) {
      list.add(('Điện thoại', userSoDienThoai.isNotEmpty ? userSoDienThoai : '(Để trống)', systemSoDienThoai.isNotEmpty ? systemSoDienThoai : '(Chưa có)'));
    }
    if (tinhTpDiff) {
      list.add(('Tỉnh/Thành', userTinhTpTen.isNotEmpty ? userTinhTpTen : (userTinhTp.isNotEmpty ? userTinhTp : '(Để trống)'), systemTinhTpTen.isNotEmpty ? systemTinhTpTen : systemTinhTp));
    }
    if (phuongXaDiff) {
      list.add(('Phường/Xã', userPhuongXaTen.isNotEmpty ? userPhuongXaTen : (userPhuongXa.isNotEmpty ? userPhuongXa : '(Để trống)'), systemPhuongXaTen.isNotEmpty ? systemPhuongXaTen : systemPhuongXa));
    }
    return list;
  }

  /// Factory: tự động tính 9 cờ Diff từ systemSnapshot và userDraft.
  factory DkkThongTinKhamModel.compare({
    required DkkTimBenhNhanResponseDto system,
    required PatientProfileDraftEntity user,
    required bool isFromSavedProfile,
  }) {
    // 1. Mã BN & Số CC/HC
    final sCccd = (system.soCcHc != null && system.soCcHc!.trim().isNotEmpty)
        ? system.soCcHc!.trim()
        : system.maBhytHoacMaBn.trim();
    final uCccd = user.identifier.trim();
    final cccdDiff = _strDiff(sCccd, uCccd);

    final sMaBn = system.maBN.trim();
    final uMaBn = (user.maBN ?? user.maSo ?? '').trim();
    final maBnDiff = uMaBn.isNotEmpty && !uMaBn.toUpperCase().startsWith('T') && uMaBn != uCccd && _strDiff(sMaBn, uMaBn);

    // 2. Ngày cấp
    final sNgayCapDisp = _displayDate(system.ngayCap);
    final uNgayCapDisp = _displayDate(user.cccdIssueDate);
    final ngayCapDiff = _dateDiff(system.ngayCap, user.cccdIssueDate);

    // 3. Họ tên
    final sHoTen = system.hoTen.trim();
    final uHoTen = user.fullName.trim();
    final hoTenDiff = _strDiff(_normalizeStr(sHoTen), _normalizeStr(uHoTen));

    // 4. Ngày sinh
    final sNgaySinhDisp = _displayDate(system.ngaySinh);
    final uNgaySinhDisp = _displayDate(user.dateOfBirth ?? user.birthYear);
    final ngaySinhDiff = _dateDiff(system.ngaySinh, user.dateOfBirth ?? user.birthYear);

    // 5. Giới tính
    final sGioiTinhDisp = _formatGenderDisplay(system.gioiTinh);
    final uGioiTinhDisp = _formatGenderDisplay(user.gender);
    final gioiTinhDiff = _normalizeGender(system.gioiTinh) != _normalizeGender(user.gender);

    // 6. Số điện thoại
    final sSdt = _normalizePhone(system.soDienThoai);
    final uSdt = _normalizePhone(user.phoneNumber);
    final soDienThoaiDiff = _strDiff(sSdt, uSdt);

    // 7. Tỉnh/Thành
    final sTinhTp = (system.tinhTp ?? '').trim();
    final uTinhTp = (user.province ?? '').trim();
    final tinhTpDiff = _tinhTpDiff(sTinhTp, system.tinhTpTen, uTinhTp);

    // 8. Phường/Xã
    final sPhuongXa = (system.phuongXa ?? '').trim();
    final uPhuongXa = (user.ward ?? '').trim();
    final phuongXaDiff = _phuongXaDiff(sPhuongXa, system.phuongXaTen, uPhuongXa);

    return DkkThongTinKhamModel(
      maBN: system.maBN,
      maBNDiff: maBnDiff,
      maBhytHoacMaBn: system.maBhytHoacMaBn,
      systemCccd: sCccd,
      userCccd: uCccd,
      maBhytHoacMaBnDiff: cccdDiff,
      systemNgayCap: sNgayCapDisp,
      userNgayCap: uNgayCapDisp,
      ngayCapDiff: ngayCapDiff,
      systemHoTen: sHoTen,
      userHoTen: uHoTen,
      hoTenDiff: hoTenDiff,
      systemNgaySinh: sNgaySinhDisp,
      userNgaySinh: uNgaySinhDisp,
      ngaySinhDiff: ngaySinhDiff,
      systemGioiTinh: sGioiTinhDisp,
      userGioiTinh: uGioiTinhDisp,
      gioiTinhDiff: gioiTinhDiff,
      systemSoDienThoai: system.soDienThoai ?? '',
      userSoDienThoai: user.phoneNumber,
      soDienThoaiDiff: soDienThoaiDiff,
      systemTinhTp: sTinhTp,
      systemTinhTpTen: system.tinhTpTen ?? sTinhTp,
      userTinhTp: uTinhTp,
      userTinhTpTen: uTinhTp,
      tinhTpDiff: tinhTpDiff,
      systemPhuongXa: sPhuongXa,
      systemPhuongXaTen: system.phuongXaTen ?? sPhuongXa,
      userPhuongXa: uPhuongXa,
      userPhuongXaTen: uPhuongXa,
      phuongXaDiff: phuongXaDiff,
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

    // QUY TẮC AN TOÀN: Nếu client HOẶC server phát hiện sai lệch -> diff = true!
    // Tránh việc serverDiff trả về false do default C# bool làm mất cảnh báo của client.
    return DkkThongTinKhamModel(
      maBN: serverDiff.maBN ?? system.maBN,
      maBNDiff: (serverDiff.maBNDiff == true) || clientCompare.maBNDiff,
      maBhytHoacMaBn: system.maBhytHoacMaBn,
      systemCccd: clientCompare.systemCccd,
      userCccd: clientCompare.userCccd,
      maBhytHoacMaBnDiff: (serverDiff.maBhytHoacMaBnDiff == true) || clientCompare.maBhytHoacMaBnDiff,
      systemNgayCap: clientCompare.systemNgayCap,
      userNgayCap: clientCompare.userNgayCap,
      ngayCapDiff: (serverDiff.ngayCapDiff == true) || clientCompare.ngayCapDiff,
      systemHoTen: clientCompare.systemHoTen,
      userHoTen: clientCompare.userHoTen,
      hoTenDiff: (serverDiff.hoTenDiff == true) || clientCompare.hoTenDiff,
      systemNgaySinh: clientCompare.systemNgaySinh,
      userNgaySinh: clientCompare.userNgaySinh,
      ngaySinhDiff: (serverDiff.ngaySinhDiff == true) || clientCompare.ngaySinhDiff,
      systemGioiTinh: clientCompare.systemGioiTinh,
      userGioiTinh: clientCompare.userGioiTinh,
      gioiTinhDiff: (serverDiff.gioiTinhDiff == true) || clientCompare.gioiTinhDiff,
      systemSoDienThoai: clientCompare.systemSoDienThoai,
      userSoDienThoai: clientCompare.userSoDienThoai,
      soDienThoaiDiff: (serverDiff.soDienThoaiDiff == true) || clientCompare.soDienThoaiDiff,
      systemTinhTp: clientCompare.systemTinhTp,
      systemTinhTpTen: clientCompare.systemTinhTpTen,
      userTinhTp: clientCompare.userTinhTp,
      userTinhTpTen: clientCompare.userTinhTpTen,
      tinhTpDiff: (serverDiff.tinhTpDiff == true) || clientCompare.tinhTpDiff,
      systemPhuongXa: clientCompare.systemPhuongXa,
      systemPhuongXaTen: clientCompare.systemPhuongXaTen,
      userPhuongXa: clientCompare.userPhuongXa,
      userPhuongXaTen: clientCompare.userPhuongXaTen,
      phuongXaDiff: (serverDiff.phuongXaDiff == true) || clientCompare.phuongXaDiff,
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

  /// Chuẩn hóa hiển thị giới tính viết hoa chữ cái đầu: "Nam", "Nữ", "Khác"
  static String _formatGenderDisplay(String? s) {
    if (s == null) return '';
    final lower = s.trim().toLowerCase();
    if (lower == 'nữ' || lower == 'nu' || lower == 'female' || lower == '1') return 'Nữ';
    if (lower == 'nam' || lower == 'male' || lower == '0') return 'Nam';
    if (lower.isEmpty) return '';
    return 'Khác';
  }

  /// Chuẩn hóa giới tính để so sánh
  static String _normalizeGender(String? s) {
    if (s == null) return '';
    final lower = s.trim().toLowerCase();
    if (lower == 'nữ' || lower == 'nu' || lower == 'female' || lower == '1') return 'nữ';
    if (lower == 'nam' || lower == 'male' || lower == '0') return 'nam';
    return lower;
  }

  /// So sánh ngày theo giá trị Date thực (bỏ giờ, phút, giây).
  /// - Cả 2 cùng null/rỗng: không khác (false)
  /// - Một bên rỗng, một bên có giá trị: KHÁC (true)
  /// - Cả 2 có giá trị: parse ra DateTime lấy Date để so sánh năm, tháng, ngày.
  static bool _dateDiff(String? a, String? b) {
    final cleanA = a?.trim() ?? '';
    final cleanB = b?.trim() ?? '';
    if (cleanA.isEmpty && cleanB.isEmpty) return false;
    if (cleanA.isEmpty || cleanB.isEmpty) return true;

    final dateA = _parseDateOnly(cleanA);
    final dateB = _parseDateOnly(cleanB);
    if (dateA != null && dateB != null) {
      return dateA.year != dateB.year ||
          dateA.month != dateB.month ||
          dateA.day != dateB.day;
    }
    // Nếu một bên chỉ có năm (birthYear 4 số)
    if (RegExp(r'^\d{4}$').hasMatch(cleanA) && dateB != null) {
      return int.tryParse(cleanA) != dateB.year;
    }
    if (RegExp(r'^\d{4}$').hasMatch(cleanB) && dateA != null) {
      return int.tryParse(cleanB) != dateA.year;
    }
    return _normalizeDateStr(cleanA) != _normalizeDateStr(cleanB);
  }

  static DateTime? _parseDateOnly(String s) {
    final clean = s.trim();
    if (clean.isEmpty) return null;
    final iso = DateTime.tryParse(clean);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    if (clean.contains('/')) {
      final parts = clean.split('/');
      if (parts.length >= 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final yearPart = parts[2].split(' ')[0].split('T')[0];
        final y = int.tryParse(yearPart);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  /// Chuẩn hóa ngày về YYYY-MM-DD
  static String _normalizeDateStr(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    final d = _parseDateOnly(s);
    if (d != null) {
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
    final clean = s.trim();
    if (RegExp(r'^\d{4}$').hasMatch(clean)) return clean;
    return clean.toLowerCase();
  }

  /// Format hiển thị ngày chuẩn dd/MM/yyyy
  static String _displayDate(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    return DateTimeConverter.toVnDate(s) ?? s.trim();
  }

  /// Chuẩn hóa SĐT: chỉ giữ chữ số
  static String _normalizePhone(String? s) {
    if (s == null) return '';
    return s.replaceAll(RegExp(r'\D'), '');
  }

  /// So chuỗi: 
  /// - Cả 2 cùng rỗng: false
  /// - Một bên rỗng, một bên có: true
  /// - Cả 2 có: so sánh giá trị
  static bool _strDiff(String a, String b) {
    final cleanA = a.trim();
    final cleanB = b.trim();
    if (cleanA.isEmpty && cleanB.isEmpty) return false;
    if (cleanA.isEmpty || cleanB.isEmpty) return true;
    return cleanA.toLowerCase() != cleanB.toLowerCase();
  }

  /// So tỉnh/thành: ưu tiên so mã nếu có, fallback so tên
  static bool _tinhTpDiff(String sysMa, String? sysTen, String userVal) {
    final cleanUser = userVal.trim();
    final cleanSysMa = sysMa.trim();
    final cleanSysTen = sysTen?.trim() ?? '';

    if (cleanSysMa.isEmpty && cleanSysTen.isEmpty && cleanUser.isEmpty) return false;
    if ((cleanSysMa.isEmpty && cleanSysTen.isEmpty) || cleanUser.isEmpty) return true;

    if (cleanSysMa.isNotEmpty && cleanSysMa.toLowerCase() == cleanUser.toLowerCase()) return false;
    if (cleanSysTen.isNotEmpty && _normalizeStr(cleanSysTen) == _normalizeStr(cleanUser)) return false;
    return true;
  }

  /// So phường/xã: tương tự tỉnh
  static bool _phuongXaDiff(String sysMa, String? sysTen, String userVal) {
    final cleanUser = userVal.trim();
    final cleanSysMa = sysMa.trim();
    final cleanSysTen = sysTen?.trim() ?? '';

    if (cleanSysMa.isEmpty && cleanSysTen.isEmpty && cleanUser.isEmpty) return false;
    if ((cleanSysMa.isEmpty && cleanSysTen.isEmpty) || cleanUser.isEmpty) return true;

    if (cleanSysMa.isNotEmpty && cleanSysMa.toLowerCase() == cleanUser.toLowerCase()) return false;
    if (cleanSysTen.isNotEmpty && _normalizeStr(cleanSysTen) == _normalizeStr(cleanUser)) return false;
    return true;
  }
}
