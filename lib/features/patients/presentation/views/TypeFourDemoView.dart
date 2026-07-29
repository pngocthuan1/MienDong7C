import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/TypeFourDemoViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/PortalDrawer.dart';

class TypeFourDemoView extends StatefulWidget {
  const TypeFourDemoView({super.key});

  @override
  State<TypeFourDemoView> createState() => _TypeFourDemoViewState();
}

class _TypeFourDemoViewState extends State<TypeFourDemoView> {
  late final TypeFourDemoViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TypeFourDemoViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppLocator.sessionStore.session;
    if (session == null) {
      AppNavigator.resetToNamed(context, RouteNames.login);
      return const SizedBox.shrink();
    }

    const summary = NotificationSummaryEntity(
      total: 0,
      unread: 0,
      important: 0,
    );

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6FAFF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4B90E2),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Demo điều hướng dạng 4',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          drawer: PortalDrawer(
            session: session,
            summary: summary,
            onDevTestingTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.devTesting);
            },
            onHomeTap: () {
              AppNavigator.safePop(context);
              AppNavigator.replaceAndKeepRoot(context, RouteNames.home);
            },
            onNotificationTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.notifications);
            },
            onBookingTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.appointmentBooking);
            },
            onTypeFourDemoTap: () => AppNavigator.safePop(context),
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
            },
            onAboutTap: () {
              AppNavigator.safePop(context);
            },
            onLogoutTap: () {
              AppLocator.sessionStore.clear();
              AppNavigator.resetToNamed(context, RouteNames.login);
            },
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAF4FF), Color(0xFFF7FBFF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFD6E7F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.alt_route_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Luồng mẫu A -> B tự chuyển -> C',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _viewModel.roleSummary,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Vai trò hiện tại: ${_viewModel.roleBadge}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _StepCard(
                stepLabel: 'Bước A',
                title: 'Màn khởi động',
                description:
                    'Đây là màn bạn chủ động mở từ menu trái. Từ đây bạn bấm nút để đi sang bước B.',
                accentColor: Color(0xFF1D6FD7),
              ),
              const SizedBox(height: 12),
              const _StepCard(
                stepLabel: 'Bước B',
                title: 'Màn trung chuyển tự đẩy tiếp',
                description:
                    'Bước B chỉ dùng để xử lý nhanh. Sau khi render xong, màn này tự push sang bước C bằng cơ chế sau build.',
                accentColor: Color(0xFF0C8A74),
              ),
              const SizedBox(height: 12),
              const _StepCard(
                stepLabel: 'Bước C',
                title: 'Màn kết quả cuối',
                description:
                    'Từ bước C bấm back sẽ quay lại bước B. Bấm back lần nữa từ B mới quay về lại bước A.',
                accentColor: Color(0xFFD77A1D),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Bắt đầu demo dạng 4',
                icon: Icons.play_circle_fill_rounded,
                onPressed: () {
                  AppNavigator.pushNamed(
                    context,
                    RouteNames.typeFourProcessing,
                  );
                },
              ),
              const SizedBox(height: AppSizes.itemSpacing),
              const Text(
                'Bạn có thể bấm nút trên rồi thử back liên tiếp để thấy đúng stack: C -> B -> A.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  final String stepLabel;
  final String title;
  final String description;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEAF8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              stepLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
