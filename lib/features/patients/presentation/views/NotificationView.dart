import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/NotificationViewModel.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/PortalDrawer.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/PortalEmptyState.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  late final NotificationViewModel _viewModel;

  bool _initializedFilter = false;

  @override
  void initState() {
    super.initState();
    _viewModel = NotificationViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    _viewModel.loadCommand.execute();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedFilter) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is NotificationFilter) {
        _viewModel.selectedFilter = args;
      }
      _initializedFilter = true;
    }
  }

  DateTime? _selectedDateFilter;

  Future<void> _selectDateFilter() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2F7DE1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateFilter) {
      setState(() {
        _selectedDateFilter = picked;
      });
    }
  }

  String _formatFilterDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _viewModel.loadCommand.execute();
  }

  Future<void> _openNotification(NotificationItemEntity item) async {
    // 1. Cập nhật ngay màu thẻ đã đọc trên giao diện
    setState(() {
      item.isRead = true;
    });

    // 2. Gửi API báo Server C# đã đọc (MarkStatus trangThai = 1)
    await _viewModel.openNotification(item.id);
    if (!mounted) return;

    // 2. Lấy đối tượng mới nhất đã được cập nhật từ ViewModel
    final currentItem = _viewModel.notificationById(item.id) ?? item;

    // 3. Mở màn hình chi tiết mới
    await Navigator.pushNamed(
      context,
      RouteNames.notificationDetail,
      arguments: currentItem,
    );

    // 4. Khi quay lại (xem xong), tự động pop để về Trang chủ
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppLocator.sessionStore.session;
    if (session == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          drawer: PortalDrawer(
            session: session,
            summary: _viewModel.summary,
            onDevTestingTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.devTesting);
            },
            onFilterTap: (filter) {
              _viewModel.setFilter(filter);
              AppNavigator.safePop(context); // Close drawer
            },
            onHomeTap: () {
              AppNavigator.safePop(context); // Đóng drawer
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteNames.home,
                (route) => false,
              );
            },
            onNotificationTap: () {
              AppNavigator.safePop(context); // Đóng drawer
            },
            onBookingTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.appointmentBooking);
            },
            onTypeFourDemoTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.typeFourDemo);
            },
            onUserManagementTap: session.isEmployee
                ? () {
                    AppNavigator.safePop(context);
                    AppNavigator.pushNamed(context, RouteNames.userManagement);
                  }
                : null,
            onChangePasswordTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.changePassword);
            },
            onDeleteAccountTap: () {
              AppNavigator.safePop(context);
              _showInfoDialog(
                'Xóa tài khoản',
                'Để yêu cầu xóa tài khoản, vui lòng liên hệ Ban quản trị hoặc Bộ phận hỗ trợ của Bệnh viện để được hướng dẫn chi tiết theo quy trình bảo mật.',
              );
            },
            onAboutTap: () {
              AppNavigator.safePop(context);
              _showInfoDialog(
                'Thông tin phần mềm',
                'Bệnh viện Quân Dân Y Miền Đông\nỨng dụng chăm sóc sức khỏe và đăng ký khám bệnh trực tuyến.',
              );
            },
            onLogoutTap: () {
              AppLocator.sessionStore.clear();
              AppNavigator.resetToNamed(context, RouteNames.login);
            },
          ),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2F7DE1), // Blue header matching screenshot
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _getFilterTitle(_viewModel.selectedFilter),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _selectedDateFilter == null
                      ? Icons.calendar_month_rounded
                      : Icons.event_available_rounded,
                  color: _selectedDateFilter == null ? Colors.white : Colors.amberAccent,
                ),
                tooltip: 'Lọc theo ngày',
                onPressed: _selectDateFilter,
              ),
              if (_selectedDateFilter != null) ...[
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.white),
                  tooltip: 'Xóa bộ lọc ngày',
                  onPressed: () {
                    setState(() {
                      _selectedDateFilter = null;
                    });
                  },
                ),
              ],
              if (session.isEmployee) ...[
                IconButton(
                  icon: const Icon(Icons.post_add_rounded, color: Colors.white),
                  tooltip: 'Đăng thông báo mới',
                  onPressed: () async {
                    final res = await Navigator.of(context).pushNamed(RouteNames.createNotification);
                    if (res == true && mounted) {
                      _viewModel.loadCommand.execute();
                    }
                  },
                ),
              ],
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, left: 8),
                  child: Text(
                    'MỚI: ${_viewModel.summary.unread}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: session.isEmployee
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final res = await Navigator.of(context).pushNamed(RouteNames.createNotification);
                    if (res == true && mounted) {
                      _viewModel.loadCommand.execute();
                    }
                  },
                  backgroundColor: const Color(0xFF2F7DE1),
                  icon: const Icon(Icons.post_add_rounded, color: Colors.white),
                  label: const Text(
                    'Đăng thông báo mới',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
          body: ListenableBuilder(
            listenable: _viewModel.loadCommand,
            builder: (context, _) {
              final listToDisplay = _viewModel.filteredItems;
              if (_viewModel.loadCommand.running && listToDisplay.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Lọc danh sách theo ngày được chọn
              final filteredList = _selectedDateFilter == null
                  ? listToDisplay
                  : listToDisplay.where((item) {
                      final itemDate = item.createdAt;
                      return itemDate.year == _selectedDateFilter!.year &&
                          itemDate.month == _selectedDateFilter!.month &&
                          itemDate.day == _selectedDateFilter!.day;
                    }).toList();

              // Widget Banner hiển thị trạng thái lọc ngày ở đầu body
              Widget activeFilterBanner = const SizedBox.shrink();
              if (_selectedDateFilter != null) {
                activeFilterBanner = Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7), // Màu vàng cam nhạt
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang lọc theo ngày: ${_formatFilterDate(_selectedDateFilter!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDateFilter = null;
                          });
                        },
                        child: const Text(
                          'Xóa bộ lọc',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (filteredList.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        activeFilterBanner,
                        PortalEmptyState(
                          title: _selectedDateFilter == null ? 'Chưa có thông báo' : 'Không tìm thấy thông báo',
                          message: _selectedDateFilter == null
                              ? (_viewModel.selectedFilter == NotificationFilter.all
                                  ? 'Hiện tại bạn không có thông báo nào mới.'
                                  : 'Không có thông báo nào phù hợp với bộ lọc này.')
                              : 'Không tìm thấy thông báo nào được đăng vào ngày ${_formatFilterDate(_selectedDateFilter!)}.',
                          icon: Icons.notifications_none_rounded,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group items by date string
              final Map<String, List<NotificationItemEntity>> grouped = {};
              for (final item in filteredList) {
                final dateStr = _formatDate(item.createdAt);
                grouped.putIfAbsent(dateStr, () => []).add(item);
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: grouped.length + (_selectedDateFilter != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_selectedDateFilter != null && index == 0) {
                      return activeFilterBanner;
                    }

                    final groupIndex = _selectedDateFilter != null ? index - 1 : index;
                    final dateStr = grouped.keys.elementAt(groupIndex);
                    final dayItems = grouped[dateStr]!;
                    final unreadCount = dayItems.where((e) => !e.isRead).length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DateHeaderBar(
                          dateStr: dateStr,
                          unreadCount: unreadCount,
                          totalCount: dayItems.length,
                        ),
                        ...List.generate(dayItems.length, (itemIndex) {
                          final item = dayItems[itemIndex];
                          return Column(
                            children: [
                              _NotificationItemRow(
                                item: item,
                                onTap: () => _openNotification(item),
                              ),
                              if (itemIndex < dayItems.length - 1)
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFEEEEEE),
                                ),
                            ],
                          );
                        }),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getFilterTitle(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return 'Thông báo';
      case NotificationFilter.unread:
        return 'Thông báo - Chưa đọc';
      case NotificationFilter.read:
        return 'Thông báo - Đã đọc';
      case NotificationFilter.important:
        return 'Thông báo - Quan trọng';
      case NotificationFilter.veryImportant:
        return 'Thông báo - Rất quan trọng';
    }
  }
}

String _formatDate(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  return '$day/$month/$year';
}

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute:$second';
}

class _DateHeaderBar extends StatelessWidget {
  const _DateHeaderBar({
    required this.dateStr,
    required this.unreadCount,
    required this.totalCount,
  });

  final String dateStr;
  final int unreadCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3A78D0), // Blue header bar
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(
            'Ngày: $dateStr',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (unreadCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF90EE90), // Green bg
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Mới: $unreadCount',
                style: const TextStyle(
                  color: Color(0xFF1E5A1E), // Green text
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            ' | Tổng: $totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }
}

bool _isSameUser(String? nameA, String? nameB) {
  if (nameA == null || nameB == null) return false;
  String clean(String name) {
    return name
        .toLowerCase()
        .replaceAll('bs.', '')
        .replaceAll('bs', '')
        .replaceAll('bác sĩ', '')
        .replaceAll('bác si', '')
        .replaceAll('y tá', '')
        .replaceAll('yt', '')
        .replaceAll('khách hàng', '')
        .replaceAll('kh', '')
        .replaceAll('(demo)', '')
        .replaceAll('(khách)', '')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
  }
  final a = clean(nameA);
  final b = clean(nameB);
  return a == b || a.contains(b) || b.contains(a);
}

class _NotificationItemRow extends StatelessWidget {
  const _NotificationItemRow({
    required this.item,
    required this.onTap,
  });

  final NotificationItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currentUserName = AppSessionStore.instance.currentUser?.fullName;
    final isCreatedByMe = _isSameUser(item.senderName, currentUserName);
    final titleColor = isCreatedByMe
        ? const Color(0xFFEC4899) // Hồng nhạt cho thông báo chính mình đăng
        : (item.isRead ? Colors.black : const Color(0xFF4CAF50)); // Mặc định: xanh lá cho chưa đọc, đen cho đã đọc
    final timeStr = _formatDateTime(item.createdAt);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title: Số X | Tên người gửi
            Text(
              'Số ${item.number} | ${item.senderName}',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle: Nơi gửi: ...
            Text(
              'Nơi gửi: ${item.senderDepartment}',
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            // Message (truncated to max 2 lines with ellipsis)
            Text(
              item.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            // Footer row
            Row(
              children: [
                // Icons on left
                if (!item.isRead) ...[
                  const Icon(
                    Icons.mail_rounded,
                    color: Color(0xFF4CAF50), // Green mail icon
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                if (item.attachmentName != null) ...[
                  const Icon(
                    Icons.attachment_rounded,
                    color: Color(0xFF3F51B5), // Blue paperclip icon
                    size: 18,
                  ),
                ],
                const Spacer(),
                // Date time on right
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
