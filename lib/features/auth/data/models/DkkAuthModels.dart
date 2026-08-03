class DkkSignUpRequestModel {
  final String soDienThoai;
  final String matKhau;
  final String hoTen;
  final String otp;
  final String key;
  final int adjustSeconds;

  DkkSignUpRequestModel({
    required this.soDienThoai,
    required this.matKhau,
    required this.hoTen,
    required this.otp,
    required this.key,
    required this.adjustSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'SoDienThoai': soDienThoai,
      'MatKhau': matKhau,
      'HoTen': hoTen,
      'Otp': otp,
      'Key': key,
      'AdjustSeconds': adjustSeconds,
    };
  }
}

class DkkResetPasswordRequestModel {
  final String soDienThoai;
  final String matKhau;
  final String otp;
  final String key;
  final int adjustSeconds;

  DkkResetPasswordRequestModel({
    required this.soDienThoai,
    required this.matKhau,
    required this.otp,
    required this.key,
    required this.adjustSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'SoDienThoai': soDienThoai,
      'MatKhau': matKhau,
      'Otp': otp,
      'Key': key,
      'AdjustSeconds': adjustSeconds,
    };
  }
}

class OtpSendInputModel {
  final String soDienThoai;
  final String key;
  final String transactionId;
  final String sendType;

  OtpSendInputModel({
    required this.soDienThoai,
    required this.key,
    this.transactionId = '',
    this.sendType = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'SoDienThoai': soDienThoai,
      'Key': key,
      'TransactionId': transactionId,
      'SendType': sendType,
    };
  }
}

class SendOtpResponseModel {
  final String createdTimeUtc;
  final int adjustSeconds;
  final int remainingSeconds;
  final String? debugOtpCode;
  final String? transactionId;
  final String? message;

  SendOtpResponseModel({
    required this.createdTimeUtc,
    required this.adjustSeconds,
    required this.remainingSeconds,
    this.debugOtpCode,
    this.transactionId,
    this.message,
  });

  factory SendOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseModel(
      createdTimeUtc: json['CreatedTimeUtc']?.toString() ?? '',
      adjustSeconds: (json['AdjustSeconds'] as num?)?.toInt() ?? 0,
      remainingSeconds: (json['RemainingSeconds'] as num?)?.toInt() ?? 0,
      debugOtpCode: json['DebugOtpCode']?.toString(),
      transactionId: json['transactionid']?.toString() ?? json['TransactionId']?.toString(),
      message: json['Message']?.toString(),
    );
  }
}

class OtpVerifyInputModel {
  final String soDienThoai;
  final String otp;
  final String key;
  final int adjustSeconds;

  OtpVerifyInputModel({
    required this.soDienThoai,
    required this.otp,
    required this.key,
    required this.adjustSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'SoDienThoai': soDienThoai,
      'Otp': otp,
      'Key': key,
      'AdjustSeconds': adjustSeconds,
    };
  }
}

class ChangePasswordRequestModel {
  final String matKhauCu;
  final String matKhauMoi;
  final String nhapLaiMatKhauMoi;

  ChangePasswordRequestModel({
    required this.matKhauCu,
    required this.matKhauMoi,
    required this.nhapLaiMatKhauMoi,
  });

  Map<String, dynamic> toJson() {
    return {
      'MatKhauCu': matKhauCu,
      'MatKhauMoi': matKhauMoi,
      'NhapLaiMatKhauMoi': nhapLaiMatKhauMoi,
    };
  }
}
