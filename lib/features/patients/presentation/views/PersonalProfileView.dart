import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/core/widgets/SearchablePickerModal.dart';
import 'package:benhvien7c/core/utils/AddressHelper.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';
import 'package:benhvien7c/features/patients/presentation/views/CccdScannerView.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';

class PersonalProfileView extends StatefulWidget {
  const PersonalProfileView({super.key});

  @override
  State<PersonalProfileView> createState() => _PersonalProfileViewState();
}

class _PersonalProfileViewState extends State<PersonalProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _phoneController = TextEditingController();
  final _identifierController = TextEditingController();
  final _cccdIssueDateController = TextEditingController();
  final _provinceController = TextEditingController();
  final _wardController = TextEditingController();

  String _gender = 'Nam';
  bool _isLoading = true;
  List<ProvinceModel> _provinces = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await AddressHelper.instance.init();
    _provinces = AddressHelper.instance.provinces;
    await _loadProfileData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    _identifierController.dispose();
    _cccdIssueDateController.dispose();
    _provinceController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final session = AppLocator.sessionStore.session;
    final username = session?.user.phoneNumber ?? 'default';

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('saved_my_personal_profile_$username');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final draft = PatientProfileDraftEntity.fromJson(jsonDecode(jsonStr));
        _fullNameController.text = draft.fullName.isNotEmpty ? draft.fullName : (session?.user.fullName ?? '');
        _dobController.text = draft.dateOfBirth ?? '';
        _birthYearController.text = draft.birthYear;
        _phoneController.text = draft.phoneNumber.isNotEmpty ? draft.phoneNumber : (session?.user.phoneNumber ?? '');
        _identifierController.text = draft.identifier;
        _cccdIssueDateController.text = draft.cccdIssueDate ?? '';
        _provinceController.text = draft.province ?? '';
        _wardController.text = draft.ward ?? '';

        if (draft.gender.isNotEmpty) {
          _gender = draft.gender;
        }
      } else if (session != null) {
        _fullNameController.text = session.user.fullName;
        _phoneController.text = session.user.phoneNumber;
        _dobController.text = '';
        _birthYearController.text = '';
        _identifierController.text = '';
        _provinceController.text = '';
        _wardController.text = '';
      }
    } catch (_) {
      if (session != null) {
        _fullNameController.text = session.user.fullName;
        _phoneController.text = session.user.phoneNumber;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (_dobController.text.contains('/')) {
      final parts = _dobController.text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initial = DateTime(y, m, d);
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _dobController.text = formatted;
        _birthYearController.text = picked.year.toString();
      });
    }
  }

  void _selectCccdIssueDate() async {
    final now = DateTime.now();
    DateTime initialDate = now;
    if (_cccdIssueDateController.text.contains('/')) {
      final parts = _cccdIssueDateController.text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initialDate = DateTime(y, m, d);
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1960),
      lastDate: now,
      locale: const Locale('vi', 'VN'),
      helpText: 'CHỌN NGÀY CẤP CCCD',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
    );

    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        _cccdIssueDateController.text = formatted;
      });
    }
  }

  void _selectProvince() async {
    final items = _provinces
        .map((p) => PickerItem<String>(
              title: p.name,
              subtitle: p.fullName,
              searchKey: p.searchKey,
              value: p.name,
            ))
        .toList();
    final selected = await SearchablePickerModal.show<String>(
      context: context,
      title: 'Chọn Tỉnh / Thành phố',
      items: items,
      selectedItem: _provinceController.text,
    );
    if (selected != null && selected != _provinceController.text) {
      setState(() {
        _provinceController.text = selected;
        _wardController.clear();
      });
    }
  }

  void _selectWard() async {
    final wards = AddressHelper.instance.getWardsForProvince(_provinceController.text);
    final items = wards
        .map((w) => PickerItem<String>(
              title: w.name,
              subtitle: w.fullName,
              searchKey: w.searchKey,
              value: w.name,
            ))
        .toList();
    final selected = await SearchablePickerModal.show<String>(
      context: context,
      title: 'Chọn Phường / Xã',
      items: items,
      selectedItem: _wardController.text,
    );
    if (selected != null) {
      setState(() {
        _wardController.text = selected;
      });
    }
  }

  Future<void> _startCccdScanning() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CccdScannerView(),
      ),
    );

    if (!mounted) return;

    if (result is CccdData) {
      final addressResult = AddressHelper.instance.parseCccdAddress(result.address);

      setState(() {
        _fullNameController.text = result.fullName;
        _identifierController.text = result.cccdNumber;
        _dobController.text = result.formattedBirthDate;
        _birthYearController.text = result.birthYear;
        _gender = result.gender == 'Nữ' ? 'Nữ' : 'Nam';
        if (result.formattedIssueDate.isNotEmpty) {
          _cccdIssueDateController.text = result.formattedIssueDate;
        }
        if (addressResult.province != null) {
          _provinceController.text = addressResult.province!.name;
          if (addressResult.ward != null) {
            _wardController.text = addressResult.ward!.name;
          } else {
            _wardController.clear();
          }
        }
      });

      ScaffoldMessenger.of(context).clearSnackBars();
      String message = 'Đã nhập thông tin ${result.isBhyt ? "BHYT" : "CCCD"} của ${result.fullName}.';
      Color bgColor = const Color(0xFF16A34A);

      if (addressResult.isExactMatch && addressResult.province != null && addressResult.ward != null) {
        message += '\nĐịa chỉ: ${addressResult.ward!.name}, ${addressResult.province!.name}';
      } else if (addressResult.province != null) {
        message += '\nĐã chọn: ${addressResult.province!.name}. Vui lòng chạm chọn Phường/Xã.';
        bgColor = const Color(0xFFD97706);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bgColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveProfileLocally() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final session = AppLocator.sessionStore.session;
    final username = session?.user.phoneNumber ?? 'default';

    // Infer birth year from DOB if needed
    String year = _birthYearController.text.trim();
    if (year.isEmpty && _dobController.text.contains('/')) {
      final parts = _dobController.text.split('/');
      if (parts.length == 3) year = parts[2];
    }

    final draft = PatientProfileDraftEntity(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      birthYear: year,
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      identifier: _identifierController.text.trim(),
      cccdIssueDate: _cccdIssueDateController.text.trim(),
      province: _provinceController.text.trim(),
      ward: _wardController.text.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_my_personal_profile_$username', jsonEncode(draft.toJson()));

      if (draft.fullName.isNotEmpty) {
        AppLocator.sessionStore.updateFullName(draft.fullName);
        await AppLocator.secureStorage.saveSavedFullName(draft.fullName);
        final cleanPhone = draft.phoneNumber.replaceAll(RegExp(r'\D'), '');
        if (cleanPhone.isNotEmpty) {
          await AppLocator.secureStorage.saveFullNameForPhone(cleanPhone, draft.fullName);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thông tin cá nhân! Dữ liệu sẽ tự động điền khi Đăng ký khám bệnh.'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lưu thông tin thất bại: $e')),
        );
      }
    }
  }

  void _confirmSoftDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text(
                'Xóa tài khoản khỏi App',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Thao tác này sẽ xóa toàn bộ dữ liệu cá nhân khai báo cục bộ trên thiết bị và đăng xuất khỏi ứng dụng.\n\nDữ liệu hồ sơ trên hệ thống máy chủ C# bệnh viện sẽ không bị ảnh hưởng.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy bỏ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final session = AppLocator.sessionStore.session;
                final username = session?.user.phoneNumber ?? 'default';

                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('saved_my_personal_profile_$username');
                } catch (_) {}

                await AppLocator.authRepository.logout();
                if (mounted) {
                  AppNavigator.resetToNamed(context, RouteNames.login);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xác nhận Xóa & Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppLocator.sessionStore.session;
    final roleLabel = session?.user.role.label ?? 'Khách hàng';
    final hisUser = session?.user.phoneNumber ?? 'Chưa xác định';

    return AppResponsiveContainer(
      maxWidth: double.infinity,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFF2563EB),
                        child: Icon(Icons.person_rounded, size: 32, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullNameController.text.isNotEmpty
                                  ? _fullNameController.text
                                  : 'Người dùng Bệnh viện 7C',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SĐT / HIS: $hisUser • $roleLabel',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Explanation Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Thông tin khai báo dưới đây được lưu an toàn trên máy của bạn và sẽ tự động nhập khi bạn thực hiện Đăng ký khám bệnh.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'KÊ KHAI THÔNG TIN CÁ NHÂN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _startCccdScanning,
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF0D6EFD)),
                            label: const Text('Quét CCCD / BHYT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Họ và tên
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Họ và tên'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateRequired(v, fieldName: 'Họ và tên'),
                      ),
                      const SizedBox(height: 14),

                      // Ngày sinh & Giới tính (Responsive: Chia đôi trên màn thường / Xếp dọc trên máy nhỏ < 380px)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 380;
                          final dobWidget = TextFormField(
                            controller: _dobController,
                            keyboardType: TextInputType.datetime,
                            decoration: InputDecoration(
                              label: _buildRequiredLabel('Ngày sinh'),
                              hintText: 'DD/MM/YYYY',
                              prefixIcon: const Icon(Icons.cake_outlined),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today_rounded, size: 18),
                                onPressed: _selectDateOfBirth,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (v) => Validators.validateFullDate(v, isRequired: true, fieldName: 'Ngày sinh'),
                          );

                          final genderWidget = Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildRequiredLabel('Giới tính'),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'Nam',
                                          groupValue: _gender,
                                          onChanged: (val) => setState(() => _gender = val!),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const Text('Nam', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<String>(
                                          value: 'Nữ',
                                          groupValue: _gender,
                                          onChanged: (val) => setState(() => _gender = val!),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const Text('Nữ', style: TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );

                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                dobWidget,
                                const SizedBox(height: 14),
                                genderWidget,
                              ],
                            );
                          } else {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: dobWidget),
                                const SizedBox(width: 10),
                                Expanded(flex: 4, child: genderWidget),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Tỉnh / Thành phố (Ô riêng dài)
                      TextFormField(
                        controller: _provinceController,
                        readOnly: true,
                        onTap: _selectProvince,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Tỉnh / Thành phố'),
                          hintText: 'Chọn Tỉnh / Thành phố',
                          prefixIcon: const Icon(Icons.location_city_rounded),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateRequired(v, fieldName: 'Tỉnh / Thành phố'),
                      ),
                      const SizedBox(height: 14),

                      // Phường / Xã (Ô riêng dài)
                      TextFormField(
                        controller: _wardController,
                        readOnly: true,
                        onTap: _selectWard,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Phường / Xã'),
                          hintText: 'Chọn Phường / Xã',
                          prefixIcon: const Icon(Icons.map_rounded),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateRequired(v, fieldName: 'Phường / Xã'),
                      ),
                      const SizedBox(height: 14),

                      // Số CCCD (Ô riêng dài)
                      TextFormField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          label: _buildRequiredLabel('Số CCCD'),
                          hintText: 'Nhập 12 số CCCD',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateCccdOrTempCode(v, isOptional: false),
                      ),
                      const SizedBox(height: 14),

                      // Ngày cấp CCCD (Ô riêng dài, Tùy chọn)
                      TextFormField(
                        controller: _cccdIssueDateController,
                        keyboardType: TextInputType.datetime,
                        decoration: InputDecoration(
                          labelText: 'Ngày cấp CCCD',
                          hintText: 'DD/MM/YYYY',
                          prefixIcon: const Icon(Icons.event_available_outlined),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today_rounded, size: 18),
                            onPressed: _selectCccdIssueDate,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateFullDate(v, isRequired: false, fieldName: 'Ngày cấp CCCD'),
                      ),
                      const SizedBox(height: 14),

                      // Số điện thoại (Optional)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại liên hệ (Tùy chọn)',
                          hintText: 'Mặc định theo số điện thoại tài khoản',
                          prefixIcon: const Icon(Icons.phone_android_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validatePhoneNumber(v, isOptional: true),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _saveProfileLocally,
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text(
                            'Lưu thông tin cá nhân',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                const Divider(),
                const SizedBox(height: 16),

                // Soft Delete Section
                const Text(
                  'QUẢN LÝ TÀI KHOẢN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.redAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _confirmSoftDeleteAccount,
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  label: const Text(
                    'Xóa tài khoản khỏi ứng dụng di động',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
    );
  }
}
