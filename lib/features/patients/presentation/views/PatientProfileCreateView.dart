import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/utils/Validators.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';
import 'package:benhvien7c/core/widgets/CloudflareTurnstile.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
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
        AppNavigator.replaceNamed(
          context,
          RouteNames.medicalTicket,
          arguments: MedicalTicketViewArgs(ticket: ticket),
        );
      },
      error: (error, message) {
        _viewModel.continueCommand.clearResult();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.error_outline_rounded, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đăng ký không thành công',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF334155)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startCccdScanning(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CccdScannerView(),
      ),
    );

    if (result is CccdData && mounted) {
      _viewModel.fillFromCccd(result);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã nhập thông tin ${result.isBhyt ? "BHYT" : "CCCD"} của ${result.fullName}'),
          backgroundColor: Colors.green,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                  const Text(
                    'Chọn Lịch Khám Bệnh',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Vui lòng chọn ngày khám và khung giờ khám bên dưới',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '1. Chọn Ngày Khám',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final isSelected = _viewModel.selectedDate != null &&
                            _viewModel.selectedDate!.year == date.year &&
                            _viewModel.selectedDate!.month == date.month &&
                            _viewModel.selectedDate!.day == date.day;
                        
                        final weekdayStr = date.weekday == DateTime.monday
                            ? 'Thứ 2'
                            : date.weekday == DateTime.tuesday
                                ? 'Thứ 3'
                                : date.weekday == DateTime.wednesday
                                    ? 'Thứ 4'
                                    : date.weekday == DateTime.thursday
                                        ? 'Thứ 5'
                                        : date.weekday == DateTime.friday
                                            ? 'Thứ 6'
                                            : date.weekday == DateTime.saturday
                                                ? 'Thứ 7'
                                                : 'Chủ nhật';
                        
                        final dateLabel = DateFormat('dd/MM').format(date);
                        
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _viewModel.selectedDate = date;
                              _viewModel.selectedTime = null; // Reset time slot
                            });
                            setState(() {}); // Update view
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEBF3FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  weekdayStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? const Color(0xFF0D6EFD) : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFF0F172A),
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
                            setState(() {}); // Update view
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
                      child: const Text('XÁC NHẬN CHỌN'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AppResponsiveContainer(
          child: Column(
            children: [
              // Custom Header Banner matching layout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F52BA), Color(0xFF0D6EFD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                            onPressed: () => AppNavigator.safePop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'BỆNH VIỆN QUÂN DÂN Y MIỀN ĐÔNG',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Đặt lịch khám bệnh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '50 Lê Văn Việt, P. Hiệp Phú, TP. Thủ Đức',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Form content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
                    children: [
                      // Guidance Banner
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBF3FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD0E3FF)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_rounded, color: Color(0xFF0D6EFD), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Vui lòng điền thông tin có dấu * (bắt buộc). Mã BN: 8 ký tự · Mã BHYT: 10 ký tự · CCCD: 12 ký tự. Chỉ nhận đặt lịch trong tháng hiện tại; ngày/giờ đã qua sẽ tự động ẩn. Nếu đăng ký giúp người khác, hãy điền thông tin người đó vào mục "Đăng ký giúp người khác".',
                                style: TextStyle(
                                  color: const Color(0xFF2C5282),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Saved Profiles List
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: const [
                                Text(
                                  'HỒ SƠ ĐÃ LƯU',
                                  style: TextStyle(
                                    color: Color(0xFF8F9BB3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Expanded(child: Divider(indent: 8, color: Color(0xFFEDF1F7))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_viewModel.savedProfiles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Chưa có hồ sơ nào được lưu. Điền thông tin bên dưới và tick "Lưu hồ sơ này" để dùng lại lần sau.',
                                style: TextStyle(color: Color(0xFF8F9BB3), fontSize: 12),
                              ),
                            )
                          else
                            SizedBox(
                              height: 48,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _viewModel.savedProfiles.length,
                                itemBuilder: (context, index) {
                                  final profile = _viewModel.savedProfiles[index];
                                  final isConfirming = _viewModel.deleteConfirmIdentifier == profile.identifier;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: InputChip(
                                      selected: _viewModel.selectedProfileIdentifier == profile.identifier,
                                      backgroundColor: const Color(0xFFF7F9FC),
                                      selectedColor: const Color(0xFFEBF3FF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: Color(0xFFE4E9F2)),
                                      ),
                                      onPressed: () => _viewModel.selectProfile(profile),
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            profile.gender.toLowerCase() == 'nam' ? Icons.male : Icons.female,
                                            color: const Color(0xFF0D6EFD),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${profile.fullName} · ${profile.birthYear} · ${profile.gender}',
                                            style: const TextStyle(
                                              color: Color(0xFF222B45),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () => _viewModel.requestDeleteProfile(profile.identifier),
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: isConfirming ? Colors.red : Colors.grey[400],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isConfirming ? Icons.check : Icons.close,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Group 1: THÔNG TIN ĐỊNH DANH
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'THÔNG TIN ĐỊNH DANH',
                                  style: TextStyle(
                                    color: Color(0xFF8F9BB3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const Expanded(child: Divider(indent: 8, color: Color(0xFFEDF1F7))),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _startCccdScanning(context),
                                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF0D6EFD)),
                                  label: const Text('Quét CCCD / BHYT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _viewModel.identifierController,
                              label: 'Mã thẻ BHYT / CCCD / Mã BN *',
                              hintText: 'BHYT: 10 ký tự, CCCD: 12 ký tự, Mã BN: 8 ký tự',
                              prefixIcon: Icons.badge_outlined,
                              textInputAction: TextInputAction.next,
                              readOnly: _viewModel.isExistingProfile,
                              onChanged: (_) => _viewModel.refreshFormState(),
                            ),
                            const SizedBox(height: 14),
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _viewModel.birthYearController,
                                    label: 'Năm sinh *',
                                    hintText: '2004',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.cake_outlined,
                                    validator: _viewModel.checkBirthYear,
                                    textInputAction: TextInputAction.next,
                                    readOnly: _viewModel.isExistingProfile,
                                    onChanged: _viewModel.updateBirthYearError,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _viewModel.gender,
                                    decoration: const InputDecoration(
                                      labelText: 'Giới tính *',
                                      prefixIcon: Icon(Icons.wc_rounded),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                                      DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                                    ],
                                    onChanged: _viewModel.isExistingProfile ? null : _viewModel.updateGender,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              controller: _viewModel.phoneController,
                              label: 'Số điện thoại *',
                              hintText: 'Nhập số điện thoại của bạn',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_android_rounded,
                              validator: _viewModel.checkPhone,
                              textInputAction: TextInputAction.done,
                              readOnly: _viewModel.isExistingProfile,
                              onChanged: _viewModel.updatePhoneError,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Group 2: CHỌN LỊCH KHÁM
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'CHỌN LỊCH KHÁM',
                                  style: TextStyle(
                                    color: Color(0xFF8F9BB3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Expanded(child: Divider(indent: 8, color: Color(0xFFEDF1F7))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final validDepartment = _viewModel.departments.contains(_viewModel.selectedDepartment)
                                    ? _viewModel.selectedDepartment
                                    : _viewModel.departments.firstWhere(
                                        (d) => _viewModel.selectedDepartment != null && (d.startsWith(_viewModel.selectedDepartment!) || _viewModel.selectedDepartment!.startsWith(d.split(' ').first)),
                                        orElse: () => _viewModel.departments.first,
                                      );
                                return DropdownButtonFormField<String>(
                                  value: validDepartment,
                                  decoration: const InputDecoration(
                                    labelText: 'Chuyên khoa / Phòng khám *',
                                    prefixIcon: Icon(Icons.local_hospital_outlined),
                                  ),
                                  items: _viewModel.departments.map((dept) {
                                    return DropdownMenuItem(value: dept, child: Text(dept));
                                  }).toList(),
                                  onChanged: _viewModel.updateDepartment,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showDateTimePickerBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F9FC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE4E9F2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Ngày khám *',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
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
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showDateTimePickerBottomSheet,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F9FC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE4E9F2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Giờ khám *',
                                            style: TextStyle(fontSize: 11, color: Colors.grey),
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
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Group 3: THÔNG TIN THÊM
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'THÔNG TIN THÊM',
                                  style: TextStyle(
                                    color: Color(0xFF8F9BB3),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Expanded(child: Divider(indent: 8, color: Color(0xFFEDF1F7))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _viewModel.symptomController,
                              label: 'Triệu chứng',
                              hintText: 'Mô tả ngắn gọn triệu chứng (không bắt buộc)',
                              prefixIcon: Icons.medical_services_outlined,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Checkboxes matching screenshots
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _viewModel.registerForSomeoneElse,
                              onChanged: (val) {
                                setState(() {
                                  _viewModel.registerForSomeoneElse = val ?? false;
                                });
                              },
                              title: const Text('Đăng ký giúp người khác', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Điền thông tin người được giúp đăng ký, nếu có.', style: TextStyle(fontSize: 11)),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF0D6EFD),
                            ),
                            CheckboxListTile(
                              value: _viewModel.saveProfile,
                              onChanged: (val) {
                                setState(() {
                                  _viewModel.saveProfile = val ?? true;
                                });
                              },
                              title: const Text('Lưu hồ sơ này', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Để dùng lại nhanh cho lần đăng ký sau.', style: TextStyle(fontSize: 11)),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF0D6EFD),
                            ),
                          ],
                        ),
                      ),

                      if (_viewModel.registerForSomeoneElse) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'THÔNG TIN NGƯỜI ĐƯỢC GIÚP ĐĂNG KÝ',
                                    style: TextStyle(
                                      color: Color(0xFF8F9BB3),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Expanded(child: Divider(indent: 8, color: Color(0xFFEDF1F7))),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _startCccdScanning(context),
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Color(0xFF0D6EFD)),
                                    label: const Text('Quét CCCD / BHYT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _viewModel.otherFullNameController,
                                label: 'Họ tên người được giúp *',
                                hintText: 'Nhập họ tên đầy đủ',
                                prefixIcon: Icons.person_outline_rounded,
                                validator: _viewModel.checkOtherFullName,
                                textInputAction: TextInputAction.next,
                                readOnly: _viewModel.isExistingProfile,
                                onChanged: _viewModel.updateOtherFullNameError,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _viewModel.otherBirthYearController,
                                      label: 'Năm sinh *',
                                      hintText: 'Nhập năm sinh',
                                      keyboardType: TextInputType.number,
                                      prefixIcon: Icons.cake_outlined,
                                      validator: _viewModel.checkOtherBirthYear,
                                      textInputAction: TextInputAction.next,
                                      readOnly: _viewModel.isExistingProfile,
                                      onChanged: _viewModel.updateOtherBirthYearError,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _viewModel.otherGender,
                                      decoration: const InputDecoration(
                                        labelText: 'Giới tính *',
                                        prefixIcon: Icon(Icons.wc_rounded),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                                        DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                                      ],
                                      onChanged: _viewModel.isExistingProfile
                                          ? null
                                          : (val) {
                                              if (val != null) {
                                                setState(() {
                                                  _viewModel.otherGender = val;
                                                });
                                              }
                                            },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      controller: _viewModel.otherPhoneController,
                                      label: 'Số điện thoại *',
                                      hintText: 'Nhập số điện thoại',
                                      keyboardType: TextInputType.phone,
                                      prefixIcon: Icons.phone_android_rounded,
                                      validator: _viewModel.checkOtherPhone,
                                      textInputAction: TextInputAction.done,
                                      readOnly: _viewModel.isExistingProfile,
                                      onChanged: _viewModel.updateOtherPhoneError,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _viewModel.selectedRelationship,
                                      decoration: const InputDecoration(
                                        labelText: 'Mối quan hệ *',
                                        prefixIcon: Icon(Icons.people_alt_outlined),
                                      ),
                                      items: _viewModel.relationships.map((rel) {
                                        return DropdownMenuItem(value: rel, child: Text(rel));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _viewModel.selectedRelationship = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Cloudflare Security Captcha
                      Center(
                        child: CloudflareTurnstile(
                          onVerified: (token) {
                            setState(() {
                              _captchaToken = token;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListenableBuilder(
                          listenable: _viewModel.continueCommand,
                          builder: (context, __) {
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
                                  padding: const EdgeInsets.symmetric(vertical: 14),
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
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
