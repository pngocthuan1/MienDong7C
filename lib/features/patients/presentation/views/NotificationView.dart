import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/NotificationViewModel.dart';
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

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await _viewModel.loadCommand.execute();
  }

  Future<void> _openNotification(NotificationItemEntity item) async {
    // 1. Đánh dấu đã đọc
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
              _showInfoDialog(
                'Đổi mật khẩu',
                'Bạn có thể vào lại flow quên mật khẩu từ màn hình auth. Phần này đã được tách sẵn để sau nối API thật.',
              );
            },
            onDeleteAccountTap: () {
              AppNavigator.safePop(context);
              _showInfoDialog(
                'Xóa tài khoản',
                'Đây là nút giao diện để test. Khi có API thật, mình có thể nối thêm confirm và gọi backend xóa tài khoản.',
              );
            },
            onAboutTap: () {
              AppNavigator.safePop(context);
              _showInfoDialog(
                'Thông tin phần mềm',
                'HPS Hospital Care - demo Tuan 4\nMVVM + Command + Role-aware auth + internal UI flow.',
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 18),
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
          body: ListenableBuilder(
            listenable: _viewModel.loadCommand,
            builder: (context, __) {
              final listToDisplay = _viewModel.filteredItems;
              if (_viewModel.loadCommand.running && listToDisplay.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (listToDisplay.isEmpty) {
                return PortalEmptyState(
                  title: 'Chưa có thông báo',
                  message: _viewModel.selectedFilter == NotificationFilter.all
                      ? 'Hiện tại danh sách đang trống. Khi bạn bấm làm mới hoặc đổi vai trò, đây sẽ là nơi test dữ liệu thông báo.'
                      : 'Không có thông báo nào phù hợp với bộ lọc này.',
                  icon: Icons.notifications_none_rounded,
                );
              }

              // Group items by date string
              final Map<String, List<NotificationItemEntity>> grouped = {};
              for (final item in listToDisplay) {
                final dateStr = _formatDate(item.createdAt);
                grouped.putIfAbsent(dateStr, () => []).add(item);
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final dateStr = grouped.keys.elementAt(index);
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

class _NotificationItemRow extends StatelessWidget {
  const _NotificationItemRow({
    required this.item,
    required this.onTap,
  });

  final NotificationItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.isRead ? Colors.black : const Color(0xFF4CAF50); // Green for unread, black for read
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
