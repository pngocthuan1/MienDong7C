import 'dart:convert';
import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

enum TicketDateFilterMode { all, today, thisWeek, thisMonth }

class AppointmentBookingViewModel extends BasePortalViewModel {
  AppointmentBookingViewModel(
    super.repository,
    super.sessionStore,
  ) {
    loadTicketsCommand = Command0<List<MedicalTicketEntity>>(_loadTickets);
    // Stale-While-Revalidate: hiển thị cache ngay → fetch server ngầm để cập nhật
    _loadCachedTickets();
    loadTicketsCommand.execute();
  }

  late final Command0<List<MedicalTicketEntity>> loadTicketsCommand;
  List<MedicalTicketEntity> allTickets = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  TicketDateFilterMode _dateFilterMode = TicketDateFilterMode.all;
  TicketDateFilterMode get dateFilterMode => _dateFilterMode;

  bool _isMutating = false;
  bool get isMutating => _isMutating;

  static const String _cacheKeyPrefix = 'cached_tickets_v1_';

  /// Đọc cache tickets từ SharedPreferences sync (không await).
  /// Gọi ngay trong constructor → người dùng thấy danh sách ngay lập tức
  /// trong khi fetch server đang chạy ngầm.
  void _loadCachedTickets() {
    try {
      final phone = session.user.phoneNumber;
      if (phone.isEmpty) return;
      final prefs = AppLocator.sharedPreferences;
      final raw = prefs.getString('$_cacheKeyPrefix$phone');
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      allTickets = list
          .map((e) => MedicalTicketEntity.fromJson(e as Map<String, dynamic>))
          .toList();
      // Không gọi notifyListeners() ở đây — constructor chưa xong,
      // frame đầu tiên sẽ build với allTickets đã có sẵn dữ liệu
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyIfMounted();
  }

  void setDateFilterMode(TicketDateFilterMode mode) {
    _dateFilterMode = mode;
    notifyIfMounted();
  }

  void clearFilters() {
    _searchQuery = '';
    _dateFilterMode = TicketDateFilterMode.all;
    notifyIfMounted();
  }

  bool _matchesFilter(MedicalTicketEntity ticket) {
    // 1. Search Query filter
    if (_searchQuery.isNotEmpty) {
      final matchName = ticket.patientName.toLowerCase().contains(_searchQuery);
      final matchCode = ticket.patientCode.toLowerCase().contains(_searchQuery);
      final matchRoom = ticket.roomName.toLowerCase().contains(_searchQuery);
      final matchService = ticket.serviceName.toLowerCase().contains(_searchQuery);
      final matchSchedule = ticket.scheduleText.toLowerCase().contains(_searchQuery);
      final matchSymptom = ticket.symptom?.toLowerCase().contains(_searchQuery) ?? false;
      final matchDept = ticket.department?.toLowerCase().contains(_searchQuery) ?? false;

      if (!matchName && !matchCode && !matchRoom && !matchService && !matchSchedule && !matchSymptom && !matchDept) {
        return false;
      }
    }

    // 2. Date Filter
    if (_dateFilterMode != TicketDateFilterMode.all) {
      final ticketDate = ticket.parsedTicketDate;
      if (ticketDate == null) return false;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tDateOnly = DateTime(ticketDate.year, ticketDate.month, ticketDate.day);

      if (_dateFilterMode == TicketDateFilterMode.today) {
        if (tDateOnly.year != today.year || tDateOnly.month != today.month || tDateOnly.day != today.day) {
          return false;
        }
      } else if (_dateFilterMode == TicketDateFilterMode.thisWeek) {
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        if (tDateOnly.isBefore(monday) || tDateOnly.isAfter(sunday)) {
          return false;
        }
      } else if (_dateFilterMode == TicketDateFilterMode.thisMonth) {
        if (tDateOnly.year != today.year || tDateOnly.month != today.month) {
          return false;
        }
      }
    }

    return true;
  }

  List<MedicalTicketEntity> get activeTickets => allTickets.where((t) => !t.isDeleted).toList();
  List<MedicalTicketEntity> get upcomingTickets => allTickets.where((t) => !t.isDeleted && !t.isPast).toList();
  List<MedicalTicketEntity> get passedTickets => allTickets.where((t) => !t.isDeleted && t.isPast).toList();
  List<MedicalTicketEntity> get deletedTickets => allTickets.where((t) => t.isDeleted).toList();

  List<MedicalTicketEntity> get filteredActiveTickets => activeTickets.where(_matchesFilter).toList();
  List<MedicalTicketEntity> get filteredUpcomingTickets => upcomingTickets.where(_matchesFilter).toList();
  List<MedicalTicketEntity> get filteredPassedTickets => passedTickets.where(_matchesFilter).toList();
  List<MedicalTicketEntity> get filteredDeletedTickets => deletedTickets.where(_matchesFilter).toList();

  bool get hasActiveFilter => _searchQuery.isNotEmpty || _dateFilterMode != TicketDateFilterMode.all;

  Future<Result<List<MedicalTicketEntity>>> _loadTickets() async {
    return runSafely(() async {
      final result = await portalRepository.loadMedicalTickets(role);
      if(isDisposed) return result;
      result.when(
        ok: (tickets) {
          if(isDisposed) return result;
          allTickets = tickets;
          clearMessage();
        },
        error: (_, message) {
          setMessage(message);
        },
      );
      return result;
    });
  }

  Future<void> softDeleteTicket(String id) async {
     if (_isMutating) return;
    _isMutating = true;
    notifyIfMounted();
    try {
      await portalRepository.softDeleteMedicalTicket(id);
      await loadTicketsCommand.execute();

    } catch (e) {
      setMessage('Xóa lịch hẹn thất bại. Vui lòng thử lại.');
    } finally {
      _isMutating = false;
      notifyIfMounted();
    }
  }

  Future<void> restoreTicket(String id) async {
    if (_isMutating) return;
    _isMutating = true;
    notifyIfMounted();
    try {
      await portalRepository.restoreMedicalTicket(id);
      await loadTicketsCommand.execute();
    } catch (e) {
      setMessage('Khôi phục lịch hẹn thất bại. Vui lòng thử lại.');
    } finally {
      _isMutating = false;
      notifyIfMounted();
    }
  }

  @override
  void dispose() {
    loadTicketsCommand.dispose();
    super.dispose();
  }
}
