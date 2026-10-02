import 'package:flutter/material.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/MedicalTicketViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/MedicalTicketBarcode.dart';
import 'package:benhvien7c/core/utils/DateTimeConverter.dart';

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
    _viewModel = MedicalTicketViewModel(
      widget.args.ticket,
      doneStatus: widget.args.ticket.doneStatus,
      coTheXoa: widget.args.ticket.coTheXoa,
      lyDoLoi: widget.args.ticket.trangThai,
    );
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
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

  void _showExpandedBarcodeDialog(BuildContext context, String code) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MÃ VẠCH BỆNH NHÂN',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mã BN: $code',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6EFD),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 280,
                    height: 110,
                    child: MedicalTicketBarcode(seed: code),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đưa mã vạch này vuông góc với máy quét tại Quầy tiếp đón Bệnh viện',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _viewModel.ticket;
    final statusInfo = _viewModel.statusInfo;
    final isExpanded = _viewModel.isExpanded;
    final canDelete = _viewModel.canDelete;

    // Địa chỉ hiển thị (ưu tiên ghép từ Phường/Xã + Tỉnh/TP mà người dùng đã đăng ký)
    final addressText = [ticket.ward, ticket.province]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(', ');
    // Tuyệt đối không lấy địa chỉ bệnh viện cho địa chỉ người dùng
    String finalAddress = addressText;
    if (finalAddress.isEmpty &&
        ticket.address.isNotEmpty &&
        ticket.address != ticket.hospitalAddress &&
        !ticket.address.contains('50 Lê Văn Việt')) {
      finalAddress = ticket.address;
    }

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
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Top Header Banner
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
                      const SizedBox(height: 10),

                      // Badge Trạng Thái (Luồng 2)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusInfo.badgeColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusInfo.textColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusInfo.textColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusInfo.label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: statusInfo.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lý do lỗi khi doneStatus = -1
                      if (_viewModel.doneStatus == -1 &&
                          _viewModel.lyDoLoi != null &&
                          _viewModel.lyDoLoi!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Lý do: ${_viewModel.lyDoLoi!}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

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

                      // --- CHẾ ĐỘ THU GỌN (MẶC ĐỊNH) ---
                      // Thứ tự spec: HoTen -> SoCcHc -> NgayCap -> NgaySinh -> GioiTinh -> DiaChi -> DienThoai
                      _DetailRow(label: 'Họ tên', value: ticket.patientName),
                      if (ticket.soCcHc != null && ticket.soCcHc!.isNotEmpty)
                        _DetailRow(label: 'CCCD/HC', value: ticket.soCcHc!)
                      else if (ticket.insuranceText.isNotEmpty)
                        _DetailRow(label: 'Mã số/Thẻ', value: ticket.insuranceText),
                      if (ticket.ngayCap != null && ticket.ngayCap!.isNotEmpty)
                        _DetailRow(
                          label: 'Ngày cấp',
                          value: DateTimeConverter.toVnDate(ticket.ngayCap) ?? ticket.ngayCap!,
                        ),
                      _DetailRow(
                        label: 'Ngày sinh',
                        value: (ticket.dateOfBirth != null && ticket.dateOfBirth!.isNotEmpty)
                            ? (DateTimeConverter.toVnDate(ticket.dateOfBirth) ?? ticket.dateOfBirth!)
                            : ticket.birthYear,
                      ),
                      _DetailRow(label: 'Giới tính', value: ticket.gender),
                      if (finalAddress.isNotEmpty)
                        _DetailRow(label: 'Địa chỉ', value: finalAddress),
                      if (ticket.phoneNumber != null && ticket.phoneNumber!.isNotEmpty)
                        _DetailRow(label: 'Điện thoại', value: ticket.phoneNumber!),

                      // --- CHẾ ĐỘ ĐẦY ĐỦ (KHI BẤM "XEM CHI TIẾT") ---
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isExpanded
                            ? Column(
                                children: [
                                  const SizedBox(height: 10),
                                  const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                  const SizedBox(height: 10),

                                  _DetailRow(
                                    label: 'Ngày khám',
                                    value: DateTimeConverter.formatScheduleForDisplay(ticket.scheduleText),
                                  ),
                                  if (ticket.clinic != null && ticket.clinic!.isNotEmpty)
                                    _DetailRow(label: 'Phòng khám', value: ticket.clinic!)
                                  else if (ticket.department != null && ticket.department!.isNotEmpty)
                                    _DetailRow(label: 'Phòng khám', value: ticket.department!),
                                  if (ticket.symptom != null && ticket.symptom!.isNotEmpty)
                                    _DetailRow(label: 'Triệu chứng', value: ticket.symptom!),

                                  // Mã BN & Barcode
                                  if (ticket.patientCode.trim().isNotEmpty) ...[
                                    _DetailRow(label: 'Mã BN', value: ticket.patientCode),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () => _showExpandedBarcodeDialog(context, ticket.patientCode),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Column(
                                          children: [
                                            Center(
                                              child: SizedBox(
                                                width: 260,
                                                height: 80,
                                                child: MedicalTicketBarcode(seed: ticket.patientCode),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              '(Chạm để phóng to mã vạch)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  _DetailRow(
                                    label: 'Đăng ký lúc',
                                    value: DateTimeConverter.toVnDateTime(ticket.createdAtText, includeSeconds: true) ?? ticket.createdAtText,
                                  ),
                                  if (ticket.dangKyGiup != null && ticket.dangKyGiup!.isNotEmpty)
                                    _DetailRow(label: 'Đăng ký giúp', value: ticket.dangKyGiup!),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 12),

                      // Nút Toggle Thu gọn / Đầy đủ
                      TextButton.icon(
                        onPressed: _viewModel.toggleExpand,
                        icon: Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: const Color(0xFF0D6EFD),
                        ),
                        label: Text(
                          isExpanded ? 'Thu gọn' : 'Xem chi tiết',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6EFD),
                          ),
                        ),
                      ),

                      // Nút Xóa phiếu (chỉ hiện khi canDelete)
                      if (canDelete) ...[
                        const SizedBox(height: 12),
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
          Expanded(
            child: Text(
              ': $value',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
