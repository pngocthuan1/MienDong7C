import 'package:flutter/material.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/AppointmentBookingViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/PortalDrawer.dart';
import 'package:benhvien7c/features/patients/presentation/views/TicketBarcodeScannerView.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/TicketPickerBottomSheet.dart';

class AppointmentBookingView extends StatefulWidget {
  const AppointmentBookingView({super.key});

  @override
  State<AppointmentBookingView> createState() => _AppointmentBookingViewState();
}

class _AppointmentBookingViewState extends State<AppointmentBookingView> {
  late final AppointmentBookingViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AppointmentBookingViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge(MedicalTicketEntity ticket) {
    final isDeleted = ticket.isDeleted;
    final isPast = ticket.isPast;

    String label = 'SẮP TỚI';
    Color bg = const Color(0xFFEBF3FF);
    Color text = const Color(0xFF0D6EFD);

    if (isDeleted) {
      label = 'ĐÃ XÓA';
      bg = const Color(0xFFFFECEF);
      text = const Color(0xFFDC2626);
    } else if (isPast) {
      label = 'ĐÃ QUA';
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: text, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFilterChip(String label, TicketDateFilterMode mode) {
    final isSelected = _viewModel.dateFilterMode == mode;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : const Color(0xFF475569),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF0D6EFD),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFE2E8F0),
        ),
      ),
      showCheckmark: false,
      onSelected: (_) => _viewModel.setDateFilterMode(mode),
    );
  }

  Widget _buildTicketsList(
    List<MedicalTicketEntity> tickets, {
    required String emptyMessage,
    bool isDeletedTab = false,
  }) {
    if (tickets.isEmpty) {
      final isFiltered = _viewModel.hasActiveFilter;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFiltered ? Icons.search_off_rounded : Icons.receipt_long_rounded,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                isFiltered ? 'Không tìm thấy phiếu đăng ký nào phù hợp' : emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (isFiltered) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _viewModel.clearFilters();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Xóa bộ lọc'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D6EFD),
                    side: const BorderSide(color: Color(0xFF0D6EFD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Bar: Pink banner if expired/past, or light blue if active/upcoming
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: ticket.isPast ? const Color(0xFFFFC0CB) : const Color(0xFFEBF3FF),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ticket.patientName.toUpperCase()} - ${(ticket.dateOfBirth != null && ticket.dateOfBirth!.isNotEmpty) ? ticket.dateOfBirth! : ticket.birthYear}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    _buildStatusBadge(ticket),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: # Mã BN (Chỉ hiển thị khi có mã chính thức 8 số)
                    if (ticket.patientCode.trim().length == 8 && RegExp(r'^\d+$').hasMatch(ticket.patientCode.trim())) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '#',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Mã BN: ${ticket.patientCode}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Line 2: Ngày khám: ...
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'Ngày khám: ${ticket.scheduleText}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Line 3: # Số đăng ký: ...
                    Row(
                      children: [
                        const Text(
                          '#',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Số đăng ký: ${ticket.queueNumber}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),

                    // Action buttons (retained)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!ticket.isDeleted) ...[
                          TextButton.icon(
                            onPressed: () async {
                              await AppNavigator.pushNamed(
                                context,
                                RouteNames.medicalTicket,
                                arguments: MedicalTicketViewArgs(ticket: ticket),
                              );
                              if (!mounted) return;
                              _viewModel.loadTicketsCommand.execute();
                            },
                            icon: const Icon(Icons.qr_code_rounded, size: 16),
                            label: const Text('Chi tiết'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0D6EFD),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              await AppNavigator.pushNamed(
                                context,
                                RouteNames.patientProfileCreate,
                                arguments: ticket,
                              );
                              if (!mounted) return;
                              _viewModel.loadTicketsCommand.execute();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Đăng ký lại'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0D6EFD),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xác nhận xóa phiếu'),
                                  content: Text('Bạn có chắc chắn muốn xóa phiếu đặt lịch khám "${ticket.serviceName}" của bệnh nhân ${ticket.patientName} không?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Bỏ qua'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Xóa phiếu', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _viewModel.softDeleteTicket(ticket.id!);
                              }
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            tooltip: 'Xóa phiếu',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ] else ...[
                          TextButton.icon(
                            onPressed: () => _viewModel.restoreTicket(ticket.id!),
                            icon: const Icon(Icons.restore_rounded, size: 16),
                            label: const Text('Khôi phục'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openTicketDetail(MedicalTicketEntity ticket) async {
    await AppNavigator.pushNamed(
      context,
      RouteNames.medicalTicket,
      arguments: MedicalTicketViewArgs(ticket: ticket),
    );
    if (!mounted) return;
    _viewModel.loadTicketsCommand.execute();
  }

  Future<void> _scanTicketBarcode() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const TicketBarcodeScannerView(),
      ),
    );

    if (scannedCode == null || scannedCode.trim().isEmpty || !mounted) return;
    final cleanCode = scannedCode.trim();

    // 1. Khớp chính xác ID phiếu (ticket.id) nếu mã quét là mã phiếu
    final directIdMatches = _viewModel.allTickets
        .where((t) => !t.isDeleted && t.id != null && t.id!.trim() == cleanCode)
        .toList();
    if (directIdMatches.isNotEmpty) {
      await _openTicketDetail(directIdMatches.first);
      return;
    }

    // 2. Lọc danh sách phiếu chưa xóa theo Mã bệnh nhân (patientCode)
    final matchingTickets = _viewModel.allTickets
        .where((t) => !t.isDeleted && t.patientCode.trim() == cleanCode)
        .toList();

    if (matchingTickets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không tìm thấy phiếu khám nào khớp với mã: $cleanCode'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Sắp xếp các phiếu: ngày khám gần nhất/mới nhất lên đầu
    matchingTickets.sort((a, b) {
      final dateA = a.parsedTicketDate ?? DateTime(1970);
      final dateB = b.parsedTicketDate ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    // Nếu chỉ có đúng 1 phiếu duy nhất -> Mở thẳng luôn (không cần hỏi)
    if (matchingTickets.length == 1) {
      await _openTicketDetail(matchingTickets.first);
      return;
    }

    // Nếu có từ 2 phiếu trở lên: Kiểm tra các phiếu của ngày hôm nay
    final todayTickets = matchingTickets.where((t) => t.isToday).toList();

    // Nếu đúng 1 phiếu hôm nay -> Mở thẳng luôn (Tốc độ tối đa cho trường hợp phổ biến nhất)
    if (todayTickets.length == 1) {
      await _openTicketDetail(todayTickets.first);
      return;
    }

    // Nếu có >= 2 phiếu hôm nay HOẶC 0 phiếu hôm nay: Hiện Bottom Sheet để người dùng/nhân viên chọn
    if (!mounted) return;
    final selectedTicket = await TicketPickerBottomSheet.show(
      context: context,
      patientCode: cleanCode,
      allTickets: matchingTickets,
      todayTickets: todayTickets,
    );

    if (selectedTicket != null && mounted) {
      await _openTicketDetail(selectedTicket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppLocator.sessionStore.session!;
    const summary = NotificationSummaryEntity(
      total: 0,
      unread: 0,
      important: 0,
    );

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return DefaultTabController(
          length: 4,
          child: AppResponsiveContainer(
            maxWidth: double.infinity,
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
              onBookingTap: () => AppNavigator.safePop(context),
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
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'Lịch sử Đăng ký Khám',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  tooltip: 'Quét mã vạch phiếu',
                  onPressed: _scanTicketBarcode,
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: [
                  Tab(text: 'Tất cả (${_viewModel.filteredActiveTickets.length})'),
                  Tab(text: 'Sắp tới (${_viewModel.filteredUpcomingTickets.length})'),
                  Tab(text: 'Đã qua (${_viewModel.filteredPassedTickets.length})'),
                  Tab(text: 'Đã xóa (${_viewModel.filteredDeletedTickets.length})'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                await AppNavigator.pushNamed(
                  context,
                  RouteNames.patientProfileCreate,
                );
                if (!mounted) return;
                _viewModel.loadTicketsCommand.execute();
              },
              backgroundColor: const Color(0xFF0D6EFD),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Đăng ký mới',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            child: Column(
              children: [
                // Search & Filter Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => _viewModel.setSearchQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên BN, mã BN, phòng khám, ngày...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0D6EFD)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _viewModel.setSearchQuery('');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tất cả thời gian', TicketDateFilterMode.all),
                            const SizedBox(width: 8),
                            _buildFilterChip('Hôm nay', TicketDateFilterMode.today),
                            const SizedBox(width: 8),
                            _buildFilterChip('Tuần này', TicketDateFilterMode.thisWeek),
                            const SizedBox(width: 8),
                            _buildFilterChip('Tháng này', TicketDateFilterMode.thisMonth),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTicketsList(
                        _viewModel.filteredActiveTickets,
                        emptyMessage: 'Chưa có phiếu đăng ký nào',
                        isDeletedTab: false,
                      ),
                      _buildTicketsList(
                        _viewModel.filteredUpcomingTickets,
                        emptyMessage: 'Chưa có phiếu khám nào sắp tới',
                        isDeletedTab: false,
                      ),
                      _buildTicketsList(
                        _viewModel.filteredPassedTickets,
                        emptyMessage: 'Chưa có phiếu khám nào đã qua',
                        isDeletedTab: false,
                      ),
                      _buildTicketsList(
                        _viewModel.filteredDeletedTickets,
                        emptyMessage: 'Không có phiếu đã xóa nào',
                        isDeletedTab: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
