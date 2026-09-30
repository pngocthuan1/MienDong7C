import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';
import 'package:benhvien7c/core/utils/AddressHelper.dart';
import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:benhvien7c/features/patients/domain/entities/DkkThongTinKhamModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';
import 'package:benhvien7c/core/widgets/SearchablePickerModal.dart';

class PatientProfileCreateViewModel extends BasePortalViewModel {
  PatientProfileCreateViewModel(
    super.repository,
    super.sessionStore,
  ) {
    fullNameController.text = session.user.fullName;
    phoneController.text = session.user.phoneNumber;
    birthYearController.text = '';
    continueCommand = Command0<MedicalTicketEntity>(_continueFlow);
    loadProfilesCommand = Command0<List<PatientProfileDraftEntity>>(_loadProfiles);
    searchByCccdCommand = Command1<DkkTimBenhNhanResponseDto?, String>(_searchByCccd);
    loadMasterCommand = Command0<DkkListMasterDto>(_loadMaster);
    loadMasterCommand.execute();
    _initAddressData();
    // Đọc thông tin cá nhân đã lưu NGAY LẬP TỨC (sync, không await) từ
    // SharedPreferences đã sẵn sàng trong AppLocator — điền vào form trước
    // frame đầu tiên, loại bỏ hoàn toàn delay ~1 giây
    _loadPersonalProfileSync();
    // Load danh sách hồ sơ đã lưu (async) và đồng bộ SharedPreferences → SecureStorage
    loadProfilesCommand.execute();
  }

  bool isExistingProfile = false;
  String? selectedProfileIdentifier;

  // ---------------------------------------------------------------------------
  // Luồng 1 — Tìm hồ sơ bệnh viện theo CCCD/HC
  // ---------------------------------------------------------------------------
  /// TextField riêng để nhập số tìm kiếm CCCD/HC (tách khỏi identifierController)
  final cccdSearchController = TextEditingController();

  /// Snapshot hồ sơ gốc từ server (bất biến trong phiên; mất thì gọi lại)
  DkkTimBenhNhanResponseDto? _hospitalSnapshot;
  DkkTimBenhNhanResponseDto? get hospitalSnapshot => _hospitalSnapshot;

  /// Đánh dấu form đến từ Luồng 1 (tìm theo CCCD — nguồn hệ thống)
  bool _isFromHospitalRecord = false;
  bool get isFromHospitalRecord => _isFromHospitalRecord;

  /// Form chỉ đọc (khi chọn từ danh sách đã lưu)
  bool _formIsReadOnly = false;
  bool get formIsReadOnly => _formIsReadOnly;

  /// MaBN tương ứng (dùng để gọi lại server nếu mất snapshot)
  String? _maBN;
  String? get maBN => _maBN;

  /// MaHS của hồ sơ được chọn từ ListHoSo
  String? _selectedMaHS;
  String? get selectedMaHS => _selectedMaHS;

  /// Cờ xác định hồ sơ có MaBN thật (8 số, không bắt đầu bằng T)
  bool _hasRealMaBN = false;
  bool get hasRealMaBN => _hasRealMaBN;

  /// Nguồn Thẻ 2 trong màn đối chiếu: true = hồ sơ đã lưu, false = nhập tay
  bool _compareSourceIsSavedProfile = false;

  late final Command1<DkkTimBenhNhanResponseDto?, String> searchByCccdCommand;



  final identifierController = TextEditingController();
  final cccdIssueDateController = TextEditingController();
  final patientCodeController = TextEditingController();
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final birthYearController = TextEditingController();
  final phoneController = TextEditingController();
  final symptomController = TextEditingController();
  final provinceController = TextEditingController();
  final wardController = TextEditingController();
  final clinicController = TextEditingController();

  // "Register for someone else" single text field
  final dangKyGiupController = TextEditingController();
  final otherFullNameController = TextEditingController();
  final otherDobController = TextEditingController();
  final otherBirthYearController = TextEditingController();
  final otherPhoneController = TextEditingController();
  final otherCccdIssueDateController = TextEditingController();
  final otherPatientCodeController = TextEditingController();
  String otherGender = 'Nam';
  String? selectedRelationship = 'Khác';
  final List<String> relationships = ['Con', 'Bố/Mẹ', 'Vợ/Chồng', 'Anh/Chị/Em', 'Khác'];

  List<ProvinceModel> provinces = [];
  String? selectedProvinceCode;

  String _gender = 'Nam';
  String get gender => _gender;

  late final Command0<MedicalTicketEntity> continueCommand;
  late final Command0<List<PatientProfileDraftEntity>> loadProfilesCommand;

  DkkListMasterDto? masterData;
  bool isLoadingMaster = false;
  String? masterError;
  late final Command0<DkkListMasterDto> loadMasterCommand;
  String? selectedClinicId;  // Lưu Id phòng khám từ server


  // Selected values
  String? selectedDepartment = 'Phòng khám 1 - Nội tổng quát';
  DateTime? selectedDate;
  String? selectedTime;
  bool saveProfile = false;
  bool _registerForSomeoneElse = false;
  bool get registerForSomeoneElse => _registerForSomeoneElse;
  set registerForSomeoneElse(bool val) {
    if (_registerForSomeoneElse == val) return;
    _registerForSomeoneElse = val;
    // Clear selection state when switching mode
    selectedProfileIdentifier = null;
    isExistingProfile = false;
    notifyListeners();
  }

  // Profiles list
  List<PatientProfileDraftEntity> savedProfiles = [];
  String? deleteConfirmIdentifier; // For 2-click soft delete

  Future<void> _initAddressData() async {
    await AddressHelper.instance.init();
    provinces = AddressHelper.instance.provinces;
    notifyListeners();
  }

  /// Đọc thông tin hồ sơ cá nhân đã lưu ĐỒNG BỘ (sync) từ SharedPreferences
  /// đã sẵn sàng trong AppLocator. Không cần await — gọi trong constructor để
  /// điền form trước frame đầu tiên, loại bỏ hoàn toàn delay ~1 giây.
  void _loadPersonalProfileSync() {
    try {
      final username = session.user.phoneNumber;
      if (username.isEmpty) return;
      final prefs = AppLocator.sharedPreferences;
      final jsonStr = prefs.getString('saved_my_personal_profile_$username');
      if (jsonStr == null || jsonStr.isEmpty) return;
      final draft = PatientProfileDraftEntity.fromJson(jsonDecode(jsonStr));
      if (draft.fullName.isNotEmpty) fullNameController.text = draft.fullName;
      if (draft.dateOfBirth != null && draft.dateOfBirth!.isNotEmpty) {
        dobController.text = DateTimeConverter.toVnDate(draft.dateOfBirth) ?? draft.dateOfBirth!;
      }
      if (draft.birthYear.isNotEmpty) birthYearController.text = draft.birthYear;
      if (draft.phoneNumber.isNotEmpty) phoneController.text = draft.phoneNumber;
      if (draft.identifier.isNotEmpty && draft.identifier != draft.maSo) {
        identifierController.text = draft.identifier;
      }
      if (draft.cccdIssueDate != null && draft.cccdIssueDate!.isNotEmpty) {
        cccdIssueDateController.text = DateTimeConverter.toVnDate(draft.cccdIssueDate) ?? draft.cccdIssueDate!;
      }
      if (draft.gender.isNotEmpty) _gender = draft.gender;
      if (draft.province != null) provinceController.text = draft.province!;
      if (draft.ward != null) wardController.text = draft.ward!;
      if (draft.clinic != null) clinicController.text = draft.clinic!;
      if (draft.identifier.isNotEmpty && draft.identifier != 'N/A') {
        identifierController.text = draft.identifier;
      }
      final savedMaSo = (draft.maSo != null && draft.maSo!.isNotEmpty && draft.maSo != 'N/A')
          ? draft.maSo!.trim()
          : null;
      final savedIdentifier = draft.identifier.trim();
      // Phân biệt rõ: Chỉ gán Mã bệnh nhân nếu khác với số CCCD/Hộ chiếu và không phải mã tạm 'T...'
      if (savedMaSo != null &&
          savedMaSo != savedIdentifier &&
          !savedMaSo.toUpperCase().startsWith('T')) {
        patientCodeController.text = savedMaSo;
        _maBN = savedMaSo;
        _hasRealMaBN = true;
      } else {
        patientCodeController.clear();
        _maBN = null;
        _hasRealMaBN = false;
      }
    } catch (_) {
      // Bỏ qua lỗi parse — _loadProfiles() async vẫn sẽ thử lại
    }
  }

  String? selectedProvinceName;
  String? selectedWardCode;
  String? selectedWardName;

  List<PickerItem<DkkTinhDto>> _cachedProvincePickerItems = [];
  List<PickerItem<DkkTinhDto>> get cachedProvincePickerItems => _cachedProvincePickerItems;
  final Map<String, List<PickerItem<DkkPhuongDto>>> _cachedWardPickerItems = {};

  /// Danh sách Tỉnh từ API server
  List<DkkTinhDto> get apiProvinces => masterData?.listTinh ?? [];

  /// Lấy danh sách `PickerItem<DkkPhuongDto>` đã cache và pre-compute search key
  List<PickerItem<DkkPhuongDto>> getCachedWardPickerItems() {
    final key = selectedProvinceCode ?? provinceController.text.trim();
    if (key.isEmpty) return [];
    if (_cachedWardPickerItems.containsKey(key)) {
      return _cachedWardPickerItems[key]!;
    }
    final rawWards = getWardsForSelectedProvince();
    final items = rawWards.map((w) {
      final item = PickerItem<DkkPhuongDto>(
        title: w.display,
        searchKey: w.display,
        value: w,
      );
      item.preComputeSearchKey();
      return item;
    }).toList();
    _cachedWardPickerItems[key] = items;
    return items;
  }

  /// Chọn Tỉnh từ API
  void selectProvinceFromApi(DkkTinhDto tinh) {
    selectedProvinceCode = tinh.id.toString();
    selectedProvinceName = tinh.display;
    provinceController.text = tinh.display;
    wardController.clear();
    selectedWardCode = null;
    selectedWardName = null;
    notifyListeners();
  }

  /// Lấy danh sách Phường/Xã theo Tỉnh đã chọn từ API (DicPhuong)
  List<DkkPhuongDto> getWardsForSelectedProvince() {
    final master = masterData;
    if (master == null) return [];

    // Tìm tỉnh tương ứng
    DkkTinhDto? tinh;
    if (selectedProvinceCode != null) {
      tinh = master.listTinh.where((t) => t.id.toString() == selectedProvinceCode).firstOrNull;
    }
    if (tinh == null && provinceController.text.isNotEmpty) {
      tinh = master.listTinh.where((t) => t.display.toLowerCase() == provinceController.text.toLowerCase().trim()).firstOrNull;
    }

    if (tinh != null) {
      // 1. Tìm theo ma_byt của tỉnh
      if (tinh.maByt.isNotEmpty && master.dicPhuong.containsKey(tinh.maByt)) {
        return master.dicPhuong[tinh.maByt]!;
      }
      // 2. Tìm theo id của tỉnh
      if (master.dicPhuong.containsKey(tinh.id.toString())) {
        return master.dicPhuong[tinh.id.toString()]!;
      }
      // 3. Tìm key khớp
      for (final entry in master.dicPhuong.entries) {
        if (entry.key.toLowerCase() == tinh.maByt.toLowerCase() ||
            entry.key.toLowerCase() == tinh.id.toString().toLowerCase()) {
          return entry.value;
        }
      }
    }

    final pName = provinceController.text.trim();
    if (pName.isNotEmpty && master.dicPhuong.containsKey(pName)) {
      return master.dicPhuong[pName]!;
    }
    return [];
  }

  /// Chọn Phường/Xã từ API
  void selectWardFromApi(DkkPhuongDto phuong) {
    selectedWardCode = phuong.id.toString();
    selectedWardName = phuong.display;
    wardController.text = phuong.display;
    notifyListeners();
  }

  void selectProvince(String name) {
    provinceController.text = name;
    selectedProvinceName = name;
    final master = masterData;
    if (master != null && master.listTinh.isNotEmpty) {
      final matched = master.listTinh.where(
        (t) => t.display.toLowerCase() == name.toLowerCase() ||
               name.toLowerCase().contains(t.display.toLowerCase()) ||
               t.display.toLowerCase().contains(name.toLowerCase()),
      ).firstOrNull;
      if (matched != null) {
        selectedProvinceCode = matched.id.toString();
        selectedProvinceName = matched.display;
        provinceController.text = matched.display;
      }
    }
    wardController.clear();
    selectedWardCode = null;
    selectedWardName = null;
    notifyListeners();
  }

  void selectWard(String name) {
    wardController.text = name;
    selectedWardName = name;
    final wards = getWardsForSelectedProvince();
    if (wards.isNotEmpty) {
      final matched = wards.where(
        (w) => w.display.toLowerCase() == name.toLowerCase() ||
               name.toLowerCase().contains(w.display.toLowerCase()) ||
               w.display.toLowerCase().contains(name.toLowerCase()),
      ).firstOrNull;
      if (matched != null) {
        selectedWardCode = matched.id.toString();
        selectedWardName = matched.display;
        wardController.text = matched.display;
      }
    }
    notifyListeners();
  }

  void selectClinic(String name) {
    clinicController.text = name;
    selectedDepartment = name;
    // Map sang clinicId từ masterData
    selectedClinicId = null;
    if (_serverPhongKhamList.isNotEmpty) {
      final matched = _serverPhongKhamList.where((p) => p.display == name);
      if (matched.isNotEmpty) selectedClinicId = matched.first.id;
    }
    notifyListeners();
  }

  List<DkkPhongKhamDto> _serverPhongKhamList = [];
  List<DkkPhongKhamDto> get serverPhongKhamList => _serverPhongKhamList;

  Future<Result<DkkListMasterDto>> _loadMaster() async {
    return runSafely(() async {
      isLoadingMaster = true;
      notifyIfMounted();
      final result = await portalRepository.fetchListMaster();
      result.when(
        ok: (data) {
          masterData = data;
          // Pre-compute và cache PickerItem cho Tỉnh một lần duy nhất
          _cachedProvincePickerItems = data.listTinh.map((p) {
            final item = PickerItem<DkkTinhDto>(
              title: p.display,
              searchKey: p.display,
              value: p,
            );
            item.preComputeSearchKey();
            return item;
          }).toList();
          _cachedWardPickerItems.clear();

          // Cập nhật departments từ server
          if (data.listPhongKham.isNotEmpty) {
            _serverPhongKhamList = data.listPhongKham;
          }
          masterError = null;
        },
        error: (_, message) {
          masterError = message;
        },
      );
      isLoadingMaster = false;
      return result;
    });
  }

  // Dropdowns lists
  /// Danh sách phòng khám: Ưu tiên dữ liệu từ server; fallback về hardcode nếu chưa load xong
  List<String> get departments {
    if (_serverPhongKhamList.isNotEmpty) {
      return _serverPhongKhamList.map((e) => e.display).toList();
    }
    // Fallback hardcode
    return [
      'Phòng khám 1 - Nội tổng quát',
      'Phòng khám 2 - Ngoại tổng quát',
      'Phòng khám 3 - Sản phụ khoa',
      'Phòng khám 4 - Nhi khoa',
      'Phòng khám 5 - Tai Mũi Họng',
      'Phòng khám 6 - Mắt',
      'Phòng khám 7 - Răng Hàm Mặt',
      'Phòng khám 8 - Da liễu',
    ];
  }

  /// Danh sách khung giờ khám: Ưu tiên dữ liệu từ server; fallback về hardcode
  List<String> get timeSlots {
    final master = masterData;
    if (master != null && master.listGioKham.isNotEmpty) {
      if (selectedDate != null) {
        // Lấy danh sách giờ theo ngày từ DicNgayGioKham
        final dateIso = _dateToIsoKey(selectedDate!);
        final slots = master.getSlotsForDate(dateIso);
        if (slots.isNotEmpty) return slots;
      }
      return master.listGioKham.map((e) => e.display).toList();
    }
    // Fallback hardcode
    return [
      '7g00 - 7g30', '7g30 - 8g00', '8g00 - 8g30', '8g30 - 9g00', '9g00 - 9g30',
      '9g30 - 10g00', '10g00 - 10g30', '10g30 - 11g00', '11g00 - 11g30',
      '13g00 - 13g30', '13g30 - 14g00', '14g00 - 14g30', '14g30 - 15g00', '15g00 - 15g30',
      '15g30 - 16g00', '16g00 - 16g30',
    ];
  }

  String _dateToIsoKey(DateTime date) {
    return '${date.year.toString().padLeft(4,'0')}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}T00:00:00';
  }

  bool get canContinue {
    final hasDate = selectedDate != null;
    final hasTime = selectedTime != null;
    if (!hasDate || !hasTime) return false;

    final hasIdentifier = identifierController.text.trim().isNotEmpty;
    final hasFullName = fullNameController.text.trim().isNotEmpty;
    final hasPhone = phoneController.text.trim().isNotEmpty;
    final hasBasicInfo = (hasIdentifier || hasFullName) && (hasPhone || hasIdentifier);
    if (!hasBasicInfo) return false;

    if (registerForSomeoneElse) {
      return dangKyGiupController.text.trim().isNotEmpty;
    }
    return true;
  }

  // Field validation error notifiers — tách nhỏ state để tránh rebuild toàn form khi gõ
  final fullNameErrorNotifier = ValueNotifier<String?>(null);
  final birthYearErrorNotifier = ValueNotifier<String?>(null);
  final phoneErrorNotifier = ValueNotifier<String?>(null);
  final otherFullNameErrorNotifier = ValueNotifier<String?>(null);
  final otherBirthYearErrorNotifier = ValueNotifier<String?>(null);
  final otherPhoneErrorNotifier = ValueNotifier<String?>(null);

  String? get fullNameError => fullNameErrorNotifier.value;
  set fullNameError(String? val) => fullNameErrorNotifier.value = val;

  String? get birthYearError => birthYearErrorNotifier.value;
  set birthYearError(String? val) => birthYearErrorNotifier.value = val;

  String? get phoneError => phoneErrorNotifier.value;
  set phoneError(String? val) => phoneErrorNotifier.value = val;

  String? get otherFullNameError => otherFullNameErrorNotifier.value;
  set otherFullNameError(String? val) => otherFullNameErrorNotifier.value = val;

  String? get otherBirthYearError => otherBirthYearErrorNotifier.value;
  set otherBirthYearError(String? val) => otherBirthYearErrorNotifier.value = val;

  String? get otherPhoneError => otherPhoneErrorNotifier.value;
  set otherPhoneError(String? val) => otherPhoneErrorNotifier.value = val;

  // 1. Full name validation logic
  String? checkFullName(String? value) {
    if (identifierController.text.trim().isNotEmpty) return null;
    return Validators.validateRequired(value, fieldName: 'Họ tên');
  }

  // 2. Full name error update
  void updateFullNameError(String? value) {
    final error = checkFullName(value);
    if (fullNameErrorNotifier.value != error) {
      fullNameErrorNotifier.value = error;
    }
  }

  // 1. Birth year validation logic
  String? checkBirthYear(String? value) {
    if (identifierController.text.trim().isNotEmpty) return null;
    return Validators.validateRequired(value, fieldName: 'Năm sinh');
  }

  // 2. Birth year error update
  void updateBirthYearError(String? value) {
    final error = checkBirthYear(value);
    if (birthYearErrorNotifier.value != error) {
      birthYearErrorNotifier.value = error;
    }
  }

  // 1. Phone validation logic
  String? checkPhone(String? value) {
    if (identifierController.text.trim().isNotEmpty && (value == null || value.trim().isEmpty)) {
      return null;
    }
    return Validators.validatePhoneNumber(value, isOptional: true);
  }

  // 2. Phone error update
  void updatePhoneError(String? value) {
    final error = checkPhone(value);
    if (phoneErrorNotifier.value != error) {
      phoneErrorNotifier.value = error;
    }
  }

  // 1. Other Full name validation logic
  String? checkOtherFullName(String? value) {
    if (!registerForSomeoneElse) return null;
    return Validators.validateRequired(value, fieldName: 'Họ tên người được giúp');
  }

  // 2. Other Full name error update
  void updateOtherFullNameError(String? value) {
    final error = checkOtherFullName(value);
    if (otherFullNameErrorNotifier.value != error) {
      otherFullNameErrorNotifier.value = error;
    }
  }

  // 1. Other Birth year validation logic
  String? checkOtherBirthYear(String? value) {
    if (!registerForSomeoneElse) return null;
    return Validators.validateRequired(value, fieldName: 'Năm sinh');
  }

  // 2. Other Birth year error update
  void updateOtherBirthYearError(String? value) {
    final error = checkOtherBirthYear(value);
    if (otherBirthYearErrorNotifier.value != error) {
      otherBirthYearErrorNotifier.value = error;
    }
  }

  // 1. Other Phone validation logic
  String? checkOtherPhone(String? value) {
    if (!registerForSomeoneElse) return null;
    return Validators.validatePhoneNumber(value, isOptional: true);
  }

  // 2. Other Phone error update
  void updateOtherPhoneError(String? value) {
    final error = checkOtherPhone(value);
    if (otherPhoneErrorNotifier.value != error) {
      otherPhoneErrorNotifier.value = error;
    }
  }

  void updateGender(String? value) {
    if (value == null || _gender == value) return;
    _gender = value;
    notifyListeners();
  }

  void updateDepartment(String? value) {
    if (value == null || selectedDepartment == value) return;
    selectedDepartment = value;
    clinicController.text = value;
    selectedClinicId = null;
    if (_serverPhongKhamList.isNotEmpty) {
      final matched = _serverPhongKhamList.where((p) => p.display == value);
      if (matched.isNotEmpty) selectedClinicId = matched.first.id;
    }
    notifyListeners();
  }

  void refreshFormState() {
    final text = identifierController.text.trim();
    if (text.contains('|') || text.contains(r'$')) {
      final parsed = CccdParserHelper.parse(text);
      if (parsed != null) {
        fillFromCccd(parsed);
        return;
      }
    }
    notifyListeners();
  }

  String _getProfileUniqueKey(PatientProfileDraftEntity profile) {
    if (profile.identifier.isNotEmpty && profile.identifier != 'N/A') {
      return profile.identifier.trim().toLowerCase();
    }
    return '${profile.fullName.trim().toLowerCase()}_${profile.birthYear.trim()}';
  }

  // Pre-fill fields from saved profile
  void selectProfile(PatientProfileDraftEntity profile) {
    final key = _getProfileUniqueKey(profile);
    if (selectedProfileIdentifier == key) {
      // Toggle off / Unselect
      clearProfileSelection();
      return;
    }

    selectedProfileIdentifier = key;
    isExistingProfile = true;

    // Hồ sơ đã lưu → form chỉ đọc
    _formIsReadOnly = true;
    _isFromHospitalRecord = false;

    // Lưu MaHS của hồ sơ được chọn từ ListHoSo
    _selectedMaHS = (profile.maSo != null && profile.maSo!.isNotEmpty && profile.maSo != 'N/A')
        ? profile.maSo!.trim()
        : null;

    // PHÂN BIỆT RÕ MÃ BỆNH NHÂN (MaBN) VÀ SỐ HỘ CHIẾU/CCCD:
    // - Trường "Số CCCD / Hộ Chiếu" (identifierController): chứa CCCD hoặc Hộ chiếu (kể cả Hộ chiếu 8 số/ký tự).
    // - Trường "Mã bệnh nhân" (patientCodeController): chứa MaBN do bệnh viện cấp.
    // - Tuyệt đối KHÔNG coi Hộ chiếu 8 số là Mã bệnh nhân!
    // - Chỉ coi là MaBN thật khi:
    //   1. Có mã từ profile.maBN hoặc _selectedMaHS
    //   2. Không bắt đầu bằng 'T' (mã tạm)
    //   3. KHÁC với số CCCD/Hộ chiếu (profile.identifier)
    final candidateMa = (profile.maBN != null && profile.maBN!.trim().isNotEmpty)
        ? profile.maBN!.trim()
        : (_selectedMaHS ?? '');
    final cccdOrPassport = (profile.identifier.isNotEmpty && profile.identifier != 'N/A')
        ? profile.identifier.trim()
        : '';

    final isReal = candidateMa.isNotEmpty &&
        !candidateMa.toUpperCase().startsWith('T') &&
        candidateMa != cccdOrPassport;
    _hasRealMaBN = isReal;
    _maBN = isReal ? candidateMa : null;
    _hospitalSnapshot = null; // Chưa có snapshot — sẽ fetch khi cần
    _compareSourceIsSavedProfile = true;

    // Gán mã bệnh nhân vào đúng controller ô Mã BN
    patientCodeController.text = _maBN ?? '';

    // Số CCCD / Hộ chiếu: Luôn gán đúng vào ô Số CCCD / Hộ Chiếu (trừ khi trùng với MaBN)
    final cccdVal = (profile.identifier.isNotEmpty && profile.identifier != 'N/A' && profile.identifier != _maBN)
        ? profile.identifier
        : ((profile.identifier.isNotEmpty && profile.identifier != 'N/A' && !isReal) ? profile.identifier : '');

    final formattedDob = (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty)
        ? (DateTimeConverter.toVnDate(profile.dateOfBirth) ?? profile.dateOfBirth!)
        : '';
    final formattedCccdDate = (profile.cccdIssueDate != null && profile.cccdIssueDate!.isNotEmpty)
        ? (DateTimeConverter.toVnDate(profile.cccdIssueDate) ?? profile.cccdIssueDate!)
        : '';

    if (registerForSomeoneElse) {
      otherFullNameController.text = profile.fullName;
      otherDobController.text = formattedDob;
      otherBirthYearController.text = profile.birthYear;
      otherGender = profile.gender;
      otherPhoneController.text = profile.phoneNumber;
      identifierController.text = cccdVal;
      cccdIssueDateController.text = formattedCccdDate;
      otherCccdIssueDateController.text = formattedCccdDate;
      otherPatientCodeController.text = _maBN ?? '';
      provinceController.text = profile.province ?? '';
      wardController.text = profile.ward ?? '';
      if (profile.clinic != null && profile.clinic!.isNotEmpty) {
        clinicController.text = profile.clinic!;
        selectedDepartment = profile.clinic;
      }

      otherFullNameError = null;
      otherBirthYearError = null;
      otherPhoneError = null;
    } else {
      identifierController.text = cccdVal;
      cccdIssueDateController.text = formattedCccdDate;
      fullNameController.text = profile.fullName;
      dobController.text = formattedDob;
      birthYearController.text = profile.birthYear;
      _gender = profile.gender;
      phoneController.text = profile.phoneNumber;
      provinceController.text = profile.province ?? '';
      wardController.text = profile.ward ?? '';
      if (profile.clinic != null && profile.clinic!.isNotEmpty) {
        clinicController.text = profile.clinic!;
        selectedDepartment = profile.clinic;
      }

      fullNameError = null;
      birthYearError = null;
      phoneError = null;
    }
    deleteConfirmIdentifier = null;
    notifyListeners();
  }



  void clearProfileSelection() {
    selectedProfileIdentifier = null;
    isExistingProfile = false;
    _formIsReadOnly = false;
    _isFromHospitalRecord = false;
    _maBN = null;
    _selectedMaHS = null;
    _hasRealMaBN = false;
    _hospitalSnapshot = null;
    _compareSourceIsSavedProfile = false;
    identifierController.clear();
    cccdIssueDateController.clear();
    patientCodeController.clear();
    fullNameController.text = session.user.fullName;
    dobController.clear();
    birthYearController.clear();
    _gender = 'Nam';
    phoneController.clear();
    provinceController.clear();
    wardController.clear();
    clinicController.clear();
    dangKyGiupController.clear();
    fullNameError = null;
    birthYearError = null;
    phoneError = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Luồng 1 — Tìm hồ sơ bệnh viện theo CCCD/HC
  // ---------------------------------------------------------------------------

  /// Gọi API tìm bệnh nhân theo số CCCD/HC.
  Future<Result<DkkTimBenhNhanResponseDto?>> _searchByCccd(String soCcHc) async {
    return runSafely(() async {
      final result = await portalRepository.timBenhNhanByCccdHc(soCcHc.trim());
      return result;
    });
  }

  /// Điền form từ hồ sơ gốc bệnh viện (Luồng 1 — Trường hợp A).
  /// Gọi khi người dùng bấm [Đồng ý] trong dialog xác nhận.
  void fillFromHospitalRecord(DkkTimBenhNhanResponseDto dto, {String? searchedNumber}) {
    _hospitalSnapshot = dto;
    _isFromHospitalRecord = true;
    _formIsReadOnly = false; // Được phép sửa sau khi đồng ý
    _maBN = dto.maBN;
    _compareSourceIsSavedProfile = false;
    isExistingProfile = false;
    selectedProfileIdentifier = null;

    // 1. Ô "Số CCCD/HC" (identifierController):
    // PHẢI giữ đúng số CCCD/Hộ chiếu người dùng tìm kiếm (hoặc số từ hệ thống).
    // TUYỆT ĐỐI KHÔNG ghi đè bằng Mã bệnh nhân (MaBN)!
    final queryCccd = (searchedNumber != null && searchedNumber.trim().isNotEmpty)
        ? searchedNumber.trim()
        : cccdSearchController.text.trim();
    if (queryCccd.isNotEmpty && queryCccd != dto.maBN) {
      identifierController.text = queryCccd;
    } else if (dto.soCcHc != null && dto.soCcHc!.isNotEmpty && dto.soCcHc != dto.maBN) {
      identifierController.text = dto.soCcHc!;
    } else if (dto.maBhytHoacMaBn.isNotEmpty && dto.maBhytHoacMaBn != dto.maBN) {
      identifierController.text = dto.maBhytHoacMaBn;
    } else if (queryCccd.isNotEmpty) {
      identifierController.text = queryCccd;
    }

    // 2. Ô "Mã bệnh nhân (Hệ thống tự cấp)" (patientCodeController):
    // PHẢI được điền đúng giá trị MaBN trả về từ server
    patientCodeController.text = dto.maBN;

    // 3. Họ tên
    fullNameController.text = dto.hoTen;

    // 4. Ngày sinh (chuẩn hóa dd/MM/yyyy)
    final vnDob = DateTimeConverter.toVnDate(dto.ngaySinh);
    if (vnDob != null) {
      dobController.text = vnDob;
      final parts = vnDob.split('/');
      if (parts.length == 3) {
        birthYearController.text = parts[2];
      }
    } else {
      dobController.clear();
      birthYearController.clear();
    }

    // 5. Giới tính
    final g = dto.gioiTinh?.trim().toLowerCase() ?? '';
    if (g == 'nữ' || g == 'nu' || g == '1' || g == 'female') {
      _gender = 'Nữ';
    } else {
      _gender = 'Nam';
    }

    // 6. Số điện thoại
    if (dto.soDienThoai != null && dto.soDienThoai!.isNotEmpty && dto.soDienThoai != 'null') {
      phoneController.text = dto.soDienThoai!;
    } else {
      phoneController.clear();
    }

    // 7. Ngày cấp (chuẩn hóa dd/MM/yyyy, không để null)
    final vnNgayCap = DateTimeConverter.toVnDate(dto.ngayCap);
    if (vnNgayCap != null) {
      cccdIssueDateController.text = vnNgayCap;
    } else {
      cccdIssueDateController.clear();
    }

    // 8. Tỉnh / Thành phố
    final tinhTen = (dto.tinhTpTen != null && dto.tinhTpTen!.isNotEmpty && dto.tinhTpTen != 'null')
        ? dto.tinhTpTen!
        : ((dto.tinhTp != null && dto.tinhTp!.isNotEmpty && dto.tinhTp != 'null')
            ? dto.tinhTp!
            : '');
    if (tinhTen.isNotEmpty) {
      selectProvince(tinhTen);
      if (dto.tinhTp != null && dto.tinhTp!.isNotEmpty && dto.tinhTp != 'null') {
        selectedProvinceCode = dto.tinhTp;
      }
    } else {
      provinceController.clear();
      selectedProvinceCode = null;
      selectedProvinceName = null;
    }

    // 9. Phường / Xã
    final phuongTen = (dto.phuongXaTen != null && dto.phuongXaTen!.isNotEmpty && dto.phuongXaTen != 'null')
        ? dto.phuongXaTen!
        : ((dto.phuongXa != null && dto.phuongXa!.isNotEmpty && dto.phuongXa != 'null')
            ? dto.phuongXa!
            : '');
    if (phuongTen.isNotEmpty) {
      selectWard(phuongTen);
      if (dto.phuongXa != null && dto.phuongXa!.isNotEmpty && dto.phuongXa != 'null') {
        selectedWardCode = dto.phuongXa;
      }
    } else {
      wardController.clear();
      selectedWardCode = null;
      selectedWardName = null;
    }

    fullNameError = null;
    birthYearError = null;
    phoneError = null;
    notifyListeners();
  }

  /// Luồng 1 Trường hợp B: không tìm thấy → mở form nhập tay đầy đủ.
  void enableManualEntry() {
    _isFromHospitalRecord = false;
    _formIsReadOnly = false;
    _maBN = null;
    _selectedMaHS = null;
    _hasRealMaBN = false;
    _hospitalSnapshot = null;
    _compareSourceIsSavedProfile = false;
    isExistingProfile = false;
    selectedProfileIdentifier = null;

    // Giữ lại số CCCD/HC người dùng vừa nhập tìm kiếm để nhập tay, nhưng xóa Mã BN
    final searchedNumber = cccdSearchController.text.trim();
    if (searchedNumber.isNotEmpty) {
      identifierController.text = searchedNumber;
    } else {
      identifierController.clear();
    }
    patientCodeController.clear();

    cccdIssueDateController.clear();
    fullNameController.text = session.user.fullName;
    dobController.clear();
    birthYearController.clear();
    phoneController.text = session.user.phoneNumber;
    provinceController.clear();
    wardController.clear();
    selectedProvinceCode = null;
    selectedProvinceName = null;
    selectedWardCode = null;
    selectedWardName = null;
    fullNameError = null;
    birthYearError = null;
    phoneError = null;
    notifyListeners();
  }

  /// true nếu cần kiểm tra so sánh với hệ thống trước khi đăng ký:
  /// Chỉ gọi khi bệnh nhân có MaBN thật (hồ sơ từ TimBenhNhan hoặc hồ sơ đã lưu có MaBN 8 số).
  /// Không gọi khi bệnh nhân mới (không có MaBN hoặc mã tạm T...).
  bool get needsComparisonCheck =>
      _isFromHospitalRecord || _hasRealMaBN;

  /// Tạo model đối chiếu cho Luồng 3.
  /// Sử dụng API KiemTraBenhNhan từ server để kiểm tra sai lệch.
  /// Trả về null nếu không cần so sánh hoặc không có khác biệt (server xác nhận hasDiff == false).
  Future<DkkThongTinKhamModel?> buildCompareModel() async {
    if (!needsComparisonCheck) return null;

    final req = _buildDangKyKhamRequestDto();
    DkkKiemTraBenhNhanResponseDto? serverDiff;

    try {
      final res = await portalRepository.kiemTraBenhNhan(req);
      res.when(
        ok: (dto) => serverDiff = dto,
        error: (err, msg) {},
      );
    } catch (_) {}

    // Nếu server kiểm tra và xác nhận không có bất kỳ sai lệch nào -> cho đăng ký thẳng!
    final diffResult = serverDiff;
    if (diffResult != null && !diffResult.hasDiff) {
      return null;
    }

    // Nếu có sai lệch (hoặc serverDiff lỗi tạm thời), lấy snapshot hệ thống để hiển thị màn đối chiếu
    var snapshot = _hospitalSnapshot;
    if (snapshot == null) {
      final queryKey = cccdSearchController.text.trim().isNotEmpty
          ? cccdSearchController.text.trim()
          : (identifierController.text.trim().isNotEmpty
              ? identifierController.text.trim()
              : (_maBN ?? ''));
      if (queryKey.isNotEmpty) {
        try {
          final result = await portalRepository.timBenhNhanByCccdHc(queryKey);
          result.when(
            ok: (dto) => snapshot = dto,
            error: (_, _) {},
          );
        } catch (_) {}
      }
    }

    final validSnapshot = snapshot;
    if (validSnapshot == null) return null;

    final draft = _buildCurrentDraft();
    final model = DkkThongTinKhamModel.fromServerCheck(
      system: validSnapshot,
      user: draft,
      isFromSavedProfile: _compareSourceIsSavedProfile,
      serverDiff: serverDiff,
    );

    return model.hasDiff ? model : null;
  }

  /// Xây dựng request DTO đăng ký khám chuẩn (17 trường) để gửi kiểm tra hoặc đăng ký
  DangKyKhamRequestDto _buildDangKyKhamRequestDto() {
    final String finalFullName = registerForSomeoneElse
        ? otherFullNameController.text.trim()
        : fullNameController.text.trim();
    final String finalDob = registerForSomeoneElse
        ? otherDobController.text.trim()
        : dobController.text.trim();
    final String finalGender = registerForSomeoneElse ? otherGender : _gender;
    final String finalPhone = registerForSomeoneElse
        ? otherPhoneController.text.trim()
        : phoneController.text.trim();
    final String finalCccdIssueDate = registerForSomeoneElse
        ? (otherCccdIssueDateController.text.trim().isNotEmpty
            ? otherCccdIssueDateController.text.trim()
            : cccdIssueDateController.text.trim())
        : cccdIssueDateController.text.trim();

    final selectedClinicName = clinicController.text.trim().isNotEmpty
        ? clinicController.text.trim()
        : selectedDepartment;

    final weekdayStr = selectedDate != null
        ? (selectedDate!.weekday == DateTime.monday
            ? 'Thứ 2'
            : selectedDate!.weekday == DateTime.tuesday
                ? 'Thứ 3'
                : selectedDate!.weekday == DateTime.wednesday
                    ? 'Thứ 4'
                    : selectedDate!.weekday == DateTime.thursday
                        ? 'Thứ 5'
                        : selectedDate!.weekday == DateTime.friday
                            ? 'Thứ 6'
                            : selectedDate!.weekday == DateTime.saturday
                                ? 'Thứ 7'
                                : 'Chủ nhật')
        : '';
    final dateStr = selectedDate != null
        ? '$weekdayStr, ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
        : '';

    final effectiveMaHS = _isFromHospitalRecord ? '' : (_selectedMaHS ?? '');
    final effectiveMaBN = _hasRealMaBN ? (_maBN ?? '') : (_isFromHospitalRecord ? (_maBN ?? '') : '');

    return DangKyKhamRequestDto(
      maHS: effectiveMaHS,
      maBN: effectiveMaBN,
      maBhytHoacMaBn: identifierController.text.trim().isNotEmpty
          ? identifierController.text.trim()
          : effectiveMaBN,
      hoTen: finalFullName.isNotEmpty ? finalFullName : session.user.fullName,
      gioiTinh: (finalGender.trim().toLowerCase() == 'nữ' || finalGender.trim().toLowerCase() == 'nu') ? 'Nữ' : 'Nam',
      ngaySinh: DateTimeConverter.toServerIsoString(finalDob),
      ngayCap: DateTimeConverter.toServerIsoString(finalCccdIssueDate),
      soDienThoai: finalPhone.isNotEmpty ? finalPhone : session.user.phoneNumber,
      ngayKham: dateStr,
      gioKham: selectedTime ?? '',
      phongKham: selectedClinicId ?? '',
      phongKhamTen: selectedClinicName ?? '',
      tinhTp: selectedProvinceCode ?? '',
      tinhTpTen: selectedProvinceName ?? provinceController.text.trim(),
      phuongXa: selectedWardCode ?? '',
      phuongXaTen: selectedWardName ?? wardController.text.trim(),
      trieuChung: symptomController.text.trim(),
      dangKyDum: registerForSomeoneElse ? dangKyGiupController.text.trim() : '',
    );
  }

  /// Build draft từ trạng thái form hiện tại
  PatientProfileDraftEntity _buildCurrentDraft() {
    final String inputName = registerForSomeoneElse
        ? otherFullNameController.text.trim()
        : fullNameController.text.trim();
    final String inputDob = registerForSomeoneElse
        ? otherDobController.text.trim()
        : dobController.text.trim();
    final String inputBirthYear = registerForSomeoneElse
        ? otherBirthYearController.text.trim()
        : birthYearController.text.trim();
    final String inputPhone = registerForSomeoneElse
        ? otherPhoneController.text.trim()
        : phoneController.text.trim();
    final String inputCccdIssueDate = registerForSomeoneElse
        ? (otherCccdIssueDateController.text.trim().isNotEmpty
            ? otherCccdIssueDateController.text.trim()
            : cccdIssueDateController.text.trim())
        : cccdIssueDateController.text.trim();
    final String currentGender = registerForSomeoneElse ? otherGender : _gender;

    String finalBirthYear = inputBirthYear;
    if (inputDob.contains('/')) {
      final parts = inputDob.split('/');
      if (parts.length == 3 && parts[2].length == 4) {
        finalBirthYear = parts[2];
      }
    }

    return PatientProfileDraftEntity(
      identifier: identifierController.text.trim(),
      fullName: inputName.isNotEmpty ? inputName : session.user.fullName,
      dateOfBirth: inputDob.isNotEmpty ? inputDob : null,
      birthYear: finalBirthYear,
      gender: currentGender,
      phoneNumber: inputPhone,
      province: provinceController.text.trim().isNotEmpty ? provinceController.text.trim() : null,
      ward: wardController.text.trim().isNotEmpty ? wardController.text.trim() : null,
      clinic: clinicController.text.trim().isNotEmpty ? clinicController.text.trim() : selectedDepartment,
      cccdIssueDate: inputCccdIssueDate.isNotEmpty ? inputCccdIssueDate : null,
      maSo: _hasRealMaBN ? _maBN : _selectedMaHS,
      maHS: _isFromHospitalRecord ? '' : _selectedMaHS,
      maBN: _hasRealMaBN ? _maBN : (_isFromHospitalRecord ? _maBN : null),
    );
  }

  /// Draft hiện tại dùng cho đối chiếu Luồng 3
  PatientProfileDraftEntity get currentDraftForBooking => _buildCurrentDraft();

  /// Chuỗi ngày khám định dạng gửi sang DkkCompareArgs
  String? get formattedSelectedDate {
    if (selectedDate == null) return null;
    final weekdayStr = selectedDate!.weekday == DateTime.monday
        ? 'Thứ 2'
        : selectedDate!.weekday == DateTime.tuesday
            ? 'Thứ 3'
            : selectedDate!.weekday == DateTime.wednesday
                ? 'Thứ 4'
                : selectedDate!.weekday == DateTime.thursday
                    ? 'Thứ 5'
                    : selectedDate!.weekday == DateTime.friday
                        ? 'Thứ 6'
                        : selectedDate!.weekday == DateTime.saturday
                            ? 'Thứ 7'
                            : 'Chủ nhật';
    return '$weekdayStr, ${DateFormat('dd/MM/yyyy').format(selectedDate!)}';
  }




  // Pre-fill fields from scanned CCCD QR code
  ParsedAddressResult fillFromCccd(CccdData data) {
    final parsedAddress = AddressHelper.instance.parseCccdAddress(
      data.address,
      issueDate: data.issueDate,
    );

    if (registerForSomeoneElse) {
      otherFullNameController.text = data.fullName;
      otherDobController.text = data.formattedBirthDate;
      otherBirthYearController.text = data.birthYear;
      otherGender = data.gender == 'Nữ' ? 'Nữ' : 'Nam';
      identifierController.text = data.cccdNumber;
      if (data.formattedIssueDate.isNotEmpty) {
        otherCccdIssueDateController.text = data.formattedIssueDate;
      }
      if (parsedAddress.province != null) {
        selectProvince(parsedAddress.province!.name);
        if (parsedAddress.ward != null) {
          selectWard(parsedAddress.ward!.name);
        }
      } else {
        // Địa chỉ cũ chưa sáp nhập -> Để trống cả hai trường Tỉnh và Phường/Xã để người dùng tự chọn
        provinceController.clear();
        wardController.clear();
        selectedProvinceCode = null;
      }
      
      updateOtherFullNameError(data.fullName);
      updateOtherBirthYearError(data.birthYear);
    } else {
      fullNameController.text = data.fullName;
      dobController.text = data.formattedBirthDate;
      birthYearController.text = data.birthYear;
      _gender = data.gender == 'Nữ' ? 'Nữ' : 'Nam';
      identifierController.text = data.cccdNumber;
      if (data.formattedIssueDate.isNotEmpty) {
        cccdIssueDateController.text = data.formattedIssueDate;
      }
      if (parsedAddress.province != null) {
        selectProvince(parsedAddress.province!.name);
        if (parsedAddress.ward != null) {
          selectWard(parsedAddress.ward!.name);
        }
      } else {
        // Địa chỉ cũ chưa sáp nhập -> Để trống cả hai trường Tỉnh và Phường/Xã để người dùng tự chọn
        provinceController.clear();
        wardController.clear();
        selectedProvinceCode = null;
      }
      
      updateFullNameError(data.fullName);
      updateBirthYearError(data.birthYear);
    }
    refreshFormState();
    notifyListeners();
    return parsedAddress;
  }

  MedicalTicketEntity? _initialTicket;

  // Pre-fill from existing ticket for rebooking
  void prefillFromTicket(MedicalTicketEntity ticket) {
    _initialTicket = ticket;

    // 1. Họ tên đầy đủ: LẤY ĐÚNG TỪ PHIẾU KHÁM GỐC, KHÔNG DÙNG TÊN RÚT GỌN CỦA TÀI KHOẢN
    final fullPatientName = ticket.patientName.trim();
    fullNameController.text = fullPatientName;
    otherFullNameController.text = fullPatientName;

    // 2. Chế độ đặt hộ / cho mình
    _registerForSomeoneElse = (ticket.dangKyGiup != null && ticket.dangKyGiup!.trim().isNotEmpty);
    dangKyGiupController.text = ticket.dangKyGiup ?? '';

    // 3. Form CHO PHÉP SỬA lại thông tin trước khi đăng ký
    isExistingProfile = false;
    _formIsReadOnly = false;
    selectedProfileIdentifier = null;
    _isFromHospitalRecord = true;
    _compareSourceIsSavedProfile = false;

    // 4. Mã bệnh nhân: Điền đúng vào ô "Mã bệnh nhân (Hệ thống tự cấp)"
    final maBNVal = (ticket.patientCode.trim().isNotEmpty && ticket.patientCode.trim() != 'N/A')
        ? ticket.patientCode.trim()
        : null;
    _maBN = maBNVal;
    patientCodeController.text = maBNVal ?? '';
    otherPatientCodeController.text = maBNVal ?? '';

    // 5. Số CCCD/Hộ chiếu: TUYỆT ĐỐI KHÔNG dùng Mã BN để điền vào ô này
    String cccdVal = (ticket.soCcHc != null && ticket.soCcHc!.trim().isNotEmpty && ticket.soCcHc != 'N/A' && ticket.soCcHc != maBNVal)
        ? ticket.soCcHc!.trim()
        : '';
    if (cccdVal.isEmpty && ticket.insuranceText.trim().isNotEmpty && ticket.insuranceText.trim() != 'Không có BHYT' && ticket.insuranceText.trim() != maBNVal) {
      final clean = ticket.insuranceText.replaceAll(RegExp(r'[^\w]'), '').trim();
      if ((clean.length == 12 || clean.length == 8) && clean != maBNVal) {
        cccdVal = clean;
      }
    }
    identifierController.text = cccdVal;

    // 6. Ngày cấp CCCD (định dạng dd/MM/yyyy)
    String vnNgayCap = DateTimeConverter.toVnDate(ticket.ngayCap) ?? '';
    cccdIssueDateController.text = vnNgayCap;
    otherCccdIssueDateController.text = vnNgayCap;

    // 7. Ngày sinh & Năm sinh (định dạng dd/MM/yyyy)
    String vnDob = DateTimeConverter.toVnDate(ticket.dateOfBirth) ?? '';
    String bYear = ticket.birthYear.trim();
    if (vnDob.isNotEmpty && vnDob.contains('/')) {
      final parts = vnDob.split('/');
      if (parts.length == 3 && parts[2].length == 4) {
        bYear = parts[2];
      }
    }
    dobController.text = vnDob;
    otherDobController.text = vnDob;
    birthYearController.text = bYear;
    otherBirthYearController.text = bYear;

    // 8. Giới tính
    final g = ticket.gender.trim().toLowerCase();
    _gender = (g == 'nữ' || g == 'nu' || g == '1' || g == 'female') ? 'Nữ' : 'Nam';
    otherGender = _gender;

    // 9. Số điện thoại
    final sdt = (ticket.phoneNumber != null && ticket.phoneNumber!.isNotEmpty && ticket.phoneNumber != 'null')
        ? ticket.phoneNumber!.trim()
        : '';
    phoneController.text = sdt;
    otherPhoneController.text = sdt;

    // 10. Tỉnh / Thành phố & Phường / Xã
    if (ticket.province != null && ticket.province!.trim().isNotEmpty) {
      selectProvince(ticket.province!.trim());
    }
    if (ticket.ward != null && ticket.ward!.trim().isNotEmpty) {
      selectWard(ticket.ward!.trim());
    }

    // 11. Phòng khám & Triệu chứng
    final clinicVal = (ticket.clinic != null && ticket.clinic!.trim().isNotEmpty)
        ? ticket.clinic!.trim()
        : (ticket.department ?? '');
    if (clinicVal.isNotEmpty) {
      selectClinic(clinicVal);
    }
    symptomController.text = ticket.symptom ?? '';

    // 12. Tạo ngay Snapshot gốc để phục vụ so sánh đối chiếu (Luồng 3) nếu người dùng sửa đổi
    _hospitalSnapshot = DkkTimBenhNhanResponseDto(
      maBN: maBNVal ?? '',
      maBhytHoacMaBn: cccdVal.isNotEmpty ? cccdVal : (maBNVal ?? ''),
      hoTen: fullPatientName,
      gioiTinh: _gender,
      ngaySinh: vnDob.isNotEmpty ? vnDob : null,
      ngayCap: vnNgayCap.isNotEmpty ? vnNgayCap : null,
      soCcHc: cccdVal.isNotEmpty ? cccdVal : null,
      soDienThoai: sdt.isNotEmpty ? sdt : null,
      tinhTpTen: provinceController.text.isNotEmpty ? provinceController.text : null,
      phuongXaTen: wardController.text.isNotEmpty ? wardController.text : null,
    );

    // 13. Bổ sung thông tin nếu phiếu gốc bị thiếu (tra từ savedProfiles hoặc API bệnh viện)
    _enrichTicketDataAsync(ticket, maBNVal, cccdVal);

    fullNameError = null;
    birthYearError = null;
    phoneError = null;
    notifyListeners();
  }

  Future<void> _enrichTicketDataAsync(MedicalTicketEntity ticket, String? maBN, String currentCccd) async {
    // A. Thử tìm trong savedProfiles nếu có sẵn
    if (savedProfiles.isNotEmpty) {
      _applyMatchedSavedProfile(maBN, ticket.patientName, currentCccd);
    }

    // B. Nếu vẫn thiếu CCCD, ngày cấp, ngày sinh hoặc địa chỉ: gọi API tra cứu bệnh nhân
    final needsApiLookup = identifierController.text.isEmpty ||
        cccdIssueDateController.text.isEmpty ||
        dobController.text.isEmpty ||
        provinceController.text.isEmpty;

    final searchKey = (maBN != null && maBN.isNotEmpty)
        ? maBN
        : (identifierController.text.isNotEmpty ? identifierController.text : currentCccd);

    if (needsApiLookup && searchKey.isNotEmpty) {
      try {
        final result = await portalRepository.timBenhNhanByCccdHc(searchKey);
        result.when(
          ok: (dto) {
            if (dto != null) {
              if (identifierController.text.isEmpty) {
                final sc = (dto.soCcHc != null && dto.soCcHc!.isNotEmpty && dto.soCcHc != dto.maBN)
                    ? dto.soCcHc!
                    : (dto.maBhytHoacMaBn.isNotEmpty && dto.maBhytHoacMaBn != dto.maBN ? dto.maBhytHoacMaBn : '');
                if (sc.isNotEmpty) identifierController.text = sc;
              }
              if (cccdIssueDateController.text.isEmpty) {
                final nc = DateTimeConverter.toVnDate(dto.ngayCap);
                if (nc != null) {
                  cccdIssueDateController.text = nc;
                  otherCccdIssueDateController.text = nc;
                }
              }
              if (dobController.text.isEmpty) {
                final ns = DateTimeConverter.toVnDate(dto.ngaySinh);
                if (ns != null) {
                  dobController.text = ns;
                  otherDobController.text = ns;
                  final p = ns.split('/');
                  if (p.length == 3 && p[2].length == 4) {
                    birthYearController.text = p[2];
                    otherBirthYearController.text = p[2];
                  }
                }
              }
              if (provinceController.text.isEmpty) {
                final t = (dto.tinhTpTen != null && dto.tinhTpTen!.isNotEmpty) ? dto.tinhTpTen! : (dto.tinhTp ?? '');
                if (t.isNotEmpty) selectProvince(t);
              }
              if (wardController.text.isEmpty) {
                final w = (dto.phuongXaTen != null && dto.phuongXaTen!.isNotEmpty) ? dto.phuongXaTen! : (dto.phuongXa ?? '');
                if (w.isNotEmpty) selectWard(w);
              }
              // Cập nhật snapshot chuẩn từ bệnh viện
              _hospitalSnapshot = dto;
              notifyListeners();
            }
          },
          error: (_, _) {},
        );
      } catch (_) {}
    }
  }

  void _applyMatchedSavedProfile(String? maBN, String patientName, String currentCccd) {
    PatientProfileDraftEntity? matched;
    for (final p in savedProfiles) {
      final pMaSo = (p.maSo ?? '').trim();
      final pId = p.identifier.trim();
      final pName = p.fullName.trim().toLowerCase();
      if ((maBN != null && maBN.isNotEmpty && (maBN == pMaSo || (maBN == pId && pMaSo.isEmpty))) ||
          (currentCccd.isNotEmpty && currentCccd == pId) ||
          (pName == patientName.trim().toLowerCase())) {
        matched = p;
        break;
      }
    }
    if (matched != null) {
      if (identifierController.text.isEmpty && matched.identifier.isNotEmpty && matched.identifier != matched.maSo && matched.identifier != 'N/A') {
        identifierController.text = matched.identifier;
      }
      if (cccdIssueDateController.text.isEmpty && matched.cccdIssueDate != null && matched.cccdIssueDate!.isNotEmpty) {
        final nc = DateTimeConverter.toVnDate(matched.cccdIssueDate);
        if (nc != null) {
          cccdIssueDateController.text = nc;
          otherCccdIssueDateController.text = nc;
        }
      }
      if (dobController.text.isEmpty && matched.dateOfBirth != null && matched.dateOfBirth!.isNotEmpty) {
        final ns = DateTimeConverter.toVnDate(matched.dateOfBirth);
        if (ns != null) {
          dobController.text = ns;
          otherDobController.text = ns;
          final p = ns.split('/');
          if (p.length == 3 && p[2].length == 4) {
            birthYearController.text = p[2];
            otherBirthYearController.text = p[2];
          }
        }
      }
      if (provinceController.text.isEmpty && matched.province != null && matched.province!.isNotEmpty) {
        selectProvince(matched.province!);
      }
      if (wardController.text.isEmpty && matched.ward != null && matched.ward!.isNotEmpty) {
        selectWard(matched.ward!);
      }
    }
  }

  // Load patient profiles from storage
  Future<Result<List<PatientProfileDraftEntity>>> _loadProfiles() async {
    return runSafely(() async {
      try {
        // Chỉ điền hồ sơ cá nhân mặc định nếu KHÔNG PHẢI đang ở luồng Đăng ký lại
        if (_initialTicket == null) {
          final username = session.user.phoneNumber;
          final prefs = await SharedPreferences.getInstance();
          final jsonStr = prefs.getString('saved_my_personal_profile_$username');
          if (jsonStr != null && jsonStr.isNotEmpty) {
            final draft = PatientProfileDraftEntity.fromJson(jsonDecode(jsonStr));
            if (draft.fullName.isNotEmpty) fullNameController.text = draft.fullName;
            if (draft.dateOfBirth != null && draft.dateOfBirth!.isNotEmpty) {
              dobController.text = DateTimeConverter.toVnDate(draft.dateOfBirth) ?? draft.dateOfBirth!;
            }
            if (draft.birthYear.isNotEmpty) birthYearController.text = draft.birthYear;
            if (draft.phoneNumber.isNotEmpty) phoneController.text = draft.phoneNumber;
            if (draft.identifier.isNotEmpty && draft.identifier != 'N/A') {
              identifierController.text = draft.identifier;
            }
            if (draft.cccdIssueDate != null && draft.cccdIssueDate!.isNotEmpty) {
              cccdIssueDateController.text = DateTimeConverter.toVnDate(draft.cccdIssueDate) ?? draft.cccdIssueDate!;
            }
            if (draft.gender.isNotEmpty) _gender = draft.gender;
            if (draft.province != null) provinceController.text = draft.province!;
            if (draft.ward != null) wardController.text = draft.ward!;
            if (draft.clinic != null) clinicController.text = draft.clinic!;
            final savedMaSo = (draft.maSo != null && draft.maSo!.isNotEmpty && draft.maSo != 'N/A')
                ? draft.maSo!.trim()
                : null;
            final savedIdentifier = draft.identifier.trim();
            // Phân biệt rõ: Chỉ gán Mã bệnh nhân nếu khác với số CCCD/Hộ chiếu và không phải mã tạm 'T...'
            if (savedMaSo != null &&
                savedMaSo != savedIdentifier &&
                !savedMaSo.toUpperCase().startsWith('T')) {
              patientCodeController.text = savedMaSo;
              _maBN = savedMaSo;
              _hasRealMaBN = true;
            } else {
              patientCodeController.clear();
              _maBN = null;
              _hasRealMaBN = false;
            }
          }
        }
      } catch (_) {}

      final result = await portalRepository.loadPatientProfiles();
      result.when(
        ok: (list) {
          savedProfiles = list;
          if (_initialTicket != null) {
            // Chỉ bổ sung các ô còn trống, KHÔNG ghi đè họ tên và KHÔNG khóa form!
            _applyMatchedSavedProfile(_maBN, _initialTicket!.patientName, identifierController.text);
          }
          notifyListeners();
        },
        error: (_, _) {},
      );
      return result;
    });
  }

  // Soft delete patient profile card (2 clicks)
  Future<void> requestDeleteProfile(PatientProfileDraftEntity profile) async {
    final key = profile.identifier.isNotEmpty ? profile.identifier : profile.fullName;
    if (deleteConfirmIdentifier == key) {
      await portalRepository.softDeletePatientProfile(profile);
      deleteConfirmIdentifier = null;
      loadProfilesCommand.execute();
    } else {
      deleteConfirmIdentifier = key;
      notifyListeners();
    }
  }

  // Holiday logic for 2026
  bool isHoliday2026(DateTime date) {
    // Tết Dương Lịch: 1/1
    if (date.month == 1 && date.day == 1) return true;
    
    // Tết Nguyên Đán 2026: 14/2 - 22/2 (9 ngày)
    if (date.year == 2026 && date.month == 2 && date.day >= 14 && date.day <= 22) return true;
    
    // Giỗ Tổ Hùng Vương 2026: 25/4 - 27/4 (Nghỉ bù)
    if (date.year == 2026 && date.month == 4 && date.day >= 25 && date.day <= 27) return true;
    
    // Giải phóng & Quốc tế lao động: 30/4 - 1/5
    if (date.month == 4 && date.day == 30) return true;
    if (date.month == 5 && date.day == 1) return true;
    
    // Quốc khánh 2026: 1/9 - 2/9
    if (date.month == 9 && (date.day == 1 || date.day == 2)) return true;
    
    return false;
  }

  // Generate selectable dates skipping Sundays and holidays
  List<DateTime> getAvailableDates() {
    final master = masterData;
    if (master != null && master.listNgayKham.isNotEmpty) {
      final List<DateTime> result = [];
      for (final ngayDto in master.listNgayKham) {
        final date = DateTime.tryParse(ngayDto.id);
        if (date != null) result.add(date);
      }
      if (result.isNotEmpty) return result;
    }
    // Fallback: tự generate dựa theo logic local
    final List<DateTime> list = [];
    DateTime current = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = current.add(Duration(days: i));
      if (date.weekday == DateTime.sunday) continue;
      if (isHoliday2026(date)) continue;
      if (i == 0) {
        final slots = getSlotsForDate(date);
        if (slots.isEmpty) continue;
      }
      list.add(date);
    }
    return list;
  }

  // Get selectable time slots
  List<String> getSlotsForDate(DateTime date) {
    final master = masterData;
    if (master != null) {
      final dateIso = _dateToIsoKey(date);
      final slots = master.getSlotsForDate(dateIso);
      if (slots.isNotEmpty) return slots;
    }
    // Fallback local
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target.isBefore(today)) return [];
    const fallbackSlots = [
      '7g00 - 7g30', '7g30 - 8g00', '8g00 - 8g30', '8g30 - 9g00', '9g00 - 9g30',
      '9g30 - 10g00', '10g00 - 10g30', '10g30 - 11g00', '11g00 - 11g30',
      '13g00 - 13g30', '13g30 - 14g00', '14g00 - 14g30', '14g30 - 15g00', '15g00 - 15g30',
      '15g30 - 16g00', '16g00 - 16g30',
    ];
    if (target.isAfter(today)) return fallbackSlots;
    return fallbackSlots.where((slot) {
      final startPart = slot.split('-')[0].trim().toLowerCase();
      int hr = 0, min = 0;
      if (startPart.contains('g')) {
        final parts = startPart.split('g');
        hr = int.parse(parts[0]);
        min = parts[1].isEmpty ? 0 : int.parse(parts[1]);
      }
      final slotStartTime = DateTime(now.year, now.month, now.day, hr, min);
      return !now.isAfter(slotStartTime.add(const Duration(minutes: 15)));
    }).toList();
  }

  // Double checks if the selected slot is still valid (has not passed)
  bool validateSelectedSlot() {
    if (selectedDate == null || selectedTime == null) return false;
    final now = DateTime.now();
    final dateParts = DateFormat('dd/MM/yyyy').format(selectedDate!).split('/');
    final ticketDay = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );
    final today = DateTime(now.year, now.month, now.day);
    
    if (ticketDay.isBefore(today)) return false;
    if (ticketDay.isAfter(today)) return true;
    
    // Today: check hour/minute
    final startPart = selectedTime!.split('-')[0].trim().toLowerCase();
    int hr = 0;
    int min = 0;
    if (startPart.contains('g')) {
      final parts = startPart.split('g');
      hr = int.parse(parts[0]);
      min = parts[1].isEmpty ? 0 : int.parse(parts[1]);
    }
    final slotTime = DateTime(now.year, now.month, now.day, hr, min);
    return slotTime.isAfter(now);
  }

  Future<Result<MedicalTicketEntity>> _continueFlow() async {
    // 1. Validate slot one last time to prevent time drift bookings
    if (!validateSelectedSlot()) {
      return Error(Exception('TimeExpired'), 'Khung giờ khám được chọn đã trôi qua. Vui lòng chọn khung giờ khác.');
    }

    if (registerForSomeoneElse && dangKyGiupController.text.trim().isEmpty) {
      return Error(Exception('ValidationError'), 'Vui lòng điền thông tin đăng ký giúp.');
    }

    return runSafely(() async {
      final String inputName = fullNameController.text.trim();
      final String inputDob = dobController.text.trim();
      final String inputBirthYear = birthYearController.text.trim();
      final String inputPhone = phoneController.text.trim();
      final String inputOtherName = otherFullNameController.text.trim();
      final String inputOtherDob = otherDobController.text.trim();
      final String inputOtherBirthYear = otherBirthYearController.text.trim();
      final String inputOtherPhone = otherPhoneController.text.trim();

      final String finalFullName = registerForSomeoneElse
          ? (inputOtherName.isNotEmpty ? inputOtherName : (inputName.isNotEmpty ? inputName : 'Người thân'))
          : (inputName.isNotEmpty ? inputName : session.user.fullName);

      final String finalDob = registerForSomeoneElse
          ? (inputOtherDob.isNotEmpty ? inputOtherDob : inputDob)
          : inputDob;

      String finalBirthYear = registerForSomeoneElse
          ? (inputOtherBirthYear.isNotEmpty ? inputOtherBirthYear : (inputBirthYear.isNotEmpty ? inputBirthYear : '2005'))
          : (inputBirthYear.isNotEmpty ? inputBirthYear : '2005');

      if (finalDob.contains('/')) {
        final parts = finalDob.split('/');
        if (parts.length == 3 && parts[2].length == 4) {
          finalBirthYear = parts[2];
        }
      }

      final String finalGender = registerForSomeoneElse
          ? (inputOtherName.isNotEmpty ? otherGender : _gender)
          : _gender;

      final String finalPhone = registerForSomeoneElse
          ? (inputOtherPhone.isNotEmpty ? inputOtherPhone : inputPhone)
          : inputPhone;

      final selectedClinicName = clinicController.text.trim().isNotEmpty
          ? clinicController.text.trim()
          : selectedDepartment;

      final draft = PatientProfileDraftEntity(
        identifier: identifierController.text.trim(),
        fullName: finalFullName,
        dateOfBirth: finalDob.isNotEmpty ? finalDob : null,
        birthYear: finalBirthYear,
        gender: finalGender,
        phoneNumber: finalPhone,
        province: provinceController.text.trim().isNotEmpty ? provinceController.text.trim() : null,
        ward: wardController.text.trim().isNotEmpty ? wardController.text.trim() : null,
        clinic: selectedClinicName,
        dangKyGiup: registerForSomeoneElse ? dangKyGiupController.text.trim() : null,
        cccdIssueDate: (registerForSomeoneElse && otherCccdIssueDateController.text.trim().isNotEmpty)
            ? otherCccdIssueDateController.text.trim()
            : (cccdIssueDateController.text.trim().isNotEmpty ? cccdIssueDateController.text.trim() : null),
        maSo: _hasRealMaBN ? _maBN : _selectedMaHS,
        maHS: _isFromHospitalRecord ? '' : _selectedMaHS,
        maBN: _hasRealMaBN ? _maBN : (_isFromHospitalRecord ? _maBN : null),
      );


      final weekdayStr = selectedDate!.weekday == DateTime.monday
          ? 'Thứ 2'
          : selectedDate!.weekday == DateTime.tuesday
              ? 'Thứ 3'
              : selectedDate!.weekday == DateTime.wednesday
                  ? 'Thứ 4'
                  : selectedDate!.weekday == DateTime.thursday
                      ? 'Thứ 5'
                      : selectedDate!.weekday == DateTime.friday
                          ? 'Thứ 6'
                          : selectedDate!.weekday == DateTime.saturday
                              ? 'Thứ 7'
                              : 'Chủ nhật';
      final dateStr = '$weekdayStr, ${DateFormat('dd/MM/yyyy').format(selectedDate!)}';
      final result = await portalRepository.createMedicalTicket(
        role,
        draft,
        department: selectedClinicName,
        departmentId: selectedClinicId,
        provinceCode: selectedProvinceCode,
        provinceName: selectedProvinceName ?? provinceController.text.trim(),
        wardCode: selectedWardCode,
        wardName: selectedWardName ?? wardController.text.trim(),
        selectedDate: dateStr,
        selectedTime: selectedTime,
        symptom: symptomController.text.trim(),
      );

      if (result is Ok<MedicalTicketEntity>) {
        final ticket = result.data.copyWith(
          dateOfBirth: finalDob,
          province: draft.province,
          ward: draft.ward,
          clinic: selectedClinicName,
        );
        return Ok(ticket);
      }

      result.when(
        ok: (_) {
          clearMessage();
        },
        error: (_, message) {
          setMessage(message);
        },
      );
      return result;
    });
  }

  @override
  void dispose() {
    dangKyGiupController.dispose();
    identifierController.dispose();
    fullNameController.dispose();
    dobController.dispose();
    birthYearController.dispose();
    phoneController.dispose();
    provinceController.dispose();
    wardController.dispose();
    clinicController.dispose();
    symptomController.dispose();
    otherFullNameController.dispose();
    otherDobController.dispose();
    otherBirthYearController.dispose();
    otherPhoneController.dispose();
    cccdSearchController.dispose();
    fullNameErrorNotifier.dispose();
    birthYearErrorNotifier.dispose();
    phoneErrorNotifier.dispose();
    otherFullNameErrorNotifier.dispose();
    otherBirthYearErrorNotifier.dispose();
    otherPhoneErrorNotifier.dispose();
    continueCommand.dispose();
    loadProfilesCommand.dispose();
    searchByCccdCommand.dispose();
    loadMasterCommand.dispose();
    super.dispose();
  }
}

