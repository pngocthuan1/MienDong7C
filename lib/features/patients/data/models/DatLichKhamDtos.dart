class DkkHoSoBenhNhanDto {
  final String? hoTen;
  final String? maSo;
  final String? maThe;
  final String? maBhyt;
  final String? ngaySinh;
  final String? namSinh;
  final String? gioiTinh;
  final String? cccd;
  final String? soDienThoai;

  DkkHoSoBenhNhanDto({
    this.hoTen,
    this.maSo,
    this.maThe,
    this.maBhyt,
    this.ngaySinh,
    this.namSinh,
    this.gioiTinh,
    this.cccd,
    this.soDienThoai,
  });

  factory DkkHoSoBenhNhanDto.fromJson(Map<String, dynamic> json) {
    return DkkHoSoBenhNhanDto(
      hoTen: json['HoTen']?.toString(),
      maSo: json['MaSo']?.toString(),
      maThe: json['MaThe']?.toString(),
      maBhyt: json['MaBhyt']?.toString(),
      ngaySinh: json['NgaySinh']?.toString(),
      namSinh: json['NamSinh']?.toString(),
      gioiTinh: json['GioiTinh']?.toString(),
      cccd: json['Cccd']?.toString(),
      soDienThoai: json['SoDienThoai']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// DTO kết quả tìm bệnh nhân theo CCCD / Hộ chiếu (Luồng 1)
// ---------------------------------------------------------------------------
// TODO(endpoint): Điền tên endpoint và key JSON theo response thực tế khi có API.
// Các field hiện ánh xạ theo tên quy ước — chỉnh sửa nếu server trả về tên khác.
// ---------------------------------------------------------------------------
class DkkTimBenhNhanResponseDto {
  final String maBN;
  final String maBhytHoacMaBn;
  final String hoTen;
  final String? gioiTinh;
  final String? ngaySinh;    // ISO hoặc dd/MM/yyyy
  final String? ngayCap;     // Ngày cấp CCCD/HC
  final String? soCcHc;      // Số CCCD hoặc Hộ chiếu
  final String? soDienThoai;
  final String? tinhTp;      // Mã tỉnh/thành
  final String? tinhTpTen;   // Tên tỉnh/thành
  final String? phuongXa;    // Mã phường/xã
  final String? phuongXaTen; // Tên phường/xã

  const DkkTimBenhNhanResponseDto({
    required this.maBN,
    required this.maBhytHoacMaBn,
    required this.hoTen,
    this.gioiTinh,
    this.ngaySinh,
    this.ngayCap,
    this.soCcHc,
    this.soDienThoai,
    this.tinhTp,
    this.tinhTpTen,
    this.phuongXa,
    this.phuongXaTen,
  });

  // TODO(endpoint): Cập nhật key JSON khi có API thật.
  factory DkkTimBenhNhanResponseDto.fromJson(Map<String, dynamic> json) {
    return DkkTimBenhNhanResponseDto(
      maBN: json['MaBN']?.toString() ?? json['MaBn']?.toString() ?? '',
      maBhytHoacMaBn: json['MaBhytHoacMaBn']?.toString() ?? json['MaBN']?.toString() ?? '',
      hoTen: json['HoTen']?.toString() ?? '',
      gioiTinh: json['GioiTinh']?.toString(),
      ngaySinh: json['NgaySinh']?.toString(),
      ngayCap: json['NgayCap']?.toString(),
      soCcHc: json['SoCcHc']?.toString() ?? json['Cccd']?.toString(),
      soDienThoai: json['SoDienThoai']?.toString(),
      tinhTp: json['TinhTp']?.toString() ?? json['MaTinh']?.toString(),
      tinhTpTen: json['TinhTpTen']?.toString() ?? json['TenTinh']?.toString(),
      phuongXa: json['PhuongXa']?.toString() ?? json['MaPhuong']?.toString(),
      phuongXaTen: json['PhuongXaTen']?.toString() ?? json['TenPhuong']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'MaBN': maBN,
        'MaBhytHoacMaBn': maBhytHoacMaBn,
        'HoTen': hoTen,
        'GioiTinh': gioiTinh,
        'NgaySinh': ngaySinh,
        'NgayCap': ngayCap,
        'SoCcHc': soCcHc,
        'SoDienThoai': soDienThoai,
        'TinhTp': tinhTp,
        'TinhTpTen': tinhTpTen,
        'PhuongXa': phuongXa,
        'PhuongXaTen': phuongXaTen,
      };
}

// ---------------------------------------------------------------------------
// DTO phản hồi API Kiểm tra sai lệch thông tin bệnh nhân (API 4: KiemTraBenhNhan)
// ---------------------------------------------------------------------------
class DkkKiemTraBenhNhanResponseDto {
  final String? maBN;
  final String? soDienThoai;
  final bool? soDienThoaiDiff;
  final bool? hoTenDiff;
  final bool? gioiTinhDiff;
  final bool? ngaySinhDiff;
  final bool? ngayCapDiff;
  final bool? tinhTpDiff;
  final bool? phuongXaDiff;

  const DkkKiemTraBenhNhanResponseDto({
    this.maBN,
    this.soDienThoai,
    this.soDienThoaiDiff,
    this.hoTenDiff,
    this.gioiTinhDiff,
    this.ngaySinhDiff,
    this.ngayCapDiff,
    this.tinhTpDiff,
    this.phuongXaDiff,
  });

  factory DkkKiemTraBenhNhanResponseDto.fromJson(Map<String, dynamic> json) {
    return DkkKiemTraBenhNhanResponseDto(
      maBN: json['MaBN']?.toString() ?? json['mabn']?.toString(),
      soDienThoai: json['SoDienThoai']?.toString() ?? json['sdt']?.toString(),
      soDienThoaiDiff: json['SoDienThoaiDiff'] as bool? ?? json['soDienThoaiDiff'] as bool?,
      hoTenDiff: json['HoTenDiff'] as bool? ?? json['hoTenDiff'] as bool?,
      gioiTinhDiff: json['GioiTinhDiff'] as bool? ?? json['gioiTinhDiff'] as bool?,
      ngaySinhDiff: json['NgaySinhDiff'] as bool? ?? json['ngaySinhDiff'] as bool?,
      ngayCapDiff: json['NgayCapDiff'] as bool? ?? json['ngayCapDiff'] as bool?,
      tinhTpDiff: json['TinhTpDiff'] as bool? ?? json['tinhTpDiff'] as bool?,
      phuongXaDiff: json['PhuongXaDiff'] as bool? ?? json['phuongXaDiff'] as bool?,
    );
  }

  bool get hasDiff =>
      (soDienThoaiDiff ?? false) ||
      (hoTenDiff ?? false) ||
      (gioiTinhDiff ?? false) ||
      (ngaySinhDiff ?? false) ||
      (ngayCapDiff ?? false) ||
      (tinhTpDiff ?? false) ||
      (phuongXaDiff ?? false);
}

class DkkPhongKhamDto {

  final String id;
  final String display;
  DkkPhongKhamDto({required this.id, required this.display});
  factory DkkPhongKhamDto.fromJson(Map<String, dynamic> json) => DkkPhongKhamDto(
    id: json['Id']?.toString() ?? '',
    display: json['Display']?.toString() ?? '',
  );
}

class DkkTinhDto {
  final int id;
  final String maByt;
  final String display;
  DkkTinhDto({required this.id, required this.maByt, required this.display});
  factory DkkTinhDto.fromJson(Map<String, dynamic> json) => DkkTinhDto(
    id: (json['Id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
    maByt: json['ma_byt']?.toString() ??
        json['Ma_byt']?.toString() ??
        json['MaByt']?.toString() ??
        json['maByt']?.toString() ??
        '',
    display: json['Display']?.toString() ??
        json['display']?.toString() ??
        json['Ten']?.toString() ??
        json['ten']?.toString() ??
        '',
  );
}

class DkkPhuongDto {
  final int id;
  final String maByt;
  final String maTinhByt;
  final String display;
  DkkPhuongDto({
    required this.id,
    required this.maByt,
    required this.maTinhByt,
    required this.display,
  });
  factory DkkPhuongDto.fromJson(Map<String, dynamic> json) => DkkPhuongDto(
    id: (json['Id'] as num?)?.toInt() ?? (json['id'] as num?)?.toInt() ?? 0,
    maByt: json['ma_byt']?.toString() ??
        json['Ma_byt']?.toString() ??
        json['MaByt']?.toString() ??
        json['maByt']?.toString() ??
        '',
    maTinhByt: json['ma_tinh_byt']?.toString() ??
        json['Ma_tinh_byt']?.toString() ??
        json['MaTinhByt']?.toString() ??
        json['maTinhByt']?.toString() ??
        '',
    display: json['Display']?.toString() ??
        json['display']?.toString() ??
        json['Ten']?.toString() ??
        json['ten']?.toString() ??
        '',
  );
}

class DkkNgayKhamDto {
  final String id;    // ISO datetime string e.g. "2026-09-30T00:00:00"
  final String display; // e.g. "Thứ 4, 30/09/2026"
  DkkNgayKhamDto({required this.id, required this.display});
  factory DkkNgayKhamDto.fromJson(Map<String, dynamic> json) => DkkNgayKhamDto(
    id: json['Id']?.toString() ?? json['id']?.toString() ?? '',
    display: json['Display']?.toString() ?? json['display']?.toString() ?? '',
  );
}

class DkkGioKhamSlotDto {
  final int tuGio;
  final int tuPhut;
  final int denGio;
  final int denPhut;
  final String display;
  DkkGioKhamSlotDto({required this.tuGio, required this.tuPhut, required this.denGio, required this.denPhut, required this.display});
  factory DkkGioKhamSlotDto.fromJson(Map<String, dynamic> json) => DkkGioKhamSlotDto(
    tuGio: (json['TuGio'] as num?)?.toInt() ?? (json['tuGio'] as num?)?.toInt() ?? 0,
    tuPhut: (json['TuPhut'] as num?)?.toInt() ?? (json['tuPhut'] as num?)?.toInt() ?? 0,
    denGio: (json['DenGio'] as num?)?.toInt() ?? (json['denGio'] as num?)?.toInt() ?? 0,
    denPhut: (json['DenPhut'] as num?)?.toInt() ?? (json['denPhut'] as num?)?.toInt() ?? 0,
    display: json['Display']?.toString() ?? json['display']?.toString() ?? '',
  );
}

class DkkListMasterDto {
  final List<DkkPhongKhamDto> listPhongKham;
  final List<DkkTinhDto> listTinh;
  final Map<String, List<DkkPhuongDto>> dicPhuong;
  final List<DkkNgayKhamDto> listNgayKham;
  final List<DkkGioKhamSlotDto> listGioKham;
  final Map<String, List<String>> dicNgayGioKham;

  DkkListMasterDto({
    required this.listPhongKham,
    required this.listTinh,
    required this.dicPhuong,
    required this.listNgayKham,
    required this.listGioKham,
    required this.dicNgayGioKham,
  });

  factory DkkListMasterDto.fromJson(Map<String, dynamic> json) {
    final rawPhongKham = json['ListPhongKham'] ?? json['listPhongKham'];
    final phongKhamList = (rawPhongKham as List?)
        ?.map((e) => DkkPhongKhamDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final rawTinh = json['ListTinh'] ?? json['listTinh'];
    final tinhList = (rawTinh as List?)
        ?.map((e) => DkkTinhDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final Map<String, List<DkkPhuongDto>> dicPhuong = {};
    final rawDicPhuong = json['DicPhuong'] ?? json['dicPhuong'];
    if (rawDicPhuong is Map) {
      rawDicPhuong.forEach((k, v) {
        if (v is List) {
          dicPhuong[k.toString()] = v.map((e) => DkkPhuongDto.fromJson(e as Map<String, dynamic>)).toList();
        }
      });
    }
    final rawNgay = json['ListNgayKham'] ?? json['listNgayKham'];
    final ngayList = (rawNgay as List?)
        ?.map((e) => DkkNgayKhamDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final rawGio = json['ListGioKham'] ?? json['listGioKham'];
    final gioList = (rawGio as List?)
        ?.map((e) => DkkGioKhamSlotDto.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    final Map<String, List<String>> dicNgayGio = {};
    final rawDicNgayGio = json['DicNgayGioKham'] ?? json['dicNgayGioKham'];
    if (rawDicNgayGio is Map) {
      rawDicNgayGio.forEach((k, v) {
        if (v is List) {
          dicNgayGio[k.toString()] = v.map((e) => e.toString()).toList();
        }
      });
    }
    return DkkListMasterDto(
      listPhongKham: phongKhamList,
      listTinh: tinhList,
      dicPhuong: dicPhuong,
      listNgayKham: ngayList,
      listGioKham: gioList,
      dicNgayGioKham: dicNgayGio,
    );
  }

  /// Lấy danh sách giờ khám khả dụng cho một ngày cụ thể
  List<String> getSlotsForDate(String ngayIso) {
    final key = dicNgayGioKham.keys.firstWhere(
      (k) => k == ngayIso || k.startsWith(ngayIso.substring(0, 10)),
      orElse: () => '',
    );
    if (key.isEmpty) return listGioKham.map((e) => e.display).toList();
    return dicNgayGioKham[key] ?? [];
  }
}

class DangKyKhamRequestDto {
  final String? maHS;
  final String? maBN;
  final String? maBhytHoacMaBn;
  final String hoTen;
  final String gioiTinh;
  // Ngày sinh ISO: "1995-05-15T00:00:00"
  final String? ngaySinh;
  // Ngày cấp CCCD ISO: "2021-10-20T00:00:00"
  final String? ngayCap;
  final String? soDienThoai;
  // NgayKham: string lấy từ ListNgayKham.Display, ví dụ "Thứ 4, 30/09/2026"
  final String ngayKham;
  // GioKham: string lấy từ ListGioKham.Display, ví dụ "07g00 - 07g30"
  final String gioKham;
  // PhongKham: Id lấy từ ListPhongKham, ví dụ "49"
  final String? phongKham;
  // PhongKhamTen: Display lấy từ ListPhongKham
  final String? phongKhamTen;
  // TinhTp: MaByt lấy từ ListTinh
  final String? tinhTp;
  // TinhTpTen: Display lấy từ ListTinh
  final String? tinhTpTen;
  // PhuongXa: MaByt lấy từ DicPhuong
  final String? phuongXa;
  // PhuongXaTen: Display lấy từ DicPhuong
  final String? phuongXaTen;
  final String? trieuChung;
  final String? dangKyDum;

  DangKyKhamRequestDto({
    this.maHS,
    this.maBN,
    this.maBhytHoacMaBn,
    required this.hoTen,
    required this.gioiTinh,
    this.ngaySinh,
    this.ngayCap,
    this.soDienThoai,
    required this.ngayKham,
    required this.gioKham,
    this.phongKham,
    this.phongKhamTen,
    this.tinhTp,
    this.tinhTpTen,
    this.phuongXa,
    this.phuongXaTen,
    this.trieuChung,
    this.dangKyDum,
  });

  Map<String, dynamic> toJson() {
    return {
      'MaHS': maHS ?? '',
      'MaBN': maBN ?? '',
      'MaBhytHoacMaBn': maBhytHoacMaBn ?? '',
      'HoTen': hoTen,
      'GioiTinh': gioiTinh,
      'NgaySinh': ngaySinh,
      'NgayCap': ngayCap,
      'SoDienThoai': soDienThoai ?? '',
      'NgayKham': ngayKham,
      'GioKham': gioKham,
      'PhongKham': phongKham ?? '',
      'PhongKhamTen': phongKhamTen ?? '',
      'TinhTp': tinhTp ?? '',
      'TinhTpTen': tinhTpTen ?? '',
      'PhuongXa': phuongXa ?? '',
      'PhuongXaTen': phuongXaTen ?? '',
      'TrieuChung': trieuChung ?? '',
      'DangKyDum': dangKyDum ?? '',
    };
  }
}

class DkkSoKhamDto {
  final int id;
  final String? sdtDangNhap;
  final String? maThe;
  final String? hoTen;
  final int? namSinh;
  final dynamic gioiTinh;
  final String? sdt;
  final String? ngayGioKham;
  final String? trieuChung;
  final String? dangKyDum;
  final int? soDangKy;
  final String? ngayud;
  final String? maBN;
  final int? done;
  final String? trangThai;
  final String? bgColor;
  // --- Fields mới (Luồng 2) ---
  /// Cờ server cho phép xóa phiếu (nullable — server có thể chưa có field này).
  final bool? coTheXoa;
  /// Số CCCD hoặc Hộ chiếu
  final String? soCcHc;
  /// Ngày cấp CCCD/HC
  final String? ngayCap;
  /// Địa chỉ đầy đủ
  final String? diaChi;
  final String? ngaySinh;
  final String? tinhTp;
  final String? tinhTpTen;
  final String? phuongXa;
  final String? phuongXaTen;
  final String? phongKham;
  final String? phongKhamTen;

  DkkSoKhamDto({
    required this.id,
    this.sdtDangNhap,
    this.maThe,
    this.hoTen,
    this.namSinh,
    this.gioiTinh,
    this.sdt,
    this.ngayGioKham,
    this.trieuChung,
    this.dangKyDum,
    this.soDangKy,
    this.ngayud,
    this.maBN,
    this.done,
    this.trangThai,
    this.bgColor,
    this.coTheXoa,
    this.soCcHc,
    this.ngayCap,
    this.diaChi,
    this.ngaySinh,
    this.tinhTp,
    this.tinhTpTen,
    this.phuongXa,
    this.phuongXaTen,
    this.phongKham,
    this.phongKhamTen,
  });

  factory DkkSoKhamDto.fromJson(Map<String, dynamic> json) {
    return DkkSoKhamDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      sdtDangNhap: json['sdtdangnhap']?.toString(),
      maThe: json['mathe']?.toString(),
      hoTen: json['hoten']?.toString(),
      namSinh: (json['namsinh'] as num?)?.toInt(),
      gioiTinh: json['gioitinh'],
      sdt: json['sdt']?.toString(),
      ngayGioKham: json['ngaygiokham']?.toString(),
      trieuChung: json['trieuchung']?.toString(),
      dangKyDum: json['dangkydum']?.toString(),
      soDangKy: (json['sodangky'] as num?)?.toInt(),
      ngayud: json['ngayud']?.toString(),
      maBN: json['mabn']?.toString(),
      done: (json['done'] as num?)?.toInt(),
      trangThai: json['TrangThai']?.toString(),
      bgColor: json['BgColor']?.toString(),
      // Fields mới
      coTheXoa: json['CoTheXoa'] as bool?,
      soCcHc: json['SoCcHc']?.toString() ?? json['soCcHc']?.toString(),
      ngayCap: json['NgayCap']?.toString() ?? json['ngayCap']?.toString(),
      diaChi: json['DiaChi']?.toString() ?? json['diaChi']?.toString(),
      ngaySinh: json['NgaySinh']?.toString() ?? json['ngaysinh']?.toString(),
      tinhTp: json['TinhTp']?.toString() ?? json['tinhtp']?.toString(),
      tinhTpTen: json['TinhTpTen']?.toString() ?? json['tinhtpten']?.toString(),
      phuongXa: json['PhuongXa']?.toString() ?? json['phuongxa']?.toString(),
      phuongXaTen: json['PhuongXaTen']?.toString() ?? json['phuongxaten']?.toString(),
      phongKham: json['PhongKham']?.toString() ?? json['phongkham']?.toString(),
      phongKhamTen: json['PhongKhamTen']?.toString() ?? json['phongkhamten']?.toString(),
    );
  }
}
