class CccdData {
  final String cccdNumber;
  final String fullName;
  final String birthYear;
  final String gender;
  final String address;
  final bool isBhyt;

  const CccdData({
    required this.cccdNumber,
    required this.fullName,
    required this.birthYear,
    required this.gender,
    required this.address,
    this.isBhyt = false,
  });
}

class CccdParserHelper {
  const CccdParserHelper._();

  static CccdData? parse(String rawData) {
    final parts = rawData.split('|');
    if (parts.length >= 7) {
      // 1. Kiểm tra BHYT (độ dài mã thẻ là 15, ngày sinh chứa dấu /)
      if (parts[0].length == 15 && parts[2].contains('/')) {
        final birthDate = parts[2];
        final birthYear = birthDate.substring(birthDate.lastIndexOf('/') + 1);
        final rawGender = parts[3];
        final gender = rawGender == '1' ? 'Nam' : 'Nữ';
        return CccdData(
          cccdNumber: parts[0],
          fullName: parts[1],
          birthYear: birthYear,
          gender: gender,
          address: parts[4],
          isBhyt: true,
        );
      }

      // 2. Kiểm tra CCCD (độ dài mã CCCD là 12)
      if (parts[0].length == 12 && parts[2].isNotEmpty) {
        final birthDate = parts[3];
        String birthYear = '';
        if (birthDate.length == 8) {
          birthYear = birthDate.substring(4); // ddMMyyyy -> yyyy
        } else if (birthDate.length == 4) {
          birthYear = birthDate;
        }
        return CccdData(
          cccdNumber: parts[0],
          fullName: parts[2],
          birthYear: birthYear,
          gender: parts[4],
          address: parts[5],
          isBhyt: false,
        );
      }
    }
    return null;
  }
}
