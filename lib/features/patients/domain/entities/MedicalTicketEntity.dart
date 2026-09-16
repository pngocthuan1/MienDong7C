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
    this.dangKyGiup,
    this.dateOfBirth,
    this.province,
    this.ward,
    this.clinic,
    this.isDeleted = false,
    bool isPast = false,
  }) : _isPastExplicit = isPast;

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
  final String? dangKyGiup;
  final String? dateOfBirth;
  final String? province;
  final String? ward;
  final String? clinic;
  final bool isDeleted;
  final bool _isPastExplicit;

  bool get isToday {
    final d = parsedTicketDate;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool get isPast {
    if (_isPastExplicit) return true;
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final clean = scheduleText.trim();
      final parts = clean.split(' ');
      if (parts.isNotEmpty) {
        final dateStr = parts[0].replaceAll(',', '').trim();
        final dateParts = dateStr.split('/');
        if (dateParts.length == 3) {
          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);

          final ticketDate = DateTime(year, month, day);
          if (ticketDate.isBefore(today)) return true;

          if (ticketDate.isAtSameMomentAs(today) && parts.length >= 2) {
            final timeStr = parts[1].replaceAll('g', ':').replaceAll('h', ':').trim();
            final timeParts = timeStr.split(':');
            if (timeParts.isNotEmpty) {
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final min = timeParts.length >= 2 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
              final ticketTime = DateTime(year, month, day, hour, min);
              return ticketTime.isBefore(now);
            }
          }
        }
      }
    } catch (_) {}
    return _isPastExplicit;
  }

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
      'dangKyGiup': dangKyGiup,
      'dateOfBirth': dateOfBirth,
      'province': province,
      'ward': ward,
      'clinic': clinic,
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
      dangKyGiup: json['dangKyGiup'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      province: json['province'] as String?,
      ward: json['ward'] as String?,
      clinic: json['clinic'] as String?,
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
    String? dangKyGiup,
    String? dateOfBirth,
    String? province,
    String? ward,
    String? clinic,
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
      dangKyGiup: dangKyGiup ?? this.dangKyGiup,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      province: province ?? this.province,
      ward: ward ?? this.ward,
      clinic: clinic ?? this.clinic,
      isDeleted: isDeleted ?? this.isDeleted,
      isPast: isPast ?? this.isPast,
    );
  }

  DateTime? get parsedTicketDate {
    if (selectedDate != null && selectedDate!.trim().isNotEmpty) {
      final d = _tryParseDate(selectedDate!);
      if (d != null) return d;
    }
    if (scheduleText.trim().isNotEmpty) {
      final d = _tryParseDate(scheduleText);
      if (d != null) return d;
    }
    if (createdAtText.trim().isNotEmpty) {
      final d = _tryParseDate(createdAtText);
      if (d != null) return d;
    }
    return null;
  }

  static DateTime? _tryParseDate(String raw) {
    try {
      final clean = raw.trim();
      final isoParsed = DateTime.tryParse(clean);
      if (isoParsed != null) return isoParsed;

      final parts = clean.split(RegExp(r'\s+'));
      for (final p in parts) {
        final dateClean = p.replaceAll(',', '').trim();
        final slashParts = dateClean.split('/');
        if (slashParts.length == 3) {
          final day = int.tryParse(slashParts[0]);
          final month = int.tryParse(slashParts[1]);
          final year = int.tryParse(slashParts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
        final dashParts = dateClean.split('-');
        if (dashParts.length == 3) {
          if (dashParts[0].length == 4) {
            final year = int.tryParse(dashParts[0]);
            final month = int.tryParse(dashParts[1]);
            final day = int.tryParse(dashParts[2]);
            if (day != null && month != null && year != null) {
              return DateTime(year, month, day);
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
