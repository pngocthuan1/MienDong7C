import 'package:benhvien7c/core/network/ErrorCode.dart';

class ApiResponseDto<T> {
  final String? errorId;
  final int errorCodeValue;
  final T? data;
  final dynamic extraData;
  final String? errorMessage;
  final dynamic serverSetting;

  ApiResponseDto({
    this.errorId,
    required this.errorCodeValue,
    this.data,
    this.extraData,
    this.errorMessage,
    this.serverSetting,
  });

  bool get isSuccess => errorCodeValue == 0 || errorCode.isSuccess;

  ErrorCode get errorCode => ErrorCode.fromValue(errorCodeValue);

  String get displayMessage {
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return errorMessage!.trim();
    }
    return errorCode.message;
  }

  factory ApiResponseDto.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? dataParser,
  ]) {
    final rawErrorCode = (json['ErrorCode'] as num?)?.toInt() ??
        (json['errorCode'] as num?)?.toInt() ??
        0;

    dynamic rawData = json['Data'] ?? json['data'];
    T? parsedData;
    if (rawData != null && dataParser != null) {
      parsedData = dataParser(rawData);
    } else if (rawData is T) {
      parsedData = rawData;
    }

    return ApiResponseDto<T>(
      errorId: json['ErrorId']?.toString() ?? json['errorId']?.toString(),
      errorCodeValue: rawErrorCode,
      data: parsedData,
      extraData: json['ExtraData'] ?? json['extraData'],
      errorMessage: json['ErrorMessage']?.toString() ?? json['errorMessage']?.toString(),
      serverSetting: json['ServerSetting'] ?? json['serverSetting'],
    );
  }
}
