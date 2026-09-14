/// TIỆN ÍCH SO KHỚP VÀ XỬ LÝ CHUỖI TIẾNG VIỆT KHÔNG DẤU
/// Đã được tối ưu hiệu năng tối đa bằng static RegExp để tránh giật lag UI khi tìm kiếm.

final _regexA = RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]');
final _regexAUpper = RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]');
final _regexE = RegExp(r'[èéẹẻẽêềếệểễ]');
final _regexEUpper = RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]');
final _regexI = RegExp(r'[ìíịỉĩ]');
final _regexIUpper = RegExp(r'[ÌÍỊỈĨ]');
final _regexO = RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]');
final _regexOUpper = RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]');
final _regexU = RegExp(r'[ùúụủũưừứựửữ]');
final _regexUUpper = RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]');
final _regexY = RegExp(r'[ỳýỵỷỹ]');
final _regexYUpper = RegExp(r'[ỲÝỴỶỸ]');
final _regexD = RegExp(r'[đ]');
final _regexDUpper = RegExp(r'[Đ]');

String removeVietnameseDiacritics(String str) {
  if (str.isEmpty) return str;
  var result = str;
  result = result.replaceAll(_regexA, 'a');
  result = result.replaceAll(_regexAUpper, 'A');
  result = result.replaceAll(_regexE, 'e');
  result = result.replaceAll(_regexEUpper, 'E');
  result = result.replaceAll(_regexI, 'i');
  result = result.replaceAll(_regexIUpper, 'I');
  result = result.replaceAll(_regexO, 'o');
  result = result.replaceAll(_regexOUpper, 'O');
  result = result.replaceAll(_regexU, 'u');
  result = result.replaceAll(_regexUUpper, 'U');
  result = result.replaceAll(_regexY, 'y');
  result = result.replaceAll(_regexYUpper, 'Y');
  result = result.replaceAll(_regexD, 'd');
  result = result.replaceAll(_regexDUpper, 'D');
  return result;
}
