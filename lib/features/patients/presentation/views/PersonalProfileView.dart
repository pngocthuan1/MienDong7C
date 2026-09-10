import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';

class PersonalProfileView extends StatefulWidget {
  const PersonalProfileView({super.key});

  @override
  State<PersonalProfileView> createState() => _PersonalProfileViewState();
}

class _PersonalProfileViewState extends State<PersonalProfileView> {
  final _fullNameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _phoneController = TextEditingController();
  final _identifierController = TextEditingController();
  String _gender = 'Nam';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _birthYearController.dispose();
    _phoneController.dispose();
    _identifierController.dispose();
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
        _fullNameController.text = draft.fullName;
        _birthYearController.text = draft.birthYear;
        _phoneController.text = draft.phoneNumber;
        _identifierController.text = draft.identifier;
        if (draft.gender.isNotEmpty) {
          _gender = draft.gender;
        }
      } else if (session != null) {
        _fullNameController.text = session.user.fullName;
        _phoneController.text = session.user.phoneNumber;
        _birthYearController.text = '';
        _identifierController.text = '';
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

  Future<void> _saveProfileLocally() async {
    final session = AppLocator.sessionStore.session;
    final username = session?.user.phoneNumber ?? 'default';

    final draft = PatientProfileDraftEntity(
      fullName: _fullNameController.text.trim(),
      birthYear: _birthYearController.text.trim(),
      gender: _gender,
      phoneNumber: _phoneController.text.trim(),
      identifier: _identifierController.text.trim(),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_my_personal_profile_$username', jsonEncode(draft.toJson()));

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

  @override
  Widget build(BuildContext context) {
    final session = AppLocator.sessionStore.session;
    final roleLabel = session?.user.role.label ?? 'Khách hàng';
    final hisUser = session?.user.phoneNumber ?? 'Chưa xác định';

    return AppResponsiveContainer(
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
                const Text(
                  'KÊ KHAI THÔNG TIN CÁ NHÂN',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),

                // Họ và tên
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Họ và tên *',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Năm sinh & Giới tính Row
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _birthYearController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Năm sinh *',
                          hintText: 'Ví dụ: 1997',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Giới tính', style: TextStyle(fontSize: 11, color: Colors.grey)),
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Số điện thoại
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại liên hệ *',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Mã BHYT / CCCD
                TextField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    labelText: 'Mã thẻ BHYT / Số CCCD (nếu có)',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
