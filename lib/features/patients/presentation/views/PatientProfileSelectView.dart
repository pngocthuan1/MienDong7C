import 'package:flutter/material.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';

class PatientProfileSelectView extends StatefulWidget {
  const PatientProfileSelectView({super.key});

  @override
  State<PatientProfileSelectView> createState() => _PatientProfileSelectViewState();
}

class _PatientProfileSelectViewState extends State<PatientProfileSelectView> {
  final _repository = AppLocator.portalRepository;
  List<PatientProfileDraftEntity> _profiles = [];
  List<PatientProfileDraftEntity> _filteredProfiles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final result = await _repository.loadPatientProfiles();
    result.when(
      ok: (list) {
        if (mounted) {
          setState(() {
            _profiles = list;
            _applySearch();
            _isLoading = false;
          });
        }
      },
      error: (_, __) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredProfiles = List.from(_profiles);
    } else {
      final q = _searchQuery.trim().toLowerCase();
      _filteredProfiles = _profiles.where((p) {
        return p.fullName.toLowerCase().contains(q) ||
            p.phoneNumber.contains(q) ||
            p.identifier.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _deleteProfile(PatientProfileDraftEntity profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hồ sơ'),
        content: Text('Bạn có chắc chắn muốn xóa hồ sơ "${profile.fullName}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repository.softDeletePatientProfile(profile.identifier);
      await _loadProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveContainer(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chọn hồ sơ đăng ký',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppNavigator.safePop(context),
        ),
      ),
      child: Column(
        children: [
          // Search Header
          Container(
            color: const Color(0xFF0D6EFD),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                  _applySearch();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm theo họ tên, SĐT, mã BN...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applySearch();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Profiles Count Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF1F5F9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HỒ SƠ ĐÃ LƯU (${_filteredProfiles.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF0D6EFD)),
                  label: const Text(
                    'Tạo hồ sơ mới',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Profile Cards List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProfiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Không tìm thấy hồ sơ phù hợp'
                                  : 'Chưa có hồ sơ nào được lưu',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProfiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final profile = _filteredProfiles[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Header Bar: Person icon + Name - BirthYear
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  color: const Color(0xFFF8FAFC),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person_rounded,
                                        color: Color(0xFF4F46E5),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${profile.fullName.toUpperCase()} - ${profile.birthYear}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Mã thẻ / CCCD / Mã BN
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '#',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Mã thẻ: ${(profile.identifier.isNotEmpty && profile.identifier != 'N/A') ? profile.identifier : '<Tự động cấp tạo mới>'}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4F46E5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Giới tính
                                      Row(
                                        children: [
                                          const Icon(Icons.smartphone_rounded, size: 18, color: Colors.black),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Giới tính: ${profile.gender}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF1E293B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),

                                      // SĐT
                                      Row(
                                        children: [
                                          const Icon(Icons.smartphone_rounded, size: 18, color: Colors.black),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SĐT: ${profile.phoneNumber}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF1E293B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Action Buttons: Chọn hồ sơ | Xóa hồ sơ
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(profile);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4F46E5),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: const Text(
                                              'Chọn hồ sơ',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          OutlinedButton(
                                            onPressed: () => _deleteProfile(profile),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFFEF4444),
                                              side: const BorderSide(color: Color(0xFFEF4444)),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            child: const Text(
                                              'Xóa hồ sơ',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
