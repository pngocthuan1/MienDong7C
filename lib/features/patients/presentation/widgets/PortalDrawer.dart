import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/NotificationViewModel.dart';

class PortalDrawer extends StatelessWidget {
  const PortalDrawer({
    required this.session,
    required this.summary,
    required this.onHomeTap,
    required this.onNotificationTap,
    required this.onBookingTap,
    this.onTypeFourDemoTap,
    this.onDevTestingTap,
    this.onChangePasswordTap,
    required this.onDeleteAccountTap,
    required this.onAboutTap,
    required this.onLogoutTap,
    super.key,
    this.onUserManagementTap,
    this.onFilterTap,
  });

  final AuthSessionEntity session;
  final NotificationSummaryEntity summary;
  final VoidCallback onHomeTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onBookingTap;
  final VoidCallback? onTypeFourDemoTap;
  final VoidCallback? onDevTestingTap;
  final VoidCallback? onUserManagementTap;
  final VoidCallback? onChangePasswordTap;
  final VoidCallback onDeleteAccountTap;
  final VoidCallback onAboutTap;
  final VoidCallback onLogoutTap;
  final Function(NotificationFilter filter)? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5CA4F2), Color(0xFF3E79CF)],
              ),
            ),
            child: Column(
              children: [
                Text(
                  session.user.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tài khoản: ${session.user.phoneNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    session.user.role.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerTile(
                  icon: Icons.home_rounded,
                  label: 'Trang chủ',
                  onTap: onHomeTap,
                ),
                const Divider(height: 1),
                _DrawerGroup(
                  title: 'Thông báo',
                  icon: Icons.notifications_active_rounded,
                  child: Column(
                    children: [
                      _CounterTile(
                        label: 'Tất cả',
                        value: summary.total,
                        color: const Color(0xFF4285F4),
                        onTap: () => onFilterTap?.call(NotificationFilter.all),
                      ),
                      _CounterTile(
                        label: 'Chưa đọc',
                        value: summary.unread,
                        color: const Color(0xFF34A853),
                        onTap: () => onFilterTap?.call(NotificationFilter.unread),
                      ),
                      _CounterTile(
                        label: 'Đã đọc',
                        value: summary.total - summary.unread,
                        color: const Color(0xFF9AA0A6),
                        onTap: () => onFilterTap?.call(NotificationFilter.read),
                      ),
                      _CounterTile(
                        label: 'Quan trọng',
                        value: summary.important,
                        color: const Color(0xFFFBBC05),
                        onTap: () => onFilterTap?.call(NotificationFilter.important),
                      ),
                      _CounterTile(
                        label: 'Rất quan trọng',
                        value: summary.important > 0 ? 1 : 0,
                        color: const Color(0xFFEA4335),
                        onTap: () => onFilterTap?.call(NotificationFilter.veryImportant),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: onNotificationTap,
                          child: const Text('Mở danh sách thông báo'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _DrawerTile(
                  icon: Icons.calendar_month_rounded,
                  label: session.user.role.secondMenuTitle,
                  onTap: onBookingTap,
                ),

                if (session.isEmployee && onUserManagementTap != null) ...[
                  const Divider(height: 1),
                  _DrawerTile(
                    icon: Icons.manage_accounts_rounded,
                    label: 'Quản lý người dùng',
                    onTap: onUserManagementTap!,
                  ),
                ],
                const Divider(height: 1),
                _DrawerTile(
                  icon: Icons.lock_reset_rounded,
                  label: 'Đổi mật khẩu',
                  onTap: onChangePasswordTap ?? () {
                    AppNavigator.safePop(context);
                    AppNavigator.pushNamed(context, RouteNames.changePassword);
                  },
                ),
                _DrawerTile(
                  icon: Icons.person_remove_alt_1_rounded,
                  label: 'Xóa tài khoản',
                  onTap: onDeleteAccountTap,
                ),
                _DrawerTile(
                  icon: Icons.info_rounded,
                  label: 'Thông tin phần mềm',
                  onTap: onAboutTap,
                ),
                const Divider(height: 1),
                _DrawerTile(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  iconColor: Colors.red,
                  onTap: onLogoutTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}

class _DrawerGroup extends StatelessWidget {
  const _DrawerGroup({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  const _CounterTile({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  final String label;
  final int value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
