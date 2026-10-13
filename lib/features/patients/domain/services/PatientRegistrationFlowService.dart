import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';
import 'package:benhvien7c/features/patients/domain/entities/DkkThongTinKhamModel.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';

/// [TẠM THỜI PHÍA CLIENT] Các quyết định điều phối luồng đăng ký bệnh nhân.
/// Khi Backend hoàn thiện và gom toàn bộ luồng vào 1 API duy nhất, các quyết định này
/// sẽ do Server trực tiếp chỉ định.
sealed class RegistrationDecision {
  const RegistrationDecision();
}

/// Cho phép đăng ký với mã bệnh nhân xác định (mã gốc khi CC/HC không đổi và không diff,
/// hoặc mã tìm thấy từ hệ thống khi CC/HC đổi).
class ProceedDecision extends RegistrationDecision {
  final String effectiveMaBN;
  const ProceedDecision({required this.effectiveMaBN});
}

/// Cho phép đăng ký nhưng không có MaBN (MaBN = ""), Server sẽ tự động cấp mã mới qua cơ chế MaBNAuto.
class ProceedWithAutoMaBN extends RegistrationDecision {
  const ProceedWithAutoMaBN();
}

/// Yêu cầu mở màn hình đối chiếu 2 thẻ (khi CC/HC không đổi và Server trả về HasDiff = true).
class RequireComparisonDecision extends RegistrationDecision {
  final String originMaBN;
  final DkkThongTinKhamModel comparisonModel;
  final DkkKiemTraBenhNhanResponseDto? serverDiff;

  const RequireComparisonDecision({
    required this.originMaBN,
    required this.comparisonModel,
    this.serverDiff,
  });
}

/// Lỗi không thể tiếp tục đăng ký.
class FailureDecision extends RegistrationDecision {
  final String message;
  const FailureDecision(this.message);
}

/// [TẠM THỜI TRÊN APP] Service này đóng vai trò Orchestrator tạm thời để điều phối các nhánh CC/HC và MaBN.
/// Khi Backend nâng cấp xong và gom toàn bộ luồng này vào 1 API duy nhất (Backend-driven), Service này sẽ được tinh giản chỉ còn 1 lệnh gọi API.
class PatientRegistrationFlowService {
  final PortalRepository _portalRepository;

  PatientRegistrationFlowService(this._portalRepository);

  /// Đánh giá và ra quyết định cho luồng đăng ký khám:
  /// 1. Nhánh CC/HC đổi:
  ///    - Gọi ngầm TimBenhNhan(số mới).
  ///    - Tìm thấy hồ sơ -> ProceedDecision(effectiveMaBN: dto.maBN). KHÔNG gửi rỗng, KHÔNG hiện dialog hỏi thừa.
  ///    - Không tìm thấy hồ sơ -> ProceedWithAutoMaBN() (gửi MaBN rỗng, Server tự cấp).
  /// 2. Nhánh CC/HC không đổi:
  ///    - Giữ originMaBN.
  ///    - Gọi KiemTraBenhNhan(requestDto).
  ///    - HasDiff == false -> ProceedDecision(effectiveMaBN: originMaBN).
  ///    - HasDiff == true -> RequireComparisonDecision(originMaBN: originMaBN, ...).
  Future<RegistrationDecision> evaluateRegistration({
    required String currentCccd,
    required String? linkedCccd,
    required String? originMaBN,
    required bool isExistingProfile,
    required PatientProfileDraftEntity userDraft,
    required DkkTimBenhNhanResponseDto? hospitalSnapshot,
    required DangKyKhamRequestDto requestDto,
  }) async {
    final cleanCurrent = currentCccd.trim();
    final cleanLinked = (linkedCccd ?? '').trim();

    // 1. Kiểm tra CC/HC có đổi so với hồ sơ gốc đã liên kết/chọn không
    final bool isCccdChanged = cleanLinked.isNotEmpty &&
        cleanCurrent.toLowerCase() != cleanLinked.toLowerCase();

    // ─────────────────────────────────────────────────────────────
    // NHÁNH 1: SỐ CC/HC BỊ ĐỔI (App tự phát hiện)
    // ─────────────────────────────────────────────────────────────
    if (isCccdChanged) {
      if (cleanCurrent.isEmpty) {
        return const ProceedWithAutoMaBN();
      }

      // Gọi ngầm TimBenhNhan(số mới)
      try {
        final searchResult = await _portalRepository.timBenhNhanByCccdHc(cleanCurrent);
        DkkTimBenhNhanResponseDto? foundDto;
        searchResult.when(
          ok: (dto) => foundDto = dto,
          error: (_, _) {},
        );

        if (foundDto != null && foundDto!.maBN.trim().isNotEmpty) {
          // Trường hợp 1A: Tìm thấy hồ sơ của số mới
          // Dùng đúng MaBN của hồ sơ đó, KHÔNG gửi MaBN rỗng để tránh tạo hồ sơ trùng
          return ProceedDecision(effectiveMaBN: foundDto!.maBN.trim());
        } else {
          // Trường hợp 1B: Không tìm thấy hồ sơ (bệnh nhân mới)
          // Gửi MaBN rỗng, server tự cấp
          return const ProceedWithAutoMaBN();
        }
      } catch (_) {
        // Dự phòng lỗi mạng: cho phép gửi rỗng để server tự cấp
        return const ProceedWithAutoMaBN();
      }
    }

    // ─────────────────────────────────────────────────────────────
    // NHÁNH 2: SỐ CC/HC GIỮ NGUYÊN (Khớp hồ sơ gốc)
    // ─────────────────────────────────────────────────────────────
    final cleanOriginMaBN = (originMaBN ?? '').trim();

    // Nếu hồ sơ chưa có MaBN (ví dụ nhập tay từ đầu) -> Gửi mã rỗng để server cấp
    if (cleanOriginMaBN.isEmpty) {
      return const ProceedWithAutoMaBN();
    }

    // Giữ nguyên originMaBN và gọi KiemTraBenhNhan
    try {
      final checkResult = await _portalRepository.kiemTraBenhNhan(
        requestDto.copyWith(maBN: cleanOriginMaBN),
      );

      DkkKiemTraBenhNhanResponseDto? serverDiff;
      checkResult.when(
        ok: (dto) => serverDiff = dto,
        error: (_, _) {},
      );

      // Nếu server không trả diff hoặc hasDiff == false -> Đăng ký thẳng
      if (serverDiff == null || !serverDiff!.hasDiff) {
        return ProceedDecision(effectiveMaBN: cleanOriginMaBN);
      }

      // Server trả HasDiff == true -> Mở màn hình đối chiếu 2 thẻ
      final snapshot = hospitalSnapshot ??
          DkkTimBenhNhanResponseDto(
            maBN: cleanOriginMaBN,
            maBhytHoacMaBn: cleanCurrent,
            hoTen: userDraft.fullName,
          );

      final comparisonModel = DkkThongTinKhamModel.fromServerCheck(
        system: snapshot,
        user: userDraft,
        isFromSavedProfile: isExistingProfile,
        serverDiff: serverDiff,
      );

      return RequireComparisonDecision(
        originMaBN: cleanOriginMaBN,
        comparisonModel: comparisonModel,
        serverDiff: serverDiff,
      );
    } catch (_) {
      // Khi API kiểm tra gặp lỗi mạng, cho phép tiếp tục đăng ký với originMaBN
      return ProceedDecision(effectiveMaBN: cleanOriginMaBN);
    }
  }
}
