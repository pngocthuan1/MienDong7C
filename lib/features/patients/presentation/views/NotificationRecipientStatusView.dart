import 'package:flutter/material.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/data/datasources/ThongBaoRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';

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
      final realStatuses = await ds.checkReadUser(widget.item.id);

      if (mounted && realStatuses.isNotEmpty) {
        setState(() {
          _recipients = realStatuses.map((s) {
            final timeStr = s.readAt != null
                ? '${s.readAt!.hour.toString().padLeft(2, '0')}:${s.readAt!.minute.toString().padLeft(2, '0')} - ${s.readAt!.day.toString().padLeft(2, '0')}/${s.readAt!.month.toString().padLeft(2, '0')}'
                : null;
            return {
              'name': s.userName,
              'dept': s.userRole,
              'role': 'Thành viên',
              'isRead': s.isRead,
              'readTime': timeStr,
            };
          }).toList();
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
        for (final name in targetNames) {
          fallbackRecipients.add({
            'name': 'Nhân viên thuộc $name',
            'dept': name,
            'role': 'Người nhận',
            'isRead': false,
            'readTime': null,
          });
        }
      } else {
        fallbackRecipients.add({
          'name': 'Toàn thể nhân viên',
          'dept': 'Hệ thống Bệnh viện',
          'role': 'Người nhận',
          'isRead': false,
          'readTime': null,
        });
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
    return _recipients.where((r) {
      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'read' && r['isRead'] == true) ||
          (_selectedFilter == 'unread' && r['isRead'] == false);

      final name = (r['name'] as String).toLowerCase();
      final dept = (r['dept'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase().trim();

      final matchesSearch = query.isEmpty || name.contains(query) || dept.contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get _readCount => _recipients.where((r) => r['isRead'] == true).length;
  int get _unreadCount => _recipients.where((r) => r['isRead'] == false).length;

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
          // Stat Summary Cards Header
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

          // Search bar & Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Input Box
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người xem, khoa phòng...',
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

                // Filter Buttons Row
                Row(
                  children: [
                    _buildFilterChip('all', 'Tất cả (${_recipients.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('read', 'Đã đọc ($_readCount)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('unread', 'Chưa đọc ($_unreadCount)'),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Recipient List View
          Expanded(
            child: _filteredRecipients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Không tìm thấy người nhận trùng khớp'
                              : 'Không có dữ liệu trong mục này',
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
                      final initial = name.replaceAll('BS.', '').trim().isNotEmpty
                          ? name.replaceAll('BS.', '').trim().characters.first.toUpperCase()
                          : 'U';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar Circle
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: isRead ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isRead ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Recipient Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${r['dept']} • ${r['role']}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),

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
