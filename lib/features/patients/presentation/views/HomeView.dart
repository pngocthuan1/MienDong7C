import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/HomeViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/HomeActionCard.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/PortalDrawer.dart';

import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    _viewModel.loadCommand.execute();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showInfoDialog(String title, String content) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
      AppNavigator.resetToNamed(context, RouteNames.login);
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final effectiveSummary = (_viewModel.summary.total > 0 || _viewModel.summary.unread > 0)
            ? _viewModel.summary
            : AppLocator.sessionStore.notificationSummary;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final now = DateTime.now();
            if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
              _lastPressedAt = now;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nhấn thêm một lần nữa để thoát ứng dụng'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              SystemNavigator.pop();
            }
          },
          child: AppResponsiveContainer(
            maxWidth: double.infinity,
            appBar: AppBar(
              backgroundColor: const Color(0xFF4B90E2),
              foregroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 0,
              title: const Text(
                'Trang chủ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ),
            drawer: PortalDrawer(
              session: session,
              summary: effectiveSummary,
              onDevTestingTap: () {
                AppNavigator.safePop(context);
                AppNavigator.pushNamed(context, RouteNames.devTesting);
              },
              onFilterTap: (filter) {
                AppNavigator.safePop(context);
                AppNavigator.pushNamed(
                  context,
                  RouteNames.notifications,
                  arguments: filter,
                ).then((_) {
                  if (mounted) {
                    _viewModel.loadCommand.execute();
                  }
                });
              },
              onHomeTap: () => AppNavigator.safePop(context),
              onNotificationTap: () {
                AppNavigator.safePop(context);
                AppNavigator.pushNamed(context, RouteNames.notifications).then((_) {
                  if (!mounted) {
                    return;
                  }
                  _viewModel.loadCommand.execute();
                });
              },
              onBookingTap: () {
                AppNavigator.safePop(context);
                AppNavigator.pushNamed(context, RouteNames.appointmentBooking);
              },
              onTypeFourDemoTap: () {
                AppNavigator.safePop(context);
                AppNavigator.pushNamed(context, RouteNames.typeFourDemo);
              },
              onUserManagementTap:
                  session
                      .isEmployee // bật menu quản lý user
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
                AppNavigator.pushNamed(context, RouteNames.aboutApp);
              },
              onLogoutTap: () async {
                await AppLocator.authRepository.logout();
                if (!context.mounted) return;
                AppNavigator.resetToNamed(context, RouteNames.login);
              },
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Row(
                  children: [
                    HomeActionCard(
                      title: 'Thông Báo\nTin Tức',
                      icon: Icons.notifications_active_rounded,
                      badgeCount: effectiveSummary.unread > 0 ? effectiveSummary.unread : effectiveSummary.total,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF4C5), Color(0xFFFFFDF0)],
                      ),
                    onTap: () {
                      AppNavigator.pushNamed(context, RouteNames.notifications)
                          .then((_) {
                        if (!mounted) {
                          return;
                        }
                        _viewModel.loadCommand.execute();
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  HomeActionCard(
                    title: session
                        .user
                        .role
                        .secondHomeCardTitle, // Đổi text, icon theo vai trò
                    icon: session.user.role == UserRole.employee
                        ? Icons.medical_services_rounded
                        : Icons.calendar_month_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F2FF), Color(0xFFF9FCFF)],
                    ),
                    onTap: () {
                      AppNavigator.pushNamed(
                        context,
                        RouteNames.appointmentBooking,
                      );
                    },
                  ),
                ],
              ),
              if (session.isEmployee) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    HomeActionCard(
                      title: 'Đăng\nThông Báo',
                      icon: Icons.campaign_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFECEB), Color(0xFFFFF8F7)],
                      ),
                      onTap: () {
                        AppNavigator.pushNamed(
                          context,
                          RouteNames.createNotification,
                        ).then((_) {
                          if (!mounted) return;
                          _viewModel.loadCommand.execute();
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE1EEFB)),
                ),
                child: Column(
                  children: [
                    Text(
                      session.user.role.topWelcome, // welcome theo vai trò.
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _CenterHospitalMark(),
                    const SizedBox(height: 18),
                    Text(
                      session.user.role.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
  }
}

class _CenterHospitalMark extends StatelessWidget {
  const _CenterHospitalMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),
        const Text(
          'BỆNH VIỆN QUÂN Y MIỀN ĐÔNG',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
