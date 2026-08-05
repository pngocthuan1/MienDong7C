class PatientProfileDraftEntity {
  const PatientProfileDraftEntity({
    required this.identifier,
    required this.fullName,
    required this.birthYear,
    required this.gender,
    required this.phoneNumber,
    this.maSo,
    this.dangKyGiup,
    this.isDeleted = false,
  });

  final String identifier;
  final String fullName;
  final String birthYear;
  final String gender;
  final String phoneNumber;
  final String? maSo;
  final String? dangKyGiup;
  final bool isDeleted;

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'fullName': fullName,
      'birthYear': birthYear,
      'gender': gender,
      'phoneNumber': phoneNumber,
      'maSo': maSo,
      'dangKyGiup': dangKyGiup,
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
      maSo: json['maSo'] as String?,
      dangKyGiup: json['dangKyGiup'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  PatientProfileDraftEntity copyWith({
    String? identifier,
    String? fullName,
    String? birthYear,
    String? gender,
    String? phoneNumber,
    String? maSo,
    String? dangKyGiup,
    bool? isDeleted,
  }) {
    return PatientProfileDraftEntity(
      identifier: identifier ?? this.identifier,
      fullName: fullName ?? this.fullName,
      birthYear: birthYear ?? this.birthYear,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      maSo: maSo ?? this.maSo,
      dangKyGiup: dangKyGiup ?? this.dangKyGiup,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
