import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/data/datasources/ThongBaoRemoteDataSource.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/RecipientEntity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

enum RecipientSubFilter { all, selected, unselected }

enum AddAttachmentResult {
  success,
  exceedsFileCount,
  exceedsFileSize,
  exceedsTotalImageSize,
  cannotMixImageAndDocument,
}

class BatchAttachmentResult {
  final int addedCount;
  final int rejectedSizeCount;
  final int rejectedDocCount;
  final int addedSizeBytes;
  final bool isMixedAttempt;

  const BatchAttachmentResult({
    required this.addedCount,
    required this.rejectedSizeCount,
    required this.rejectedDocCount,
    required this.addedSizeBytes,
    this.isMixedAttempt = false,
  });
}

class ConsolidatedApiPayload {
  final bool isSingleFile;
  final bool isMultiImage;
  final List<String> filePaths;
  final String summary;
  final int totalSizeBytes;

  const ConsolidatedApiPayload({
    required this.isSingleFile,
    required this.isMultiImage,
    required this.filePaths,
    required this.summary,
    required this.totalSizeBytes,
  });

  String get formattedTotalSize {
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

class NotificationAttachmentModel {
  final String id;
  final String fileName;
  final String path;
  final int sizeBytes;
  final bool isImage;
  final String extension;
  final bool isCompressed;

  const NotificationAttachmentModel({
    required this.id,
    required this.fileName,
    required this.path,
    required this.sizeBytes,
    required this.isImage,
    required this.extension,
    this.isCompressed = false,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class CreateNotificationViewModel extends BasePortalViewModel {
  static const int maxTotalImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxSingleFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// 1 TRONG 2: true = Đang chọn Tệp tài liệu
  bool get isDocumentMode => documentAttachments.isNotEmpty;

  /// 1 TRONG 2: true = Đang chọn Hình ảnh
  bool get isImageMode => imageAttachments.isNotEmpty;

  /// Tổng dung lượng danh sách ảnh hiện tại (bytes)
  int get totalImageSizeBytes =>
      imageAttachments.fold(0, (sum, a) => sum + a.sizeBytes);

  /// Chuỗi hiển thị tổng dung lượng ảnh
  String get formattedTotalImageSize {
    final mb = (totalImageSizeBytes / (1024 * 1024)).toStringAsFixed(2);
    return '$mb MB / 5.0 MB';
  }

  /// Tỷ lệ dung lượng ảnh đã dùng (0.0 -> 1.0)
  double get totalImageSizeProgress {
    final progress = totalImageSizeBytes / maxTotalImageSizeBytes;
    return progress.clamp(0.0, 1.0);
  }

  CreateNotificationViewModel(
    super.repository,
    super.sessionStore,
  ) {
    // TODO: 'Lê Nguyễn Gia Hưng' đang được dùng làm tên người gửi MẶC ĐỊNH
    // khi session.user.fullName rỗng. Nếu đây không phải giá trị test còn
    // sót lại, cân nhắc đổi thành thông điệp trung tính hơn (ví dụ: tên
    // phòng ban gửi, hoặc chặn gửi thông báo nếu chưa xác định được người
    // gửi) — tránh hiển thị nhầm tên 1 cá nhân cụ thể trong thông báo thật
    // gửi tới toàn bộ nhân viên.
    senderName = session.user.fullName.isNotEmpty ? session.user.fullName : 'Lê Nguyễn Gia Hưng';
    senderDepartment = 'Hệ thống thông báo nội bộ';

    expandedGroupIds.add('group_cntt');

    sendNotificationCommand = Command0<NotificationItemEntity>(_sendNotification);

    contentController.addListener(_onContentChanged);
    searchController.addListener(_onSearchChanged);
  }

  void refreshUI() {
    notifyIfMounted();
  }

  // Active Tab Index: 0 = Nội dung, 1 = Nơi nhận
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;
  set activeTabIndex(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    notifyIfMounted();
  }

  // --- TAB 1: NỘI DUNG ---
  late String senderName;
  late String senderDepartment;

  final contentController = TextEditingController();
  final List<NotificationAttachmentModel> attachments = [];

  List<NotificationAttachmentModel> get imageAttachments =>
      attachments.where((a) => a.isImage).toList();

  List<NotificationAttachmentModel> get documentAttachments =>
      attachments.where((a) => !a.isImage).toList();

  void _onContentChanged() {
    notifyIfMounted();
  }

  // --- THÔNG SỐ SỐ THÔNG BÁO THEO THÁNG & TỰ ĐỘNG ĐỔI TÊN FILE ---
  int _notificationNumber = 19;
  int get notificationNumber => _notificationNumber;

  String get formattedNotificationNumber {
    if (_notificationNumber < 10) {
      return '0$_notificationNumber';
    }
    return '$_notificationNumber';
  }

  Future<void> initNotificationNumber() async {
    try {
      final now = DateTime.now();
      final monthKey = 'notif_seq_${now.year}_${now.month.toString().padLeft(2, '0')}';
      final prefs = await SharedPreferences.getInstance();

      int currentSeq = prefs.getInt(monthKey) ?? 19;
      _notificationNumber = currentSeq;
      notifyIfMounted();
    } catch (e) {
      // Log lại thay vì nuốt im lặng — nếu SharedPreferences lỗi,
      // _notificationNumber giữ giá trị mặc định 19 mà không ai biết
      // vì sao, gây khó debug khi số thứ tự thông báo bị sai lệch.
      if (kDebugMode) {
        debugPrint('[CreateNotificationViewModel] initNotificationNumber failed: $e');
      }
    }
  }

  /// Thêm tệp chọn thực tế (Tự động đổi tên theo số thông báo 01.pdf, 01.doc...)
  AddAttachmentResult addRealPickedAttachment({
    required String fileName,
    required String filePath,
    required int sizeBytes,
  }) {
    final rawExt = fileName.contains('.') ? fileName.split('.').last : '';
    final ext = rawExt.toLowerCase();
    final isImg = ['jpg', 'jpeg', 'png', 'bmp', 'webp', 'heic'].contains(ext);

    // Ràng buộc "1 trong 2": không cho trộn ảnh và tài liệu trong cùng
    // 1 thông báo. Trước đây chỉ addRealCameraPhoto() kiểm tra điều này,
    // còn hàm này (dùng khi chọn file thủ công từ thư viện) bị thiếu check
    // — khiến người dùng có thể vô tình thêm cả ảnh lẫn PDF, nhưng
    // prepareApiPayload() chỉ lấy 1 trong 2 loại, làm rơi mất file đã chọn
    // mà không có cảnh báo gì.
    if (isImg && isDocumentMode) {
      return AddAttachmentResult.cannotMixImageAndDocument;
    }
    if (!isImg && isImageMode) {
      return AddAttachmentResult.cannotMixImageAndDocument;
    }

    if (sizeBytes > maxSingleFileSizeBytes) {
      return AddAttachmentResult.exceedsFileSize;
    }

    // Giới hạn tổng dung lượng ảnh (5MB) — trước đây chỉ được check ở
    // addRealCameraPhoto(), không được check ở đây, nên chọn nhiều ảnh
    // từ thư viện có thể vượt quá tổng cho phép mà không bị chặn.
    if (isImg && totalImageSizeBytes + sizeBytes > maxTotalImageSizeBytes) {
      return AddAttachmentResult.exceedsTotalImageSize;
    }

    // TỰ ĐỘNG ĐỔI TÊN FILE THEO SỐ THÔNG BÁO (ví dụ: 19.PDF hoặc 19.DOCX)
    final formattedExt = rawExt.isNotEmpty ? rawExt.toUpperCase() : 'PDF';
    final autoRenamedFileName = '$formattedNotificationNumber.$formattedExt';

    final id = 'REAL_${DateTime.now().millisecondsSinceEpoch}_${attachments.length}';
    attachments.add(NotificationAttachmentModel(
      id: id,
      fileName: autoRenamedFileName,
      path: filePath,
      sizeBytes: sizeBytes,
      isImage: isImg,
      extension: ext,
      isCompressed: isImg && sizeBytes < 500 * 1024,
    ));
    notifyIfMounted();
    return AddAttachmentResult.success;
  }

  /// Thêm danh sách tệp đính kèm hàng loạt (Tính toán dung lượng thời gian thực)
  BatchAttachmentResult addRealPickedAttachmentBatch(
    List<({String fileName, String filePath, int sizeBytes})> fileItems,
  ) {
    int addedCount = 0;
    int rejectedSizeCount = 0;
    int rejectedDocCount = 0;
    int addedSizeBytes = 0;
    bool mixedAttempt = false;

    for (final item in fileItems) {
      final res = addRealPickedAttachment(
        fileName: item.fileName,
        filePath: item.filePath,
        sizeBytes: item.sizeBytes,
      );

      if (res == AddAttachmentResult.success) {
        addedCount++;
        addedSizeBytes += item.sizeBytes;
      } else if (res == AddAttachmentResult.exceedsTotalImageSize || res == AddAttachmentResult.exceedsFileSize) {
        rejectedSizeCount++;
      } else if (res == AddAttachmentResult.exceedsFileCount) {
        rejectedDocCount++;
      } else if (res == AddAttachmentResult.cannotMixImageAndDocument) {
        mixedAttempt = true;
      }
    }

    return BatchAttachmentResult(
      addedCount: addedCount,
      rejectedSizeCount: rejectedSizeCount,
      rejectedDocCount: rejectedDocCount,
      addedSizeBytes: addedSizeBytes,
      isMixedAttempt: mixedAttempt,
    );
  }

  /// Thêm ảnh chụp camera thực tế (Không cho phép nếu đang đính kèm tệp tài liệu)
  AddAttachmentResult addRealCameraPhoto({
    required String fileName,
    required String filePath,
    required int sizeBytes,
  }) {
    if (isDocumentMode) {
      return AddAttachmentResult.cannotMixImageAndDocument;
    }

    if (totalImageSizeBytes + sizeBytes > maxTotalImageSizeBytes) {
      return AddAttachmentResult.exceedsTotalImageSize;
    }

    final id = 'CAM_${DateTime.now().millisecondsSinceEpoch}_${attachments.length}';
    attachments.add(NotificationAttachmentModel(
      id: id,
      fileName: fileName,
      path: filePath,
      sizeBytes: sizeBytes,
      isImage: true,
      extension: 'jpg',
      isCompressed: true,
    ));
    notifyIfMounted();
    return AddAttachmentResult.success;
  }

  /// Nén ảnh chụp giả lập < 500KB
  NotificationAttachmentModel addCompressedCameraPhoto() {
    final timestamp = DateTime.now().millisecondsSinceEpoch % 10000;
    final jpgFileName = 'IMG_7C_CAMERA_$timestamp.jpg';
    final compressedSize = (220 + (timestamp % 150)) * 1024;

    final attachment = NotificationAttachmentModel(
      id: 'CAM_$timestamp',
      fileName: jpgFileName,
      path: '/camera/$jpgFileName',
      sizeBytes: compressedSize,
      isImage: true,
      extension: 'jpg',
      isCompressed: true,
    );

    attachments.add(attachment);
    notifyIfMounted();
    return attachment;
  }

  /// Ghép tất cả ảnh đính kèm hoặc tệp thành 1 Dữ Liệu Payload API duy nhất để lưu CSDL sau này
  ConsolidatedApiPayload? prepareApiPayload() {
    if (attachments.isEmpty) return null;

    if (isDocumentMode) {
      final doc = documentAttachments.first;
      return ConsolidatedApiPayload(
        isSingleFile: true,
        isMultiImage: false,
        filePaths: [doc.path],
        summary: '1 Tệp tài liệu [${doc.fileName}] (${doc.formattedSize})',
        totalSizeBytes: doc.sizeBytes,
      );
    }

    if (isImageMode) {
      final paths = imageAttachments.map((a) => a.path).toList();
      return ConsolidatedApiPayload(
        isSingleFile: imageAttachments.length == 1,
        isMultiImage: imageAttachments.length > 1,
        filePaths: paths,
        summary: '${imageAttachments.length} Hình ảnh đính kèm (Tổng dung lượng API: $formattedTotalImageSize)',
        totalSizeBytes: totalImageSizeBytes,
      );
    }

    return null;
  }

  void removeAttachmentById(String id) {
    attachments.removeWhere((a) => a.id == id);
    notifyIfMounted();
  }

  // --- TAB 2: NƠI NHẬN ---
  String _targetMode = 'all'; // Mặc định là 'all' (Tất cả)
  String get targetMode => _targetMode;
  void setTargetMode(String mode) {
    if (_targetMode == mode) return;
    _targetMode = mode;
    _subFilter = RecipientSubFilter.all; // Mặc định chuyển sang tab 'Tất cả' để hiển thị đầy đủ danh sách nhóm!
    notifyIfMounted();
  }

  RecipientSubFilter _subFilter = RecipientSubFilter.all;
  RecipientSubFilter get subFilter => _subFilter;
  void setSubFilter(RecipientSubFilter filter) {
    if (_subFilter == filter) return;
    _subFilter = filter;
    notifyIfMounted();
  }

  final searchController = TextEditingController();
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void _onSearchChanged() {
    _searchQuery = searchController.text.trim().toLowerCase();
    notifyIfMounted();
  }

  final Set<String> selectedGroupIds = {};
  final Set<String> selectedMemberIds = {};
  final Set<String> expandedGroupIds = {};

  bool isGroupExpanded(String groupId) => expandedGroupIds.contains(groupId);

  void toggleGroupExpand(String groupId) {
    if (expandedGroupIds.contains(groupId)) {
      expandedGroupIds.remove(groupId);
    } else {
      expandedGroupIds.add(groupId);
    }
    notifyIfMounted();
  }

  bool isGroupSelected(RecipientGroup group) => selectedGroupIds.contains(group.id);

  // TODO: luôn trả về false — checkbox 3 trạng thái ("chọn 1 phần thành
  // viên trong nhóm") dường như chưa được implement. Nếu UI có hiển thị
  // trạng thái này, cần bổ sung logic so sánh selectedMemberIds với
  // group.members. Nếu không dùng, cân nhắc xóa hàm này cho gọn.
  bool isGroupPartiallySelected(RecipientGroup group) => false;

  void toggleGroupSelect(RecipientGroup group) {
    if (selectedGroupIds.contains(group.id)) {
      selectedGroupIds.remove(group.id);
    } else {
      selectedGroupIds.add(group.id);
    }
    notifyIfMounted();
  }

  void selectAll() {
    for (final group in recipientGroups) {
      selectedGroupIds.add(group.id);
    }
    notifyIfMounted();
  }

  void deselectAll() {
    selectedGroupIds.clear();
    notifyIfMounted();
  }

  int get totalSelectedCount {
    if (_targetMode == 'all') return totalRecipientCount;

    // Nếu người dùng tích chọn nhóm "Tất cả", hiển thị tổng số cá nhân chuẩn
    for (final group in recipientGroups) {
      if (selectedGroupIds.contains(group.id)) {
        if (group.name.toLowerCase().trim() == 'tất cả' || group.id == 'nhom_1') {
          return totalRecipientCount;
        }
      }
    }

    final Set<String> uniqueUserIds = {};
    for (final group in recipientGroups) {
      if (selectedGroupIds.contains(group.id)) {
        for (final m in group.members) {
          uniqueUserIds.add(m.id.trim().toLowerCase());
        }
      }
    }
    return uniqueUserIds.length;
  }

  List<String> get selectedNoiNhanIds {
    if (_targetMode == 'all' || (selectedGroupIds.isEmpty && selectedMemberIds.isEmpty)) {
      return [];
    }
    final List<String> noiNhanList = [];

    for (final group in recipientGroups) {
      if (selectedGroupIds.contains(group.id)) {
        final rawId = group.id.startsWith('nhom_') ? group.id.substring(5) : group.id;
        if (rawId.isNotEmpty && rawId != '1') {
          noiNhanList.add(rawId);
        }
      }
    }

    for (final mId in selectedMemberIds) {
      final cleanId = mId.trim();
      if (cleanId.isNotEmpty) {
        noiNhanList.add(';$cleanId');
      }
    }

    return noiNhanList;
  }

  List<String> get selectedRecipientNames {
    if (_targetMode == 'all' || selectedGroupIds.isEmpty) {
      return ['Tất cả nhân viên'];
    }
    final List<String> names = [];
    for (final group in recipientGroups) {
      if (selectedGroupIds.contains(group.id)) {
        names.add(group.name);
      }
    }
    return names.isNotEmpty ? names : ['Tất cả nhân viên'];
  }

  final List<RecipientGroup> recipientGroups = [];

  // TODO: 626 là số nhân viên hardcode dùng làm giá trị FALLBACK khi API
  // loadListMasterFromApi() thất bại hoặc trả về danh sách rỗng. Nếu số
  // nhân viên thực tế đã thay đổi kể từ khi giá trị này được viết, người
  // dùng sẽ thấy số liệu "Tất cả nhân viên" SAI mà không có cảnh báo nào
  // cho biết đây là dữ liệu fallback, không phải số liệu thời gian thực.
  // Cân nhắc: (1) cập nhật định kỳ giá trị này, hoặc (2) hiển thị cảnh
  // báo rõ ràng cho người dùng khi đang dùng fallback thay vì dữ liệu API.
  int _totalUniqueUsersCount = 626;

  int get totalRecipientCount => _totalUniqueUsersCount > 0 ? _totalUniqueUsersCount : 626;

  dynamic _extractKey(Map<String, dynamic> map, List<String> candidates) {
    for (final key in map.keys) {
      for (final cand in candidates) {
        if (key.toLowerCase() == cand.toLowerCase()) {
          return map[key];
        }
      }
    }
    return null;
  }

  Future<void> loadListMasterFromApi() async {
    try {
      final dioClient = AppLocator.dioClient;
      final ds = ThongBaoRemoteDataSource(dioClient);
      final data = await ds.fetchListMaster();

      final rawListNoiNhan = _extractKey(data, ['ListNoiNhan', 'listNoiNhan', 'noiNhan']);
      final rawListNhom = _extractKey(data, ['ListNhom', 'listNhom', 'nhom']);

      final listNoiNhan = (rawListNoiNhan is List) ? rawListNoiNhan : [];
      final listNhom = (rawListNhom is List) ? rawListNhom : [];

      // 1. Ánh xạ toàn bộ danh sách cá nhân chuẩn từ ListNoiNhan theo UserId / Ma / Username
      final Map<String, RecipientMember> memberMap = {};
      final Map<String, RecipientMember> uniqueUserMap = {};

      for (final item in listNoiNhan) {
        if (item is! Map<String, dynamic>) continue;
        final userId = _extractKey(item, ['UserId', 'userId', 'Id', 'id'])?.toString() ?? '';
        final ma = _extractKey(item, ['Ma', 'ma', 'Code', 'code'])?.toString() ?? '';
        final username = _extractKey(item, ['TenDangNhap', 'tenDangNhap', 'Username', 'username'])?.toString() ?? '';

        final primaryKey = userId.isNotEmpty ? userId : (ma.isNotEmpty ? ma : username);
        if (primaryKey.isEmpty) continue;

        final name = _extractKey(item, ['Ten', 'ten', 'HoTen', 'hoTen', 'Name'])?.toString() ?? 'Thành viên';
        final departmentName = _extractKey(item, ['Nhom', 'nhom', 'PhongBan', 'phongBan'])?.toString() ?? '';
        final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(3).join().toUpperCase();

        final member = RecipientMember(
          id: primaryKey,
          name: name,
          initials: initials.isNotEmpty ? initials : 'TV',
          departmentName: departmentName,
        );

        uniqueUserMap[primaryKey.trim().toLowerCase()] = member;

        if (userId.isNotEmpty) memberMap[userId.trim().toLowerCase()] = member;
        if (ma.isNotEmpty) memberMap[ma.trim().toLowerCase()] = member;
        if (username.isNotEmpty) memberMap[username.trim().toLowerCase()] = member;
      }

      _totalUniqueUsersCount = uniqueUserMap.isNotEmpty ? uniqueUserMap.length : 626;

      final List<RecipientGroup> loadedGroups = [];

      // 2. Dựng các Nhóm từ ListNhom chuẩn theo danh sách nhân viên
      for (final nhomItem in listNhom) {
        if (nhomItem is! Map<String, dynamic>) continue;
        final gId = _extractKey(nhomItem, ['id', 'Id', 'ID'])?.toString() ?? '';
        final gName = _extractKey(nhomItem, ['ten', 'Ten', 'Name'])?.toString() ?? 'Nhóm';
        final rawMemberIds = _extractKey(nhomItem, ['ListThanhVienId', 'listThanhVienId', 'ThanhVienId', 'Members']);
        final memberIdList = (rawMemberIds is List) ? rawMemberIds.map((e) => e.toString()).toList() : <String>[];

        final List<RecipientMember> groupMembers = [];

        // Nếu là nhóm "Tất cả" (hoặc id = 1), gán toàn bộ nhân viên chuẩn
        if (gName.toLowerCase().trim() == 'tất cả' || gId == '1') {
          groupMembers.addAll(uniqueUserMap.values);
        } else {
          for (final mId in memberIdList) {
            final cleanId = mId.trim().toLowerCase();
            if (memberMap.containsKey(cleanId)) {
              groupMembers.add(memberMap[cleanId]!);
            } else {
              final initials = mId.split('_').map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();
              groupMembers.add(RecipientMember(
                id: mId,
                name: mId,
                initials: initials.isNotEmpty ? initials : 'TV',
                departmentName: gName,
              ));
            }
          }
        }

        final gInitials = gName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

        loadedGroups.add(RecipientGroup(
          id: 'nhom_$gId',
          name: gName,
          initials: gInitials.isNotEmpty ? gInitials : 'NH',
          totalCount: groupMembers.length,
          members: groupMembers,
        ));
      }

      if (loadedGroups.isNotEmpty) {
        recipientGroups.clear();
        recipientGroups.addAll(loadedGroups);
        notifyIfMounted();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Exception loading ListMaster: $e');
      }
    }
  }

  List<RecipientGroup> get filteredRecipientGroups {
    if (_searchQuery.isEmpty && _subFilter == RecipientSubFilter.all) {
      return recipientGroups;
    }

    return recipientGroups.where((group) {
      final matchesGroupName = group.name.toLowerCase().contains(_searchQuery);
      final isSelected = selectedGroupIds.contains(group.id);

      if (_subFilter == RecipientSubFilter.selected && !isSelected) return false;
      if (_subFilter == RecipientSubFilter.unselected && isSelected) return false;
      if (_searchQuery.isNotEmpty && !matchesGroupName) {
        final matchesMember = group.members.any((m) => m.name.toLowerCase().contains(_searchQuery));
        if (!matchesMember) return false;
      }

      return true;
    }).toList();
  }

  // SEND COMMAND
  late final Command0<NotificationItemEntity> sendNotificationCommand;

  bool get canSend {
    return contentController.text.trim().isNotEmpty;
  }

  Future<Result<NotificationItemEntity>> _sendNotification() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      return Error(Exception('EmptyContent'), 'Vui lòng nhập nội dung thông báo');
    }

    final attachmentNames = attachments.map((a) => a.fileName).toList();
    final attachmentPaths = attachments.map((a) => a.path).toList();

    return runSafely(() async {
      final result = await portalRepository.createNotification(
        role: session.user.role,
        content: content,
        attachments: attachmentNames,
        attachmentPaths: attachmentPaths,
        targetMode: _targetMode,
        recipientIds: selectedNoiNhanIds,
        recipientNames: selectedRecipientNames,
        senderName: senderName,
        senderDepartment: senderDepartment,
      );

      if (result is Ok<NotificationItemEntity>) {
        try {
          final now = DateTime.now();
          final monthKey = 'notif_seq_${now.year}_${now.month.toString().padLeft(2, '0')}';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(monthKey, _notificationNumber + 1);
          _notificationNumber += 1;
          notifyIfMounted();
        } catch (e) {
          // Log lại thay vì nuốt im lặng — nếu lưu số thứ tự thất bại,
          // lần gửi thông báo tiếp theo có thể dùng lại đúng số cũ,
          // gây trùng tên file tự động đổi tên (ví dụ 2 file cùng "19.pdf").
          if (kDebugMode) {
            debugPrint('[CreateNotificationViewModel] persist notificationNumber failed: $e');
          }
        }
      }

      return result;
    });
  }

  @override
  void dispose() {
    contentController.dispose();
    searchController.dispose();
    sendNotificationCommand.dispose();
    super.dispose();
  }
}