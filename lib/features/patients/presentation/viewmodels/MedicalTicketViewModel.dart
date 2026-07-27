import 'package:benhvien7c/core/viewmodels/BaseViewModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

class MedicalTicketViewModel extends BaseViewModel {
  MedicalTicketViewModel(this.ticket);

  final MedicalTicketEntity ticket;
}
