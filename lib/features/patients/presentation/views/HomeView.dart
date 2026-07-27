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
              summary: _viewModel.summary,
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Row(
                children: [
                  HomeActionCard(
                    title: 'Thông Báo\nTin Tức',
                    icon: Icons.notifications_active_rounded,
                    badgeCount: _viewModel.summary.total,
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
              const SizedBox(height: 36),
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
        Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Container(
                  width: 46,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF29AA0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 46,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9ED0F3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const Positioned.fill(child: _WaveBand()),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'MIỀN ĐÔNG 7C',
          style: TextStyle(
            color: Color(0xFF8EC7F1),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _WaveBand extends StatelessWidget {
  const _WaveBand();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Transform.translate(
          offset: Offset(index.isOdd ? -12 : 12, 0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 146,
            height: 6,
            decoration: BoxDecoration(
              color: index.isEven
                  ? const Color(0xFF9ED0F3)
                  : const Color(0xFFF29AA0),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}
