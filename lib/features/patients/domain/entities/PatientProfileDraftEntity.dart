class PatientProfileDraftEntity {
  const PatientProfileDraftEntity({
    required this.identifier,
    required this.fullName,
    required this.birthYear,
    required this.gender,
    required this.phoneNumber,
    this.dateOfBirth,
    this.cccdIssueDate,
    this.province,
    this.ward,
    this.clinic,
    this.maThe,
    this.maSo,
    this.maHS,
    this.maBN,
    this.dangKyGiup,
    this.idTinh,
    this.idPhuong,
    this.isDeleted = false,
  });

  final String identifier;
  final String fullName;
  final String birthYear;
  final String gender;
  final String phoneNumber;
  final String? dateOfBirth;
  final String? cccdIssueDate;
  final String? province;
  final String? ward;
  final String? clinic;
  final String? maThe;
  final String? maSo;
  final String? maHS;
  final String? maBN;
  final String? dangKyGiup;
  final dynamic idTinh;
  final dynamic idPhuong;
  final bool isDeleted;

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'fullName': fullName,
      'birthYear': birthYear,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth,
      'cccdIssueDate': cccdIssueDate,
      'province': province,
      'ward': ward,
      'clinic': clinic,
      'maThe': maThe,
      'maSo': maSo,
      'maHS': maHS,
      'maBN': maBN,
      'dangKyGiup': dangKyGiup,
      'idTinh': idTinh,
      'idPhuong': idPhuong,
      'isDeleted': isDeleted,
    };
  }

  factory PatientProfileDraftEntity.fromJson(Map<String, dynamic> json) {
    return PatientProfileDraftEntity(
      identifier: json['identifier'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      birthYear: json['birthYear'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] as String?,
      cccdIssueDate: json['cccdIssueDate'] as String?,
      province: json['province'] as String?,
      ward: json['ward'] as String?,
      clinic: json['clinic'] as String?,
      maThe: json['maThe'] as String?,
      maSo: json['maSo'] as String?,
      maHS: json['maHS'] as String?,
      maBN: json['maBN'] as String?,
      dangKyGiup: json['dangKyGiup'] as String?,
      idTinh: json['idTinh'],
      idPhuong: json['idPhuong'],
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  PatientProfileDraftEntity copyWith({

    String? identifier,
    String? fullName,
    String? birthYear,
    String? gender,
    String? phoneNumber,
    String? dateOfBirth,
    String? cccdIssueDate,
    String? province,
    String? ward,
    String? clinic,
    String? maThe,
    String? maSo,
    String? maHS,
    String? maBN,
    String? dangKyGiup,
    dynamic idTinh,
    dynamic idPhuong,
    bool? isDeleted,
  }) {
    return PatientProfileDraftEntity(
      identifier: identifier ?? this.identifier,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      cccdIssueDate: cccdIssueDate ?? this.cccdIssueDate,
      province: province ?? this.province,
      ward: ward ?? this.ward,
      clinic: clinic ?? this.clinic,
      maThe: maThe ?? this.maThe,
      maSo: maSo ?? this.maSo,
      maHS: maHS ?? this.maHS,
      maBN: maBN ?? this.maBN,
      dangKyGiup: dangKyGiup ?? this.dangKyGiup,
      idTinh: idTinh ?? this.idTinh,
      idPhuong: idPhuong ?? this.idPhuong,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
