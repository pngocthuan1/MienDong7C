import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

class PatientProfileCreateViewModel extends BasePortalViewModel {
  PatientProfileCreateViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore) {
    fullNameController.text = session.user.fullName;
    phoneController.text = session.user.phoneNumber;
    birthYearController.text = '';
    continueCommand = Command0<MedicalTicketEntity>(_continueFlow);
    loadProfilesCommand = Command0<List<PatientProfileDraftEntity>>(_loadProfiles);
    loadProfilesCommand.execute();
  }

  bool isExistingProfile = false;
  String? selectedProfileIdentifier;

  final identifierController = TextEditingController();
  final fullNameController = TextEditingController();
  final birthYearController = TextEditingController();
  final phoneController = TextEditingController();
  final symptomController = TextEditingController();

  // "Register for someone else" single text field
  final dangKyGiupController = TextEditingController();
  final otherFullNameController = TextEditingController();
  final otherBirthYearController = TextEditingController();
  final otherPhoneController = TextEditingController();
  String otherGender = 'Nam';
  String? selectedRelationship = 'Khác';
  final List<String> relationships = ['Con', 'Bố/Mẹ', 'Vợ/Chồng', 'Anh/Chị/Em', 'Khác'];

  String _gender = 'Nam';
  String get gender => _gender;

  late final Command0<MedicalTicketEntity> continueCommand;
  late final Command0<List<PatientProfileDraftEntity>> loadProfilesCommand;

  // Selected values
  String? selectedDepartment = 'Phòng khám 1 - Nội tổng quát';
  DateTime? selectedDate;
  String? selectedTime;
  bool saveProfile = true;
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

  // Dropdowns lists
  final List<String> departments = [
    'Phòng khám 1 - Nội tổng quát',
    'Phòng khám 2 - Ngoại tổng quát',
    'Phòng khám 3 - Sản phụ khoa',
    'Phòng khám 4 - Nhi khoa',
    'Phòng khám 5 - Tai Mũi Họng',
    'Phòng khám 6 - Mắt',
    'Phòng khám 7 - Răng Hàm Mặt',
    'Phòng khám 8 - Da liễu',
  ];

  static const List<String> timeSlots = [
    '7g00 - 7g30', '7g30 - 8g00', '8g00 - 8g30', '8g30 - 9g00', '9g00 - 9g30',
    '9g30 - 10g00', '10g00 - 10g30', '10g30 - 11g00', '11g00 - 11g30',
    '13g00 - 13g30', '13g30 - 14g00', '14g00 - 14g30', '14g30 - 15g00', '15g00 - 15g30',
    '15g30 - 16g00', '16g00 - 16g30'
  ];

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

  // Field validation error states
  String? fullNameError;
  String? birthYearError;
  String? phoneError;
  String? otherFullNameError;
  String? otherBirthYearError;
  String? otherPhoneError;

  // 1. Full name validation logic
  String? checkFullName(String? value) {
    if (identifierController.text.trim().isNotEmpty) return null;
    return Validators.validateRequired(value, fieldName: 'Họ tên');
  }

  // 2. Full name error update
  void updateFullNameError(String? value) {
    final error = checkFullName(value);
    if (fullNameError != error) {
      fullNameError = error;
      notifyListeners();
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
    if (birthYearError != error) {
      birthYearError = error;
      notifyListeners();
    }
  }

  // 1. Phone validation logic
  String? checkPhone(String? value) {
    if (identifierController.text.trim().isNotEmpty && (value == null || value.trim().isEmpty)) {
      return null;
    }
    return Validators.validatePhoneNumber(value);
  }

  // 2. Phone error update
  void updatePhoneError(String? value) {
    final error = checkPhone(value);
    if (phoneError != error) {
      phoneError = error;
      notifyListeners();
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
    if (otherFullNameError != error) {
      otherFullNameError = error;
      notifyListeners();
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
    if (otherBirthYearError != error) {
      otherBirthYearError = error;
      notifyListeners();
    }
  }

  // 1. Other Phone validation logic
  String? checkOtherPhone(String? value) {
    if (!registerForSomeoneElse) return null;
    return Validators.validatePhoneNumber(value);
  }

  // 2. Other Phone error update
  void updateOtherPhoneError(String? value) {
    final error = checkOtherPhone(value);
    if (otherPhoneError != error) {
      otherPhoneError = error;
      notifyListeners();
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

  // Pre-fill fields from saved profile
  void selectProfile(PatientProfileDraftEntity profile) {
    if (selectedProfileIdentifier == profile.identifier) {
      // Toggle off / Unselect
      selectedProfileIdentifier = null;
      isExistingProfile = false;
      
      if (registerForSomeoneElse) {
        otherFullNameController.clear();
        otherBirthYearController.clear();
        otherGender = 'Nam';
        otherPhoneController.clear();
        otherFullNameError = null;
        otherBirthYearError = null;
        otherPhoneError = null;
      } else {
        identifierController.clear();
        fullNameController.text = session.user.fullName;
        birthYearController.text = '1997';
        _gender = 'Nam';
        phoneController.clear();
        fullNameError = null;
        birthYearError = null;
        phoneError = null;
      }
    } else {
      selectedProfileIdentifier = profile.identifier;
      isExistingProfile = true;
      
      if (registerForSomeoneElse) {
        otherFullNameController.text = profile.fullName;
        otherBirthYearController.text = profile.birthYear;
        otherGender = profile.gender;
        otherPhoneController.text = profile.phoneNumber;
        identifierController.text = profile.identifier;
        
        otherFullNameError = null;
        otherBirthYearError = null;
        otherPhoneError = null;
      } else {
        identifierController.text = profile.identifier;
        fullNameController.text = profile.fullName;
        birthYearController.text = profile.birthYear;
        _gender = profile.gender;
        phoneController.text = profile.phoneNumber;
        
        fullNameError = null;
        birthYearError = null;
        phoneError = null;
      }
    }
    deleteConfirmIdentifier = null;
    notifyListeners();
  }

  void clearProfileSelection() {
    selectedProfileIdentifier = null;
    isExistingProfile = false;
    identifierController.clear();
    fullNameController.text = session.user.fullName;
    birthYearController.text = '1997';
    _gender = 'Nam';
    phoneController.clear();
    dangKyGiupController.clear();
    fullNameError = null;
    birthYearError = null;
    phoneError = null;
    notifyListeners();
  }

  // Pre-fill fields from scanned CCCD QR code
  void fillFromCccd(CccdData data) {
    if (registerForSomeoneElse) {
      otherFullNameController.text = data.fullName;
      otherBirthYearController.text = data.birthYear;
      otherGender = data.gender == 'Nữ' ? 'Nữ' : 'Nam';
      identifierController.text = data.cccdNumber;
      
      updateOtherFullNameError(data.fullName);
      updateOtherBirthYearError(data.birthYear);
    } else {
      fullNameController.text = data.fullName;
      birthYearController.text = data.birthYear;
      _gender = data.gender == 'Nữ' ? 'Nữ' : 'Nam';
      identifierController.text = data.cccdNumber;
      
      updateFullNameError(data.fullName);
      updateBirthYearError(data.birthYear);
    }
    notifyListeners();
  }

  MedicalTicketEntity? _initialTicket;

  // Pre-fill from existing ticket for rebooking
  void prefillFromTicket(MedicalTicketEntity ticket) {
    _initialTicket = ticket;

    // Check if name matches main user
    final isMainUser = ticket.patientName.trim().toUpperCase() == session.user.fullName.trim().toUpperCase();
    if (!isMainUser) {
      _registerForSomeoneElse = true;
      otherFullNameController.text = ticket.patientName;
      otherBirthYearController.text = ticket.birthYear;
      otherGender = ticket.gender;
      otherPhoneController.text = ticket.phoneNumber ?? '';
    } else {
      _registerForSomeoneElse = false;
      fullNameController.text = ticket.patientName;
      birthYearController.text = ticket.birthYear;
      _gender = ticket.gender;
      phoneController.text = ticket.phoneNumber ?? '';
    }

    // Set card / BHYT / patient code identifier
    final cardCode = (ticket.insuranceText.trim().isNotEmpty && ticket.insuranceText != 'Không có BHYT')
        ? ticket.insuranceText.trim()
        : ticket.patientCode.trim();
    if (cardCode.isNotEmpty && cardCode != 'N/A') {
      identifierController.text = cardCode;
    }

    final deptVal = ticket.department ?? '';
    selectedDepartment = departments.firstWhere(
      (d) => d == deptVal || (deptVal.isNotEmpty && (d.startsWith(deptVal) || deptVal.startsWith(d.split(' ').first))),
      orElse: () => departments.first,
    );
    symptomController.text = ticket.symptom ?? '';
    isExistingProfile = true;
    selectedProfileIdentifier = identifierController.text.isNotEmpty ? identifierController.text : ticket.patientCode;

    _tryAutoMatchProfileWithTicket(ticket);
    notifyListeners();
  }

  void _tryAutoMatchProfileWithTicket(MedicalTicketEntity ticket) {
    if (savedProfiles.isEmpty) return;

    final targetName = ticket.patientName.trim().toLowerCase();
    final targetYear = ticket.birthYear.trim();
    final targetCode = ticket.patientCode.trim();
    final targetInsurance = ticket.insuranceText.trim();

    PatientProfileDraftEntity? matched;
    for (final p in savedProfiles) {
      final pName = p.fullName.trim().toLowerCase();
      final pYear = p.birthYear.trim();
      final pId = p.identifier.trim();
      final pMaSo = (p.maSo ?? '').trim();

      if ((targetCode.isNotEmpty && (targetCode == pId || targetCode == pMaSo)) ||
          (targetInsurance.isNotEmpty && targetInsurance == pId) ||
          (pName == targetName && (pYear.isEmpty || targetYear.isEmpty || pYear == targetYear))) {
        matched = p;
        break;
      }
    }

    if (matched != null) {
      selectProfile(matched);
    }
  }

  // Load patient profiles from storage
  Future<Result<List<PatientProfileDraftEntity>>> _loadProfiles() async {
    return runSafely(() async {
      final result = await portalRepository.loadPatientProfiles();
      result.when(
        ok: (list) {
          savedProfiles = list;
          if (_initialTicket != null) {
            _tryAutoMatchProfileWithTicket(_initialTicket!);
          }
          notifyListeners();
        },
        error: (_, __) {},
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
    final List<DateTime> list = [];
    DateTime current = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = current.add(Duration(days: i));
      if (date.weekday == DateTime.sunday) continue;
      if (isHoliday2026(date)) continue;
      
      // If today, make sure there are remaining time slots
      if (i == 0) {
        final slots = getSlotsForDate(date);
        if (slots.isEmpty) continue; // Skip today since all slots passed
      }
      
      list.add(date);
    }
    return list;
  }

  // Get selectable time slots
  List<String> getSlotsForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    
    if (target.isBefore(today)) return [];
    if (target.isAfter(today)) return timeSlots;
    
    // Filter out passed slots for today
    return timeSlots.where((slot) {
      final startPart = slot.split('-')[0].trim().toLowerCase();
      int hr = 0;
      int min = 0;
      if (startPart.contains('g')) {
        final parts = startPart.split('g');
        hr = int.parse(parts[0]);
        min = parts[1].isEmpty ? 0 : int.parse(parts[1]);
      }
      final slotTime = DateTime(now.year, now.month, now.day, hr, min);
      return slotTime.isAfter(now);
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
      final draft = PatientProfileDraftEntity(
        identifier: identifierController.text.trim(),
        fullName: registerForSomeoneElse
            ? (otherFullNameController.text.trim().isEmpty ? 'Người thân' : otherFullNameController.text.trim())
            : (fullNameController.text.trim().isEmpty ? session.user.fullName : fullNameController.text.trim()),
        birthYear: registerForSomeoneElse
            ? (otherBirthYearController.text.trim().isEmpty ? '1997' : otherBirthYearController.text.trim())
            : (birthYearController.text.trim().isEmpty ? '1997' : birthYearController.text.trim()),
        gender: registerForSomeoneElse ? otherGender : _gender,
        phoneNumber: registerForSomeoneElse
            ? otherPhoneController.text.trim()
            : phoneController.text.trim(),
        dangKyGiup: registerForSomeoneElse ? dangKyGiupController.text.trim() : null,
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
        department: selectedDepartment,
        selectedDate: dateStr,
        selectedTime: selectedTime,
        symptom: symptomController.text.trim(),
      );

      if (result is Ok<MedicalTicketEntity>) {
        final ticket = result.data;
        if (saveProfile) {
          final profileToSave = PatientProfileDraftEntity(
            identifier: (ticket.patientCode.trim().isNotEmpty && ticket.patientCode != 'N/A')
                ? ticket.patientCode.trim()
                : (draft.identifier.trim().isNotEmpty ? draft.identifier.trim() : 'N/A'),
            fullName: ticket.patientName,
            birthYear: ticket.birthYear,
            gender: ticket.gender,
            phoneNumber: (ticket.phoneNumber != null && ticket.phoneNumber!.isNotEmpty)
                ? ticket.phoneNumber!
                : draft.phoneNumber,
          );
          await portalRepository.savePatientProfile(profileToSave);
        }
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
    birthYearController.dispose();
    phoneController.dispose();
    symptomController.dispose();
    otherFullNameController.dispose();
    otherBirthYearController.dispose();
    otherPhoneController.dispose();
    continueCommand.dispose();
    loadProfilesCommand.dispose();
    super.dispose();
  }
}
