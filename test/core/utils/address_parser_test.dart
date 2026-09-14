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
}
