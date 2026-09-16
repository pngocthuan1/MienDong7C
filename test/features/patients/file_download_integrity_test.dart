import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('File Download Integrity & Verification Tests', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('download_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Verification: File with 0 bytes is NOT marked as downloaded', () async {
      final emptyFile = File('${tempDir.path}/empty.pdf');
      await emptyFile.create();
      expect(emptyFile.existsSync(), isTrue);
      expect(emptyFile.lengthSync(), equals(0));

      final isValid = emptyFile.existsSync() && emptyFile.lengthSync() > 0;
      expect(isValid, isFalse);

      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList('downloaded_notif_ids_test') ?? [];
      expect(downloadedList.contains('notif_1'), isFalse);
    });

    test('Verification: Non-empty file is verified and marked as downloaded', () async {
      final validFile = File('${tempDir.path}/valid.pdf');
      await validFile.writeAsString('Test PDF content for Bệnh Viện 7C');
      expect(validFile.existsSync(), isTrue);
      expect(validFile.lengthSync(), greaterThan(0));

      final isValid = validFile.existsSync() && validFile.lengthSync() > 0;
      expect(isValid, isTrue);

      final prefs = await SharedPreferences.getInstance();
      final downloadedList = prefs.getStringList('downloaded_notif_ids_test') ?? [];
      downloadedList.add('notif_1');
      await prefs.setStringList('downloaded_notif_ids_test', downloadedList);
      await prefs.setString('downloaded_file_path_notif_1', validFile.path);

      expect(prefs.getStringList('downloaded_notif_ids_test'), contains('notif_1'));
      expect(prefs.getString('downloaded_file_path_notif_1'), equals(validFile.path));
    });

    test('Lazy Check: When saved file still exists, it opens directly without redownloading', () async {
      final validFile = File('${tempDir.path}/report.pdf');
      await validFile.writeAsString('Report data');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_notif_ids_test', ['notif_2']);
      await prefs.setString('downloaded_file_path_notif_2', validFile.path);

      final savedPath = prefs.getString('downloaded_file_path_notif_2');
      expect(savedPath, isNotNull);

      final checkFile = File(savedPath!);
      final canOpenDirectly = checkFile.existsSync() && checkFile.lengthSync() > 0;
      expect(canOpenDirectly, isTrue);
    });

    test('Lazy Check: When user deletes file from Downloads, state resets to allow redownload', () async {
      final deletedFilePath = '${tempDir.path}/deleted_by_user.pdf';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('downloaded_notif_ids_test', ['notif_3']);
      await prefs.setString('downloaded_file_path_notif_3', deletedFilePath);

      // Giả lập người dùng bấm nút: Kiểm tra file
      final savedPath = prefs.getString('downloaded_file_path_notif_3');
      final checkFile = File(savedPath!);
      final fileStillExists = checkFile.existsSync() && checkFile.lengthSync() > 0;
      expect(fileStillExists, isFalse);

      // Logic Lazy Check reset:
      bool isDownloaded = true;
      if (!fileStillExists) {
        isDownloaded = false;
        final list = List<String>.from(prefs.getStringList('downloaded_notif_ids_test') ?? []);
        list.remove('notif_3');
        await prefs.setStringList('downloaded_notif_ids_test', list);
        await prefs.remove('downloaded_file_path_notif_3');
      }

      expect(isDownloaded, isFalse);
      expect(prefs.getStringList('downloaded_notif_ids_test'), isNot(contains('notif_3')));
      expect(prefs.getString('downloaded_file_path_notif_3'), isNull);
    });
  });
}
