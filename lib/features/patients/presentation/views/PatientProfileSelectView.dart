import 'package:flutter/material.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/utils/StringUtils.dart';

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
  String? _errorMessage;
  bool _isNetworkError = false;
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isNetworkError = false;
    });
    final result = await _repository.loadPatientProfiles();
    result.when(
      ok: (list) {
        if (mounted) {
          setState(() {
            _profiles = list;
            _applySearch();
            _isLoading = false;
            _errorMessage = null;
            _isNetworkError = false;
          });
        }
      },
      error: (e, message) {
        if (mounted) {
          final isNet = message.toLowerCase().contains('mạng') ||
              message.toLowerCase().contains('kết nối') ||
              message.toLowerCase().contains('quá hạn') ||
              message.toLowerCase().contains('timeout');
          setState(() {
            _isLoading = false;
            _errorMessage = message;
            _isNetworkError = isNet;
          });
        }
      },
    );
  }

  void _applySearch() {
    if (_searchQuery.trim().isEmpty) {
      _filteredProfiles = List.from(_profiles);
    } else {
      final qRaw = _searchQuery.trim().toLowerCase();
      final qNoSign = removeVietnameseDiacritics(qRaw);
      _filteredProfiles = _profiles.where((p) {
        final nameNoSign = removeVietnameseDiacritics(p.fullName).toLowerCase();
        final idNoSign = removeVietnameseDiacritics(p.identifier).toLowerCase();
        final maBn = (p.maBN ?? p.maSo ?? '').toLowerCase();
        return nameNoSign.contains(qNoSign) ||
            p.phoneNumber.contains(qRaw) ||
            idNoSign.contains(qNoSign) ||
            maBn.contains(qRaw);
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
      final delRes = await _repository.softDeletePatientProfile(profile);
      if (!mounted) return;
      delRes.when(
        ok: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa hồ sơ: ${profile.fullName}'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          _loadProfiles();
        },
        error: (_, msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xóa hồ sơ thất bại: $msg'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveContainer(
      maxWidth: double.infinity,
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
                : _errorMessage != null
                    // TRẠNG THÁI LỖI (MẠNG HOẶC SERVER)
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                                size: 56,
                                color: _isNetworkError ? const Color(0xFFDC2626) : Colors.orange,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _isNetworkError
                                    ? 'Không có kết nối mạng'
                                    : 'Không thể tải danh sách hồ sơ',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: _loadProfiles,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Thử lại'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredProfiles.isEmpty
                        // TRẠNG THÁI RỖNG (EMPTY)
                        ? RefreshIndicator(
                            onRefresh: _loadProfiles,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: SizedBox(
                                height: 300,
                                child: Center(
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
                                ),
                              ),
                            ),
                          )
                    : RefreshIndicator(
                        onRefresh: _loadProfiles,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProfiles.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final profile = _filteredProfiles[index];

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
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
                                          color: Color(0xFF0D6EFD),
                                          size: 22,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${profile.fullName.toUpperCase()} - ${profile.birthYear}',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0D6EFD),
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
                                        // Mã BN / Mã thẻ & Số CC
                                        Builder(
                                          builder: (context) {
                                            final mb = (profile.maBN != null && profile.maBN!.isNotEmpty)
                                                ? profile.maBN!
                                                : ((profile.maSo != null && profile.maSo!.isNotEmpty && profile.maSo != 'N/A')
                                                    ? profile.maSo!
                                                    : '');
                                            final label = mb.isNotEmpty ? 'Mã BN' : 'Mã thẻ';
                                            final code = mb.isNotEmpty
                                                ? mb
                                                : ((profile.identifier.isNotEmpty && profile.identifier != 'N/A')
                                                    ? profile.identifier
                                                    : '<Chưa có mã BN>');
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      '#',
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF0D6EFD),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '$label: $code',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF0D6EFD),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (profile.identifier.isNotEmpty &&
                                                    profile.identifier != 'N/A' &&
                                                    profile.identifier != mb) ...[
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Số CC: ${profile.identifier}',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          color: Color(0xFF1E293B),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        // Giới tính
                                        Row(
                                          children: [
                                            const Icon(Icons.wc_rounded, size: 18, color: Color(0xFF0D6EFD)),
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
                                            const Icon(Icons.smartphone_rounded, size: 18, color: Colors.black87),
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
                                                backgroundColor: const Color(0xFF0D6EFD),
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
          ),
        ],
      ),
    );
  }
}