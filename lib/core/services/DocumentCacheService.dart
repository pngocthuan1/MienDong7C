import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';

class DocumentCacheService {
  DocumentCacheService._();
  static final DocumentCacheService instance = DocumentCacheService._();

  /// Giới hạn dung lượng cache tối đa (100 MB - an toàn cho máy người dùng phổ thông)
  static const int maxCacheSizeBytes = 100 * 1024 * 1024;

  /// Ngưỡng đưa về sau khi dọn dẹp (75 MB)
  static const int targetCacheSizeBytes = 75 * 1024 * 1024;

  /// Thời gian tối đa lưu giữ file không truy cập (7 ngày)
  static const int maxAgeDays = 7;

  /// Map lưu trữ các tiến trình tải đang chạy để chống tải trùng lặp (Deduping)
  final Map<String, Future<File?>> _pendingDownloads = {};

  /// Thư mục cơ sở ghi đè (phục vụ Unit Test)
  Directory? overrideBaseDir;

  Directory? _cachedDir;

  /// Lấy thư mục cache chuyên biệt `cache_docs`
  Future<Directory> getCacheDirectory() async {
    if (_cachedDir != null && _cachedDir!.existsSync()) {
      return _cachedDir!;
    }
    final baseDir = overrideBaseDir ?? await getTemporaryDirectory();
    final dir = Directory('${baseDir.path}/cache_docs');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  /// Sinh tên file cache duy nhất theo ID, URL hash và tên file an toàn
  String generateCacheFileName({
    required String notifId,
    required String fileName,
    required String fileUrl,
  }) {
    final cleanName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '_');
    final urlHash = fileUrl.hashCode.abs().toRadixString(16);
    return 'cache_${notifId}_${urlHash}_$cleanName';
  }

  /// Kiểm tra và lấy file từ Cache nếu đã tải hoàn tất
  Future<File?> getCachedFile({
    required String notifId,
    required String fileName,
    required String fileUrl,
  }) async {
    try {
      final dir = await getCacheDirectory();
      final cacheFileName = generateCacheFileName(
        notifId: notifId,
        fileName: fileName,
        fileUrl: fileUrl,
      );
      final file = File('${dir.path}/$cacheFileName');

      if (file.existsSync() && file.lengthSync() > 0) {
        // Cập nhật timestamp truy cập để phục vụ thuật toán LRU
        try {
          file.setLastModifiedSync(DateTime.now());
        } catch (_) {}
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Đọc nhanh mảng bytes của file từ cache (0ms delay cho Word/PDF)
  Future<Uint8List?> getCachedBytes({
    required String notifId,
    required String fileName,
    required String fileUrl,
  }) async {
    final file = await getCachedFile(
      notifId: notifId,
      fileName: fileName,
      fileUrl: fileUrl,
    );
    if (file != null) {
      try {
        return await file.readAsBytes();
      } catch (_) {}
    }
    return null;
  }

  /// Tải file ngầm với cơ chế Atomic Download (.downloading -> rename) và Deduping
  Future<File?> downloadAndCache({
    required String notifId,
    required String fileName,
    required String fileUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    if (fileUrl.isEmpty) return null;

    // 1. Kiểm tra nếu file đã có sẵn trong Cache -> Trả về tức thì 0ms
    final existingFile = await getCachedFile(
      notifId: notifId,
      fileName: fileName,
      fileUrl: fileUrl,
    );
    if (existingFile != null) {
      return existingFile;
    }

    final cacheKey = '${notifId}_${fileUrl.hashCode}';

    // 2. Chống tải trùng lặp: Nếu đang có tác vụ tải file này, trả về Future đang chạy
    if (_pendingDownloads.containsKey(cacheKey)) {
      return _pendingDownloads[cacheKey];
    }

    // 3. Khởi tạo tác vụ tải Atomic
    final downloadFuture = _executeAtomicDownload(
      notifId: notifId,
      fileName: fileName,
      fileUrl: fileUrl,
      onProgress: onProgress,
    );

    _pendingDownloads[cacheKey] = downloadFuture;

    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _pendingDownloads.remove(cacheKey);
    }
  }

  Future<File?> _executeAtomicDownload({
    required String notifId,
    required String fileName,
    required String fileUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final dir = await getCacheDirectory();
      final finalFileName = generateCacheFileName(
        notifId: notifId,
        fileName: fileName,
        fileUrl: fileUrl,
      );
      final finalTargetFile = File('${dir.path}/$finalFileName');

      // Tải vào file tạm .downloading để đảm bảo tính toàn vẹn (Atomic)
      final tempDownloadingFile = File('${finalTargetFile.path}.downloading');

      if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
        await AppLocator.dioClient.dio.download(
          fileUrl,
          tempDownloadingFile.path,
          onReceiveProgress: onProgress,
        );
      } else {
        final localSrc = File(fileUrl);
        if (localSrc.existsSync()) {
          await localSrc.copy(tempDownloadingFile.path);
        }
      }

      // Xác thực file tạm tồn tại và có dung lượng > 0 bytes
      if (tempDownloadingFile.existsSync() && tempDownloadingFile.lengthSync() > 0) {
        // Atomic Rename: Đổi tên thành file chuẩn
        if (finalTargetFile.existsSync()) {
          finalTargetFile.deleteSync();
        }
        await tempDownloadingFile.rename(finalTargetFile.path);

        // Kích hoạt dọn dẹp cache nền unawaited (không block UI)
        unawaited(_cleanCacheInBackground());

        return finalTargetFile;
      } else {
        if (tempDownloadingFile.existsSync()) {
          tempDownloadingFile.deleteSync();
        }
      }
    } catch (_) {
      // Dọn dẹp file dở dang nếu xảy ra exception
      try {
        final dir = await getCacheDirectory();
        final finalFileName = generateCacheFileName(
          notifId: notifId,
          fileName: fileName,
          fileUrl: fileUrl,
        );
        final tempDownloadingFile = File('${dir.path}/$finalFileName.downloading');
        if (tempDownloadingFile.existsSync()) {
          tempDownloadingFile.deleteSync();
        }
      } catch (_) {}
    }
    return null;
  }

  /// Dọn dẹp cache ngầm theo thuật toán LRU và hạn mức 100MB (Không block UI)
  Future<void> _cleanCacheInBackground() async {
    try {
      final dir = await getCacheDirectory();
      final entities = dir.listSync();
      final now = DateTime.now();

      int totalBytes = 0;
      final List<FileStatItem> validFiles = [];

      for (final entity in entities) {
        if (entity is File) {
          final path = entity.path;

          // Xóa file rác .downloading mồ côi nếu tạo từ hơn 1 giờ trước
          if (path.endsWith('.downloading')) {
            try {
              final stat = entity.statSync();
              if (now.difference(stat.modified).inHours >= 1) {
                entity.deleteSync();
              }
            } catch (_) {}
            continue;
          }

          try {
            final stat = entity.statSync();
            final size = stat.size;

            // Xóa file không truy cập quá 7 ngày
            if (now.difference(stat.modified).inDays >= maxAgeDays) {
              entity.deleteSync();
              continue;
            }

            totalBytes += size;
            validFiles.add(FileStatItem(file: entity, lastModified: stat.modified, size: size));
          } catch (_) {}
        }
      }

      // Nếu tổng dung lượng vượt quá 100MB: Xóa dần file cũ nhất (LRU) cho đến khi <= 75MB
      if (totalBytes > maxCacheSizeBytes) {
        validFiles.sort((a, b) => a.lastModified.compareTo(b.lastModified));

        for (final item in validFiles) {
          if (totalBytes <= targetCacheSizeBytes) break;
          try {
            item.file.deleteSync();
            totalBytes -= item.size;
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}

class FileStatItem {
  final File file;
  final DateTime lastModified;
  final int size;

  FileStatItem({
    required this.file,
    required this.lastModified,
    required this.size,
  });
}
