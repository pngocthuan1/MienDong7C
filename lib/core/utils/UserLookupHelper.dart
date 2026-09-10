import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/data/datasources/ThongBaoRemoteDataSource.dart';

class UserLookupHelper {
  static final Map<String, String> _userMap = {};
  static final Map<String, String> _groupMap = {};
  static bool _isLoaded = false;

  static Future<void> ensureLoaded() async {
    if (_isLoaded && _userMap.isNotEmpty) return;
    try {
      final ds = ThongBaoRemoteDataSource(AppLocator.dioClient);
      final master = await ds.fetchListMaster();
      populateFromMaster(master);
    } catch (_) {}
  }

  static void populateFromMaster(Map<String, dynamic> master) {
    final listNoiNhan = master['ListNoiNhan'] as List<dynamic>? ?? [];
    final listNhom = master['ListNhom'] as List<dynamic>? ?? [];

    for (final item in listNoiNhan) {
      if (item is! Map<String, dynamic>) continue;
      final uId = item['UserId']?.toString() ?? item['userId']?.toString() ?? item['Ma']?.toString() ?? '';
      final name = item['Ten']?.toString() ?? item['ten']?.toString() ?? item['HoTen']?.toString() ?? '';
      if (uId.isNotEmpty && name.isNotEmpty) {
        _userMap[uId.trim().toLowerCase()] = name.trim();
        final username = item['TenDangNhap']?.toString() ?? item['tenDangNhap']?.toString() ?? '';
        if (username.isNotEmpty) {
          _userMap[username.trim().toLowerCase()] = name.trim();
        }
      }
    }

    for (final item in listNhom) {
      if (item is! Map<String, dynamic>) continue;
      final gId = item['id']?.toString() ?? item['Id']?.toString() ?? '';
      final gName = item['ten']?.toString() ?? item['Ten']?.toString() ?? '';
      if (gId.isNotEmpty && gName.isNotEmpty) {
        _groupMap[gId.trim().toLowerCase()] = gName.trim();
        _groupMap['nhom_$gId'.toLowerCase()] = gName.trim();
      }
    }
    _isLoaded = true;
  }

  static String lookupName(String rawIdOrCode) {
    final clean = rawIdOrCode.replaceAll(';', '').trim();
    if (clean.isEmpty) return rawIdOrCode;

    final lower = clean.toLowerCase();

    if (_userMap.containsKey(lower)) {
      return _userMap[lower]!;
    }
    if (_groupMap.containsKey(lower)) {
      return _groupMap[lower]!;
    }

    if (lower == 'it_loc') return 'Lê Quốc Lộc';
    if (lower == 'hunglng') return 'Lê Nguyễn Gia Hưng';
    if (lower == 'thuanpn') return 'Phạm Ngọc Thuân';
    if (lower == 'trangbth') return 'Bùi Thị Huyền Trang';
    if (lower == '10') return 'Tổ BHYT';
    if (lower == '1' || lower == '2' || lower == 'khoa khám bệnh') return 'Hệ thống thông báo nội bộ';
    if (lower == '5') return 'Phòng CNTT';

    return clean;
  }
}
