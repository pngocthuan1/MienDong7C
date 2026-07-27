class MedicalTicketEntity {
  const MedicalTicketEntity({
    required this.hospitalName,
    required this.hospitalAddress,
    required this.ticketTitle,
    required this.roomName,
    required this.serviceName,
    required this.queueNumber,
    required this.scheduleText,
    required this.patientName,
    required this.gender,
    required this.birthYear,
    required this.address,
    required this.insuranceText,
    required this.patientCode,
    required this.createdAtText,
    required this.note,
    this.id,
    this.symptom,
    this.phoneNumber,
    this.department,
    this.selectedDate,
    this.selectedTime,
    this.isDeleted = false,
    this.isPast = false,
  });

  final String? id;
  final String hospitalName;
  final String hospitalAddress;
  final String ticketTitle;
  final String roomName;
  final String serviceName;
  final String queueNumber;
  final String scheduleText;
  final String patientName;
  final String gender;
  final String birthYear;
  final String address;
  final String insuranceText;
  final String patientCode;
  final String createdAtText;
  final String note;
  final String? symptom;
  final String? phoneNumber;
  final String? department;
  final String? selectedDate;
  final String? selectedTime;
  final bool isDeleted;
  final bool isPast;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'ticketTitle': ticketTitle,
      'roomName': roomName,
      'serviceName': serviceName,
      'queueNumber': queueNumber,
      'scheduleText': scheduleText,
      'patientName': patientName,
      'gender': gender,
      'birthYear': birthYear,
      'address': address,
      'insuranceText': insuranceText,
      'patientCode': patientCode,
      'createdAtText': createdAtText,
      'note': note,
      'symptom': symptom,
      'phoneNumber': phoneNumber,
      'department': department,
      'selectedDate': selectedDate,
      'selectedTime': selectedTime,
      'isDeleted': isDeleted,
      'isPast': isPast,
    };
  }

  factory MedicalTicketEntity.fromJson(Map<String, dynamic> json) {
    return MedicalTicketEntity(
      id: json['id'] as String?,
      hospitalName: json['hospitalName'] as String? ?? '',
      hospitalAddress: json['hospitalAddress'] as String? ?? '',
      ticketTitle: json['ticketTitle'] as String? ?? '',
      roomName: json['roomName'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      queueNumber: json['queueNumber'] as String? ?? '',
      scheduleText: json['scheduleText'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      birthYear: json['birthYear'] as String? ?? '',
      address: json['address'] as String? ?? '',
      insuranceText: json['insuranceText'] as String? ?? '',
      patientCode: json['patientCode'] as String? ?? '',
      createdAtText: json['createdAtText'] as String? ?? '',
      note: json['note'] as String? ?? '',
      symptom: json['symptom'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      department: json['department'] as String?,
      selectedDate: json['selectedDate'] as String?,
      selectedTime: json['selectedTime'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      isPast: json['isPast'] as bool? ?? false,
    );
  }

  MedicalTicketEntity copyWith({
    String? id,
    String? hospitalName,
    String? hospitalAddress,
    String? ticketTitle,
    String? roomName,
    String? serviceName,
    String? queueNumber,
    String? scheduleText,
    String? patientName,
    String? gender,
    String? birthYear,
    String? address,
    String? insuranceText,
    String? patientCode,
    String? createdAtText,
    String? note,
    String? symptom,
    String? phoneNumber,
    String? department,
    String? selectedDate,
    String? selectedTime,
    bool? isDeleted,
    bool? isPast,
  }) {
    return MedicalTicketEntity(
      id: id ?? this.id,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      ticketTitle: ticketTitle ?? this.ticketTitle,
      roomName: roomName ?? this.roomName,
      serviceName: serviceName ?? this.serviceName,
      queueNumber: queueNumber ?? this.queueNumber,
      scheduleText: scheduleText ?? this.scheduleText,
      patientName: patientName ?? this.patientName,
      gender: gender ?? this.gender,
      birthYear: birthYear ?? this.birthYear,
      address: address ?? this.address,
      insuranceText: insuranceText ?? this.insuranceText,
      patientCode: patientCode ?? this.patientCode,
      createdAtText: createdAtText ?? this.createdAtText,
      note: note ?? this.note,
      symptom: symptom ?? this.symptom,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      isDeleted: isDeleted ?? this.isDeleted,
      isPast: isPast ?? this.isPast,
    );
  }
}
