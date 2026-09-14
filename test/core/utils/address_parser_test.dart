import 'package:flutter_test/flutter_test.dart';
import 'package:benhvien7c/core/utils/AddressHelper.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddressHelper CCCD Parsing Tests', () {
    setUpAll(() async {
      await AddressHelper.instance.init();
    });

    test('AddressHelper loaded successfully with 34 provinces and lookup tables', () {
      expect(AddressHelper.instance.isLoaded, isTrue);
      expect(AddressHelper.instance.provinces.length, greaterThanOrEqualTo(34));
    });

    test('Parse CCCD Address: Hồ Chí Minh - Phường Bến Nghé, Quận 1', () {
      const raw = 'Số 123 đường Lê Lợi, Phường Bến Nghé, Quận 1, Thành phố Hồ Chí Minh';
      final result = AddressHelper.instance.parseCccdAddress(raw);

      expect(result.province, isNotNull);
      expect(result.province!.name, 'Hồ Chí Minh');
      expect(result.ward, isNotNull);
      expect(result.ward!.name, 'Sài Gòn');
      expect(result.isExactMatch, isTrue);
    });

    test('Parse CCCD Address: Hồ Chí Minh - Phường Linh Trung, TP Thủ Đức', () {
      const raw = 'Khu phố 3, Phường Linh Trung, Thành phố Thủ Đức, Thành phố Hồ Chí Minh';
      final result = AddressHelper.instance.parseCccdAddress(raw);

      expect(result.province, isNotNull);
      expect(result.province!.name, 'Hồ Chí Minh');
      expect(result.ward, isNotNull);
      expect(result.ward!.name, 'Linh Xuân');
      expect(result.isExactMatch, isTrue);
    });

    test('Parse CCCD Address: Đồng Nai - Xã An Phước, Huyện Long Thành', () {
      const raw = 'Ấp 2, Xã An Phước, Huyện Long Thành, Tỉnh Đồng Nai';
      final result = AddressHelper.instance.parseCccdAddress(raw);

      expect(result.province, isNotNull);
      expect(result.province!.name, 'Đồng Nai');
      expect(result.ward, isNotNull);
      expect(result.ward!.name, 'An Phước');
      expect(result.isExactMatch, isTrue);
    });

    test('Parse CCCD Address: Bình Dương - Phường An Phú, TP Thuận An (mapped to HCM An Phú)', () {
      const raw = 'Khu phố 2, Phường An Phú, Thành phố Thuận An, Tỉnh Bình Dương';
      final result = AddressHelper.instance.parseCccdAddress(raw);

      expect(result.province, isNotNull);
      expect(result.province!.name, 'Hồ Chí Minh');
      expect(result.ward, isNotNull);
      expect(result.ward!.name, 'An Phú');
      expect(result.isExactMatch, isTrue);
    });

    test('Parse CCCD Address: Hà Nội - Phường Dịch Vọng Hậu, Quận Cầu Giấy', () {
      const raw = 'Số 10, Ngõ 50, Phường Dịch Vọng Hậu, Quận Cầu Giấy, Hà Nội';
      final result = AddressHelper.instance.parseCccdAddress(raw);

      expect(result.province, isNotNull);
      expect(result.province!.name, 'Hà Nội');
      expect(result.ward, isNotNull);
      expect(result.ward!.name, 'Cầu Giấy');
      expect(result.isExactMatch, isTrue);
    });

    test('Parse CCCD Address: Cần Thơ - Xã Mỹ Khánh sáp nhập vào Phường An Bình', () {
      const raw = 'Xã Mỹ Khánh, Huyện Phong Điền, Thành phố Cần Thơ';
      final result = AddressHelper.instance.parseCccdAddress(raw);

      expect(result.province, isNotNull);
      expect(result.province!.name, 'Cần Thơ');
      expect(result.ward, isNotNull);
      expect(result.ward!.name, 'An Bình');
      expect(result.isExactMatch, isTrue);
    });
  });

  group('CccdData Date Formatter Tests', () {
    test('Format 8-digit birth date and issue date to dd/MM/yyyy', () {
      final data = CccdData(
        cccdNumber: '079095012345',
        oldIdNumber: '',
        fullName: 'Nguyễn Văn An',
        birthDate: '15081995',
        gender: 'Nam',
        address: 'Thành phố Hồ Chí Minh',
        issueDate: '25042021',
      );

      expect(data.formattedBirthDate, '15/08/1995');
      expect(data.birthYear, '1995');
      expect(data.formattedIssueDate, '25/04/2021');
    });

    test('Preserve already formatted slash dates', () {
      final data = CccdData(
        cccdNumber: '079095012345',
        oldIdNumber: '',
        fullName: 'Trần Thị Bình',
        birthDate: '02/03/1988',
        gender: 'Nữ',
        address: 'Đồng Nai',
        issueDate: '10/10/2021',
      );

      expect(data.formattedBirthDate, '02/03/1988');
      expect(data.birthYear, '1988');
      expect(data.formattedIssueDate, '10/10/2021');
    });
  });

  group('CccdParserHelper Old CCCD & New Can Cuoc 2025-2026 Tests', () {
    test('Parse Old CCCD with 9-digit old CMND', () {
      const raw = '079090001234|025812345|Nguyễn Văn An|15081990|Nam|Số 10 Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh|25122021';
      final parsed = CccdParserHelper.parse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.cccdNumber, '079090001234');
      expect(parsed.oldIdNumber, '025812345');
      expect(parsed.fullName, 'Nguyễn Văn An');
      expect(parsed.formattedBirthDate, '15/08/1990');
      expect(parsed.birthYear, '1990');
      expect(parsed.gender, 'Nam');
      expect(parsed.address, contains('Lê Lợi'));
      expect(parsed.formattedIssueDate, '25/12/2021');
      expect(parsed.isBhyt, isFalse);
    });

    test('Parse Old CCCD without old CMND', () {
      const raw = '079090001234||Trần Thị Bình|20111995|Nữ|Ấp 2, Xã An Phước, Huyện Long Thành, Tỉnh Đồng Nai|15012022';
      final parsed = CccdParserHelper.parse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.cccdNumber, '079090001234');
      expect(parsed.oldIdNumber, '');
      expect(parsed.fullName, 'Trần Thị Bình');
      expect(parsed.formattedBirthDate, '20/11/1995');
      expect(parsed.gender, 'Nữ');
      expect(parsed.isBhyt, isFalse);
    });

    test('Parse Can Cuoc with soCMND (empty or digits) and > 7 fields as specified by user', () {
      // Đúng cấu trúc người dùng mô tả:
      // parts[0]: soCCCD, parts[1]: soCMND (rỗng hoặc có số), parts[2]: hoTen, parts[3]: ngaySinh, parts[4]: gioiTinh, parts[5]: diaChi, parts[6]: ngayCap, parts[7]: extra
      const rawWithCmnd = '079090001234|341371445|Phạm Văn Nam|15081995|Nam|Số 10 Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh|10072025|EXTRA_DATA';
      final parsed1 = CccdParserHelper.parse(rawWithCmnd);

      expect(parsed1, isNotNull);
      expect(parsed1!.cccdNumber, '079090001234');
      expect(parsed1.oldIdNumber, '341371445');
      expect(parsed1.fullName, 'Phạm Văn Nam');
      expect(parsed1.formattedBirthDate, '15/08/1995');
      expect(parsed1.gender, 'Nam');
      expect(parsed1.address, contains('Lê Lợi'));
      expect(parsed1.formattedIssueDate, '10/07/2025');
      expect(parsed1.isBhyt, isFalse);

      // Trường hợp soCMND rỗng:
      const rawWithoutCmnd = '079090001234||Phạm Văn Nam|15081995|Nam|Số 10 Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh|10072025|EXTRA_DATA';
      final parsed2 = CccdParserHelper.parse(rawWithoutCmnd);

      expect(parsed2, isNotNull);
      expect(parsed2!.cccdNumber, '079090001234');
      expect(parsed2.oldIdNumber, '');
      expect(parsed2.fullName, 'Phạm Văn Nam');
      expect(parsed2.formattedBirthDate, '15/08/1995');
      expect(parsed2.gender, 'Nam');
      expect(parsed2.address, contains('Lê Lợi'));
      expect(parsed2.formattedIssueDate, '10/07/2025');
      expect(parsed2.isBhyt, isFalse);
    });

    test('Parse New Can Cuoc (TT 16/2024 - 8 fields with 2025/2026 issue)', () {
      const raw = '079090001234|NGUYỄN VĂN AN|Nam|15081990|Số 10 Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh|10072024|025812345||';
      final parsed = CccdParserHelper.parse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.cccdNumber, '079090001234');
      expect(parsed.fullName, 'NGUYỄN VĂN AN');
      expect(parsed.gender, 'Nam');
      expect(parsed.formattedBirthDate, '15/08/1990');
      expect(parsed.birthYear, '1990');
      expect(parsed.address, 'Số 10 Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh');
      expect(parsed.formattedIssueDate, '10/07/2024');
      expect(parsed.oldIdNumber, '025812345');
      expect(parsed.isBhyt, isFalse);

      // Verify address parsing works seamlessly on the extracted address
      final addressResult = AddressHelper.instance.parseCccdAddress(parsed.address);
      expect(addressResult.province?.name, 'Hồ Chí Minh');
      expect(addressResult.ward?.name, 'Sài Gòn');
    });

    test('Parse New Can Cuoc with DOB before Gender', () {
      const raw = '079090001234|LÊ THỊ HOA|12032000|Nữ|Xã Mỹ Khánh, Huyện Phong Điền, Thành phố Cần Thơ|15082025||';
      final parsed = CccdParserHelper.parse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.fullName, 'LÊ THỊ HOA');
      expect(parsed.gender, 'Nữ');
      expect(parsed.formattedBirthDate, '12/03/2000');
      expect(parsed.birthYear, '2000');
      expect(parsed.formattedIssueDate, '15/08/2025');
      expect(parsed.isBhyt, isFalse);

      final addressResult = AddressHelper.instance.parseCccdAddress(parsed.address);
      expect(addressResult.province?.name, 'Cần Thơ');
      expect(addressResult.ward?.name, 'An Bình');
    });

    test('Parse New Can Cuoc minimal (6 fields, no old CMND)', () {
      const raw = '079090001234|HOÀNG VĂN CƯỜNG|Nam|01011985|Phường Dịch Vọng Hậu, Quận Cầu Giấy, Hà Nội|02012026';
      final parsed = CccdParserHelper.parse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.fullName, 'HOÀNG VĂN CƯỜNG');
      expect(parsed.gender, 'Nam');
      expect(parsed.formattedBirthDate, '01/01/1985');
      expect(parsed.formattedIssueDate, '02/01/2026');
      expect(parsed.isBhyt, isFalse);
    });

    test('Parse Traditional BHYT (does not confuse with CCCD)', () {
      const raw = 'GD4797931835695|PHẠM VĂN NAM|15/08/1990|1|Số 10 Lê Lợi, Q1, TP HCM|01/01/2024|31/12/2024||25/12/2023';
      final parsed = CccdParserHelper.parse(raw);

      expect(parsed, isNotNull);
      expect(parsed!.isBhyt, isTrue);
      expect(parsed.cccdNumber, 'GD4797931835695');
      expect(parsed.fullName, 'PHẠM VĂN NAM');
      expect(parsed.gender, 'Nam');
      expect(parsed.birthDate, '15/08/1990');
    });
  });
}

