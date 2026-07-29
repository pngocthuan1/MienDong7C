import 'package:benhvien7c/core/viewmodels/BaseViewModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';

class MedicalTicketViewModel extends BaseViewModel {
  MedicalTicketViewModel(this.ticket);

  final MedicalTicketEntity ticket;

  Future<void> deleteTicket() async {
    if (ticket.id != null && ticket.id!.isNotEmpty) {
      await AppLocator.portalRepository.softDeleteMedicalTicket(ticket.id!);
    }
  }
}
