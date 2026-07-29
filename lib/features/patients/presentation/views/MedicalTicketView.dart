import 'package:flutter/material.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/MedicalTicketViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/MedicalTicketBarcode.dart';

class MedicalTicketView extends StatefulWidget {
  const MedicalTicketView({required this.args, super.key});

  final MedicalTicketViewArgs args;

  @override
  State<MedicalTicketView> createState() => _MedicalTicketViewState();
}

class _MedicalTicketViewState extends State<MedicalTicketView> {
  late final MedicalTicketViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MedicalTicketViewModel(widget.args.ticket);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  bool _isOfficialCode(String code) {
    final clean = code.trim();
    return clean.length == 8 && RegExp(r'^\d+$').hasMatch(clean);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu khám'),
        content: const Text('Bạn có chắc chắn muốn xóa phiếu đặt lịch khám này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _viewModel.deleteTicket();
              if (mounted) {
                AppNavigator.safePop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _viewModel.ticket;

    return AppResponsiveContainer(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Phiếu đặt lịch khám',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppNavigator.safePop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_rounded, color: Color(0xFF1E40AF), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Phiếu khám đăng ký tiêu đề nền màu hồng là phiếu đã quá thời gian khám (quá hạn).',
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ticket Card Main Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Top Header Banner (Pink ONLY if expired/past ticket, or light blue if active)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  color: ticket.isPast ? const Color(0xFFFFC0CB) : const Color(0xFFDBEAFE),
                  child: Column(
                    children: [
                      Text(
                        'Bệnh viện Quân Dân Y Miền Đông',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ticket.isPast ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '50 Lê Văn Việt, Phường Tăng Nhơn Phú, Thành Phố Hồ Chí Minh',
                        style: TextStyle(
                          fontSize: 12,
                          color: ticket.isPast ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'PHIẾU ĐẶT LỊCH KHÁM',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Large Sequence Number
                      Text(
                        ticket.queueNumber,
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B82F6),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Patient Details List (: value format)
                      _DetailRow(label: 'Ngày khám', value: ticket.scheduleText),
                      if (_isOfficialCode(ticket.patientCode))
                        _DetailRow(label: 'Mã BN', value: ticket.patientCode),
                      _DetailRow(label: 'Họ tên', value: ticket.patientName),
                      _DetailRow(label: 'Năm sinh', value: ticket.birthYear),
                      _DetailRow(label: 'Giới tính', value: ticket.gender),
                      _DetailRow(label: 'Điện thoại', value: ticket.phoneNumber ?? ''),
                      _DetailRow(label: 'Triệu chứng', value: (ticket.symptom != null && ticket.symptom!.isNotEmpty) ? ticket.symptom! : 'không có'),

                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                      const SizedBox(height: 14),

                      _DetailRow(label: 'Đăng ký lúc', value: ticket.createdAtText),
                      if (ticket.dangKyGiup != null && ticket.dangKyGiup!.trim().isNotEmpty)
                        _DetailRow(label: 'Đăng ký giúp', value: ticket.dangKyGiup!.trim()),

                      const SizedBox(height: 20),

                      // Center Red Delete Button
                      SizedBox(
                        width: 120,
                        height: 38,
                        child: ElevatedButton(
                          onPressed: _confirmDelete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Xóa phiếu',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      // Scannable barcode ONLY if official 8-digit patient code
                      if (_isOfficialCode(ticket.patientCode)) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                        const SizedBox(height: 14),
                        Text(
                          'Mã BN: ${ticket.patientCode}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: MedicalTicketBarcode(seed: ticket.patientCode),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Footer Text
          const Center(
            child: Text(
              'Ghi chú: Phiếu đặt lịch khám chỉ có giá trị trong ngày đặt khám từ 6g30 - 16g30',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
          ),
          Text(
            ':$value',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
