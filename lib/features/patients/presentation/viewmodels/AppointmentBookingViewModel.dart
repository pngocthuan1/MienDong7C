import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

class AppointmentBookingViewModel extends BasePortalViewModel {
  AppointmentBookingViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore) {
    loadTicketsCommand = Command0<List<MedicalTicketEntity>>(_loadTickets);
    loadTicketsCommand.execute();
  }

  late final Command0<List<MedicalTicketEntity>> loadTicketsCommand;
  List<MedicalTicketEntity> allTickets = [];

  List<MedicalTicketEntity> get activeTickets => allTickets.where((t) => !t.isDeleted).toList();
  List<MedicalTicketEntity> get upcomingTickets => allTickets.where((t) => !t.isDeleted && !t.isPast).toList();
  List<MedicalTicketEntity> get passedTickets => allTickets.where((t) => !t.isDeleted && t.isPast).toList();
  List<MedicalTicketEntity> get deletedTickets => allTickets.where((t) => t.isDeleted).toList();

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
