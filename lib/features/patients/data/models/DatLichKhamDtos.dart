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

class DkkGioKhamDto {
  final String id;
  final String display;

  DkkGioKhamDto({required this.id, required this.display});

  factory DkkGioKhamDto.fromJson(Map<String, dynamic> json) {
    return DkkGioKhamDto(
      id: json['Id']?.toString() ?? '',
      display: json['Display']?.toString() ?? '',
    );
  }
}

class DkkThongTinKhamListMasterDto {
  final List<DkkGioKhamDto> listGioKham;
  final List<String> listNgayKham;
  final int maxNgayKham;

  DkkThongTinKhamListMasterDto({
    required this.listGioKham,
    required this.listNgayKham,
    required this.maxNgayKham,
  });

  factory DkkThongTinKhamListMasterDto.fromJson(Map<String, dynamic> json) {
    final gioList = (json['ListGioKham'] as List?)
            ?.map((e) => DkkGioKhamDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final ngayList = (json['ListNgayKham'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final maxDays = (json['MaxNgayKham'] as num?)?.toInt() ?? 20;

    return DkkThongTinKhamListMasterDto(
      listGioKham: gioList,
      listNgayKham: ngayList,
      maxNgayKham: maxDays,
    );
  }
}

class DangKyKhamRequestDto {
  final String? maHS;
  final String? maBN;
  final String? maBhytHoacMaBn;
  final String hoTen;
  final String gioiTinh;
  final String namSinh;
  final String soDienThoai;
  final String ngayKham;
  final String gioKham;
  final String? trieuChung;
  final String? dangKyDum;

  DangKyKhamRequestDto({
    this.maHS,
    this.maBN,
    this.maBhytHoacMaBn,
    required this.hoTen,
    required this.gioiTinh,
    required this.namSinh,
    required this.soDienThoai,
    required this.ngayKham,
    required this.gioKham,
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
      'NamSinh': namSinh,
      'SoDienThoai': soDienThoai,
      'NgayKham': ngayKham,
      'GioKham': gioKham,
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
    );
  }
}
