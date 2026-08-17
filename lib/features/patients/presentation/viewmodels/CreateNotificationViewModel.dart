import 'package:flutter/material.dart';
import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/RecipientEntity.dart';
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
    senderName = session.user.fullName.isNotEmpty ? session.user.fullName : 'Lê Nguyễn Gia Hưng';
    senderDepartment = 'Hệ thống thông báo nội bộ';

    selectedMemberIds.addAll(['cntt_1', 'cntt_2']);
    expandedGroupIds.add('group_cntt');

    sendNotificationCommand = Command0<NotificationItemEntity>(_sendNotification);

    contentController.addListener(_onContentChanged);
    searchController.addListener(_onSearchChanged);
  }

  // Active Tab Index: 0 = Nội dung, 1 = Nơi nhận
  int _activeTabIndex = 0;
  int get activeTabIndex => _activeTabIndex;
  set activeTabIndex(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    notifyListeners();
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
    notifyListeners();
  }

  /// Thêm tệp chọn thực tế (Chỉ chọn 1 TỆP HOẶC NHIỀU ẢNH, không trộn lẫn)
  AddAttachmentResult addRealPickedAttachment({
    required String fileName,
    required String filePath,
    required int sizeBytes,
  }) {
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    final isImg = ['jpg', 'jpeg', 'png', 'bmp', 'webp', 'heic'].contains(ext);

    // Quy tắc 1 TRONG 2: Không cho trộn tệp tài liệu và ảnh
    if (isImg && isDocumentMode) {
      return AddAttachmentResult.cannotMixImageAndDocument;
    }
    if (!isImg && isImageMode) {
      return AddAttachmentResult.cannotMixImageAndDocument;
    }

    if (isImg) {
      if (totalImageSizeBytes + sizeBytes > maxTotalImageSizeBytes) {
        return AddAttachmentResult.exceedsTotalImageSize;
      }
    } else {
      if (documentAttachments.isNotEmpty) {
        return AddAttachmentResult.exceedsFileCount;
      }
      if (sizeBytes > maxSingleFileSizeBytes) {
        return AddAttachmentResult.exceedsFileSize;
      }
    }

    final id = 'REAL_${DateTime.now().millisecondsSinceEpoch}_${attachments.length}';
    attachments.add(NotificationAttachmentModel(
      id: id,
      fileName: fileName,
      path: filePath,
      sizeBytes: sizeBytes,
      isImage: isImg,
      extension: ext,
      isCompressed: isImg && sizeBytes < 500 * 1024,
    ));
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
  }

  // --- TAB 2: NƠI NHẬN ---
  String _targetMode = 'custom'; // 'custom' (Tùy chọn) hoặc 'all' (Tất cả)
  String get targetMode => _targetMode;
  void setTargetMode(String mode) {
    if (_targetMode == mode) return;
    _targetMode = mode;
    notifyListeners();
  }

  RecipientSubFilter _subFilter = RecipientSubFilter.all;
  RecipientSubFilter get subFilter => _subFilter;
  void setSubFilter(RecipientSubFilter filter) {
    if (_subFilter == filter) return;
    _subFilter = filter;
    notifyListeners();
  }

  final searchController = TextEditingController();
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void _onSearchChanged() {
    _searchQuery = searchController.text.trim().toLowerCase();
    notifyListeners();
  }

  final Set<String> selectedMemberIds = {};
  final Set<String> expandedGroupIds = {};

  bool isGroupExpanded(String groupId) => expandedGroupIds.contains(groupId);

  void toggleGroupExpand(String groupId) {
    if (expandedGroupIds.contains(groupId)) {
      expandedGroupIds.remove(groupId);
    } else {
      expandedGroupIds.add(groupId);
    }
    notifyListeners();
  }

  bool isMemberSelected(String memberId) => selectedMemberIds.contains(memberId);

  void toggleMember(String memberId) {
    if (selectedMemberIds.contains(memberId)) {
      selectedMemberIds.remove(memberId);
    } else {
      selectedMemberIds.add(memberId);
    }
    notifyListeners();
  }

  bool isGroupSelected(RecipientGroup group) {
    if (group.members.isEmpty) return false;
    return group.members.every((m) => selectedMemberIds.contains(m.id));
  }

  bool isGroupPartiallySelected(RecipientGroup group) {
    if (group.members.isEmpty) return false;
    final selectedCount = group.members.where((m) => selectedMemberIds.contains(m.id)).length;
    return selectedCount > 0 && selectedCount < group.members.length;
  }

  void toggleGroupSelect(RecipientGroup group) {
    if (isGroupSelected(group)) {
      for (final m in group.members) {
        selectedMemberIds.remove(m.id);
      }
    } else {
      for (final m in group.members) {
        selectedMemberIds.add(m.id);
      }
    }
    notifyListeners();
  }

  void selectAll() {
    for (final group in recipientGroups) {
      for (final m in group.members) {
        selectedMemberIds.add(m.id);
      }
    }
    notifyListeners();
  }

  void deselectAll() {
    selectedMemberIds.clear();
    notifyListeners();
  }

  int get totalSelectedCount {
    if (_targetMode == 'all') return totalRecipientCount;
    return selectedMemberIds.length;
  }

  int get totalRecipientCount => 577;

  // Mock Groups matching Screenshot 2
  final List<RecipientGroup> recipientGroups = const [
    RecipientGroup(
      id: 'group_cntt',
      name: 'Ban CNTT',
      initials: 'CN',
      totalCount: 7,
      members: [
        RecipientMember(id: 'cntt_1', name: 'Đinh Thùy Nhị', initials: 'ĐTH', departmentName: 'Ban CNTT'),
        RecipientMember(id: 'cntt_2', name: 'Đỗ Văn Lợi', initials: 'ĐVL', departmentName: 'Ban CNTT'),
        RecipientMember(id: 'cntt_3', name: 'Nguyễn Trọng Hùng', initials: 'NTH', departmentName: 'Ban CNTT'),
        RecipientMember(id: 'cntt_4', name: 'Trần Anh Tùng', initials: 'TAT', departmentName: 'Ban CNTT'),
        RecipientMember(id: 'cntt_5', name: 'Vũ Đình Tuân', initials: 'VT', departmentName: 'Ban CNTT'),
        RecipientMember(id: 'cntt_6', name: 'Phạm Ngọc Thuận', initials: 'PNT', departmentName: 'Ban CNTT'),
        RecipientMember(id: 'cntt_7', name: 'Phạm Văn Nam', initials: 'PVN', departmentName: 'Ban CNTT'),
      ],
    ),
    RecipientGroup(
      id: 'group_cb1',
      name: 'Chi bộ 1',
      initials: 'CB',
      totalCount: 0,
      members: [
        RecipientMember(id: 'cb1_1', name: 'Lê Nguyễn Gia Hưng', initials: 'LGH', departmentName: 'Chi bộ 1'),
        RecipientMember(id: 'cb1_2', name: 'Nguyễn Thị Thu Lệ', initials: 'NTL', departmentName: 'Chi bộ 1'),
        RecipientMember(id: 'cb1_3', name: 'Trịnh Văn Minh', initials: 'TVM', departmentName: 'Chi bộ 1'),
        RecipientMember(id: 'cb1_4', name: 'Hoàng Thị Hoa', initials: 'HTH', departmentName: 'Chi bộ 1'),
        RecipientMember(id: 'cb1_5', name: 'Bùi Hoàng Nam', initials: 'BHN', departmentName: 'Chi bộ 1'),
      ],
    ),
    RecipientGroup(
      id: 'group_tc',
      name: 'Tất cả',
      initials: 'TC',
      totalCount: 0,
      members: [],
    ),
  ];

  List<RecipientGroup> get filteredRecipientGroups {
    if (_searchQuery.isEmpty && _subFilter == RecipientSubFilter.all) {
      return recipientGroups;
    }

    return recipientGroups.map((group) {
      final matchesGroupName = group.name.toLowerCase().contains(_searchQuery);
      final filteredMembers = group.members.where((member) {
        final matchesName = member.name.toLowerCase().contains(_searchQuery);
        final isSelected = selectedMemberIds.contains(member.id);

        if (_subFilter == RecipientSubFilter.selected && !isSelected) return false;
        if (_subFilter == RecipientSubFilter.unselected && isSelected) return false;
        if (_searchQuery.isNotEmpty && !matchesName && !matchesGroupName) return false;

        return true;
      }).toList();

      return RecipientGroup(
        id: group.id,
        name: group.name,
        initials: group.initials,
        totalCount: group.totalCount,
        members: filteredMembers,
      );
    }).where((group) => group.members.isNotEmpty || _searchQuery.isEmpty).toList();
  }

  // SEND COMMAND
  late final Command0<NotificationItemEntity> sendNotificationCommand;

  bool get canSend {
    final hasContent = contentController.text.trim().isNotEmpty;
    final hasRecipients = _targetMode == 'all' || selectedMemberIds.isNotEmpty;
    return hasContent && hasRecipients;
  }

  Future<Result<NotificationItemEntity>> _sendNotification() async {
    final content = contentController.text.trim();
    if (content.isEmpty) {
      return Error(Exception('EmptyContent'), 'Vui lòng nhập nội dung thông báo');
    }
    if (_targetMode == 'custom' && selectedMemberIds.isEmpty) {
      return Error(Exception('NoRecipients'), 'Vui lòng chọn ít nhất 1 nơi nhận thông báo');
    }

    final attachmentNames = attachments.map((a) => a.fileName).toList();

    return runSafely(() async {
      final result = await portalRepository.createNotification(
        role: session.user.role,
        content: content,
        attachments: attachmentNames,
        targetMode: _targetMode,
        recipientIds: selectedMemberIds.toList(),
        senderName: senderName,
        senderDepartment: senderDepartment,
      );
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
