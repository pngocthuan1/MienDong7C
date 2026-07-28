import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

enum TicketDateFilterMode { all, today, thisWeek, thisMonth }

class AppointmentBookingViewModel extends BasePortalViewModel {
  AppointmentBookingViewModel(
    super.repository,
    super.sessionStore,
  ) {
    loadTicketsCommand = Command0<List<MedicalTicketEntity>>(_loadTickets);
    loadTicketsCommand.execute();
  }

  late final Command0<List<MedicalTicketEntity>> loadTicketsCommand;
  List<MedicalTicketEntity> allTickets = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  TicketDateFilterMode _dateFilterMode = TicketDateFilterMode.all;
  TicketDateFilterMode get dateFilterMode => _dateFilterMode;

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setDateFilterMode(TicketDateFilterMode mode) {
    _dateFilterMode = mode;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _dateFilterMode = TicketDateFilterMode.all;
    notifyListeners();
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
    if (_dateFilterMode != TicketDateFilterMode.all && ticket.selectedDate != null) {
      try {
        final parts = ticket.selectedDate!.split('/');
        if (parts.length == 3) {
          final ticketDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          if (_dateFilterMode == TicketDateFilterMode.today) {
            if (ticketDate.year != today.year || ticketDate.month != today.month || ticketDate.day != today.day) {
              return false;
            }
          } else if (_dateFilterMode == TicketDateFilterMode.thisWeek) {
            final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
            if (ticketDate.isBefore(startOfWeek) || ticketDate.isAfter(endOfWeek)) {
              return false;
            }
          } else if (_dateFilterMode == TicketDateFilterMode.thisMonth) {
            if (ticketDate.year != today.year || ticketDate.month != today.month) {
              return false;
            }
          }
        }
      } catch (_) {}
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
      result.when(
        ok: (tickets) {
          allTickets = tickets;
          clearMessage();
          notifyListeners();
        },
        error: (_, message) {
          setMessage(message);
        },
      );
      return result;
    });
  }

  Future<void> softDeleteTicket(String id) async {
    await portalRepository.softDeleteMedicalTicket(id);
    loadTicketsCommand.execute();
  }

  Future<void> restoreTicket(String id) async {
    await portalRepository.restoreMedicalTicket(id);
    loadTicketsCommand.execute();
  }

  @override
  void dispose() {
    loadTicketsCommand.dispose();
    super.dispose();
  }
}
