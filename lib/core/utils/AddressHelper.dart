import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:benhvien7c/core/utils/StringUtils.dart';

class WardModel {
  final String code;
  final String name;
  final String fullName;
  final String type;
  final String searchKey;

  const WardModel({
    required this.code,
    required this.name,
    required this.fullName,
    required this.type,
    required this.searchKey,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final fullName = json['fullName'] as String? ?? '';
    final searchKey = removeVietnameseDiacritics('$name $fullName').toLowerCase();
    return WardModel(
      code: json['code'] as String? ?? '',
      name: name,
      fullName: fullName,
      type: json['type'] as String? ?? 'ward',
      searchKey: searchKey,
    );
  }
}

class ProvinceModel {
  final String code;
  final String name;
  final String fullName;
  final String type;
  final bool isCentral;
  final String searchKey;
  final List<WardModel> wards;

  const ProvinceModel({
    required this.code,
    required this.name,
    required this.fullName,
    required this.type,
    required this.isCentral,
    required this.searchKey,
    required this.wards,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    final rawWards = json['wards'] as List<dynamic>? ?? [];
    final name = json['name'] as String? ?? '';
    final fullName = json['fullName'] as String? ?? '';
    final searchKey = removeVietnameseDiacritics('$name $fullName').toLowerCase();
    return ProvinceModel(
      code: json['code'] as String? ?? '',
      name: name,
      fullName: fullName,
      type: json['type'] as String? ?? 'city',
      isCentral: json['isCentral'] as bool? ?? false,
      searchKey: searchKey,
      wards: rawWards
          .map((e) => WardModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AddressHelper {
  AddressHelper._();
  static final AddressHelper instance = AddressHelper._();

  List<ProvinceModel> _provinces = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<ProvinceModel> get provinces => List.unmodifiable(_provinces);

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonStr = await rootBundle.loadString('lib/address/vn_address_tree.json');
      final List<dynamic> decoded = jsonDecode(jsonStr);
      _provinces = decoded
          .map((e) => ProvinceModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
}
