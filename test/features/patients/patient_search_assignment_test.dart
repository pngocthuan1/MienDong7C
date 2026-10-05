import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:benhvien7c/features/auth/domain/repositories/AuthRepository.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/PatientProfileCreateViewModel.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/core/commands/result.dart';

import 'package:benhvien7c/features/patients/domain/entities/DkkThongTinKhamModel.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/DkkCompareViewModel.dart';

class FakePortalRepository implements PortalRepository {
  DkkTimBenhNhanResponseDto? mockSearchResponse;
  PatientProfileDraftEntity? lastCreatedDraft;
  String? lastDeptId;
  String? lastProvinceCode;
  String? lastWardCode;

  @override
  Future<Result<MedicalTicketEntity>> createMedicalTicket(
    UserRole role,
    PatientProfileDraftEntity draft, {
    String? department,
    String? departmentId,
    String? provinceCode,
    String? provinceName,
    String? wardCode,
    String? wardName,
    String? selectedDate,
    String? selectedTime,
    String? symptom,
  }) async {
    lastCreatedDraft = draft;
    lastDeptId = departmentId;
    lastProvinceCode = provinceCode;
    lastWardCode = wardCode;
    return const Ok(MedicalTicketEntity(
      hospitalName: 'BV Quân Dân Y Miền Đông',
      hospitalAddress: '50 Lê Văn Việt',
      ticketTitle: 'Phiếu khám',
      roomName: 'P01',
      serviceName: 'Khám bệnh',
      queueNumber: '001',
      scheduleText: 'Thứ 5, 01/10/2026',
      patientName: 'LÊ NGUYỄN GIA HƯNG',
      gender: 'Nam',
      birthYear: '1989',
      address: '50 Lê Văn Việt',
      insuranceText: 'Có BHYT',
      patientCode: '07641190',
      createdAtText: '01/10/2026',
      note: 'Note',
    ));
  }

  @override
  Future<Result<DkkTimBenhNhanResponseDto?>> timBenhNhanByCccdHc(String soCcHc) async {
    return Ok(mockSearchResponse);
  }

  @override
  Future<Result<DkkListMasterDto>> fetchListMaster() async {
    return Ok(DkkListMasterDto(
      listPhongKham: [],
      listTinh: [],
      dicPhuong: {},
      listNgayKham: [],
      listGioKham: [],
      dicNgayGioKham: {},
    ));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository implements AuthRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final secureStorage = SecureStorageService();
    final sessionStore = AppSessionStore.instance;
    final userSession = const UserProfileSession(
      fullName: 'Người Dùng Test',
      phoneNumber: '0901234567',
      role: UserRole.customer,
    );
    sessionStore.setSession(
      sessionStore.session ??
          AuthSessionEntity(
            accessToken: 'dummy_token',
            refreshToken: 'dummy_refresh',
            user: userSession,
          ),
      userSession,
    );

    AppLocator.init(
      repository: FakeAuthRepository(),
      storage: secureStorage,
      portalRepo: FakePortalRepository(),
      session: sessionStore,
      dio: DioClient(secureStorage: secureStorage),
      prefs: prefs,
    );
  });

  group('Luồng 1 — Tìm Bệnh Nhân & Định dạng Ngày Tháng', () {
    test('1. Chuẩn hóa định dạng ngày tháng và xử lý null/rỗng', () {
      expect(DateTimeConverter.toVnDate('1989-03-25T00:00:00'), '25/03/1989');
      expect(DateTimeConverter.toVnDate('2005-01-04T15:30:00'), '04/01/2005');
      expect(DateTimeConverter.toVnDate('2021-10-20'), '20/10/2021');
      expect(DateTimeConverter.toVnDate('25/03/1989'), '25/03/1989');
      expect(DateTimeConverter.toVnDate(null), isNull);
      expect(DateTimeConverter.toVnDate('null'), isNull);
      expect(DateTimeConverter.toVnDate(''), isNull);
      expect(DateTimeConverter.toVnDate('   '), isNull);
    });

    test('2. Sửa lỗi gán sai trường: CCCD A (MaBN X) -> Tìm lại CCCD B (MaBN Y)', () {
      final repo = FakePortalRepository();
      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);

      // --- LẦN 1: Tìm CCCD A ('082089008431') có MaBN X ('07641190') ---
      final dtoA = DkkTimBenhNhanResponseDto(
        maBN: '07641190',
        maBhytHoacMaBn: '082089008431',
        hoTen: 'LÊ NGUYỄN GIA HƯNG',
        ngaySinh: '1989-03-25T00:00:00',
        ngayCap: null, // Chưa có ngày cấp
        soCcHc: '082089008431',
        gioiTinh: 'Nam',
        soDienThoai: '0902377251',
        tinhTpTen: 'Thành phố Hồ Chí Minh',
        phuongXaTen: 'Phường Đông Hòa',
      );

      vm.cccdSearchController.text = '082089008431';
      vm.fillFromHospitalRecord(dtoA, searchedNumber: '082089008431');

      // Xác nhận ô CCCD hiển thị đúng số CCCD A (KHÔNG ĐƯỢC bị gán bằng MaBN X)
      expect(vm.identifierController.text, '082089008431',
          reason: 'Ô CCCD/HC phải hiển thị đúng số CCCD A đã tìm');
      // Xác nhận ô Mã bệnh nhân hiển thị đúng MaBN X
      expect(vm.patientCodeController.text, '07641190',
          reason: 'Ô Mã bệnh nhân phải hiển thị đúng MaBN X');
      // Xác nhận ngày sinh format chuẩn dd/MM/yyyy
      expect(vm.dobController.text, '25/03/1989');
      // Xác nhận ngày cấp null không hiển thị chữ "null"
      expect(vm.cccdIssueDateController.text, isEmpty);
      expect(vm.fullNameController.text, 'LÊ NGUYỄN GIA HƯNG');

      // --- LẦN 2: Tìm lại với CCCD B ('079123456789') có MaBN Y ('08889999') ---
      final dtoB = DkkTimBenhNhanResponseDto(
        maBN: '08889999',
        maBhytHoacMaBn: '079123456789',
        hoTen: 'TRẦN THỊ BÍCH NGỌC',
        ngaySinh: '1995-10-15T00:00:00',
        ngayCap: '2021-05-20T00:00:00',
        soCcHc: '079123456789',
        gioiTinh: 'Nữ',
        soDienThoai: '0987654321',
        tinhTpTen: 'Tỉnh Bình Dương',
        phuongXaTen: 'Phường Dĩ An',
      );

      vm.cccdSearchController.text = '079123456789';
      vm.fillFromHospitalRecord(dtoB, searchedNumber: '079123456789');

      // Xác nhận CẢ HAI ô được cập nhật lại theo giá trị mới, không còn sót A/X
      expect(vm.identifierController.text, '079123456789',
          reason: 'Ô CCCD/HC phải cập nhật thành số CCCD B mới');
      expect(vm.patientCodeController.text, '08889999',
          reason: 'Ô Mã bệnh nhân phải cập nhật thành MaBN Y mới');
      expect(vm.fullNameController.text, 'TRẦN THỊ BÍCH NGỌC');
      expect(vm.dobController.text, '15/10/1995');
      expect(vm.cccdIssueDateController.text, '20/05/2021');
      expect(vm.gender, 'Nữ');
    });

    test('3. Chọn hồ sơ đã lưu (selectProfile): Gán đúng ô CCCD và ô Mã BN, không bị nhầm lẫn', () {
      final repo = FakePortalRepository();
      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);

      // Hồ sơ chuẩn: CCCD 12 số, Mã BN 8 số
      const profile = PatientProfileDraftEntity(
        identifier: '079123456789',
        maSo: '07641190',
        fullName: 'NGUYỄN VĂN AN',
        birthYear: '1990',
        gender: 'Nam',
        phoneNumber: '0912345678',
        dateOfBirth: '1990-05-20T00:00:00',
        cccdIssueDate: '2021-08-15T00:00:00',
      );

      vm.selectProfile(profile);

      expect(vm.identifierController.text, '079123456789',
          reason: 'Ô CCCD/HC phải hiển thị đúng số CCCD');
      expect(vm.patientCodeController.text, '07641190',
          reason: 'Ô Mã bệnh nhân phải hiển thị đúng Mã BN');
      expect(vm.maBN, '07641190');
      expect(vm.dobController.text, '20/05/1990',
          reason: 'Ngày sinh phải được format dd/MM/yyyy');
      expect(vm.cccdIssueDateController.text, '15/08/2021',
          reason: 'Ngày cấp phải được format dd/MM/yyyy');

      // Trường hợp dữ liệu cũ bị lỗi identifier trùng với maSo:
      const corruptProfile = PatientProfileDraftEntity(
        identifier: '07641190', // Bị lẫn MaSo vào ô identifier
        maSo: '07641190',
        fullName: 'LÊ THỊ BÌNH',
        birthYear: '1985',
        gender: 'Nữ',
        phoneNumber: '0988776655',
      );

      vm.clearProfileSelection();
      vm.selectProfile(corruptProfile);

      expect(vm.identifierController.text, isEmpty,
          reason: 'Ô CCCD không được hiển thị Mã bệnh nhân');
      expect(vm.patientCodeController.text, '07641190',
          reason: 'Ô Mã BN phải hiển thị đúng Mã BN');
    });

    test('4. Đăng ký lại từ phiếu khám cũ (prefillFromTicket): Điền đúng đầy đủ 9 trường vào 9 ô, không ô nào bị trống hoặc nhầm lẫn', () {
      final repo = FakePortalRepository();
      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);

      const ticket = MedicalTicketEntity(
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt, Tăng Nhơn Phú',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '001',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'LÊ NGUYỄN GIA HƯNG',
        gender: 'Nam',
        birthYear: '1989',
        address: '50 Lê Văn Việt',
        insuranceText: 'Có BHYT',
        patientCode: '07641190',
        createdAtText: '29/09/2026',
        note: 'Ghi chú',
        phoneNumber: '0902377251',
        dateOfBirth: '1989-03-25T00:00:00',
        soCcHc: '082089008431',
        ngayCap: '2021-10-20T00:00:00',
        province: 'Thành phố Hồ Chí Minh',
        ward: 'Phường Đông Hòa',
        clinic: 'Phòng khám 1 - Nội tổng quát',
        symptom: 'Đau đầu, sốt nhẹ',
      );

      vm.prefillFromTicket(ticket);

      // 1. Mã bệnh nhân: Điền đúng ô "Mã bệnh nhân (Hệ thống tự cấp)"
      expect(vm.patientCodeController.text, '07641190',
          reason: 'Ô Mã bệnh nhân phải hiển thị đúng Mã BN 07641190 từ ticket');
      expect(vm.maBN, '07641190');

      // 2. Số CCCD/HC: Điền đúng ô CCCD, TUYỆT ĐỐI KHÔNG lấy Mã BN để điền vào ô này
      expect(vm.identifierController.text, '082089008431',
          reason: 'Ô CCCD/HC phải hiển thị đúng số CCCD soCcHc, không được nhầm thành Mã BN');
      expect(vm.identifierController.text, isNot(equals(vm.patientCodeController.text)));

      // 3. Ngày cấp: Điền đúng định dạng dd/MM/yyyy
      expect(vm.cccdIssueDateController.text, '20/10/2021',
          reason: 'Ô Ngày cấp CCCD phải chuẩn dd/MM/yyyy');

      // 4. Họ tên: Giữ nguyên họ tên đầy đủ từ phiếu khám, không bị rút gọn thành tên tài khoản đăng nhập
      expect(vm.fullNameController.text, 'LÊ NGUYỄN GIA HƯNG',
          reason: 'Họ tên phải là họ tên đầy đủ của phiếu khám, không bị đè bằng tên tài khoản');

      // 5. Ngày sinh: Điền đúng định dạng dd/MM/yyyy
      expect(vm.dobController.text, '25/03/1989',
          reason: 'Ô Ngày sinh phải chuẩn dd/MM/yyyy');
      expect(vm.birthYearController.text, '1989');

      // 6. Giới tính
      expect(vm.gender, 'Nam');

      // 7. Số điện thoại
      expect(vm.phoneController.text, '0902377251',
          reason: 'Ô Số điện thoại phải đúng thông tin từ phiếu');

      // 8. Tỉnh / TP
      expect(vm.provinceController.text, 'Thành phố Hồ Chí Minh',
          reason: 'Ô Tỉnh/TP phải đúng thông tin từ phiếu');

      // 9. Phường / Xã
      expect(vm.wardController.text, 'Phường Đông Hòa',
          reason: 'Ô Phường/Xã phải đúng thông tin từ phiếu');

      // Trạng thái form: Form KHÔNG bị khóa read-only, người dùng được quyền sửa đổi
      expect(vm.isExistingProfile, isFalse,
          reason: 'Đăng ký lại không được coi là chọn hồ sơ tĩnh read-only');
      expect(vm.formIsReadOnly, isFalse,
          reason: 'Form đăng ký lại phải cho phép người dùng sửa lại thông tin');
      expect(vm.isFromHospitalRecord, isTrue,
          reason: 'Nguồn dữ liệu đánh dấu từ bệnh viện để kích hoạt đối chiếu Luồng 3');
      expect(vm.needsComparisonCheck, isTrue);
    });

    test('5. Đăng ký lại cho phép sửa thông tin và kích hoạt màn đối chiếu Luồng 3 khi có thay đổi', () async {
      final repo = FakePortalRepository();
      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);

      const ticket = MedicalTicketEntity(
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt, Tăng Nhơn Phú',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '001',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'LÊ NGUYỄN GIA HƯNG',
        gender: 'Nam',
        birthYear: '1989',
        address: '50 Lê Văn Việt',
        insuranceText: 'Có BHYT',
        patientCode: '07641190',
        createdAtText: '29/09/2026',
        note: 'Ghi chú',
        phoneNumber: '0902377251',
        dateOfBirth: '1989-03-25T00:00:00',
        soCcHc: '082089008431',
        ngayCap: '2021-10-20T00:00:00',
        province: 'Thành phố Hồ Chí Minh',
        ward: 'Phường Đông Hòa',
      );

      vm.prefillFromTicket(ticket);

      // Trường hợp 1: Người dùng giữ nguyên thông tin phiếu khám cũ -> Không phát sinh khác biệt
      final compareModelSame = await vm.buildCompareModel();
      expect(compareModelSame, isNull,
          reason: 'Nếu không chỉnh sửa gì thì không phát sinh Diff');

      // Trường hợp 2: Người dùng sửa đổi Số điện thoại
      vm.phoneController.text = '0988999888';
      final compareModelDiffPhone = await vm.buildCompareModel();
      expect(compareModelDiffPhone, isNotNull);
      expect(compareModelDiffPhone!.hasDiff, isTrue);
      expect(compareModelDiffPhone.soDienThoaiDiff, isTrue,
          reason: 'Trường số điện thoại phải phát hiện khác biệt');
      expect(compareModelDiffPhone.hoTenDiff, isFalse);

      // Trường hợp 3: Người dùng sửa đổi Họ tên
      vm.fullNameController.text = 'LÊ GIA HƯNG';
      final compareModelDiffName = await vm.buildCompareModel();
      expect(compareModelDiffName, isNotNull);
      expect(compareModelDiffName!.hasDiff, isTrue);
      expect(compareModelDiffName.hoTenDiff, isTrue,
          reason: 'Trường họ tên phải phát hiện khác biệt');
    });

    test('6. Đăng ký lại phiếu cũ bị thiếu CCCD / ngày cấp -> Tự động tra cứu làm giàu dữ liệu từ API', () async {
      final repo = FakePortalRepository();
      repo.mockSearchResponse = DkkTimBenhNhanResponseDto(
        maBN: '07641190',
        maBhytHoacMaBn: '082089008431',
        hoTen: 'LÊ NGUYỄN GIA HƯNG',
        ngaySinh: '1989-03-25T00:00:00',
        ngayCap: '2021-10-20T00:00:00',
        soCcHc: '082089008431',
        gioiTinh: 'Nam',
        soDienThoai: '0902377251',
        tinhTpTen: 'Thành phố Hồ Chí Minh',
        phuongXaTen: 'Phường Đông Hòa',
      );

      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);

      // Phiếu khám cũ bị thiếu soCcHc và ngayCap (do hệ thống cũ lưu thiếu)
      const ticketThieu = MedicalTicketEntity(
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '001',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'LÊ NGUYỄN GIA HƯNG',
        gender: 'Nam',
        birthYear: '1989',
        address: '50 Lê Văn Việt',
        insuranceText: 'Có BHYT',
        patientCode: '07641190',
        createdAtText: '29/09/2026',
        note: 'Ghi chú',
      );

      vm.prefillFromTicket(ticketThieu);

      // Đợi microtasks / async enrichment hoàn tất
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Xác nhận các trường thiếu đã được bổ sung tự động từ hồ sơ bệnh viện
      expect(vm.patientCodeController.text, '07641190');
      expect(vm.identifierController.text, '082089008431',
          reason: 'Số CCCD được tự động làm giàu từ hồ sơ bệnh viện');
      expect(vm.cccdIssueDateController.text, '20/10/2021',
          reason: 'Ngày cấp được tự động làm giàu từ hồ sơ bệnh viện');
      expect(vm.dobController.text, '25/03/1989',
          reason: 'Ngày sinh được tự động làm giàu từ hồ sơ bệnh viện');
      expect(vm.provinceController.text, 'Thành phố Hồ Chí Minh');
      expect(vm.wardController.text, 'Phường Đông Hòa');
    });

    test('7. Khắc phục lỗi TimeExpired: Lọc bỏ khung giờ đã qua trong ngày và tự khởi tạo ngày giờ hợp lệ', () {
      final repo = FakePortalRepository();
      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      // 1. Ngày mai -> Luôn hợp lệ với mọi khung giờ
      vm.selectedDate = tomorrow;
      vm.selectedTime = '07g00 - 07g30';
      expect(vm.validateSelectedSlot(), isTrue,
          reason: 'Khung giờ ở ngày trong tương lai luôn hợp lệ');

      // 2. Ngày hôm qua -> Luôn không hợp lệ
      vm.selectedDate = today.subtract(const Duration(days: 1));
      vm.selectedTime = '07g00 - 07g30';
      expect(vm.validateSelectedSlot(), isFalse,
          reason: 'Khung giờ ở ngày quá khứ phải bị từ chối');

      // 3. Khung giờ sáng sớm 06:00 của ngày hôm nay (nếu hiện tại đã trôi qua sau 06:15)
      final earlyMorning = DateTime(now.year, now.month, now.day, 6, 0);
      if (now.isAfter(earlyMorning.add(const Duration(minutes: 15)))) {
        vm.selectedDate = today;
        vm.selectedTime = '06g00 - 06g30';
        expect(vm.validateSelectedSlot(), isFalse,
            reason: 'Khung giờ sáng sớm đã trôi qua hơn 15 phút phải bị từ chối');
        
        // Xác nhận getSlotsForDate(today) tự động loại bỏ các khung giờ đã qua
        final slotsToday = vm.getSlotsForDate(today);
        expect(slotsToday.contains('06g00 - 06g30'), isFalse,
            reason: 'getSlotsForDate không được chứa khung giờ đã hết hạn');
      }

      // 4. Bấm "Đăng ký lại" từ phiếu cũ: Hệ thống tự động chọn ngày khám và khung giờ khám mới hợp lệ
      const oldTicket = MedicalTicketEntity(
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '001',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'LÊ NGUYỄN GIA HƯNG',
        gender: 'Nam',
        birthYear: '1989',
        address: '50 Lê Văn Việt',
        insuranceText: 'Có BHYT',
        patientCode: '07641190',
        createdAtText: '29/09/2026',
        note: 'Ghi chú',
      );

      vm.prefillFromTicket(oldTicket);
      expect(vm.selectedDate, isNotNull,
          reason: 'Đăng ký lại phải tự động khởi tạo ngày khám mới');
      expect(vm.selectedTime, isNotNull,
          reason: 'Đăng ký lại phải tự động khởi tạo khung giờ khám mới');
      expect(vm.validateSelectedSlot(), isTrue,
          reason: 'Ngày giờ tự khởi tạo khi Đăng ký lại phải hợp lệ');
    });

    test('8. Luồng 3: Màn đối chiếu thông tin — Đầy đủ trường Số CC/HC, Giới tính viết hoa, cờ NgayCapDiff & maBhytHoacMaBnDiff chính xác, và submit an toàn không lỗi', () async {
      final repo = FakePortalRepository();

      const systemSnapshot = DkkTimBenhNhanResponseDto(
        maBN: '07641190',
        maBhytHoacMaBn: '082089008431',
        hoTen: 'LÊ NGUYỄN GIA HƯNG',
        ngaySinh: '1989-03-25T00:00:00',
        ngayCap: '2021-10-20T00:00:00',
        soCcHc: '082089008431',
        gioiTinh: 'nam', // dữ liệu thô từ server dạng chữ thường
        soDienThoai: '0902377251',
        tinhTp: '79',
        tinhTpTen: 'Thành phố Hồ Chí Minh',
        phuongXa: '26830',
        phuongXaTen: 'Phường Đông Hòa',
      );

      // Trường hợp 1: Người dùng để trống Ngày cấp và nhập giới tính chữ thường 'nam'
      const userDraftEmptyNgayCap = PatientProfileDraftEntity(
        identifier: '082089008431',
        fullName: 'LÊ NGUYỄN GIA HƯNG',
        birthYear: '1989',
        gender: 'nam', // chữ thường
        phoneNumber: '0988999888', // SĐT sửa khác
        dateOfBirth: '25/03/1989',
        cccdIssueDate: null, // để trống ngày cấp
        province: 'Thành phố Hồ Chí Minh',
        ward: 'Phường Đông Hòa',
        maSo: '07641190',
        maBN: '07641190',
      );

      final model1 = DkkThongTinKhamModel.compare(
        system: systemSnapshot,
        user: userDraftEmptyNgayCap,
        isFromSavedProfile: true,
      );

      // 1. Kiểm tra trường Số CC/HC được map chính xác trên cả 2 bên
      expect(model1.systemCccd, '082089008431');
      expect(model1.userCccd, '082089008431');
      expect(model1.maBhytHoacMaBnDiff, isFalse);

      // 2. Kiểm tra chuẩn hóa Giới tính viết hoa chữ cái đầu: 'Nam', 'Nữ'
      expect(model1.systemGioiTinh, 'Nam', reason: 'Giới tính hệ thống phải viết hoa "Nam"');
      expect(model1.userGioiTinh, 'Nam', reason: 'Giới tính người dùng phải viết hoa "Nam"');
      expect(model1.gioiTinhDiff, isFalse);

      // 3. Kiểm tra cờ NgayCapDiff: Người dùng để trống ngày cấp còn hệ thống có -> BẮT BUỘC ĐÁNH DẤU DIFF = TRUE
      expect(model1.ngayCapDiff, isTrue,
          reason: 'Một bên rỗng và một bên có ngày cấp phải tính là Diff = true');

      // 4. Kiểm tra SoDienThoaiDiff
      expect(model1.soDienThoaiDiff, isTrue);

      // 5. Kiểm tra khi serverDiff trả về kết quả (thậm chí server trả về NgayCapDiff: false do default bool),
      // client compare vẫn giữ vững NgayCapDiff = true
      final combinedModel = DkkThongTinKhamModel.fromServerCheck(
        system: systemSnapshot,
        user: userDraftEmptyNgayCap,
        isFromSavedProfile: true,
        serverDiff: const DkkKiemTraBenhNhanResponseDto(
          soDienThoaiDiff: true,
          ngayCapDiff: false, // server bool default
        ),
      );
      expect(combinedModel.ngayCapDiff, isTrue,
          reason: 'NgayCapDiff không bị ghi đè bởi false của serverDiff khi client đã phát hiện khác biệt');

      // 6. Kiểm tra trường hợp sửa khác số CCCD: maBhytHoacMaBnDiff = true
      const userDraftDiffCccd = PatientProfileDraftEntity(
        identifier: '079089001234', // CCCD khác
        fullName: 'LÊ NGUYỄN GIA HƯNG',
        birthYear: '1989',
        gender: 'Nam',
        phoneNumber: '0902377251',
        dateOfBirth: '25/03/1989',
        cccdIssueDate: '20/10/2021',
        province: 'Thành phố Hồ Chí Minh',
        ward: 'Phường Đông Hòa',
        maSo: '07641190',
        maBN: '07641190',
      );
      final modelDiffCccd = DkkThongTinKhamModel.compare(
        system: systemSnapshot,
        user: userDraftDiffCccd,
        isFromSavedProfile: false,
      );
      expect(modelDiffCccd.maBhytHoacMaBnDiff, isTrue,
          reason: 'Khác CCCD phải đánh dấu maBhytHoacMaBnDiff = true');

      // 7. Kiểm tra Submit từ DkkCompareViewModel: Cả 2 nút xác nhận đều truyền đầy đủ các trường bắt buộc
      final compareVm = DkkCompareViewModel(
        compareModel: model1,
        userDraft: userDraftEmptyNgayCap,
        repository: repo,
        role: UserRole.customer,
        department: 'Phòng khám 1 - Nội tổng quát',
        departmentId: '49',
        provinceCode: '79',
        provinceName: 'Thành phố Hồ Chí Minh',
        wardCode: '26830',
        wardName: 'Phường Đông Hòa',
        selectedDate: 'Thứ 5, 01/10/2026',
        selectedTime: '07g00 - 07g30',
        symptom: 'Đau đầu',
      );

      // Nút 1: Xác nhận bằng thông tin hệ thống
      final resultSys = await compareVm.submit(true);
      expect(resultSys is Ok<MedicalTicketEntity>, isTrue);
      expect(repo.lastCreatedDraft, isNotNull);
      expect(repo.lastCreatedDraft!.identifier, '082089008431');
      expect(repo.lastCreatedDraft!.cccdIssueDate, '2021-10-20T00:00:00');
      expect(repo.lastCreatedDraft!.gender, 'Nam');
      expect(repo.lastDeptId, '49');
      expect(repo.lastProvinceCode, '79');
      expect(repo.lastWardCode, '26830');

      // Nút 2: Xác nhận bằng thông tin người dùng nhập (dù user để trống ngày cấp, hệ thống tự bảo lưu an toàn từ snapshot)
      final resultUser = await compareVm.submit(false);
      expect(resultUser is Ok<MedicalTicketEntity>, isTrue);
      expect(repo.lastCreatedDraft, isNotNull);
      expect(repo.lastCreatedDraft!.identifier, '082089008431');
      expect(repo.lastCreatedDraft!.cccdIssueDate, isNotNull,
          reason: 'Ngày cấp được bảo lưu an toàn từ hệ thống để backend không bị lỗi null');
      expect(repo.lastCreatedDraft!.gender, 'Nam');
      expect(repo.lastDeptId, '49');
    });

    test('9. Lưu & Đọc Địa chỉ phiếu khám: Đầy đủ TinhTpTen, PhuongXaTen, DiaChi và không hiển thị "--"', () async {
      // 1. Kiểm tra format hiển thị ở danh sách với phiếu có đầy đủ địa chỉ
      const ticketWithFullAddress = MedicalTicketEntity(
        id: '101',
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '001',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'LÊ NGUYỄN GIA HƯNG',
        gender: 'Nam',
        birthYear: '1989',
        address: 'Phường Đông Hòa, Thành phố Hồ Chí Minh',
        province: 'Thành phố Hồ Chí Minh',
        ward: 'Phường Đông Hòa',
        insuranceText: 'Có BHYT',
        patientCode: '07641190',
        createdAtText: '29/09/2026',
        note: 'Ghi chú',
      );

      final resolvedAddr1 = ticketWithFullAddress.address.trim().isNotEmpty
          ? ticketWithFullAddress.address.trim()
          : [ticketWithFullAddress.ward, ticketWithFullAddress.province]
              .where((s) => s != null && s.trim().isNotEmpty)
              .join(', ');
      final display1 = resolvedAddr1.trim().isEmpty ? '--' : resolvedAddr1.trim();
      expect(display1, 'Phường Đông Hòa, Thành phố Hồ Chí Minh');
      expect(display1, isNot('--'));

      // 2. Kiểm tra fallback khi address rỗng nhưng ward và province có giá trị
      const ticketFallback = MedicalTicketEntity(
        id: '102',
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '002',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'LÊ NGUYỄN GIA HƯNG',
        gender: 'Nam',
        birthYear: '1989',
        address: '', // rỗng
        province: 'Thành phố Hồ Chí Minh',
        ward: 'Phường Tăng Nhơn Phú',
        insuranceText: 'Có BHYT',
        patientCode: '07641190',
        createdAtText: '29/09/2026',
        note: 'Ghi chú',
      );

      final resolvedAddr2 = ticketFallback.address.trim().isNotEmpty
          ? ticketFallback.address.trim()
          : [ticketFallback.ward, ticketFallback.province]
              .where((s) => s != null && s.trim().isNotEmpty)
              .join(', ');
      final display2 = resolvedAddr2.trim().isEmpty ? '--' : resolvedAddr2.trim();
      expect(display2, 'Phường Tăng Nhơn Phú, Thành phố Hồ Chí Minh');
      expect(display2, isNot('--'));

      // 3. Kiểm tra phiếu cũ hoàn toàn không có thông tin thì hiển thị '--' theo đúng đặc tả mục 4
      const ticketOldEmpty = MedicalTicketEntity(
        id: '103',
        hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
        hospitalAddress: '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
        ticketTitle: 'PHIẾU ĐẶT LỊCH KHÁM',
        roomName: 'Phòng 01',
        serviceName: 'Khám bệnh',
        queueNumber: '003',
        scheduleText: 'Thứ 4, 30/09/2026',
        patientName: 'TEST 260928 12:32',
        gender: 'Nam',
        birthYear: '2000',
        address: '',
        province: null,
        ward: null,
        insuranceText: 'Tự túc',
        patientCode: '07641190',
        createdAtText: '28/09/2026',
        note: 'Ghi chú',
      );

      final resolvedAddr3 = ticketOldEmpty.address.trim().isNotEmpty
          ? ticketOldEmpty.address.trim()
          : [ticketOldEmpty.ward, ticketOldEmpty.province]
              .where((s) => s != null && s.trim().isNotEmpty)
              .join(', ');
      final display3 = resolvedAddr3.trim().isEmpty ? '--' : resolvedAddr3.trim();
      expect(display3, '--', reason: 'Phiếu cũ thực sự không có địa chỉ thì hiển thị --');

      // 4. Kiểm tra prefillFromTicket tách address thành province và ward khi đăng ký lại
      final repo = FakePortalRepository();
      final vm = PatientProfileCreateViewModel(repo, AppSessionStore.instance);
      vm.prefillFromTicket(ticketWithFullAddress);
      expect(vm.provinceController.text, 'Thành phố Hồ Chí Minh');
      expect(vm.wardController.text, 'Phường Đông Hòa');
    });
  });
}
