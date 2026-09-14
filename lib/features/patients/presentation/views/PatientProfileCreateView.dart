import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';
import 'package:benhvien7c/core/widgets/CloudflareTurnstile.dart';
import 'package:benhvien7c/core/widgets/SearchablePickerModal.dart';
import 'package:benhvien7c/core/utils/AddressHelper.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/PatientProfileCreateViewModel.dart';
import 'package:benhvien7c/core/utils/CccdParserHelper.dart';
import 'package:benhvien7c/features/patients/presentation/views/CccdScannerView.dart';

class PatientProfileCreateView extends StatefulWidget {
  const PatientProfileCreateView({super.key});

  @override
  State<PatientProfileCreateView> createState() =>
      _PatientProfileCreateViewState();
}

class _PatientProfileCreateViewState extends State<PatientProfileCreateView> {
  final _formKey = GlobalKey<FormState>();
  late final PatientProfileCreateViewModel _viewModel;
  String? _captchaToken;
  bool _initializedArgs = false;

  @override
  void initState() {
    super.initState();
    _viewModel = PatientProfileCreateViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    _viewModel.continueCommand.addListener(_onContinueChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is MedicalTicketEntity) {
        _viewModel.prefillFromTicket(args);
      }
      _initializedArgs = true;
    }
  }

  Future<void> _selectDateOfBirth(TextEditingController controller, {required bool isOther}) async {
    DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 25));
    if (controller.text.contains('/')) {
      final parts = controller.text.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initial = DateTime(y, m, d);
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        controller.text = formatted;
        if (isOther) {
          _viewModel.otherBirthYearController.text = picked.year.toString();
        } else {
          _viewModel.birthYearController.text = picked.year.toString();
        }
      });
    }
  }

  Future<void> _selectProvince() async {
    final items = _viewModel.provinces
        .map((p) => PickerItem<String>(
              title: p.name,
              subtitle: p.fullName,
              searchKey: p.searchKey,
              value: p.name,
            ))
        .toList();
    final selected = await SearchablePickerModal.show<String>(
      context: context,
      title: 'Chọn Tỉnh / Thành phố',
      items: items,
      selectedItem: _viewModel.provinceController.text,
    );
    if (selected != null) {
      _viewModel.selectProvince(selected);
    }
  }

  Future<void> _selectWard() async {
    final wards = AddressHelper.instance.getWardsForProvince(_viewModel.provinceController.text);
    final items = wards
        .map((w) => PickerItem<String>(
              title: w.name,
              subtitle: w.fullName,
              searchKey: w.searchKey,
              value: w.name,
            ))
        .toList();
    final selected = await SearchablePickerModal.show<String>(
      context: context,
      title: 'Chọn Phường / Xã',
      items: items,
      selectedItem: _viewModel.wardController.text,
    );
    if (selected != null) {
      _viewModel.selectWard(selected);
    }
  }

  Future<void> _selectClinic() async {
    final items = _viewModel.departments
        .map((d) => PickerItem<String>(title: d, value: d))
        .toList();
    final selected = await SearchablePickerModal.show<String>(
      context: context,
      title: 'Chọn Phòng khám',
      items: items,
      selectedItem: _viewModel.clinicController.text.isNotEmpty
          ? _viewModel.clinicController.text
          : _viewModel.selectedDepartment,
    );
    if (selected != null) {
      _viewModel.selectClinic(selected);
    }
  }

  @override
  void dispose() {
    _viewModel.continueCommand.removeListener(_onContinueChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onContinueChanged() {
    if (_viewModel.continueCommand.running) {
      return;
    }

    final result = _viewModel.continueCommand.result;
    if (result == null || !mounted) {
      return;
    }

    result.when(
      ok: (MedicalTicketEntity ticket) {
        _viewModel.continueCommand.clearResult();
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
        AppNavigator.resetToNamed(
          context,
          RouteNames.home,
          arguments: ticket,
        );
      },
      error: (err, _) {
        _viewModel.continueCommand.clearResult();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đặt lịch: ${err.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _startCccdScanning() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CccdScannerView(),
      ),
    );

    if (!mounted) return;

    if (result is CccdData) {
      final addressResult = _viewModel.fillFromCccd(result);
      ScaffoldMessenger.of(context).clearSnackBars();

      String message = 'Đã nhập thông tin ${result.isBhyt ? "BHYT" : "CCCD"} của ${result.fullName}.';
      Color bgColor = const Color(0xFF16A34A);

      if (addressResult.isExactMatch && addressResult.province != null && addressResult.ward != null) {
        message += '\nĐịa chỉ: ${addressResult.ward!.name}, ${addressResult.province!.name}';
      } else if (addressResult.province != null) {
        message += '\nĐã chọn: ${addressResult.province!.name}. Vui lòng chạm chọn Phường/Xã.';
        bgColor = const Color(0xFFD97706);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bgColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _submit() async {
    try {
      FocusScope.of(context).unfocus();
      if (!_formKey.currentState!.validate()) {
        return;
      }
      await _viewModel.continueCommand.execute();
    } catch (_) {}
  }

  void _showDateTimePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dates = _viewModel.getAvailableDates();
            
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFF0D6EFD)),
                        const SizedBox(width: 8),
                        const Text(
                          'Chọn Ngày & Giờ khám',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Chọn Ngày Khám',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 70,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: dates.length,
                        itemBuilder: (context, index) {
                          final date = dates[index];
                          final isSelected = _viewModel.selectedDate != null &&
                              _viewModel.selectedDate!.year == date.year &&
                              _viewModel.selectedDate!.month == date.month &&
                              _viewModel.selectedDate!.day == date.day;

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _viewModel.selectedDate = date;
                                final slots = _viewModel.getSlotsForDate(date);
                                if (slots.isNotEmpty && !slots.contains(_viewModel.selectedTime)) {
                                  _viewModel.selectedTime = slots.first;
                                }
                              });
                              setState(() {});
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('E', 'vi_VN').format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd/MM').format(date),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      '2. Chọn Giờ Khám',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_viewModel.selectedDate == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Vui lòng chọn Ngày khám trước.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    else ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _viewModel.getSlotsForDate(_viewModel.selectedDate!).map((slot) {
                          final isSelected = _viewModel.selectedTime == slot;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                _viewModel.selectedTime = slot;
                              });
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFEBF3FF) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_viewModel.selectedDate != null && _viewModel.selectedTime != null)
                            ? () => Navigator.pop(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D6EFD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Xác nhận chọn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGuidanceBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E3FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF0D6EFD), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, height: 1.3),
                children: [
                  TextSpan(text: 'Vui lòng điền thông tin '),
                  TextSpan(text: 'bắt buộc (*)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  TextSpan(text: '. Số CCCD 12 ký tự, BHYT 10/15 ký tự.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedProfilesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'HỒ SƠ ĐÃ LƯU',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            final selected = await Navigator.pushNamed(
              context,
              RouteNames.patientProfileSelect,
            );
            if (selected is PatientProfileDraftEntity) {
              _viewModel.selectProfile(selected);
            }
          },
          icon: const Icon(Icons.folder_shared_rounded, size: 16, color: Color(0xFF0D6EFD)),
          label: const Text('Danh sách hồ sơ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
        ),
      ],
    );
  }

  Widget _buildSelectedProfileChip() {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 14, color: Color(0xFF0D6EFD)),
          const SizedBox(width: 4),
          Icon(
            _viewModel.gender.toLowerCase() == 'nam' ? Icons.male : Icons.female,
            color: const Color(0xFF0D6EFD),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${_viewModel.fullNameController.text} · ${_viewModel.birthYearController.text} · ${_viewModel.gender}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _viewModel.clearProfileSelection();
              });
            },
            child: const Icon(Icons.cancel, size: 16, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF0D6EFD), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsivePair({
    required Widget child1,
    required Widget child2,
    double spacing = 12,
    double runSpacing = 14,
    double breakpoint = 500,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child1),
              SizedBox(width: spacing),
              Expanded(child: child2),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child1,
              SizedBox(height: runSpacing),
              child2,
            ],
          );
        }
      },
    );
  }

  Widget _buildSummaryCard() {
    final name = _viewModel.fullNameController.text.trim();
    final cccd = _viewModel.identifierController.text.trim();
    final clinic = _viewModel.clinicController.text.trim().isNotEmpty
        ? _viewModel.clinicController.text.trim()
        : (_viewModel.selectedDepartment ?? 'Chưa chọn');
    final dateStr = _viewModel.selectedDate != null
        ? DateFormat('dd/MM/yyyy').format(_viewModel.selectedDate!)
        : 'Chưa chọn';
    final timeStr = _viewModel.selectedTime ?? 'Chưa chọn';
    final addressStr = [
      if (_viewModel.wardController.text.isNotEmpty) _viewModel.wardController.text,
      if (_viewModel.provinceController.text.isNotEmpty) _viewModel.provinceController.text,
    ].join(', ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D6EFD).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF0D6EFD), size: 22),
              SizedBox(width: 8),
              Text(
                'TÓM TẮT THÔNG TIN KHÁM',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          _buildSummaryRow(Icons.person_rounded, 'Bệnh nhân', name.isNotEmpty ? name : 'Chưa nhập'),
          _buildSummaryRow(Icons.badge_rounded, 'Số CCCD', cccd.isNotEmpty ? cccd : 'Chưa nhập'),
          _buildSummaryRow(Icons.local_hospital_rounded, 'Phòng khám', clinic),
          _buildSummaryRow(Icons.event_rounded, 'Lịch khám', '$dateStr ($timeStr)'),
          _buildSummaryRow(Icons.location_on_rounded, 'Địa chỉ', addressStr.isNotEmpty ? addressStr : 'Chưa chọn'),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          ListenableBuilder(
            listenable: _viewModel.continueCommand,
            builder: (context, _) {
              final isCaptchaVerified = _captchaToken != null;
              final canSubmit = _viewModel.canContinue && isCaptchaVerified;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  child: _viewModel.continueCommand.running
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Đăng ký khám',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveContainer(
      maxWidth: double.infinity,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B90E2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Đặt lịch khám bệnh',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGuidanceBanner(),
              _buildSavedProfilesHeader(),
              if (_viewModel.isExistingProfile && _viewModel.selectedProfileIdentifier != null)
                _buildSelectedProfileChip(),
              const SizedBox(height: 8),

              // Card 1: Thông tin cá nhân & CCCD
              _buildCardSection(
                icon: Icons.person_pin_rounded,
                title: '1. Thông tin cá nhân & CCCD',
                trailing: TextButton.icon(
                  onPressed: _viewModel.isExistingProfile ? null : _startCccdScanning,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF0D6EFD)),
                  label: const Text('Quét CCCD / BHYT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                children: [
                  // Hàng 1 (Chia đôi trên màn lớn / Xếp dọc trên màn nhỏ): Số CCCD & Ngày cấp CCCD
                  _buildResponsivePair(
                    child1: AppTextField(
                      controller: _viewModel.identifierController,
                      label: 'Số CCCD *',
                      hintText: 'Nhập 12 số CCCD',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => Validators.validateCccdOrTempCode(v, isOptional: false),
                      textInputAction: TextInputAction.next,
                      readOnly: _viewModel.isExistingProfile,
                      onChanged: (_) => _viewModel.refreshFormState(),
                    ),
                    child2: TextFormField(
                      controller: _viewModel.cccdIssueDateController,
                      keyboardType: TextInputType.datetime,
                      readOnly: _viewModel.isExistingProfile,
                      decoration: InputDecoration(
                        labelText: 'Ngày cấp CCCD',
                        hintText: 'DD/MM/YYYY',
                        filled: _viewModel.isExistingProfile,
                        fillColor: _viewModel.isExistingProfile ? const Color(0xFFF1F5F9) : null,
                        prefixIcon: const Icon(Icons.event_available_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_rounded, size: 18),
                          onPressed: _viewModel.isExistingProfile
                              ? null
                              : () => _selectDateOfBirth(_viewModel.cccdIssueDateController, isOther: false),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => Validators.validateFullDate(v, isRequired: false, fieldName: 'Ngày cấp CCCD'),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hàng 2: Họ tên
                  AppTextField(
                    controller: _viewModel.fullNameController,
                    label: 'Họ tên *',
                    hintText: 'Nhập đầy đủ họ tên',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: _viewModel.checkFullName,
                    textInputAction: TextInputAction.next,
                    readOnly: _viewModel.isExistingProfile,
                    onChanged: _viewModel.updateFullNameError,
                  ),
                  const SizedBox(height: 14),

                  // Hàng 3 (Responsive: Chia đôi trên màn thường / Xếp dọc trên máy nhỏ < 380px): Ngày sinh & Giới tính
                  _buildResponsivePair(
                    breakpoint: 380,
                    child1: TextFormField(
                      controller: _viewModel.dobController,
                      keyboardType: TextInputType.datetime,
                      readOnly: _viewModel.isExistingProfile,
                      decoration: InputDecoration(
                        label: _buildRequiredLabel('Ngày sinh'),
                        hintText: 'DD/MM/YYYY',
                        filled: _viewModel.isExistingProfile,
                        fillColor: _viewModel.isExistingProfile ? const Color(0xFFF1F5F9) : null,
                        prefixIcon: const Icon(Icons.cake_outlined),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today_rounded, size: 18),
                          onPressed: _viewModel.isExistingProfile
                              ? null
                              : () => _selectDateOfBirth(_viewModel.dobController, isOther: false),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => Validators.validateFullDate(v, isRequired: true, fieldName: 'Ngày sinh'),
                    ),
                    child2: DropdownButtonFormField<String>(
                      value: _viewModel.gender,
                      decoration: InputDecoration(
                        label: _buildRequiredLabel('Giới tính'),
                        filled: _viewModel.isExistingProfile,
                        fillColor: _viewModel.isExistingProfile ? const Color(0xFFF1F5F9) : null,
                        prefixIcon: const Icon(Icons.wc_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                      ],
                      onChanged: _viewModel.isExistingProfile ? null : _viewModel.updateGender,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hàng 4: Số điện thoại & Mã bệnh nhân
                  _buildResponsivePair(
                    child1: AppTextField(
                      controller: _viewModel.phoneController,
                      label: 'Số điện thoại',
                      hintText: 'Mặc định theo SĐT tài khoản',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_android_rounded,
                      validator: (v) => Validators.validatePhoneNumber(v, isOptional: true),
                      textInputAction: TextInputAction.next,
                      readOnly: _viewModel.isExistingProfile,
                      onChanged: _viewModel.updatePhoneError,
                    ),
                    child2: AppTextField(
                      controller: _viewModel.patientCodeController,
                      label: 'Mã bệnh nhân (Hệ thống tự cấp)',
                      hintText: '(Tự động cấp khi khám)',
                      prefixIcon: Icons.fingerprint_rounded,
                      textInputAction: TextInputAction.done,
                      readOnly: true,
                      readOnlyMessage: 'Mã bệnh nhân do hệ thống tự động cấp khi tới khám.',
                    ),
                  ),
                ],
              ),

              // Card 2: Địa chỉ cư trú (Chia đôi Tỉnh/Thành & Phường/Xã)
              _buildCardSection(
                icon: Icons.location_on_rounded,
                title: '2. Địa chỉ cư trú',
                children: [
                  _buildResponsivePair(
                    child1: TextFormField(
                      controller: _viewModel.provinceController,
                      readOnly: true,
                      onTap: _viewModel.isExistingProfile ? null : _selectProvince,
                      decoration: InputDecoration(
                        label: _buildRequiredLabel('Tỉnh / Thành phố'),
                        hintText: 'Chọn Tỉnh / Thành phố',
                        filled: _viewModel.isExistingProfile,
                        fillColor: _viewModel.isExistingProfile ? const Color(0xFFF1F5F9) : null,
                        prefixIcon: const Icon(Icons.location_city_rounded),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => Validators.validateRequired(v, fieldName: 'Tỉnh / Thành phố'),
                    ),
                    child2: TextFormField(
                      controller: _viewModel.wardController,
                      readOnly: true,
                      onTap: _viewModel.isExistingProfile ? null : _selectWard,
                      decoration: InputDecoration(
                        label: _buildRequiredLabel('Phường / Xã'),
                        hintText: 'Chọn Phường / Xã',
                        filled: _viewModel.isExistingProfile,
                        fillColor: _viewModel.isExistingProfile ? const Color(0xFFF1F5F9) : null,
                        prefixIcon: const Icon(Icons.map_rounded),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => Validators.validateRequired(v, fieldName: 'Phường / Xã'),
                    ),
                  ),
                ],
              ),

              // Card 3: Chọn lịch & Phòng khám
              _buildCardSection(
                icon: Icons.calendar_month_rounded,
                title: '3. Chọn lịch & Phòng khám',
                children: [
                  // Hàng (Responsive: Chia đôi trên màn thường / Xếp dọc trên máy nhỏ < 380px): Ngày khám & Giờ khám
                  _buildResponsivePair(
                    breakpoint: 380,
                    child1: GestureDetector(
                      onTap: _showDateTimePickerBottomSheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E9F2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Ngày khám', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  TextSpan(text: ' *', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _viewModel.selectedDate == null
                                  ? 'Chọn ngày'
                                  : DateFormat('dd/MM/yyyy').format(_viewModel.selectedDate!),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child2: GestureDetector(
                      onTap: _showDateTimePickerBottomSheet,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4E9F2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Giờ khám', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  TextSpan(text: ' *', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _viewModel.selectedTime ?? 'Chọn giờ',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _selectClinic,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE4E9F2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_hospital_outlined, color: Color(0xFF0D6EFD)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(text: 'Phòng khám', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      TextSpan(text: ' *', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _viewModel.clinicController.text.isNotEmpty
                                      ? _viewModel.clinicController.text
                                      : (_viewModel.selectedDepartment ?? 'Chọn Phòng khám'),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _viewModel.symptomController,
                    label: 'Triệu chứng',
                    hintText: 'Mô tả ngắn gọn triệu chứng (không bắt buộc)',
                    prefixIcon: Icons.medical_services_outlined,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),

              // Captcha
              Center(
                child: CloudflareTurnstile(
                  onVerified: (token) {
                    setState(() {
                      _captchaToken = token;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              _buildSummaryCard(),
            ],
          ),
        ),
      ),
    );
  }
}
