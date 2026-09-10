import 'package:flutter/material.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/utils/UserLookupHelper.dart';
import 'package:benhvien7c/features/patients/data/datasources/ThongBaoRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationReadStatusEntity.dart';

class NotificationRecipientStatusView extends StatefulWidget {
  const NotificationRecipientStatusView({
    super.key,
    required this.item,
  });

  final NotificationItemEntity item;

  @override
  State<NotificationRecipientStatusView> createState() => _NotificationRecipientStatusViewState();
}

class _NotificationRecipientStatusViewState extends State<NotificationRecipientStatusView> {
  String _selectedFilter = 'all'; // 'all', 'read', 'unread'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _recipients = [];

  @override
  void initState() {
    super.initState();
    _loadRecipientStatus();
  }

  Future<void> _loadRecipientStatus() async {
    try {
      final dioClient = AppLocator.dioClient;
      final ds = ThongBaoRemoteDataSource(dioClient);
      final now = widget.item.createdAt;
      final mm = now.month.toString().padLeft(2, '0');
      final yy = (now.year % 100).toString().padLeft(2, '0');
      final dynamicSchema = 'hospi$mm$yy';

      final realStatuses = await ds.checkReadUser(widget.item.id, schema: dynamicSchema);
      final master = await ds.fetchListMaster();
      final listNoiNhan = master['ListNoiNhan'] as List<dynamic>? ?? [];

      final List<Map<String, dynamic>> recipientList = [
        {
          'name': widget.item.senderName,
          'dept': widget.item.senderDepartment,
          'role': 'Người gửi thông báo',
          'isRead': true,
          'readTime': 'Vừa xong',
        },
      ];

      final Map<String, NotificationReadStatusEntity> statusMap = {};
      for (final s in realStatuses) {
        statusMap[s.userId.trim().toLowerCase()] = s;
        statusMap[s.userName.trim().toLowerCase()] = s;
      }

      final targetNames = widget.item.recipientNames;
      final bool isSendToAll = targetNames == null ||
          targetNames.isEmpty ||
          targetNames.any((n) => n.toLowerCase().contains('tất cả') || n.toLowerCase().contains('all') || n == 'Toàn thể nhân viên');

      if (listNoiNhan.isNotEmpty) {
        for (final item in listNoiNhan) {
          if (item is! Map<String, dynamic>) continue;
          final uId = item['UserId']?.toString() ?? item['userId']?.toString() ?? item['Ma']?.toString() ?? '';
          final rawName = item['Ten']?.toString() ?? item['ten']?.toString() ?? item['HoTen']?.toString() ?? item['MaVaTen']?.toString() ?? '';
          final dept = item['KhoaPhong']?.toString() ?? item['khoaPhong']?.toString() ?? item['PhongBan']?.toString() ?? 'Bệnh viện';

          if (rawName.isEmpty) continue;
          if (rawName == widget.item.senderName) continue;

          bool isRecipient = isSendToAll;
          if (!isRecipient && targetNames != null) {
            isRecipient = targetNames.any((t) {
              final clean = t.replaceAll(';', '').trim().toLowerCase();
              return clean == uId.toLowerCase() || clean == rawName.toLowerCase() || rawName.toLowerCase().contains(clean);
            });
          }

          if (isRecipient) {
            final keyId = uId.trim().toLowerCase();
            final keyName = rawName.trim().toLowerCase();
            final statusObj = statusMap[keyId] ?? statusMap[keyName];

            final bool isRead = statusObj?.isRead ?? false;
            final timeStr = statusObj?.readAt != null
                ? '${statusObj!.readAt!.hour.toString().padLeft(2, '0')}:${statusObj.readAt!.minute.toString().padLeft(2, '0')} - ${statusObj.readAt!.day.toString().padLeft(2, '0')}/${statusObj.readAt!.month.toString().padLeft(2, '0')}'
                : null;

            recipientList.add({
              'name': rawName,
              'dept': dept,
              'role': isSendToAll ? 'Toàn thể nhân viên' : 'Người nhận được chọn',
              'isRead': isRead,
              'readTime': timeStr,
            });
          }
        }

        if (mounted && recipientList.length > 1) {
          setState(() {
            _recipients = recipientList;
            _isLoading = false;
          });
          return;
        }
      } else if (mounted && realStatuses.isNotEmpty) {
        for (final s in realStatuses) {
          if (s.userName != widget.item.senderName) {
            final timeStr = s.readAt != null
                ? '${s.readAt!.hour.toString().padLeft(2, '0')}:${s.readAt!.minute.toString().padLeft(2, '0')} - ${s.readAt!.day.toString().padLeft(2, '0')}/${s.readAt!.month.toString().padLeft(2, '0')}'
                : null;
            recipientList.add({
              'name': s.userName,
              'dept': s.userRole,
              'role': 'Thành viên',
              'isRead': s.isRead,
              'readTime': timeStr,
            });
          }
        }
        setState(() {
          _recipients = recipientList;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      final List<Map<String, dynamic>> fallbackRecipients = [
        {
          'name': widget.item.senderName,
          'dept': widget.item.senderDepartment,
          'role': 'Người gửi thông báo',
          'isRead': true,
          'readTime': 'Vừa xong',
        },
      ];

      final targetNames = widget.item.recipientNames;
      if (targetNames != null && targetNames.isNotEmpty) {
        for (final rawName in targetNames) {
          final cleanName = rawName.replaceAll(';', '').trim();
          final resolvedName = UserLookupHelper.lookupName(cleanName);
          if (resolvedName.isNotEmpty && resolvedName != widget.item.senderName) {
            fallbackRecipients.add({
              'name': resolvedName.toLowerCase().contains('bhyt') || resolvedName.toLowerCase().startsWith('tổ')
                  ? 'Thành viên thuộc $resolvedName'
                  : resolvedName,
              'dept': resolvedName,
              'role': 'Người nhận được chọn',
              'isRead': false,
              'readTime': null,
            });
          }
        }
      }

      setState(() {
        _recipients = fallbackRecipients;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRecipients {
    // Chỉ lấy danh sách những người ĐÃ XEM / ĐÃ ĐỌC (isRead == true)
    final readList = _recipients.where((r) => r['isRead'] == true).toList();
    if (_searchQuery.trim().isEmpty) return readList;

    final query = _searchQuery.toLowerCase().trim();
    return readList.where((r) {
      final name = (r['name'] as String).toLowerCase();
      final dept = (r['dept'] as String).toLowerCase();
      return name.contains(query) || dept.contains(query);
    }).toList();
  }

  int get _readCount => _recipients.where((r) => r['isRead'] == true).length;
  int get _unreadCount => _recipients.length - _readCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trạng Thái Người Xem',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              'Thông báo #${widget.item.number} • ${widget.item.senderDepartment}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFDBEAFE)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stat Summary Cards Header (Giữ nguyên Tổng người nhận, Đã đọc, Chưa đọc)
          Container(
            color: const Color(0xFF2563EB),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _buildStatBadge(
                  label: 'Tổng người nhận',
                  count: '${_recipients.length}',
                  bgColor: Colors.white.withValues(alpha: 0.15),
                  textColor: Colors.white,
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'Đã đọc',
                  count: '$_readCount',
                  bgColor: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF15803D),
                ),
                const SizedBox(width: 8),
                _buildStatBadge(
                  label: 'Chưa đọc',
                  count: '$_unreadCount',
                  bgColor: const Color(0xFFFEF3C7),
                  textColor: const Color(0xFFB45309),
                ),
              ],
            ),
          ),

          // Search bar & Read List Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Box
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người đã xem...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Label tiêu đề danh sách người đã xem
                Row(
                  children: [
                    const Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      'Danh Sách Người Đã Xem ($_readCount)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Recipient List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecipients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy người xem trùng khớp'
                              : 'Chưa có người dùng nào xem thông báo này',
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRecipients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final r = _filteredRecipients[index];
                      final isRead = r['isRead'] == true;
                      final name = r['name'] as String;
                      final department = r['dept'] as String;
                      final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isRead ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                              child: Text(
                                initials.isNotEmpty ? initials : 'NV',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isRead ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    department,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Read Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isRead ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isRead ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isRead ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                    size: 13,
                                    color: isRead ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isRead ? (r['readTime'] ?? 'Đã đọc') : 'Chưa đọc',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isRead ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                    ),
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

  Widget _buildStatBadge({
    required String label,
    required String count,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textColor),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.9)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
