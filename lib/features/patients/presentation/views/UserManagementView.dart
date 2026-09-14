import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementUserEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/UserManagementViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/PortalDrawer.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/UserManagementStatusChip.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  late final UserManagementViewModel _viewModel;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _viewModel = UserManagementViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );

    if (AppLocator.sessionStore.session?.isEmployee ?? false) {
      _viewModel.loadCommand.execute();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _openDetail(String userId) {
    try {
      AppNavigator.pushNamed(
        context,
        RouteNames.userManagementDetail,
        arguments: UserManagementDetailViewArgs(userId: userId),
      );
    } catch (_) {}
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
            onTypeFourDemoTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.typeFourDemo);
            },
            onUserManagementTap: () => AppNavigator.safePop(context),
            onChangePasswordTap: () {
              AppNavigator.safePop(context);
              AppNavigator.pushNamed(context, RouteNames.changePassword);
            },
            onDeleteAccountTap: () {
              AppNavigator.safePop(context);
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
          appBar: AppBar(
            backgroundColor: const Color(0xFF4B90E2),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Quản lý người dùng',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: !session.isEmployee
              ? _NoPermissionPanel(
                  onBackHome: () {
                    AppNavigator.replaceAndKeepRoot(context, RouteNames.home);
                  },
                )
              : ListenableBuilder(
                  listenable: _viewModel.loadCommand,
                  builder: (context, __) {
                    if (_viewModel.loadCommand.running &&
                        _viewModel.users.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final filteredUsers = _viewModel.filteredUsers;

                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: CustomScrollView(
                        controller: _scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          // Toàn bộ phần tổng quan, tìm kiếm và bộ lọc nằm
                          // trong cùng luồng cuộn với danh sách. Khi kéo xuống,
                          // các phần này sẽ tự ẩn và không che thẻ bệnh nhân.
                          SliverToBoxAdapter(
                            child: _TopSummaryPanel(viewModel: _viewModel),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                12,
                                18,
                                10,
                              ),
                              child: TextField(
                                controller: _viewModel.searchController,
                                onChanged: _viewModel.updateSearch,
                                decoration: InputDecoration(
                                  labelText: 'Tìm nhanh hồ sơ',
                                  hintText:
                                      'Nhập tên, mã bệnh nhân hoặc số điện thoại',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon:
                                      _viewModel.searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          onPressed: () {
                                            _viewModel.searchController.clear();
                                            _viewModel.updateSearch('');
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _StatusFilterDropdown(viewModel: _viewModel),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 560;
                                  return isNarrow
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _HeaderCountText(
                                              filteredCount:
                                                  filteredUsers.length,
                                              totalCount:
                                                  _viewModel.users.length,
                                            ),
                                            const SizedBox(height: 6),
                                            const _HeaderLazyText(),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            _HeaderCountText(
                                              filteredCount:
                                                  filteredUsers.length,
                                              totalCount:
                                                  _viewModel.users.length,
                                            ),
                                            const Spacer(),
                                            const _HeaderLazyText(),
                                          ],
                                        );
                                },
                              ),
                            ),
                          ),
                          if (filteredUsers.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'Không có hồ sơ phù hợp với bộ lọc hiện tại.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final user = filteredUsers[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _ManagedUserCard(
                                        user: user,
                                        onTap: () => _openDetail(user.id),
                                      ),
                                    );
                                  },
                                  childCount: filteredUsers.length,
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TopSummaryPanel extends StatelessWidget {
  const _TopSummaryPanel({required this.viewModel});

  final UserManagementViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF6FF), Color(0xFFF8FBFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9EAFE)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth < 760
              ? (constraints.maxWidth - 12) / 2
              : (constraints.maxWidth - 36) / 4;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản lý dữ liệu người dùng và lịch sử khám',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Theo dõi và quản lý dữ liệu bệnh nhân cũng như lịch sử khám bệnh.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryMetricCard(
                      title: 'Tổng hồ sơ',
                      value: '${viewModel.users.length}',
                      accentColor: const Color(0xFF2366C9),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryMetricCard(
                      title: 'Đang xử lý',
                      value: '${viewModel.activeUsersCount}',
                      accentColor: const Color(0xFF0C8A74),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryMetricCard(
                      title: 'Đã khám',
                      value: '${viewModel.completedUsersCount}',
                      accentColor: const Color(0xFF2E9D48),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _SummaryMetricCard(
                      title: 'Bị từ chối',
                      value: '${viewModel.rejectedUsersCount}',
                      accentColor: const Color(0xFFD14747),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
    required this.title,
    required this.value,
    required this.accentColor,
  });

  final String title;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCountText extends StatelessWidget {
  const _HeaderCountText({
    required this.filteredCount,
    required this.totalCount,
  });

  final int filteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hiển thị $filteredCount/$totalCount hồ sơ',
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HeaderLazyText extends StatelessWidget {
  const _HeaderLazyText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Danh sách hồ sơ bệnh nhân',
      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown({required this.viewModel});

  final UserManagementViewModel viewModel;

  static const String _allStatusKey = 'all';

  @override
  Widget build(BuildContext context) {
    final selectedStatus = viewModel.selectedStatus;
    final selectedKey = selectedStatus == null
        ? _allStatusKey
        : selectedStatus.index.toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: DropdownButtonFormField<String>(
        key: ValueKey(selectedKey),
        initialValue: selectedKey,
        isExpanded: true,
        menuMaxHeight: 360,
        dropdownColor: Colors.white,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
        ),
        decoration: InputDecoration(
          labelText: 'Bộ lọc',
          prefixIcon: const Icon(
            Icons.filter_alt_rounded,
            color: AppColors.primary,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD6E6F8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD6E6F8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        items: [
          DropdownMenuItem<String>(
            value: _allStatusKey,
            child: _DropdownStatusItem(
              label: 'Tất cả trạng thái',
              count: viewModel.users.length,
            ),
          ),
          ...UserManagementVisitStatus.values.map((status) {
            return DropdownMenuItem<String>(
              value: status.index.toString(),
              child: _DropdownStatusItem(
                label: status.label,
                count: viewModel.statusCounts[status] ?? 0,
              ),
            );
          }),
        ],
        onChanged: (value) {
          if (value == null) {
            return;
          }

          if (value == _allStatusKey) {
            viewModel.selectStatus(null);
            return;
          }

          final statusIndex = int.tryParse(value);
          if (statusIndex == null ||
              statusIndex < 0 ||
              statusIndex >= UserManagementVisitStatus.values.length) {
            return;
          }

          viewModel.selectStatus(UserManagementVisitStatus.values[statusIndex]);
        },
      ),
    );
  }
}

class _DropdownStatusItem extends StatelessWidget {
  const _DropdownStatusItem({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          constraints: const BoxConstraints(minWidth: 30),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF5FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagedUserCard extends StatelessWidget {
  const _ManagedUserCard({required this.user, required this.onTap});

  final UserManagementUserEntity user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCEBFA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0E0A4F95),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 640;
            return isTight
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ManagedUserCardMainInfo(user: user),
                      const SizedBox(height: 14),
                      _ManagedUserCardSideInfo(user: user, onTap: onTap),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _ManagedUserCardMainInfo(user: user)),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 220,
                        child: _ManagedUserCardSideInfo(
                          user: user,
                          onTap: onTap,
                        ),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _ManagedUserCardMainInfo extends StatelessWidget {
  const _ManagedUserCardMainInfo({required this.user});

  final UserManagementUserEntity user;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE9F3FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _initials(user.fullName),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mã BN: ${user.patientCode}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _InfoText(icon: Icons.phone_rounded, text: user.phoneNumber),
                  _InfoText(
                    icon: Icons.badge_outlined,
                    text: '${user.gender} • ${user.birthYear}',
                  ),
                  _InfoText(
                    icon: Icons.local_hospital_outlined,
                    text: user.currentDepartmentName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagedUserCardSideInfo extends StatelessWidget {
  const _ManagedUserCardSideInfo({required this.user, required this.onTap});

  final UserManagementUserEntity user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: UserManagementStatusChip(status: user.currentStatus),
        ),
        const SizedBox(height: 10),
        Text(
          'Lần gần nhất: ${user.lastVisitText}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tổng lượt khám: ${user.totalVisits}',
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.visibility_rounded),
            label: const Text('Xem chi tiết'),
          ),
        ),
      ],
    );
  }
}

class _InfoText extends StatelessWidget {
  const _InfoText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NoPermissionPanel extends StatelessWidget {
  const _NoPermissionPanel({required this.onBackHome});

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD9EAFE)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_person_rounded,
              size: 44,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chức năng này chỉ dành cho nhân viên.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bạn hãy quay về trang chủ hoặc đăng nhập bằng tài khoản nhân viên để tiếp tục.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: AppButton(
                label: 'Về trang chủ',
                icon: Icons.home_rounded,
                onPressed: onBackHome,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String fullName) {
  try {
    final parts = fullName
        .trim()
        .split(' ')
        .where((element) => element.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'ND';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  } catch (_) {
    return 'ND';
  }
}
