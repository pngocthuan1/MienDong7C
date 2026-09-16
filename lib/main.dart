import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/core/storage/SecureStorageService.dart';
import 'package:benhvien7c/core/theme/AppTheme.dart';
import 'package:benhvien7c/features/auth/data/datasources/AuthRemoteDataSource.dart';
import 'package:benhvien7c/features/auth/data/repositories/AuthRepositoryImpl.dart';
import 'package:benhvien7c/features/auth/presentation/providers/AuthProviders.dart';
import 'package:benhvien7c/features/auth/presentation/views/SplashView.dart';
import 'package:benhvien7c/features/auth/presentation/views/LoginView.dart';
import 'package:benhvien7c/features/auth/presentation/views/RegisterView.dart';
import 'package:benhvien7c/features/auth/presentation/views/ForgotPasswordView.dart';
import 'package:benhvien7c/features/auth/presentation/views/VerifyOtpView.dart';
import 'package:benhvien7c/features/auth/presentation/views/ResetPasswordView.dart';
import 'package:benhvien7c/features/auth/presentation/views/ChangePasswordView.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';

// Patients & Core Session
import 'package:benhvien7c/features/patients/data/datasources/PortalMockDatasource.dart';
import 'package:benhvien7c/features/patients/data/datasources/DatLichKhamRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/data/datasources/ThongBaoRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/data/repositories/PortalRepositoryImpl.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';


// Views
import 'package:benhvien7c/features/patients/presentation/views/HomeView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationDetailView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationRecipientStatusView.dart';
import 'package:benhvien7c/features/patients/presentation/views/NotificationPlaygroundView.dart';
import 'package:benhvien7c/features/patients/presentation/views/AppointmentBookingView.dart';
import 'package:benhvien7c/features/patients/presentation/views/PatientProfileCreateView.dart';
import 'package:benhvien7c/features/patients/presentation/views/PatientProfileSelectView.dart';
import 'package:benhvien7c/features/patients/presentation/views/PersonalProfileView.dart';
import 'package:benhvien7c/features/patients/presentation/views/AboutAppView.dart';
import 'package:benhvien7c/features/patients/presentation/views/DevTestingView.dart';
import 'package:benhvien7c/features/patients/presentation/views/UserManagementView.dart';
import 'package:benhvien7c/features/patients/presentation/views/UserManagementDetailView.dart';
import 'package:benhvien7c/features/patients/presentation/views/TypeFourDemoView.dart';
import 'package:benhvien7c/features/patients/presentation/views/TypeFourProcessingView.dart';
import 'package:benhvien7c/features/patients/presentation/views/TypeFourResultView.dart';
import 'package:benhvien7c/features/patients/presentation/views/MedicalTicketView.dart';
import 'package:benhvien7c/features/patients/presentation/views/CreateNotificationView.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/core/services/FirebaseTokenService.dart';

import 'package:device_info_plus/device_info_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final secureStorage = SecureStorageService();
  final deviceInfoPlugin = DeviceInfoPlugin();

  // 1. Tối ưu khởi tạo song song: Đọc Device ID, SharedPreferences và DeviceInfo đồng thời
  final initResults = await Future.wait([
    secureStorage.getOrCreateDeviceId(),
    SharedPreferences.getInstance(),
    (!kIsWeb && Platform.isAndroid)
        ? deviceInfoPlugin.androidInfo
        : Future<AndroidDeviceInfo?>.value(null),
  ]);

  final deviceId = initResults[0] as String;
  final sharedPreferences = initResults[1] as SharedPreferences;
  final androidInfo = initResults[2] as AndroidDeviceInfo?;

  final isPhysicalDevice = androidInfo?.isPhysicalDevice ?? false;
  final platform = kIsWeb ? 'android' : Platform.operatingSystem;

  String? deviceInfoString;
  if (!kIsWeb && androidInfo != null) {
    deviceInfoString = '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
  }

  // 2. Khởi tạo môi trường ứng dụng
  Environment.init(
    appPackageName: 'com.hospisoft.benhvien7c',
    appVersion: '1.0.30',
    deviceId: deviceId,
    platform: platform,
    isPhysicalDevice: isPhysicalDevice,
  );

  final customBaseUrl = sharedPreferences.getString('custom_base_url');
  if (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) {
    Environment.setCustomBaseUrl(customBaseUrl.trim());
  }

  // 3. Khởi tạo các Service phụ trợ và gán vào AppLocator tĩnh
  final dioClient = DioClient(secureStorage: secureStorage);
  final remoteDataSource = AuthRemoteDataSource(dioClient);
  final authRepository = AuthRepositoryImpl(remoteDataSource, secureStorage);

  final datLichKhamRemoteDataSource = DatLichKhamRemoteDataSource(dioClient);
  final thongBaoRemoteDataSource = ThongBaoRemoteDataSource(dioClient);
  final portalDatasource = PortalMockDatasource();
  final portalRepository = PortalRepositoryImpl(
    portalDatasource,
    datLichKhamRemoteDataSource,
    thongBaoRemoteDataSource,
  );
  final appSessionStore = AppSessionStore.instance;

  AppLocator.init(
    repository: authRepository,
    storage: secureStorage,
    portalRepo: portalRepository,
    session: appSessionStore,
    dio: dioClient,
    prefs: sharedPreferences,
  );

  // 4. Phục hồi session nếu có (giữ đăng nhập khi ứng dụng khởi động lại)
  try {
    // Tự động di chuyển dữ liệu cá nhân (SĐT, Họ tên, Role) từ SharedPreferences cũ sang SecureStorage nếu cần
    await secureStorage.migratePiiFromPreferences(sharedPreferences);

    // Song song hóa các truy vấn SecureStorage độc lập
    final sessionData = await Future.wait([
      secureStorage.getTokensRecord(),
      secureStorage.isRefreshTokenExpired(),
      secureStorage.getExpiresRefreshToken(),
      secureStorage.getSavedPhone(),
      secureStorage.getSavedRole(),
    ]);

    final tokens = sessionData[0] as (String?, String?);
    final isExpired = sessionData[1] as bool;
    final expires = sessionData[2] as String?;
    final securePhone = sessionData[3] as String?;
    final secureRole = sessionData[4] as String?;

    if (tokens.$1 != null && tokens.$2 != null && !isExpired) {
      final expiry = _parseExpiry(expires);

      final savedPhone = (securePhone != null && securePhone.isNotEmpty)
          ? securePhone
          : (sharedPreferences.getString('saved_phone') ?? '');
      final cleanPhone = savedPhone.replaceAll(RegExp(r'\D'), '');

      // Truy vấn tên độc lập theo điều kiện
      final nameResults = await Future.wait([
        secureStorage.getSavedFullName(),
        cleanPhone.isNotEmpty ? secureStorage.getFullNameForPhone(cleanPhone) : Future<String?>.value(null),
      ]);

      final secureName = nameResults[0];
      final phoneFullName = nameResults[1];

      String? savedName = (secureName != null && secureName.isNotEmpty)
          ? secureName
          : (cleanPhone.isNotEmpty
              ? (phoneFullName ?? sharedPreferences.getString('full_name_$cleanPhone'))
              : sharedPreferences.getString('saved_full_name'));

      if (savedPhone.isNotEmpty) {
        final jsonStr = sharedPreferences.getString('saved_my_personal_profile_$savedPhone');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final draftMap = jsonDecode(jsonStr) as Map<String, dynamic>;
            final draftName = draftMap['fullName'] as String?;
            if (draftName != null && draftName.trim().isNotEmpty) {
              savedName = draftName.trim();
            }
          } catch (_) {}
        }
      }

      final savedRoleStr = secureRole ?? sharedPreferences.getString('saved_role');
      final role = (savedRoleStr == 'employee') ? UserRole.employee : UserRole.customer;

      final displayName = (savedName != null && savedName.trim().isNotEmpty)
          ? savedName.trim()
          : (role == UserRole.employee ? 'Nhân viên y tế' : (savedPhone.isNotEmpty ? 'Tài khoản $savedPhone' : 'Khách hàng'));

      appSessionStore.setSession(
        AuthSessionEntity(
          accessToken: tokens.$1!,
          refreshToken: tokens.$2!,
          refreshTokenExpiry: expiry,
        ),
        UserProfileSession(
          fullName: displayName,
          phoneNumber: savedPhone,
          role: role,
        ),
      );
    }
  } catch (e) {
    debugPrint('Lỗi phục hồi session: $e');
  }

  // 5. Khởi chạy UI ngay lập tức với SplashView (logo bệnh viện hoạt họa mượt mà, không giật lag)
  runApp(
    ProviderScope(
      overrides: [
        // Ghi đè sharedPreferencesProvider bằng instance thật đã tải xong
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: const MyApp(initialRoute: RouteNames.splash),
    ),
  );

  // 6. KHỞI TẠO FIREBASE CHẠY NỀN (Unawaited non-blocking background task)
  // Không chặn hàm main, không làm treo ứng dụng trên iOS khi chờ cấp quyền
  unawaited(
    FirebaseTokenService.instance.initialize(
      predefinedDeviceInfo: deviceInfoString,
      prefs: sharedPreferences,
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bệnh viện 7C',
      theme: AppTheme.light(), // Sử dụng cấu hình theme sáng có sẵn trong dự án
      navigatorKey: AppNavigator.navigatorKey, // Đăng ký navigatorKey toàn cục
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'), // Đặt mặc định tiếng Việt cho toàn hệ thống
      initialRoute: initialRoute,
      routes: {
        RouteNames.splash: (context) => const SplashView(),
        RouteNames.login: (context) => const LoginView(),
        RouteNames.home: (context) => const HomeView(),
        RouteNames.forgotPassword: (context) => const ForgotPasswordView(),
        RouteNames.register: (context) => const RegisterView(),
        RouteNames.changePassword: (context) => const ChangePasswordView(),
        RouteNames.notifications: (context) => const NotificationView(),
        RouteNames.notificationPlayground: (context) => const NotificationPlaygroundView(),
        RouteNames.appointmentBooking: (context) => const AppointmentBookingView(),
        RouteNames.patientProfileCreate: (context) => const PatientProfileCreateView(),
        RouteNames.patientProfileSelect: (context) => const PatientProfileSelectView(),
        RouteNames.devTesting: (context) => const DevTestingView(),
        RouteNames.userManagement: (context) => const UserManagementView(),
        RouteNames.typeFourDemo: (context) => const TypeFourDemoView(),
        RouteNames.typeFourProcessing: (context) => const TypeFourProcessingView(),
        RouteNames.typeFourResult: (context) => const TypeFourResultView(),
        RouteNames.createNotification: (context) => const CreateNotificationView(),
        RouteNames.personalProfile: (context) => const PersonalProfileView(),
        RouteNames.aboutApp: (context) => const AboutAppView(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == RouteNames.verifyOtp) {
          final args = settings.arguments as OtpViewArgs;
          return MaterialPageRoute(
            builder: (context) => VerifyOtpView(args: args),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.resetPassword) {
          final args = settings.arguments as ResetPasswordViewArgs;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordView(args: args),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.notificationDetail) {
          final item = settings.arguments as NotificationItemEntity;
          return MaterialPageRoute(
            builder: (context) => NotificationDetailView(item: item),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.notificationRecipientStatus) {
          final item = settings.arguments as NotificationItemEntity;
          return MaterialPageRoute(
            builder: (context) => NotificationRecipientStatusView(item: item),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.userManagementDetail) {
          final args = settings.arguments as UserManagementDetailViewArgs;
          return MaterialPageRoute(
            builder: (context) => UserManagementDetailView(args: args),
            settings: settings,
          );
        }
        if (settings.name == RouteNames.medicalTicket) {
          final args = settings.arguments as MedicalTicketViewArgs;
          return MaterialPageRoute(
            builder: (context) => MedicalTicketView(args: args),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}

DateTime _parseExpiry(String? expiresStr) {
  if (expiresStr == null || expiresStr.isEmpty) {
    return DateTime.now().add(const Duration(days: 1));
  }
  try {
    final parsedIso = DateTime.tryParse(expiresStr);
    if (parsedIso != null) return parsedIso;

    final numVal = int.tryParse(expiresStr);
    if (numVal != null) {
      if (numVal > 600000000000000000) {
        const unixEpochTicks = 621355968000000000;
        final ticksSince1970 = numVal - unixEpochTicks;
        final millisSince1970 = ticksSince1970 ~/ 10000;
        return DateTime.fromMillisecondsSinceEpoch(millisSince1970);
      }
      if (numVal > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal);
      }
      if (numVal > 100000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal * 1000);
      }
    }
  } catch (e) {
    debugPrint('Error parsing refreshTokenExpiry: $e');
  }
  return DateTime.now().add(const Duration(days: 1));
}
