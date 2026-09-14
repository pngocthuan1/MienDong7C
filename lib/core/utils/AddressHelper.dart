import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:benhvien7c/core/utils/StringUtils.dart';

class WardModel {
  final String code;
  final String name;
  final String fullName;
  final String type;
  final String slug;
  final String searchKey;

  const WardModel({
    required this.code,
    required this.name,
    required this.fullName,
    required this.type,
    this.slug = '',
    required this.searchKey,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final fullName = json['fullName'] as String? ?? '';
    final slug = json['slug'] as String? ?? '';
    final searchKey = removeVietnameseDiacritics('$name $fullName').toLowerCase();
    return WardModel(
      code: json['code'] as String? ?? '',
      name: name,
      fullName: fullName,
      type: json['type'] as String? ?? 'ward',
      slug: slug,
      searchKey: searchKey,
    );
  }
}

class ProvinceModel {
  final String code;
  final String name;
  final String fullName;
  final String type;
  final String slug;
  final bool isCentral;
  final String searchKey;
  final List<WardModel> wards;

  const ProvinceModel({
    required this.code,
    required this.name,
    required this.fullName,
    required this.type,
    this.slug = '',
    required this.isCentral,
    required this.searchKey,
    required this.wards,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    final rawWards = json['wards'] as List<dynamic>? ?? [];
    final name = json['name'] as String? ?? '';
    final fullName = json['fullName'] as String? ?? '';
    final slug = json['slug'] as String? ?? '';
    final searchKey = removeVietnameseDiacritics('$name $fullName').toLowerCase();
    return ProvinceModel(
      code: json['code'] as String? ?? '',
      name: name,
      fullName: fullName,
      type: json['type'] as String? ?? 'city',
      slug: slug,
      isCentral: json['isCentral'] as bool? ?? false,
      searchKey: searchKey,
      wards: rawWards
          .map((e) => WardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParsedAddressResult {
  final ProvinceModel? province;
  final WardModel? ward;
  final bool isExactMatch;
  final bool isLegacyAddress;

  const ParsedAddressResult({
    this.province,
    this.ward,
    this.isExactMatch = false,
    this.isLegacyAddress = false,
  });
}

class AddressHelper {
  AddressHelper._();
  static final AddressHelper instance = AddressHelper._();

  static bool isIssuedBeforeJuly2024(String? issueDate) {
    if (issueDate == null || issueDate.trim().isEmpty) return false;
    final clean = issueDate.trim();
    int? month, year;
    if (clean.contains('/')) {
      final parts = clean.split('/');
      if (parts.length >= 3) {
        month = int.tryParse(parts[1]);
        year = int.tryParse(parts[2]);
      }
    } else if (clean.length == 8 && RegExp(r'^\d{8}$').hasMatch(clean)) {
      month = int.tryParse(clean.substring(2, 4));
      year = int.tryParse(clean.substring(4, 8));
    }
    if (year != null) {
      if (year < 2024) return true;
      if (year == 2024 && month != null && month < 7) return true;
    }
    return false;
  }

  List<ProvinceModel> _provinces = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<ProvinceModel> get provinces => List.unmodifiable(_provinces);

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      // Ưu tiên nạp bộ dữ liệu đầy đủ final_address_data.json
      String jsonStr;
      try {
        jsonStr = await rootBundle.loadString('lib/address/final_address_data.json');
      } catch (_) {
        jsonStr = await rootBundle.loadString('lib/address/vn_address_tree.json');
      }

      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        final rawTree = decoded['provinceTree'] as List<dynamic>? ?? [];
        _provinces = rawTree
            .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (decoded is List<dynamic>) {
        _provinces = decoded
            .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _isLoaded = true;
    } catch (_) {
      _provinces = [];
    }
  }

  List<WardModel> getWardsForProvince(String? provinceQuery) {
    if (provinceQuery == null || provinceQuery.trim().isEmpty) return [];
    final clean = provinceQuery.trim().toLowerCase();

    for (final p in _provinces) {
      if (p.name.toLowerCase() == clean ||
          p.fullName.toLowerCase() == clean ||
          p.code == clean ||
          clean.contains(p.name.toLowerCase()) ||
          p.name.toLowerCase().contains(clean)) {
        return p.wards;
      }
    }
    return [];
  }

  static String _cleanSlug(String text) {
    if (text.isEmpty) return '';
    final noDiacritics = removeVietnameseDiacritics(text).toLowerCase();
    return noDiacritics.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String _stripPrefix(String slug, List<String> prefixes) {
    for (final p in prefixes) {
      if (slug.startsWith(p) && slug.length > p.length) {
        return slug.substring(p.length);
      }
    }
    return slug;
  }

  /// Bóc tách thông minh chuỗi địa chỉ trên CCCD thành Tỉnh và Phường/Xã
  /// Nếu là CCCD cũ hoặc địa chỉ thuộc đơn vị hành chính cũ chưa sáp nhập:
  /// Để trống cả Tỉnh và Phường/Xã để người dùng tự chọn từ danh mục (isLegacyAddress = true, province = null, ward = null).
  /// Nếu là Căn cước mới và khớp trực tiếp với cây hành chính mới:
  /// Tự động điền Tỉnh và Phường/Xã (isLegacyAddress = false, province != null, ward != null).
  ParsedAddressResult parseCccdAddress(String rawAddress, {String? issueDate}) {
    if (rawAddress.trim().isEmpty) {
      return const ParsedAddressResult();
    }

    // 1. Kiểm tra ngày cấp thẻ: Nếu thẻ cấp trước 01/07/2024 -> Thẻ CCCD cũ chưa sáp nhập
    if (isIssuedBeforeJuly2024(issueDate)) {
      return const ParsedAddressResult(
        province: null,
        ward: null,
        isExactMatch: false,
        isLegacyAddress: true,
      );
    }

    final parts = rawAddress
        .split(RegExp(r'[,;-]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length < 2) {
      return const ParsedAddressResult();
    }

    // 2. Kiểm tra dấu hiệu đơn vị hành chính cấp quận/huyện cũ (3 cấp hành chính)
    final legacyDistKeywords = [
      'quan ', 'quận ', 'huyen ', 'huyện ', 'thi xa ', 'thị xã ', 'tx ', 'tx. ',
      'tp thu duc', 'thanh pho thu duc', 'thành phố thủ đức',
      'tp thuan an', 'thanh pho thuan an', 'thành phố thuận an',
      'tp di an', 'thanh pho di an', 'thành phố dĩ an',
      'tp bien hoa', 'thanh pho bien hoa', 'thành phố biên hòa',
    ];

    bool hasLegacyDist = false;
    for (final part in parts) {
      final lower = part.toLowerCase();
      for (final kw in legacyDistKeywords) {
        if (lower.startsWith(kw) || lower.contains(kw)) {
          hasLegacyDist = true;
          break;
        }
      }
      if (hasLegacyDist) break;
    }

    if (hasLegacyDist) {
      return const ParsedAddressResult(
        province: null,
        ward: null,
        isExactMatch: false,
        isLegacyAddress: true,
      );
    }

    // 3. Khớp trực tiếp với cây hành chính mới (34 tỉnh, 3.321 xã)
    ProvinceModel? targetProvince;
    final rawProv = parts.last;
    final provSlug = _cleanSlug(rawProv);

    for (final p in _provinces) {
      final pSlug = _cleanSlug(p.name);
      final pFullSlug = _cleanSlug(p.fullName);
      if (provSlug == pSlug ||
          provSlug == pFullSlug ||
          provSlug.contains(pSlug) ||
          pSlug.contains(provSlug)) {
        targetProvince = p;
        break;
      }
    }

    // Nếu không khớp trực tiếp tỉnh mới
    if (targetProvince == null) {
      return const ParsedAddressResult(
        province: null,
        ward: null,
        isExactMatch: false,
        isLegacyAddress: true,
      );
    }

    // Tìm xã chuẩn mới trong targetProvince.wards
    WardModel? targetWard;
    for (final part in parts) {
      final cSlug = _cleanSlug(part);
      final cleanC = _stripPrefix(cSlug, ['phuong', 'xa', 'thitran', 'tt']);
      for (final w in targetProvince.wards) {
        final wSlug = _cleanSlug(w.name);
        final wClean = _stripPrefix(wSlug, ['phuong', 'xa', 'thitran', 'tt']);
        if (wSlug == cSlug || wClean == cleanC || (cleanC.length >= 3 && wSlug == cleanC)) {
          targetWard = w;
          break;
        }
      }
      if (targetWard != null) break;
    }

    if (targetWard == null) {
      return const ParsedAddressResult(
        province: null,
        ward: null,
        isExactMatch: false,
        isLegacyAddress: true,
      );
    }

    return ParsedAddressResult(
      province: targetProvince,
      ward: targetWard,
      isExactMatch: true,
      isLegacyAddress: false,
    );
  }
}
