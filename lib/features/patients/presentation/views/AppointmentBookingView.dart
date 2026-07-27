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

class AppointmentBookingView extends StatefulWidget {
  const AppointmentBookingView({super.key});

  @override
  State<AppointmentBookingView> createState() => _AppointmentBookingViewState();
}

class _AppointmentBookingViewState extends State<AppointmentBookingView> {
  late final AppointmentBookingViewModel _viewModel;

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

  Widget _buildTicketsList(List<MedicalTicketEntity> tickets, {required bool isDeletedTab}) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              isDeletedTab ? 'Không có phiếu đã xóa' : 'Chưa có phiếu đăng ký nào',
              style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.roomName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                    ),
                    _buildStatusBadge(ticket),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Khung giờ: ${ticket.scheduleText}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      ticket.patientName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· Mã BN: ${ticket.patientCode}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                        onPressed: () => _viewModel.softDeleteTicket(ticket.id!),
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
        );
      },
    );
  }

  Future<void> _scanTicketBarcode(BuildContext context) async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const TicketBarcodeScannerView(),
      ),
    );

    if (scannedCode != null && mounted) {
      final matchingTickets = _viewModel.allTickets.where(
        (t) => t.patientCode.trim() == scannedCode.trim(),
      ).toList();

      if (matchingTickets.isNotEmpty) {
        final ticket = matchingTickets.first;
        await AppNavigator.pushNamed(
          context,
          RouteNames.medicalTicket,
          arguments: MedicalTicketViewArgs(ticket: ticket),
        );
        _viewModel.loadTicketsCommand.execute();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không tìm thấy phiếu khám nào khớp với Mã BN: $scannedCode'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
            maxWidth: 800.0, // Wider container for lists/tables
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
                  onPressed: () => _scanTicketBarcode(context),
                ),
              ],
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Tất cả'),
                  Tab(text: 'Sắp tới'),
                  Tab(text: 'Đã qua'),
                  Tab(text: 'Đã xóa'),
                ],
              ),
            ),
            child: TabBarView(
              children: [
                _buildTicketsList(_viewModel.activeTickets, isDeletedTab: false),
                _buildTicketsList(_viewModel.upcomingTickets, isDeletedTab: false),
                _buildTicketsList(_viewModel.passedTickets, isDeletedTab: false),
                _buildTicketsList(_viewModel.deletedTickets, isDeletedTab: true),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                await AppNavigator.pushNamed(
                  context,
                  RouteNames.patientProfileCreate,
                );
                _viewModel.loadTicketsCommand.execute();
              },
              backgroundColor: const Color(0xFF0D6EFD),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Đăng ký mới',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}
