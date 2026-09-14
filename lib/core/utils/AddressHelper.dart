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

  const ParsedAddressResult({
    this.province,
    this.ward,
    this.isExactMatch = false,
  });
}

class AddressHelper {
  AddressHelper._();
  static final AddressHelper instance = AddressHelper._();

  List<ProvinceModel> _provinces = [];
  Map<String, dynamic> _oldProvinces = {};
  Map<String, dynamic> _oldToNewProvince = {};
  Map<String, dynamic> _oldToNewWardSimple = {};
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
        _oldProvinces = decoded['oldProvinces'] as Map<String, dynamic>? ?? {};
        _oldToNewProvince = decoded['oldToNewProvince'] as Map<String, dynamic>? ?? {};
        _oldToNewWardSimple = decoded['oldToNewWardSimple'] as Map<String, dynamic>? ?? {};
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
  ParsedAddressResult parseCccdAddress(String rawAddress) {
    if (rawAddress.trim().isEmpty) {
      return const ParsedAddressResult();
    }

    final parts = rawAddress
        .split(RegExp(r'[,;-]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length < 2) {
      return const ParsedAddressResult();
    }

    final rawProv = parts.last;
    final rawDist = parts.length >= 2 ? parts[parts.length - 2] : '';
    final rawWard = parts.length >= 3 ? parts[parts.length - 3] : '';

    // 1. Nhận diện Tỉnh cũ (old province)
    String? matchedOldProvKey;
    final provSlug = _cleanSlug(rawProv);

    for (final entry in _oldProvinces.entries) {
      final key = entry.key;
      final val = entry.value as Map<String, dynamic>? ?? {};
      final nameSlug = _cleanSlug(val['name'] as String? ?? '');
      final shortSlug = _cleanSlug(val['nameShort'] as String? ?? '');

      if (key == provSlug || nameSlug == provSlug || shortSlug == provSlug) {
        matchedOldProvKey = key;
        break;
      }

      final keywords = val['keywords'] as List<dynamic>? ?? [];
      for (final kw in keywords) {
        final kwSlug = _cleanSlug(kw.toString());
        if (kwSlug == provSlug || provSlug.contains(kwSlug) || kwSlug.contains(provSlug)) {
          matchedOldProvKey = key;
          break;
        }
      }
      if (matchedOldProvKey != null) break;
    }

    // Nếu đoạn cuối không khớp, quét tìm keyword tỉnh trong toàn bộ chuỗi
    if (matchedOldProvKey == null) {
      final fullSlug = _cleanSlug(rawAddress);
      for (final entry in _oldProvinces.entries) {
        final key = entry.key;
        final val = entry.value as Map<String, dynamic>? ?? {};
        final keywords = val['keywords'] as List<dynamic>? ?? [];
        for (final kw in keywords) {
          final kwSlug = _cleanSlug(kw.toString());
          if (kwSlug.length >= 4 && fullSlug.contains(kwSlug)) {
            matchedOldProvKey = key;
            break;
          }
        }
        if (matchedOldProvKey != null) break;
      }
    }

    // Xác định ProvinceModel chuẩn mới
    ProvinceModel? targetProvince;
    if (matchedOldProvKey != null) {
      final newProvNorm = _oldToNewProvince[matchedOldProvKey] as String? ?? '';
      for (final p in _provinces) {
        if (_cleanSlug(p.name) == newProvNorm ||
            _cleanSlug(p.slug) == newProvNorm ||
            _cleanSlug(p.fullName).contains(newProvNorm) ||
            newProvNorm.contains(_cleanSlug(p.name))) {
          targetProvince = p;
          break;
        }
      }
    }

    // 2. Nhận diện Phường/Xã bằng compound key trong oldToNewWardSimple
    Map<String, dynamic>? matchedWardInfo;
    if (matchedOldProvKey != null && rawDist.isNotEmpty && rawWard.isNotEmpty) {
      final distSlug = _cleanSlug(rawDist);
      final wardSlug = _cleanSlug(rawWard);

      final cleanDist = _stripPrefix(distSlug, ['quan', 'huyen', 'thanhpho', 'thixa', 'tx', 'tp']);
      final cleanWard = _stripPrefix(wardSlug, ['phuong', 'xa', 'thitran', 'tt']);

      final candidates = <String>[
        '${matchedOldProvKey}_${distSlug}_$wardSlug',
      ];

      for (final pd in ['quan', 'huyen', 'thanhpho', 'thixa', '']) {
        for (final pw in ['phuong', 'xa', 'thitran', '']) {
          candidates.add('${matchedOldProvKey}_$pd${cleanDist}_$pw$cleanWard');
        }
      }

      for (final cand in candidates) {
        if (_oldToNewWardSimple.containsKey(cand)) {
          matchedWardInfo = _oldToNewWardSimple[cand] as Map<String, dynamic>?;
          break;
        }
      }
    }

    // 3. Tìm WardModel trong targetProvince
    WardModel? matchedWard;
    if (matchedWardInfo != null) {
      final targetSlug = matchedWardInfo['wardSlug'] as String? ?? '';
      final targetFull = matchedWardInfo['wardFullName'] as String? ?? '';
      final targetWardNorm = matchedWardInfo['wardNorm'] as String? ?? '';
      final targetProvNorm = matchedWardInfo['provinceNorm'] as String? ?? '';

      if (targetProvince == null && targetProvNorm.isNotEmpty) {
        for (final p in _provinces) {
          if (_cleanSlug(p.name) == targetProvNorm || _cleanSlug(p.slug) == targetProvNorm) {
            targetProvince = p;
            break;
          }
        }
      }

      if (targetProvince != null) {
        for (final w in targetProvince.wards) {
          if (w.slug == targetSlug ||
              w.fullName == targetFull ||
              _cleanSlug(w.name) == targetWardNorm) {
            matchedWard = w;
            break;
          }
        }
      }
    }

    // 4. Fallback: Nếu compound key chưa ra, tìm kiếm đối chiếu trong targetProvince.wards
    if (targetProvince != null && matchedWard == null) {
      final candidateParts = [rawWard, rawDist];
      for (final cand in candidateParts) {
        if (cand.isEmpty) continue;
        final cSlug = _cleanSlug(cand);
        final cleanC = _stripPrefix(cSlug, ['phuong', 'xa', 'thitran', 'tt', 'quan', 'huyen']);
        for (final w in targetProvince.wards) {
          final wSlug = _cleanSlug(w.name);
          final wClean = _stripPrefix(wSlug, ['phuong', 'xa', 'thitran', 'tt']);
          if (wSlug == cSlug || wClean == cleanC || (cleanC.length >= 3 && wSlug.contains(cleanC))) {
            matchedWard = w;
            break;
          }
        }
        if (matchedWard != null) break;
      }
    }

    return ParsedAddressResult(
      province: targetProvince,
      ward: matchedWard,
      isExactMatch: targetProvince != null && matchedWard != null,
    );
  }
}
