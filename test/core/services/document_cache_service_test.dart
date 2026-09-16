import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:benhvien7c/core/services/DocumentCacheService.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentCacheService Tests', () {
    final service = DocumentCacheService.instance;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('doc_cache_test_');
      service.overrideBaseDir = tempDir;
    });

    tearDown(() async {
      service.overrideBaseDir = null;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generateCacheFileName cleans unsafe characters and adds url hash', () {
      final fileName = service.generateCacheFileName(
        notifId: 'notif_123',
        fileName: 'Tài liệu: BV 7C / Báo cáo.pdf',
        fileUrl: 'https://benhvien7c.vn/files/report_1.pdf',
      );

      expect(fileName, startsWith('cache_notif_123_'));
      expect(fileName, endsWith('.pdf'));
      expect(fileName.contains(':'), isFalse);
      expect(fileName.contains('/'), isFalse);
      expect(fileName.contains(' '), isFalse);
    });

    test('generateCacheFileName differs when url changes (Cache Invalidation)', () {
      final nameV1 = service.generateCacheFileName(
        notifId: 'notif_123',
        fileName: 'report.pdf',
        fileUrl: 'https://benhvien7c.vn/files/report_v1.pdf',
      );

      final nameV2 = service.generateCacheFileName(
        notifId: 'notif_123',
        fileName: 'report.pdf',
        fileUrl: 'https://benhvien7c.vn/files/report_v2.pdf',
      );

      expect(nameV1, isNot(equals(nameV2)));
    });

    test('Cache directory is created and accessible', () async {
      final dir = await service.getCacheDirectory();
      expect(dir.existsSync(), isTrue);
      expect(dir.path, contains('cache_docs'));
    });

    test('getCachedFile returns null for non-existent file', () async {
      final file = await service.getCachedFile(
        notifId: 'non_existent_id',
        fileName: 'unknown.pdf',
        fileUrl: 'https://benhvien7c.vn/unknown.pdf',
      );
      expect(file, isNull);
    });

    test('getCachedFile returns valid File when file exists and length > 0', () async {
      final dir = await service.getCacheDirectory();
      final cacheFileName = service.generateCacheFileName(
        notifId: 'test_doc_1',
        fileName: 'test.pdf',
        fileUrl: 'https://benhvien7c.vn/test.pdf',
      );

      final createdFile = File('${dir.path}/$cacheFileName');
      await createdFile.writeAsString('Dummy PDF content for unit test');

      final cachedFile = await service.getCachedFile(
        notifId: 'test_doc_1',
        fileName: 'test.pdf',
        fileUrl: 'https://benhvien7c.vn/test.pdf',
      );

      expect(cachedFile, isNotNull);
      expect(cachedFile!.existsSync(), isTrue);
      expect(cachedFile.lengthSync(), greaterThan(0));

      final bytes = await service.getCachedBytes(
        notifId: 'test_doc_1',
        fileName: 'test.pdf',
        fileUrl: 'https://benhvien7c.vn/test.pdf',
      );
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));
    });

    test('Atomic: File with .downloading suffix is NOT returned as valid cache', () async {
      final dir = await service.getCacheDirectory();
      final cacheFileName = service.generateCacheFileName(
        notifId: 'test_doc_2',
        fileName: 'incomplete.pdf',
        fileUrl: 'https://benhvien7c.vn/incomplete.pdf',
      );

      // File đang tải dở
      final downloadingFile = File('${dir.path}/$cacheFileName.downloading');
      await downloadingFile.writeAsString('Downloading in progress partial bytes...');

      final cachedFile = await service.getCachedFile(
        notifId: 'test_doc_2',
        fileName: 'incomplete.pdf',
        fileUrl: 'https://benhvien7c.vn/incomplete.pdf',
      );

      // Tuyệt đối không trả về file đang tải dở
      expect(cachedFile, isNull);
    });

    test('downloadAndCache with local file succeeds and creates atomic cached file', () async {
      final localSource = File('${tempDir.path}/original.pdf');
      await localSource.writeAsString('Original source document content');

      final cached = await service.downloadAndCache(
        notifId: 'local_1',
        fileName: 'original.pdf',
        fileUrl: localSource.path,
      );

      expect(cached, isNotNull);
      expect(cached!.existsSync(), isTrue);
      expect(await cached.readAsString(), equals('Original source document content'));

      // Check second call hits cache immediately
      final secondCached = await service.getCachedFile(
        notifId: 'local_1',
        fileName: 'original.pdf',
        fileUrl: localSource.path,
      );
      expect(secondCached, isNotNull);
      expect(secondCached!.path, equals(cached.path));
    });
  });
}
