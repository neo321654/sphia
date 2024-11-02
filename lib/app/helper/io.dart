import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sphia/app/state/io_info.dart';

class IoHelper {
  static late final IoInfo _ioInfo;

  static void init(IoInfo ioInfo) {
    _ioInfo = ioInfo;
  }

  static String get execPath => _ioInfo.execPath;

  static String get appPath => _ioInfo.appPath;

  static String get binPath => _ioInfo.binPath;

  static String get configPath => _ioInfo.configPath;

  static String get logPath => _ioInfo.logPath;

  static String get tempPath => _ioInfo.tempPath;

  static void checkDirectoryWritableSync(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dir.createSync();
      }
      final file = File(p.join(dirPath, '.test'));
      file.createSync();
      file.deleteSync();
    } on Exception catch (_) {
      rethrow;
    }
  }

  static void createDirectorySync(String dirName) {
    final dir = Directory(dirName);
    try {
      if (!dir.existsSync()) {
        dir.createSync();
      }
    } on Exception catch (_) {
      rethrow;
    }
  }

  static Future<void> deleteFileIfExists(String filePath,
      [String? logMessage]) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
