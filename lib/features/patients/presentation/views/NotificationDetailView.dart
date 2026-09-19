import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:benhvien7c/core/services/DocumentCacheService.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/NotificationViewModel.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';

class NotificationDetailView extends StatefulWidget {
  const NotificationDetailView({
    super.key,
    required this.item,
  });

  final NotificationItemEntity item;

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  late final NotificationViewModel _viewModel;
  late NotificationItemEntity _item;

  bool get _isSender => AppSessionStore.instance.currentUser?.fullName == _item.senderName;
  final Set<String> _downloadingIds = {};
  final Set<String> _cachedNotifIds = {};

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _viewModel = NotificationViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    // Tải lại danh sách để đồng bộ trạng thái mới nhất từ server giả lập
    _viewModel.loadCommand.execute();
    if (_isSender) {
      _viewModel.loadReadStatusCommand.execute(_item.id);
    }
    _prefetchAttachmentFile(_item);
  }

  void _prefetchAttachmentFile(NotificationItemEntity item) {
    final fileUrl = item.attachmentPath;
    final fileName = item.attachmentName;

    // 1. Tải ngầm file đính kèm chính (PDF, Word, Excel...) qua DocumentCacheService
    if (fileUrl != null && fileUrl.isNotEmpty && fileName != null && fileName.isNotEmpty) {
      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        // Kiểm tra xem đã có sẵn trong cache từ phiên trước chưa
        DocumentCacheService.instance.getCachedFile(
          notifId: item.id,
          fileName: fileName,
          fileUrl: fileUrl,
        ).then((cached) {
          if (cached != null && mounted) {
            setState(() {
              _cachedNotifIds.add(item.id);
            });
          }
        });

        unawaited(
          DocumentCacheService.instance.downloadAndCache(
            notifId: item.id,
            fileName: fileName,
            fileUrl: fileUrl,
          ).then((cached) {
            if (cached != null && mounted) {
              setState(() {
                _cachedNotifIds.add(item.id);
              });
            }
          }),
        );
      } else {
        _cachedNotifIds.add(item.id);
      }
    }

    // 2. Precache hình ảnh vào RAM để hiển thị tức thì 0ms
    final imagesToPrecache = <String>[];
    if (item.imagePaths != null && item.imagePaths!.isNotEmpty) {
      imagesToPrecache.addAll(item.imagePaths!);
    } else if (fileUrl != null &&
        (fileUrl.endsWith('.jpg') ||
            fileUrl.endsWith('.png') ||
            fileUrl.endsWith('.jpeg') ||
            fileUrl.endsWith('.webp'))) {
      imagesToPrecache.add(fileUrl);
    }

    for (final imgUrl in imagesToPrecache) {
      if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
        try {
          precacheImage(NetworkImage(imgUrl), context);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleImportant() async {
    final result = await _viewModel.toggleImportant(_item.id);
    result.when(
      ok: (message) {
        _showSnackBar(message);
      },
      error: (_, message) {
        _showSnackBar(message);
      },
    );
  }

  Future<void> _deleteNotification() async {
    final result = await _viewModel.deleteNotification(_item.id);
    result.when(
      ok: (message) {
        _showSnackBar(message);
        Navigator.of(context).pop();
      },
      error: (_, message) {
        _showSnackBar(message);
      },
    );
  }

  static const MethodChannel _nativeChannel = MethodChannel('com.hospisoft.benhvien7c/gallery_picker');


  void _openInAppReaderModal(NotificationItemEntity item) {
    final fileName = item.attachmentName ?? 'tai-lieu.docx';
    final targetPath = item.attachmentPath ?? '/device/$fileName';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

    if (ext == 'pdf') {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppPdfDetailModal(
          filePath: targetPath,
          fileName: fileName,
          item: item,
          onDownload: () => _performRealDownload(item),
        ),
      );
    } else if (['docx', 'doc'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppDocxDetailModal(
          filePath: targetPath,
          fileName: fileName,
          item: item,
          onDownload: () => _performRealDownload(item),
        ),
      );
    } else if (['xlsx', 'xls', 'csv'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppExcelDetailModal(
          filePath: targetPath,
          fileName: fileName,
          item: item,
          onDownload: () => _performRealDownload(item),
        ),
      );
    } else if (['jpg', 'jpeg', 'png', 'webp'].contains(ext) || (item.imagePaths != null && item.imagePaths!.isNotEmpty)) {
      final List<String> allImages = (item.imagePaths != null && item.imagePaths!.isNotEmpty)
          ? item.imagePaths!
          : [targetPath];

      showDialog<void>(
        context: context,
        builder: (_) => _InAppImageDetailModal(
          imagePaths: allImages,
          fileName: fileName,
        ),
      );
    } else {
      _performRealDownload(item);
    }
  }

  void _showOpenInAppSuggestion(NotificationItemEntity item) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thiết bị chưa có app đọc tệp này. Bạn có muốn xem trực tiếp trên ứng dụng không?'),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'XEM NGAY',
          textColor: const Color(0xFF60A5FA),
          onPressed: () => _openInAppReaderModal(item),
        ),
      ),
    );
  }

  Future<void> _performRealDownload(NotificationItemEntity item, {String? customFileName}) async {
    final fileName = customFileName ?? item.attachmentName ?? 'tai-lieu.pdf';
    final fileUrl = item.attachmentPath;
    if (fileUrl == null || fileUrl.isEmpty) {
      _showSnackBar('Không tìm thấy liên kết tệp tin đính kèm.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hisUsername = AppSessionStore.instance.currentUser?.phoneNumber.trim() ?? 'hunglng';
    final key = 'downloaded_notif_ids_$hisUsername';
    final pathKey = 'downloaded_file_path_${item.id}';
    final savedPath = prefs.getString(pathKey);

    // 1. Lazy check: Nếu đã tải trước đó và file vẫn tồn tại thực tế trên máy
    if (item.isDownloaded && savedPath != null && savedPath.isNotEmpty) {
      final savedFile = File(savedPath);
      if (savedFile.existsSync() && savedFile.lengthSync() > 0) {
        _showSnackBar('✓ Đang mở tệp $fileName trên thiết bị...');
        try {
          final opened = await _nativeChannel.invokeMethod<bool>('openFileWithExternalApp', {'filePath': savedPath});
          if (opened == false && mounted) {
            _showOpenInAppSuggestion(item);
          }
        } catch (_) {
          if (mounted) {
            _showOpenInAppSuggestion(item);
          }
        }
        return;
      } else {
        // Người dùng đã xóa file khỏi máy -> Reset trạng thái để tải lại
        setState(() {
          item.isDownloaded = false;
        });
        final list = List<String>.from(prefs.getStringList(key) ?? []);
        list.remove(item.id);
        await prefs.setStringList(key, list);
        await prefs.remove(pathKey);
      }
    }

    if (_downloadingIds.contains(item.id)) return;

    setState(() {
      _downloadingIds.add(item.id);
    });

    _showSnackBar('Đang tải tệp $fileName về máy...');

    try {
      // 2. Tận dụng tệp từ Cache nội bộ nếu đã có sẵn (tiết kiệm 100% mạng, tốc độ 0.05s)
      File? sourceFile = await DocumentCacheService.instance.getCachedFile(
        notifId: item.id,
        fileName: fileName,
        fileUrl: fileUrl,
      );

      // Nếu chưa có trong cache, tải an toàn qua DocumentCacheService
      sourceFile ??= await DocumentCacheService.instance.downloadAndCache(
        notifId: item.id,
        fileName: fileName,
        fileUrl: fileUrl,
      );

      if (sourceFile == null || !sourceFile.existsSync() || sourceFile.lengthSync() == 0) {
        throw Exception('Tệp tải về bị rỗng hoặc lỗi kết nối.');
      }

      final localCacheFile = sourceFile;

      // Đánh dấu file đã cache sẵn sàng
      if (mounted) {
        setState(() {
          _cachedNotifIds.add(item.id);
        });
      }

      // 3. Android: Lưu vào thư mục Downloads công khai qua Scoped Storage MediaStore
      final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

      String finalSavedPath = localCacheFile.path;

      if (isAndroid) {
        final String? publicSavedPath = await _nativeChannel.invokeMethod<String>('saveFileToDownloads', {
          'srcPath': localCacheFile.path,
          'fileName': fileName,
        });
        if (publicSavedPath != null && publicSavedPath.isNotEmpty) {
          finalSavedPath = publicSavedPath;
        }
      }

      // 4. VERIFY: Kiểm tra file thật sự tồn tại trên máy và kích thước > 0 bytes
      final verifyFile = File(finalSavedPath);
      final exists = verifyFile.existsSync() && verifyFile.lengthSync() > 0;

      if (exists || isIOS) {
        // CHỈ KHI NÀY MỚI ĐÁNH DẤU isDownloaded = true!
        setState(() {
          item.isDownloaded = true;
        });
        final list = List<String>.from(prefs.getStringList(key) ?? []);
        if (!list.contains(item.id)) {
          list.add(item.id);
          await prefs.setStringList(key, list);
        }
        await prefs.setString(pathKey, finalSavedPath);

        if (mounted) {
          final successMsg = isIOS
              ? '✓ Tệp đã sẵn sàng để chia sẻ / lưu tệp.'
              : '✓ Đã tải tệp $fileName vào thư mục Download.';
          _showSnackBar(successMsg);
        }

        // Mở file bằng ứng dụng ngoài
        try {
          final opened = await _nativeChannel.invokeMethod<bool>('openFileWithExternalApp', {
            'filePath': finalSavedPath,
          });
          if (opened == false && mounted) {
            _showOpenInAppSuggestion(item);
          }
        } catch (_) {
          if (mounted) {
            _showOpenInAppSuggestion(item);
          }
        }
      } else {
        throw Exception('Không thể lưu tệp vào bộ nhớ máy.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Lỗi tải tệp: ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingIds.remove(item.id);
        });
      }
    }
  }

  Future<void> _handleDownloadAndOpen(NotificationItemEntity item, String targetPath, String fileName) async {
    await _performRealDownload(item);
  }

  Widget _buildAttachmentCard(NotificationItemEntity item) {
    final fileName = item.attachmentName ?? 'tai-lieu.docx';
    final targetPath = item.attachmentPath ?? '/device/$fileName';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'docx';

    IconData iconData;
    Color iconColor;
    Color bgColor;

    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf_rounded;
      iconColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
    } else if (['docx', 'doc'].contains(ext)) {
      iconData = Icons.description_rounded;
      iconColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
    } else if (['xlsx', 'xls', 'csv'].contains(ext)) {
      iconData = Icons.table_chart_rounded;
      iconColor = const Color(0xFF059669);
      bgColor = const Color(0xFFECFDF5);
    } else if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      iconData = Icons.image_rounded;
      iconColor = const Color(0xFF9333EA);
      bgColor = const Color(0xFFF3E8FF);
    } else {
      iconData = Icons.folder_zip_rounded;
      iconColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final isCached = _cachedNotifIds.contains(item.id);
                        Color badgeBg;
                        Color badgeBorder;
                        Color badgeTextColor;
                        String badgeText;

                        if (item.isDownloaded) {
                          badgeBg = const Color(0xFFECFDF5);
                          badgeBorder = const Color(0xFFA7F3D0);
                          badgeTextColor = const Color(0xFF047857);
                          badgeText = '✓ Đã tải về máy';
                        } else if (isCached) {
                          badgeBg = const Color(0xFFEFF6FF);
                          badgeBorder = const Color(0xFFBFDBFE);
                          badgeTextColor = const Color(0xFF2563EB);
                          badgeText = '⚡ Sẵn sàng xem ngay';
                        } else {
                          badgeBg = const Color(0xFFFFF7ED);
                          badgeBorder = const Color(0xFFFFEDD5);
                          badgeTextColor = const Color(0xFFC2410C);
                          badgeText = '⏳ Chưa tải';
                        }

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeBorder),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '• Giữ 100% tệp gốc',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Auto-responsive button row with LayoutBuilder matching Image 3
          LayoutBuilder(
            builder: (context, constraints) {
              final isDownloading = _downloadingIds.contains(item.id);

              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInAppReaderModal(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                      label: const Text(
                        'Xem nhanh',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isDownloading ? null : () => _handleDownloadAndOpen(item, targetPath, fileName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isDownloaded ? const Color(0xFF047857) : const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF059669).withValues(alpha: 0.7),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(item.isDownloaded ? Icons.check_circle_rounded : Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        isDownloading
                            ? 'Đang lưu tệp...'
                            : item.isDownloaded
                                ? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                                    ? '✓ Đã lưu / Chia sẻ'
                                    : '✓ Đã tải về máy')
                                : (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
                                    ? 'Mở & Chia sẻ tệp'
                                    : 'Tải & Mở app ngoài'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        // Đồng bộ trạng thái mới nhất từ viewmodel nếu có thay đổi
        final currentItem = _viewModel.notificationById(_item.id) ?? _item;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF2F7DE1), // Blue header matching screenshot
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              'Thông báo số ${currentItem.number}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              if (_viewModel.isMutating)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadata block
                      _MetadataRow(
                        label: 'Người gửi',
                        valueWidget: Text(
                          currentItem.senderName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Nơi gửi',
                        valueWidget: Text(
                          currentItem.senderDepartment,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Ngày gửi',
                        valueWidget: Text(
                          _formatDateTime(currentItem.createdAt),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Trạng thái',
                        valueWidget: Row(
                          children: [
                            if (currentItem.attachmentName != null)
                              const Icon(
                                Icons.attachment_rounded,
                                color: Color(0xFF3F51B5),
                                size: 22,
                              )
                            else
                              const Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Link web',
                        valueWidget: const Text(
                          '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (_isSender) ...[
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              RouteNames.notificationRecipientStatus,
                              arguments: currentItem,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Theo Dõi Trạng Thái Người Xem',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Xem danh sách chi tiết ai đã đọc / chưa đọc >',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE0E0E0), height: 1),
                      const SizedBox(height: 16),
                      // Content section header
                      const Text(
                        'Nội dung',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Full details message text
                      Text(
                        currentItem.details,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                      if ((currentItem.attachmentName != null && currentItem.attachmentName!.trim().isNotEmpty) || (currentItem.attachmentPath != null && currentItem.attachmentPath!.trim().isNotEmpty) || (currentItem.imagePaths != null && currentItem.imagePaths!.isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        _buildAttachmentCard(currentItem),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row with QUAN TRỌNG and XÓA buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _viewModel.isMutating ? null : _toggleImportant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1A83C), // Orange-yellow color matching screenshot
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            currentItem.isImportant ? 'HỦY QUAN TRỌNG' : 'QUAN TRỌNG',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _viewModel.isMutating ? null : _deleteNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935), // Red color matching screenshot
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'XÓA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.valueWidget,
  });

  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ' : ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: valueWidget,
        ),
      ],
    );
  }
}

// ─── DOCX inline-formatted viewer ────────────────────────────────────────────

class _InAppDocxDetailModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  final NotificationItemEntity item;
  final Future<void> Function()? onDownload;

  const _InAppDocxDetailModal({
    required this.filePath,
    required this.fileName,
    required this.item,
    this.onDownload,
  });

  @override
  State<_InAppDocxDetailModal> createState() => _InAppDocxDetailModalState();
}

class _InAppDocxDetailModalState extends State<_InAppDocxDetailModal> {
  bool _isLoading = true;
  String? _errorMessage;
  WebViewController? _webViewController;

  // Fallback for legacy .doc binary
  List<_LegacyDocLine>? _legacyLines;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      // 1. Get bytes from cache (instant if pre-fetched)
      Uint8List? bytes = await DocumentCacheService.instance.getCachedBytes(
        notifId: widget.item.id,
        fileName: widget.fileName,
        fileUrl: widget.filePath,
      );

      if (bytes == null) {
        if (widget.filePath.startsWith('http://') || widget.filePath.startsWith('https://')) {
          final cachedFile = await DocumentCacheService.instance.downloadAndCache(
            notifId: widget.item.id,
            fileName: widget.fileName,
            fileUrl: widget.filePath,
          );
          if (cachedFile != null && cachedFile.existsSync()) {
            bytes = await cachedFile.readAsBytes();
          }
        } else {
          final file = File(widget.filePath);
          if (file.existsSync()) bytes = await file.readAsBytes();
        }
      }

      if (bytes == null) {
        if (mounted) setState(() { _isLoading = false; _errorMessage = 'Không thể tải tệp.'; });
        return;
      }

      // 2. Detect if it's a valid ZIP (DOCX) or legacy binary .doc
      final isDocx = _isZip(bytes);

      if (isDocx) {
        await _renderWithMammoth(bytes);
      } else {
        // Legacy binary .doc fallback
        final lines = _extractLegacyLines(bytes);
        if (mounted) {
          setState(() {
            _legacyLines = lines;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _errorMessage = 'Lỗi: $e'; });
    }
  }

  /// ZIP magic bytes: PK (0x50 0x4B)
  bool _isZip(Uint8List bytes) {
    return bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
  }

  Future<void> _renderWithMammoth(Uint8List docxBytes) async {
    // 1. Load mammoth.js from Flutter asset (bundled in app, no internet needed)
    final mammothJs = await rootBundle.loadString('assets/js/mammoth.min.js');

    // 2. Encode DOCX bytes as base64 (stays on device)
    final base64Docx = base64Encode(docxBytes);

    // 3. Build self-contained HTML page
    final html = _buildMammothHtml(mammothJs, base64Docx, widget.fileName);

    // 4. Create WebView controller and load HTML locally (no network)
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF1F5F9))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      ))
      ..loadHtmlString(html);

    if (mounted) {
      setState(() {
        _webViewController = controller;
        // Don't set _isLoading = false yet — wait for onPageFinished
      });
    }
  }

  String _buildMammothHtml(String mammothJs, String base64Docx, String fileName) {
    return '''<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: #f1f5f9;
    font-family: "Times New Roman", Times, serif;
    font-size: 13px;
    color: #1e293b;
    padding: 12px 8px 32px;
  }
  .banner {
    background: #fff7ed;
    border: 1px solid #fed7aa;
    border-radius: 8px;
    padding: 9px 12px;
    margin-bottom: 12px;
    font-size: 11px;
    color: #9a3412;
    font-family: sans-serif;
    display: flex;
    gap: 6px;
    align-items: flex-start;
  }
  .page {
    background: white;
    border-radius: 4px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.12);
    padding: 32px 28px 40px;
    min-height: 400px;
  }
  /* mammoth default styles override */
  p { margin-bottom: 8px; line-height: 1.65; }
  h1, h2, h3, h4 { text-align: center; margin: 14px 0 8px; font-family: "Times New Roman", serif; }
  h1 { font-size: 18px; }
  h2 { font-size: 15px; }
  h3 { font-size: 14px; }
  h4 { font-size: 13px; }
  b, strong { font-weight: bold; }
  i, em { font-style: italic; }
  u { text-decoration: underline; }
  table { border-collapse: collapse; width: 100%; margin: 12px 0; }
  td, th { border: 1px solid #cbd5e1; padding: 7px 9px; vertical-align: top; font-size: 12.5px; }
  th, tr:first-child td { background: #eff6ff; font-weight: bold; }
  tr:nth-child(even) td { background: #f8fafc; }
  ul, ol { padding-left: 24px; margin-bottom: 8px; }
  li { margin-bottom: 4px; line-height: 1.6; }
  img { max-width: 100%; height: auto; margin: 8px 0; }
  .error { color: #dc2626; font-family: sans-serif; font-size: 13px; text-align: center; padding: 24px; }
</style>
</head>
<body>
<div class="banner">
  ⚠️ Đây là bản xem nhanh. Một số định dạng phức tạp (font, màu nền, cột đôi) có thể hiển thị khác so với file gốc.
</div>
<div class="page" id="content">
  <p style="color:#64748b;text-align:center;font-family:sans-serif;font-size:12px">Đang xử lý tài liệu...</p>
</div>

<script>
${mammothJs}

(function() {
  try {
    var b64 = '${base64Docx}';
    var raw = atob(b64);
    var buf = new ArrayBuffer(raw.length);
    var view = new Uint8Array(buf);
    for (var i = 0; i < raw.length; i++) { view[i] = raw.charCodeAt(i); }

    mammoth.convertToHtml({ arrayBuffer: buf }, {
      styleMap: [
        "p[style-name='Heading 1'] => h1:fresh",
        "p[style-name='Heading 2'] => h2:fresh",
        "p[style-name='Heading 3'] => h3:fresh",
        "p[style-name='Heading 4'] => h4:fresh"
      ]
    }).then(function(result) {
      document.getElementById('content').innerHTML =
        result.value || '<p class="error">Tài liệu trống.</p>';
    }).catch(function(err) {
      document.getElementById('content').innerHTML =
        '<p class="error">Không thể đọc file: ' + err.message + '</p>';
    });
  } catch(e) {
    document.getElementById('content').innerHTML =
      '<p class="error">Lỗi xử lý: ' + e.message + '</p>';
  }
})();
</script>
</body>
</html>''';
  }

  // ─── Legacy binary .doc extractor ────────────────────────────────────────
  List<_LegacyDocLine> _extractLegacyLines(Uint8List bytes) {
    final List<String> paragraphs = [];
    final regex = RegExp(
      r'[\wàáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ0-9\s\.,;:!?\-\(\)\%\$\/\\]{6,}',
    );
    for (int offset = 0; offset < 2; offset++) {
      final length = (bytes.length - offset) ~/ 2;
      if (length <= 0) continue;
      final units = List<int>.generate(length, (i) {
        final pos = offset + i * 2;
        return bytes[pos] | (bytes[pos + 1] << 8);
      });
      final decoded = String.fromCharCodes(units);
      for (final m in regex.allMatches(decoded)) {
        final str = m.group(0)?.trim() ?? '';
        if (str.length >= 6 &&
            !str.contains('Microsoft') && !str.contains('Word.Document') &&
            !str.contains('Root Entry') && !str.contains('CompObj') &&
            !paragraphs.contains(str)) {
          paragraphs.add(str);
        }
      }
    }
    if (paragraphs.isEmpty) {
      final latin = String.fromCharCodes(bytes);
      for (final m in regex.allMatches(latin)) {
        final str = m.group(0)?.trim() ?? '';
        if (str.length >= 6 &&
            !str.contains('Microsoft') && !str.contains('Word.Document') &&
            !str.contains('Root Entry') && !str.contains('CompObj') &&
            !paragraphs.contains(str)) {
          paragraphs.add(str);
        }
      }
    }
    return paragraphs.map((p) {
      final isH = p.length < 80 &&
          (p == p.toUpperCase() ||
              p.startsWith('CỘNG HÒA') || p.startsWith('BỆNH VIỆN') ||
              p.startsWith('THÔNG BÁO') || p.startsWith('KẾ HOẠCH') ||
              p.startsWith('Kính gửi') || p.startsWith('ỦY BAN') ||
              p.startsWith('QUYẾT ĐỊNH'));
      return _LegacyDocLine(p, isHeader: isH);
    }).toList();
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.fileName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (widget.onDownload != null) await widget.onDownload!();
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text('Tải về máy',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Stack(
          children: [
            // ── WebView (DOCX via mammoth.js) ──────────────────────────────
            if (_webViewController != null)
              WebViewWidget(controller: _webViewController!),

            // ── Legacy .doc text fallback ──────────────────────────────────
            if (_webViewController == null && _legacyLines != null)
              _buildLegacyFallback(),

            // ── Error message ──────────────────────────────────────────────
            if (_errorMessage != null && _webViewController == null && _legacyLines == null)
              Center(child: Text(_errorMessage!,
                  style: const TextStyle(color: Color(0xFF64748B)))),

            // ── Loading overlay ────────────────────────────────────────────
            if (_isLoading)
              _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(height: 16),
              Text(widget.fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 14, color: Color(0xFF0F172A)),
                  textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              const SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 10),
              const Text('Đang dàn trang tài liệu...',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyFallback() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      constrained: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width - 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12, offset: const Offset(0, 2))],
            ),
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFC2410C), size: 17),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Định dạng .doc cũ (Word 97-2003). Bản xem trước chỉ hiển thị văn bản, không có hình ảnh hay con dấu. Vui lòng tải file gốc để xem đầy đủ.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF9A3412), height: 1.4),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...(_legacyLines ?? []).map((line) => Padding(
                  padding: EdgeInsets.only(top: line.isHeader ? 12 : 0, bottom: line.isHeader ? 6 : 8),
                  child: SelectableText(
                    line.text,
                    textAlign: line.isHeader ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      fontSize: line.isHeader ? 14.5 : 13.5,
                      fontWeight: line.isHeader ? FontWeight.bold : FontWeight.normal,
                      color: line.isHeader ? const Color(0xFF0F172A) : const Color(0xFF334155),
                      height: 1.65,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




class _InAppPdfDetailModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  final NotificationItemEntity item;
  final Future<void> Function()? onDownload;

  const _InAppPdfDetailModal({
    required this.filePath,
    required this.fileName,
    required this.item,
    this.onDownload,
  });

  @override
  State<_InAppPdfDetailModal> createState() => _InAppPdfDetailModalState();
}

class _InAppPdfDetailModalState extends State<_InAppPdfDetailModal> {
  int _totalPages = 0;
  int _currentPage = 0;
  String? _localPdfPath;
  bool _isLoading = true;
  double? _downloadProgress;
  String? _downloadProgressText;

  @override
  void initState() {
    super.initState();
    _preparePdfFile();
  }

  Future<void> _preparePdfFile() async {
    try {
      if (widget.filePath.startsWith('http://') || widget.filePath.startsWith('https://')) {
        // 1. Kiểm tra cache trước (0ms delay)
        final cached = await DocumentCacheService.instance.getCachedFile(
          notifId: widget.item.id,
          fileName: widget.fileName,
          fileUrl: widget.filePath,
        );
        if (cached != null && cached.existsSync() && cached.lengthSync() > 0) {
          if (mounted) {
            setState(() {
              _localPdfPath = cached.path;
              _isLoading = false;
            });
          }
          return;
        }

        // 2. Nếu chưa có, tải ngầm an toàn qua DocumentCacheService
        final downloaded = await DocumentCacheService.instance.downloadAndCache(
          notifId: widget.item.id,
          fileName: widget.fileName,
          fileUrl: widget.filePath,
          onProgress: (received, total) {
            if (mounted && total > 0) {
              setState(() {
                _downloadProgress = received / total;
                final recMb = (received / (1024 * 1024)).toStringAsFixed(1);
                final totMb = (total / (1024 * 1024)).toStringAsFixed(1);
                _downloadProgressText = '$recMb MB / $totMb MB';
              });
            }
          },
        );
        if (downloaded != null && mounted) {
          setState(() {
            _localPdfPath = downloaded.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _localPdfPath = widget.filePath;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    final pdfPath = _localPdfPath;
    final fileExists = pdfPath != null && File(pdfPath).existsSync();

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isMobile && _totalPages > 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (widget.onDownload != null) {
                  await widget.onDownload!();
                }
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text('Tải về máy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 32),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      if (_downloadProgress != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${((_downloadProgress ?? 0) * 100).toInt()}%',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            ),
                            Text(
                              _downloadProgressText ?? '',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFDC2626)),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Đang nạp file PDF...',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : fileExists && isMobile
                ? PDFView(
                    filePath: pdfPath,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages ?? 0;
                      });
                    },
                    onPageChanged: (page, total) {
                      setState(() {
                        _currentPage = page ?? 0;
                      });
                    },
                  )
                : Container(
                    color: const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFDC2626),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            widget.item.details.isNotEmpty
                                ? widget.item.details
                                : 'Nội dung tệp PDF ${widget.fileName}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _InAppExcelDetailModal extends StatelessWidget {
  final String filePath;
  final String fileName;
  final NotificationItemEntity item;
  final Future<void> Function()? onDownload;

  const _InAppExcelDetailModal({
    required this.filePath,
    required this.fileName,
    required this.item,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                if (onDownload != null) {
                  await onDownload!();
                }
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text('Tải về máy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_rounded, color: Color(0xFF059669), size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SelectableText(
                    item.details.isNotEmpty ? item.details : 'Dữ liệu bảng tính Excel $fileName',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InAppImageDetailModal extends StatefulWidget {
  final List<String> imagePaths;
  final String fileName;

  const _InAppImageDetailModal({
    required this.imagePaths,
    required this.fileName,
  });

  @override
  State<_InAppImageDetailModal> createState() => _InAppImageDetailModalState();
}

class _InAppImageDetailModalState extends State<_InAppImageDetailModal> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.imagePaths.isEmpty ? 1 : widget.imagePaths.length;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.photo_library_rounded, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalImages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/$totalImages',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: totalImages,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final path = widget.imagePaths.isNotEmpty ? widget.imagePaths[index] : '';
                final isNetwork = path.startsWith('http://') || path.startsWith('https://');
                final fileExists = path.isNotEmpty && (isNetwork || File(path).existsSync());

                return Center(
                  child: fileExists
                      ? InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: isNetwork
                              ? Image.network(
                                  path,
                                  filterQuality: FilterQuality.high,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    final total = loadingProgress.expectedTotalBytes;
                                    final loaded = loadingProgress.cumulativeBytesLoaded;
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: total != null && total > 0 ? loaded / total : null,
                                            color: const Color(0xFF2563EB),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            total != null && total > 0
                                                ? 'Đang nạp ảnh: ${(loaded / total * 100).toInt()}%'
                                                : 'Đang tải hình ảnh...',
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.cloud_off_rounded, color: Color(0xFFEF4444), size: 64),
                                          const SizedBox(height: 16),
                                          Text(
                                            widget.fileName,
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Server C# trả về lỗi 500 (chưa cấu hình thư mục lưu tệp FileShareFolder).',
                                            style: TextStyle(color: Colors.white70, fontSize: 13),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Image.file(File(path), filterQuality: FilterQuality.high),
                        )
                      : Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                widget.fileName,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hình ảnh (${index + 1}/$totalImages)',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
            if (totalImages > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalImages, (index) {
                    final isSelected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute:$second';
}

class _LegacyDocLine {
  final String text;
  final bool isHeader;
  _LegacyDocLine(this.text, {this.isHeader = false});
}
