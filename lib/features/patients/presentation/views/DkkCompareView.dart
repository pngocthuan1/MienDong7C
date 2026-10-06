import 'package:flutter/material.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/entities/DkkThongTinKhamModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/DkkCompareViewModel.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';

/// Arguments để navigate đến DkkCompareView
class DkkCompareArgs {
  final DkkThongTinKhamModel compareModel;
  final PatientProfileDraftEntity userDraft;
  final UserRole role;
  final String? department;
  final String? departmentId;
  final String? provinceCode;
  final String? provinceName;
  final String? wardCode;
  final String? wardName;
  final String? selectedDate;
  final String? selectedTime;
  final String? symptom;

  const DkkCompareArgs({
    required this.compareModel,
    required this.userDraft,
    required this.role,
    this.department,
    this.departmentId,
    this.provinceCode,
    this.provinceName,
    this.wardCode,
    this.wardName,
    this.selectedDate,
    this.selectedTime,
    this.symptom,
  });
}

/// Màn hình đối chiếu thông tin trước khi đăng ký (Luồng 3).
class DkkCompareView extends StatefulWidget {
  const DkkCompareView({super.key});

  @override
  State<DkkCompareView> createState() => _DkkCompareViewState();
}

class _DkkCompareViewState extends State<DkkCompareView> {
  late DkkCompareViewModel _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DkkCompareArgs) {
      _viewModel = DkkCompareViewModel(
        compareModel: args.compareModel,
        userDraft: args.userDraft,
        repository: AppLocator.portalRepository,
        role: args.role,
        department: args.department,
        departmentId: args.departmentId,
        provinceCode: args.provinceCode,
        provinceName: args.provinceName,
        wardCode: args.wardCode,
        wardName: args.wardName,
        selectedDate: args.selectedDate,
        selectedTime: args.selectedTime,
        symptom: args.symptom,
      );
      _viewModel.addListener(_onViewModelChanged);
    }
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

  Future<void> _submit(bool useSystemData) async {
    final result = await _viewModel.submit(useSystemData);
    if (!mounted) return;
    result.when(
      ok: (MedicalTicketEntity ticket) {
        // Refresh danh sách hồ sơ sau đăng ký thành công
        AppLocator.portalRepository.loadPatientProfiles();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đăng ký khám thành công! STT của bạn: ${ticket.queueNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
          ),
        );
        AppNavigator.replaceAndKeepRoot(
          context,
          RouteNames.medicalTicket,
          arguments: MedicalTicketViewArgs(ticket: ticket),
        );
      },
      error: (_, message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt lịch: $message'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = _viewModel.compareModel;
    final isSubmitting = _viewModel.isSubmitting;
    final errorMsg = _viewModel.errorMessage;

    return PopScope(
      // Block Back khi đang gửi; Back bình thường = "Về lại" (form giữ nguyên)
      canPop: !isSubmitting,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF4B90E2),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Đối chiếu thông tin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Khung cảnh báo vàng
              _buildWarningCard(model),
              const SizedBox(height: 16),

              // Thẻ 1: Thông tin hệ thống bệnh viện
              _buildInfoCard(
                title: 'Thông tin từ hệ thống bệnh viện',
                titleColor: const Color(0xFF0D6EFD),
                icon: Icons.local_hospital_rounded,
                rows: _buildSystemRows(model),
                buttonLabel: 'Xác nhận đăng ký bằng thông tin hệ thống bệnh viện',
                buttonColor: const Color(0xFF0D6EFD),
                onConfirm: isSubmitting ? null : () => _submit(true),
                isSubmitting: isSubmitting,
              ),
              const SizedBox(height: 16),

              // Thẻ 2: Thông tin người dùng
              _buildInfoCard(
                title: model.isFromSavedProfile
                    ? 'Thông tin từ hồ sơ đã lưu'
                    : 'Thông tin bạn vừa nhập',
                titleColor: const Color(0xFF7C3AED),
                icon: Icons.person_rounded,
                rows: _buildUserRows(model),
                buttonLabel: model.isFromSavedProfile
                    ? 'Xác nhận đăng ký bằng thông tin từ hồ sơ đã lưu'
                    : 'Xác nhận đăng ký bằng thông tin bạn vừa nhập',
                buttonColor: const Color(0xFF7C3AED),
                onConfirm: isSubmitting ? null : () => _submit(false),
                isSubmitting: isSubmitting,
              ),
              const SizedBox(height: 16),

              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (errorMsg.toLowerCase().contains('mạng') || errorMsg.toLowerCase().contains('kết nối'))
                                ? Icons.wifi_off_rounded
                                : ((errorMsg.toLowerCase().contains('quá hạn') || errorMsg.toLowerCase().contains('timeout'))
                                    ? Icons.timer_off_outlined
                                    : Icons.error_outline_rounded),
                            color: const Color(0xFFDC2626),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (errorMsg.toLowerCase().contains('mạng') || errorMsg.toLowerCase().contains('kết nối'))
                                  ? 'Lỗi kết nối mạng'
                                  : ((errorMsg.toLowerCase().contains('quá hạn') || errorMsg.toLowerCase().contains('timeout'))
                                      ? 'Hết thời gian chờ phản hồi'
                                      : 'Lỗi đăng ký đặt lịch'),
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        errorMsg,
                        style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13, height: 1.35),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thông tin bạn đã nhập được bảo lưu an toàn. Bạn có thể chọn xác nhận lại hoặc bấm "Về lại" bên dưới.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],

              // Nút Về lại
              OutlinedButton.icon(
                onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                label: const Text('Về lại thông tin khám'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard(DkkThongTinKhamModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Thông tin có sự khác biệt',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Thông tin bạn nhập khác hồ sơ gốc tại bệnh viện.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF92400E)),
              const SizedBox(width: 4),
              Text(
                'Mã bệnh nhân: ${model.maBN}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFFDE68A), height: 1),
          const SizedBox(height: 10),
          const Text(
            'Các trường khác nhau:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 6),
          ...model.diffSummary.map((item) {
            final (label, userVal, sysVal) = item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF78350F)),
                        children: [
                          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text: userVal.isEmpty ? '(trống)' : userVal,
                            style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' → '),
                          TextSpan(
                            text: sysVal.isEmpty ? '(trống)' : sysVal,
                            style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<_InfoRow> _buildSystemRows(DkkThongTinKhamModel model) => [
        _InfoRow('Số CC/HC', model.systemCccd, false),
        _InfoRow('Ngày cấp', model.systemNgayCap, model.ngayCapDiff),
        _InfoRow('Họ tên', model.systemHoTen, model.hoTenDiff),
        _InfoRow('Ngày sinh', model.systemNgaySinh, model.ngaySinhDiff),
        _InfoRow('Giới tính', model.systemGioiTinh, model.gioiTinhDiff),
        _InfoRow('Điện thoại', model.systemSoDienThoai, model.soDienThoaiDiff),
        _InfoRow('Tỉnh/Thành', model.systemTinhTpTen.isNotEmpty ? model.systemTinhTpTen : model.systemTinhTp, model.tinhTpDiff),
        _InfoRow('Phường/Xã', model.systemPhuongXaTen.isNotEmpty ? model.systemPhuongXaTen : model.systemPhuongXa, model.phuongXaDiff),
      ];

  List<_InfoRow> _buildUserRows(DkkThongTinKhamModel model) => [
        _InfoRow('Số CC/HC', model.userCccd, false),
        _InfoRow('Ngày cấp', model.userNgayCap, model.ngayCapDiff),
        _InfoRow('Họ tên', model.userHoTen, model.hoTenDiff),
        _InfoRow('Ngày sinh', model.userNgaySinh, model.ngaySinhDiff),
        _InfoRow('Giới tính', model.userGioiTinh, model.gioiTinhDiff),
        _InfoRow('Điện thoại', model.userSoDienThoai, model.soDienThoaiDiff),
        _InfoRow('Tỉnh/Thành', model.userTinhTpTen.isNotEmpty ? model.userTinhTpTen : model.userTinhTp, model.tinhTpDiff),
        _InfoRow('Phường/Xã', model.userPhuongXaTen.isNotEmpty ? model.userPhuongXaTen : model.userPhuongXa, model.phuongXaDiff),
      ];

  Widget _buildInfoCard({
    required String title,
    required Color titleColor,
    required IconData icon,
    required List<_InfoRow> rows,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback? onConfirm,
    required bool isSubmitting,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: titleColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: titleColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: rows.map((row) => _buildRow(row)).toList(),
            ),
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRow row) {
    final isDiff = row.isDiff;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              row.label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.value.isNotEmpty ? row.value : '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDiff ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (isDiff) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.circle, size: 8, color: Color(0xFFDC2626)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool isDiff;
  const _InfoRow(this.label, this.value, this.isDiff);
}
