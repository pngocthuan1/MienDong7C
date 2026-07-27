import 'package:flutter/material.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppButton.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementDetailEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementHistoryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/UserManagementDetailViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/UserManagementStatusChip.dart';

enum _HistoryDateFilterMode { all, day, month, year }

extension _HistoryDateFilterModeLabel on _HistoryDateFilterMode {
  String get label {
    switch (this) {
      case _HistoryDateFilterMode.all:
        return 'Tất cả thời gian';
      case _HistoryDateFilterMode.day:
        return 'Theo ngày';
      case _HistoryDateFilterMode.month:
        return 'Theo tháng';
      case _HistoryDateFilterMode.year:
        return 'Theo năm';
    }
  }
}

class UserManagementDetailView extends StatefulWidget {
  const UserManagementDetailView({required this.args, super.key});

  final UserManagementDetailViewArgs args;

  @override
  State<UserManagementDetailView> createState() =>
      _UserManagementDetailViewState();
}

class _UserManagementDetailViewState extends State<UserManagementDetailView> {
  late final UserManagementDetailViewModel _viewModel;

  UserManagementVisitStatus? _selectedHistoryStatus;
  _HistoryDateFilterMode _dateFilterMode = _HistoryDateFilterMode.all;
  DateTime? _selectedHistoryDate;

  @override
  void initState() {
    super.initState();
    _viewModel = UserManagementDetailViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
      userId: widget.args.userId,
    );

    if (AppLocator.sessionStore.session?.isEmployee ?? false) {
      _viewModel.loadCommand.execute();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  List<UserManagementHistoryEntity> _filterHistories(
    List<UserManagementHistoryEntity> histories,
  ) {
    return histories
        .where((history) {
          final matchesStatus =
              _selectedHistoryStatus == null ||
              history.status == _selectedHistoryStatus;

          final matchesDate = _matchesDateFilter(history);

          return matchesStatus && matchesDate;
        })
        .toList(growable: false);
  }

  Map<UserManagementVisitStatus, int> _buildStatusCountsByDate(
    List<UserManagementHistoryEntity> histories,
  ) {
    final counts = <UserManagementVisitStatus, int>{
      for (final status in UserManagementVisitStatus.values) status: 0,
    };

    for (final history in histories) {
      if (_matchesDateFilter(history)) {
        counts[history.status] = (counts[history.status] ?? 0) + 1;
      }
    }

    return counts;
  }

  bool _matchesDateFilter(UserManagementHistoryEntity history) {
    if (_dateFilterMode == _HistoryDateFilterMode.all) {
      return true;
    }

    final selectedDate = _selectedHistoryDate;
    if (selectedDate == null) {
      return true;
    }

    final historyDate = _extractHistoryDate(history);
    if (historyDate == null) {
      return false;
    }

    switch (_dateFilterMode) {
      case _HistoryDateFilterMode.all:
        return true;

      case _HistoryDateFilterMode.day:
        return historyDate.year == selectedDate.year &&
            historyDate.month == selectedDate.month &&
            historyDate.day == selectedDate.day;

      case _HistoryDateFilterMode.month:
        return historyDate.year == selectedDate.year &&
            historyDate.month == selectedDate.month;

      case _HistoryDateFilterMode.year:
        return historyDate.year == selectedDate.year;
    }
  }

  DateTime? _extractHistoryDate(UserManagementHistoryEntity history) {
    final dateTexts = <String>[
      history.registeredAtText,
      history.appointmentTimeText,
      history.statusUpdatedAtText,
    ];

    for (final text in dateTexts) {
      final parsedDate = _parseDateText(text);
      if (parsedDate != null) {
        return parsedDate;
      }
    }

    return null;
  }

  DateTime? _parseDateText(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }

    final isoDate = DateTime.tryParse(trimmedValue);
    if (isoDate != null) {
      return isoDate;
    }

    final dayMonthYearMatch = RegExp(
      r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})',
    ).firstMatch(trimmedValue);

    if (dayMonthYearMatch != null) {
      final day = int.tryParse(dayMonthYearMatch.group(1) ?? '');
      final month = int.tryParse(dayMonthYearMatch.group(2) ?? '');
      final year = int.tryParse(dayMonthYearMatch.group(3) ?? '');

      return _createValidDate(year: year, month: month, day: day);
    }

    final yearMonthDayMatch = RegExp(
      r'(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})',
    ).firstMatch(trimmedValue);

    if (yearMonthDayMatch != null) {
      final year = int.tryParse(yearMonthDayMatch.group(1) ?? '');
      final month = int.tryParse(yearMonthDayMatch.group(2) ?? '');
      final day = int.tryParse(yearMonthDayMatch.group(3) ?? '');

      return _createValidDate(year: year, month: month, day: day);
    }

    return null;
  }

  DateTime? _createValidDate({
    required int? year,
    required int? month,
    required int? day,
  }) {
    if (year == null || month == null || day == null) {
      return null;
    }

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }

  Future<void> _pickHistoryDate() async {
    final now = DateTime.now();
    final initialDate = _selectedHistoryDate ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: _dateFilterMode == _HistoryDateFilterMode.day
          ? 'Chọn ngày'
          : _dateFilterMode == _HistoryDateFilterMode.month
          ? 'Chọn một ngày trong tháng cần lọc'
          : 'Chọn một ngày trong năm cần lọc',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedHistoryDate = pickedDate;
    });
  }

  void _changeHistoryStatus(UserManagementVisitStatus? status) {
    setState(() {
      _selectedHistoryStatus = status;
    });
  }

  void _changeDateFilterMode(_HistoryDateFilterMode mode) {
    setState(() {
      _dateFilterMode = mode;

      if (mode == _HistoryDateFilterMode.all) {
        _selectedHistoryDate = null;
      }
    });
  }

  void _resetHistoryFilters() {
    setState(() {
      _selectedHistoryStatus = null;
      _dateFilterMode = _HistoryDateFilterMode.all;
      _selectedHistoryDate = null;
    });
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
        final detail = _viewModel.detail;

        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4B90E2),
            foregroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Chi tiết người dùng',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: !session.isEmployee
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: AppButton(
                      label: 'Về trang chủ',
                      icon: Icons.home_rounded,
                      onPressed: () {
                        AppNavigator.replaceAndKeepRoot(
                          context,
                          RouteNames.home,
                        );
                      },
                    ),
                  ),
                )
              : ListenableBuilder(
                  listenable: _viewModel.loadCommand,
                  builder: (context, __) {
                    if (_viewModel.loadCommand.running && detail == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (detail == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _viewModel.message ??
                                'Không tải được chi tiết người dùng.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }

                    final filteredHistories = _filterHistories(
                      detail.histories,
                    );
                    final statusCounts = _buildStatusCountsByDate(
                      detail.histories,
                    );

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      children: [
                        _UserProfileCard(detail: detail),
                        const SizedBox(height: 16),
                        _HistorySummaryCard(
                          detail: detail,
                          selectedStatus: _selectedHistoryStatus,
                          dateFilterMode: _dateFilterMode,
                          selectedDate: _selectedHistoryDate,
                          statusCounts: statusCounts,
                          totalCount: detail.histories.length,
                          filteredCount: filteredHistories.length,
                          onStatusChanged: _changeHistoryStatus,
                          onDateFilterModeChanged: _changeDateFilterMode,
                          onPickDate: _pickHistoryDate,
                          onReset: _resetHistoryFilters,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Lịch sử khám bệnh',
                                style: TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '${filteredHistories.length}/${detail.histories.length} lượt',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (filteredHistories.isEmpty)
                          const _EmptyHistoryPanel()
                        else
                          ...filteredHistories.map((history) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _HistoryCard(history: history),
                            );
                          }),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({required this.detail});

  final UserManagementDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9EAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F3FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  _detailInitials(detail.user.fullName),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.user.fullName,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mã BN: ${detail.user.patientCode}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    UserManagementStatusChip(status: detail.user.currentStatus),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _ProfileInfoLine(
                icon: Icons.phone_rounded,
                label: 'Số điện thoại',
                value: detail.user.phoneNumber,
              ),
              _ProfileInfoLine(
                icon: Icons.email_outlined,
                label: 'Email',
                value: detail.user.email,
              ),
              _ProfileInfoLine(
                icon: Icons.person_outline_rounded,
                label: 'Giới tính - năm sinh',
                value: '${detail.user.gender} • ${detail.user.birthYear}',
              ),
              _ProfileInfoLine(
                icon: Icons.health_and_safety_outlined,
                label: 'Mã BHYT',
                value: detail.insuranceCode,
              ),
              _ProfileInfoLine(
                icon: Icons.place_outlined,
                label: 'Địa chỉ',
                value: detail.address,
              ),
              _ProfileInfoLine(
                icon: Icons.contact_phone_outlined,
                label: 'Liên hệ khẩn',
                value: detail.emergencyContact,
              ),
              _ProfileInfoLine(
                icon: Icons.history_toggle_off_rounded,
                label: 'Tạo hồ sơ từ',
                value: detail.createdAtText,
              ),
              _ProfileInfoLine(
                icon: Icons.local_hospital_outlined,
                label: 'Tổng lượt khám',
                value: '${detail.user.totalVisits}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              detail.note,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoLine extends StatelessWidget {
  const _ProfileInfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.detail,
    required this.selectedStatus,
    required this.dateFilterMode,
    required this.selectedDate,
    required this.statusCounts,
    required this.totalCount,
    required this.filteredCount,
    required this.onStatusChanged,
    required this.onDateFilterModeChanged,
    required this.onPickDate,
    required this.onReset,
  });

  final UserManagementDetailEntity detail;
  final UserManagementVisitStatus? selectedStatus;
  final _HistoryDateFilterMode dateFilterMode;
  final DateTime? selectedDate;
  final Map<UserManagementVisitStatus, int> statusCounts;
  final int totalCount;
  final int filteredCount;
  final ValueChanged<UserManagementVisitStatus?> onStatusChanged;
  final ValueChanged<_HistoryDateFilterMode> onDateFilterModeChanged;
  final VoidCallback onPickDate;
  final VoidCallback onReset;

  static const String _allStatusKey = 'all';

  @override
  Widget build(BuildContext context) {
    final selectedStatusKey = selectedStatus == null
        ? _allStatusKey
        : selectedStatus!.name;

    final hasActiveFilter =
        selectedStatus != null ||
        dateFilterMode != _HistoryDateFilterMode.all ||
        selectedDate != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD9EAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng quan trạng thái',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasActiveFilter)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Đặt lại'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lần gần nhất: ${detail.user.lastVisitText}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey('status-$selectedStatusKey'),
            initialValue: selectedStatusKey,
            isExpanded: true,
            menuMaxHeight: 360,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            decoration: _filterInputDecoration(
              label: 'Bộ lọc trạng thái',
              icon: Icons.filter_alt_rounded,
            ),
            items: [
              DropdownMenuItem<String>(
                value: _allStatusKey,
                child: _FilterDropdownItem(
                  label: 'Tất cả trạng thái',
                  count: statusCounts.values.fold<int>(
                    0,
                    (total, count) => total + count,
                  ),
                ),
              ),
              ...UserManagementVisitStatus.values.map((status) {
                return DropdownMenuItem<String>(
                  value: status.name,
                  child: _FilterDropdownItem(
                    label: status.label,
                    count: statusCounts[status] ?? 0,
                  ),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }

              if (value == _allStatusKey) {
                onStatusChanged(null);
                return;
              }

              final status = UserManagementVisitStatus.values.firstWhere(
                (item) => item.name == value,
              );
              onStatusChanged(status);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_HistoryDateFilterMode>(
            key: ValueKey('date-mode-${dateFilterMode.name}'),
            initialValue: dateFilterMode,
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            decoration: _filterInputDecoration(
              label: 'Lọc theo thời gian',
              icon: Icons.date_range_rounded,
            ),
            items: _HistoryDateFilterMode.values
                .map((mode) {
                  return DropdownMenuItem<_HistoryDateFilterMode>(
                    value: mode,
                    child: Text(
                      mode.label,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                })
                .toList(growable: false),
            onChanged: (mode) {
              if (mode != null) {
                onDateFilterModeChanged(mode);
              }
            },
          ),
          if (dateFilterMode != _HistoryDateFilterMode.all) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onPickDate,
              child: InputDecorator(
                decoration: _filterInputDecoration(
                  label: _datePickerLabel(dateFilterMode),
                  icon: Icons.calendar_month_rounded,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Nhấn để chọn'
                            : _formatSelectedDate(
                                dateFilterMode,
                                selectedDate!,
                              ),
                        style: TextStyle(
                          color: selectedDate == null
                              ? AppColors.textSecondary
                              : AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1ECF8)),
            ),
            child: Text(
              'Đang hiển thị $filteredCount/$totalCount lượt khám',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _filterInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
    );
  }

  String _datePickerLabel(_HistoryDateFilterMode mode) {
    switch (mode) {
      case _HistoryDateFilterMode.all:
        return 'Chọn thời gian';
      case _HistoryDateFilterMode.day:
        return 'Chọn ngày';
      case _HistoryDateFilterMode.month:
        return 'Chọn tháng';
      case _HistoryDateFilterMode.year:
        return 'Chọn năm';
    }
  }

  String _formatSelectedDate(_HistoryDateFilterMode mode, DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    switch (mode) {
      case _HistoryDateFilterMode.all:
        return 'Tất cả thời gian';
      case _HistoryDateFilterMode.day:
        return '$day/$month/${date.year}';
      case _HistoryDateFilterMode.month:
        return 'Tháng $month/${date.year}';
      case _HistoryDateFilterMode.year:
        return 'Năm ${date.year}';
    }
  }
}

class _FilterDropdownItem extends StatelessWidget {
  const _FilterDropdownItem({required this.label, required this.count});

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

class _EmptyHistoryPanel extends StatelessWidget {
  const _EmptyHistoryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBFA)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, color: AppColors.primary, size: 42),
          SizedBox(height: 12),
          Text(
            'Không có lượt khám phù hợp với bộ lọc.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Hãy chọn trạng thái hoặc thời gian khác.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});

  final UserManagementHistoryEntity history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  history.departmentName,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              UserManagementStatusChip(status: history.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _HistoryInfo(label: 'Dịch vụ', value: history.serviceName),
              _HistoryInfo(label: 'Bác sĩ', value: history.doctorName),
              _HistoryInfo(
                label: 'Đăng ký lúc',
                value: history.registeredAtText,
              ),
              _HistoryInfo(
                label: 'Khung giờ khám',
                value: history.appointmentTimeText,
              ),
              _HistoryInfo(
                label: 'Cập nhật trạng thái',
                value: history.statusUpdatedAtText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              history.note,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (history.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD4D4)),
              ),
              child: Text(
                'Lý do từ chối: ${history.rejectionReason}',
                style: const TextStyle(
                  color: Color(0xFFB93434),
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryInfo extends StatelessWidget {
  const _HistoryInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _detailInitials(String fullName) {
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
