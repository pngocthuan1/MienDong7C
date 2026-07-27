/// Phân nhóm lỗi để tầng ViewModel/UI xử lý theo nhóm
/// thay vì switch-case từng mã lẻ.
enum ErrorCategory {
  none, // Không có lỗi / thành công
  system, // Lỗi hệ thống, network, timeout
  auth, // Lỗi đăng nhập, phiên làm việc
  validation, // Lỗi dữ liệu đầu vào
  patient, // Lỗi liên quan hồ sơ bệnh nhân
  insurance, // Lỗi liên quan BHYT
  appointment, // Lỗi liên quan đăng ký khám / phòng khám
  test, // Mã dùng riêng cho môi trường test
  unknown, // Không xác định
}

enum ErrorCode {
  /// Không có lỗi
  none(0, 'Không có lỗi', ErrorCategory.none, isSuccess: true),

  // ==================== SYSTEM ====================

  /// Lỗi dữ liệu đầu vào
  validationFail(101, 'Lỗi dữ liệu đầu vào', ErrorCategory.validation),

  /// Lỗi nghiệp vụ máy chủ
  unknownLogic(102, 'Lỗi nghiệp vụ máy chủ', ErrorCategory.system),

  /// Lỗi xử lý máy chủ
  unknownApi(103, 'Lỗi xử lý máy chủ', ErrorCategory.system),

  /// Thời gian kết nối server hết hạn
  connectionTimeOut(
    339,
    'Thời gian kết nối server hết hạn!',
    ErrorCategory.system,
  ),

  /// Lỗi hiển thị
  showErrorMessage(346, 'Đã xảy ra lỗi hiển thị', ErrorCategory.system),

  /// Bundle ID không được hỗ trợ
  bundleIdKhongHoTro(347, 'Bundle ID không được hỗ trợ', ErrorCategory.system),

  /// Sai mã bảo mật
  saiMaBaoMat(348, 'Sai mã bảo mật', ErrorCategory.system),

  // ==================== AUTH ====================

  /// Lỗi đăng nhập thất bại
  loginFail(104, 'Lỗi đăng nhập thất bại', ErrorCategory.auth),

  /// Lỗi đăng nhập thất bại (HIS)
  loginHisFail(
    105,
    'Lỗi đăng nhập thất bại (Hệ thống HIS)',
    ErrorCategory.auth,
  ),

  /// Bạn chưa đăng nhập
  banChuaDangNhap(106, 'Bạn chưa đăng nhập', ErrorCategory.auth),

  /// Tên đăng nhập người dùng đã tồn tại
  tenDangNhapNguoiDungDaTonTai(
    201,
    'Tên đăng nhập người dùng đã tồn tại',
    ErrorCategory.auth,
  ),

  /// Mật khẩu cũ không đúng
  matKhauCuKhongDung(202, 'Mật khẩu cũ không đúng', ErrorCategory.auth),

  // ==================== PATIENT ====================

  /// Không có thông tin bệnh nhân
  khongCoThongTinBenhNhan(
    301,
    'Không có thông tin bệnh nhân',
    ErrorCategory.patient,
  ),

  /// Mã bệnh nhân nhập vào không đúng
  maBenhNhanKhongDung(
    302,
    'Mã bệnh nhân nhập vào không đúng',
    ErrorCategory.patient,
  ),

  /// Thẻ hết hạn hoặc không tồn tại trên hệ thống
  theKhongHopLe(
    303,
    'Thẻ hết hạn hoặc không tồn tại trên hệ thống',
    ErrorCategory.patient,
  ),

  /// Kiểm tra thẻ bệnh nhân thành công
  checkTheBenhNhanHoanTat(
    305,
    'Kiểm tra thẻ bệnh nhân thành công',
    ErrorCategory.patient,
    isSuccess: true,
  ),

  /// Bệnh nhân đã tồn tại trong hệ thống
  benhNhanDaTonTai(
    306,
    'Bệnh nhân đã tồn tại trong hệ thống',
    ErrorCategory.patient,
  ),

  /// Bệnh nhân đã đăng ký khám trong ngày
  benhNhanDaDangKyKham(
    307,
    'Bệnh nhân đã đăng ký khám trong ngày',
    ErrorCategory.patient,
  ),

  /// Bệnh nhân đã đăng ký phòng khám này trong ngày hôm nay
  benhNhanDaDangKyPhongKham(
    308,
    'Bệnh nhân đã đăng ký phòng khám này trong ngày hôm nay',
    ErrorCategory.patient,
  ),

  /// Mã bệnh viện không tồn tại trong hệ thống
  maBenhVienKhongTonTaiTrongHeThong(
    312,
    'Mã bệnh viện không tồn tại trong hệ thống',
    ErrorCategory.patient,
  ),

  /// Không tìm thấy bệnh nhân
  khongTimThayBenhNhan(337, 'Không tìm thấy bệnh nhân', ErrorCategory.patient),

  // ==================== INSURANCE (BHYT) ====================

  /// Kiểm tra bảo hiểm y tế hợp lệ, hết hạn
  theBHYTKhongHopLe(
    304,
    'Thẻ BHYT không hợp lệ hoặc đã hết hạn',
    ErrorCategory.insurance,
  ),

  /// Không thực hiện được. Thông tin BHYT không đúng
  thongTinTheBHYTKhongDung(
    309,
    'Không thực hiện được. Thông tin BHYT không đúng',
    ErrorCategory.insurance,
  ),

  /// Trùng thẻ BHYT với bệnh nhân khác
  trungTheBHYT(
    313,
    'Trùng thẻ BHYT với bệnh nhân khác',
    ErrorCategory.insurance,
  ),

  /// Nơi ĐKKCB BHYT này không được thông tuyến
  maTheKhongDuocThongTuyen(
    314,
    'Nơi ĐKKCB BHYT này không được thông tuyến',
    ErrorCategory.insurance,
  ),

  /// Đối tượng không phù hợp với ký hiệu được khai báo trong danh mục
  doiTuongKhongPhuHopVoiKyHieu(
    315,
    'Đối tượng không phù hợp với ký hiệu được khai báo trong danh mục',
    ErrorCategory.insurance,
  ),

  /// Bệnh nhân đang điều trị nội, ngoại trú trong khoa bị trùng số thẻ BHYT
  benhNhanDangDieuTriNoiTruNgoaiTru(
    316,
    'Bệnh nhân đang điều trị nội, ngoại trú trong khoa bị trùng số thẻ BHYT',
    ErrorCategory.insurance,
  ),

  /// Bệnh nhân đã thanh toán chi phí điều trị BHYT trong ngày
  benhNhanDaThanhToanChiPhiTrongNgay(
    317,
    'Bệnh nhân đã thanh toán chi phí điều trị BHYT trong ngày',
    ErrorCategory.insurance,
  ),

  /// Bệnh nhân trái tuyến vui lòng không đăng ký ở đây
  benhNhanTraiTuyen(
    318,
    'Bệnh nhân trái tuyến vui lòng không đăng ký ở đây',
    ErrorCategory.insurance,
  ),

  /// Đối tượng không được đăng ký khám Online
  doiTuongKhongDuocDangKyKhamOnline(
    320,
    'Đối tượng không được đăng ký khám Online',
    ErrorCategory.insurance,
  ),

  /// Không Insert vào bảng bn_bhyt
  khongInsertDuocBangBHYT(
    322,
    'Không thể lưu thông tin BHYT',
    ErrorCategory.insurance,
  ),

  /// Số lượt đăng ký khám vượt quá quy định BHYT
  soLuotDangKyKhamVuotQuaQuyDinhBHYT(
    325,
    'Số lượt đăng ký khám vượt quá quy định BHYT',
    ErrorCategory.insurance,
  ),

  /// Chưa có thông tin trả lời từ cổng thông tuyến BHXH
  chuaCoThongTinTraLoiTuCongThongTuyen(
    332,
    'Chưa có thông tin trả lời từ cổng thông tuyến BHXH',
    ErrorCategory.insurance,
  ),

  /// Lỗi cổng BHXH Việt Nam
  loiCongBHXH(333, 'Lỗi cổng BHXH Việt Nam', ErrorCategory.insurance),

  /// Không Insert được bảng Nhận Bệnh BH
  khongInsertDuocBangNhanBenhBH(
    334,
    'Không Insert được bảng Nhận Bệnh BH',
    ErrorCategory.insurance,
  ),

  // ==================== APPOINTMENT ====================

  /// Từ ngày phải nhỏ hơn hoặc bằng ngày hiện tại
  tuNgayKhongDuocLonHonNgayHienTai(
    310,
    'Từ ngày phải nhỏ hơn hoặc bằng ngày hiện tại',
    ErrorCategory.appointment,
  ),

  /// Đến ngày phải lớn hơn ngày hiện tại
  denNgayKhongDuocNhoHonNgayHienTai(
    311,
    'Đến ngày phải lớn hơn ngày hiện tại',
    ErrorCategory.appointment,
  ),

  /// Không được đăng ký quá 02 phòng khám trong ngày
  khongDuocDangKyQua02PhongKham(
    319,
    'Không được đăng ký quá 02 phòng khám trong ngày',
    ErrorCategory.appointment,
  ),

  /// Không Insert vào bảng bn_nhanbenh
  khongInsertDuocBangNhanBenh(
    321,
    'Không thể nhận bệnh vào hệ thống',
    ErrorCategory.appointment,
  ),

  /// Không Insert vào bảng bn_sokham
  khongInsertDuocBangSoKham(
    323,
    'Không thể tạo số khám bệnh',
    ErrorCategory.appointment,
  ),

  /// Không được đăng ký 02 phòng cùng chuyên khoa
  khongTheDangKy02PhongCungChuyenKhoa(
    324,
    'Không được đăng ký 02 phòng cùng chuyên khoa',
    ErrorCategory.appointment,
  ),

  /// Đến ngày phải lớn hơn ngày hiện tại
  ngayDangKyKhongDuocNhoHonNgayHienTai(
    326,
    'Ngày đăng ký không được nhỏ hơn ngày hiện tại',
    ErrorCategory.appointment,
  ),

  /// Bạn vui lòng chọn phòng khám
  banVuiLongChonPhongKham(
    327,
    'Bạn vui lòng chọn phòng khám',
    ErrorCategory.appointment,
  ),

  /// Bệnh nhân đã khám không thể xóa
  benhNhanDaKhamKhongTheXoaDangKy(
    328,
    'Bệnh nhân đã khám không thể xóa đăng ký khám',
    ErrorCategory.appointment,
  ),

  /// Bệnh nhân đã thu tiền dịch vụ không thể xóa
  benhNhanDaThuTienDichVuKhongTheXoa(
    329,
    'Bệnh nhân đã thu tiền dịch vụ không thể xóa',
    ErrorCategory.appointment,
  ),

  /// Bạn vui lòng chọn phòng khám đã được đăng ký trước
  banVuiLongChonPhongKhamDaDangKy(
    330,
    'Bạn vui lòng chọn phòng khám đã được đăng ký trước',
    ErrorCategory.appointment,
  ),

  /// Bạn vui lòng chọn tháng đăng ký khám cho phù hợp
  banVuiLongChonThangDangKyChoPhuHop(
    331,
    'Bạn vui lòng chọn tháng đăng ký khám cho phù hợp',
    ErrorCategory.appointment,
  ),

  /// Phòng khám không tồn tại
  notFound(335, 'Phòng khám không tồn tại', ErrorCategory.appointment),

  /// Phòng khám không khả dụng (Phòng bận .. etc...)
  phongKhamKhongKhaDung(
    336,
    'Phòng khám không khả dụng (Phòng đang bận)',
    ErrorCategory.appointment,
  ),

  /// Đăng ký phòng khám thành công
  dangKyPhongKhamThanhCong(
    338,
    'Đăng ký phòng khám thành công',
    ErrorCategory.appointment,
    isSuccess: true,
  ),

  // ==================== TEST (chỉ dùng ở môi trường test) ====================

  /// Test tạo tên đăng nhập tồn tại
  testSignUpTenDangNhapTonTai(
    340,
    'Tên đăng nhập đã tồn tại (Chế độ test)',
    ErrorCategory.test,
  ),

  /// Test đăng ký khám quá hạn giờ khám
  testDangKyKhamNgayGioKhamHetHan(
    341,
    'Đăng ký khám quá hạn giờ khám (Chế độ test)',
    ErrorCategory.test,
  ),

  // ==================== UNKNOWN ====================

  /// Mã lỗi không xác định
  unknown(
    -1,
    'Đã xảy ra lỗi không xác định từ hệ thống',
    ErrorCategory.unknown,
  );

  final int value;
  final String message;
  final ErrorCategory category;

  /// true nếu đây là mã "thành công" chứ không phải lỗi thật sự
  /// (một số API dùng chung 1 field code cho cả success lẫn error)
  final bool isSuccess;

  const ErrorCode(
    this.value,
    this.message,
    this.category, {
    this.isSuccess = false,
  });

  /// Chuyển đổi mã lỗi dạng int nhận từ API sang ErrorCode enum.
  /// Nếu không khớp mã nào đã khai báo, trả về ErrorCode.unknown
  /// để tránh crash khi backend thêm mã mới mà app chưa cập nhật.
  factory ErrorCode.fromValue(int value) {
    return ErrorCode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ErrorCode.unknown,
    );
  }

  /// true nếu đây thực sự là lỗi (không phải none, không phải success)
  bool get isError => !isSuccess && this != ErrorCode.none;
}
