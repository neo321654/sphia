import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/notifier/config/version_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/core/core_info.dart';
import 'package:sphia/core/rules_dat/core_info.dart';

part 'updater.g.dart';

@riverpod
class CoreUpdater extends _$CoreUpdater with SystemHelper, ProxyResInfoList {
  @override
  void build() {}

  LogNotifier get logNotifier => ref.read(logNotifierProvider.notifier);

  Future<void> scanCores() async {
    logNotifier.info('Scanning cores');
    final notifier = ref.read(versionConfigNotifierProvider.notifier);
    final binPath = IoHelper.binPath;

    for (var info in proxyResInfoList) {
      final coreName = info.name;
      // if core is not found, remove it from version config
      if (!await info.exists()) {
        notifier.removeVersion(coreName);
        continue;
      }
      if (info.isRulesDat) {
        continue;
      }
      final executable = p.join(binPath, info.binFileName);
      final arguments = [info.versionArg!];
      late final ProcessResult result;
      try {
        result = await Process.run(executable, arguments);
      } on Exception catch (_) {
        logNotifier.error('Failed to run command: $executable $arguments');
        continue;
      }
      if (result.exitCode == 0) {
        final version = _parseVersion(result.stdout.toString(), info, true);
        if (version != null) {
          logNotifier.info('Found $coreName: $version');
          notifier.updateVersion(coreName, version);
        }
      }
    }
    // for rules dat
    if (!await (proxyResInfoList[4] as SingBoxRulesInfo).exists()) {
      notifier.removeVersion(ProxyRes.singRules);
    }
    if (!await (proxyResInfoList[5] as V2rayRulesDatInfo).exists()) {
      notifier.removeVersion(ProxyRes.v2rayRules);
    }
  }

  Future<bool?> importCore({required bool isMulti}) async {
    FilePickerResult? result;
    if (isWindows) {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe', 'dat', 'db'],
        allowMultiple: isMulti,
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['', 'dat', 'db'],
        allowMultiple: isMulti,
      );
    }
    if (result != null) {
      if (result.files.isEmpty) {
        return null;
      }
      final binPath = IoHelper.binPath;
      if (isMulti) {
        for (var platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            final destPath = p.join(binPath, p.basename(file.path));
            logNotifier.info('Copying $file to \'$destPath\'');
            file.copySync(destPath);
          }
        }
        return true;
      }
      final file = File(result.files.single.path!);
      final notifier = ref.read(versionConfigNotifierProvider.notifier);
      // check core version
      for (var info in proxyResInfoList) {
        if (info.isRulesDat) {
          continue;
        }
        final coreName = info.name;
        final arguments = info.versionArg!;
        late final ProcessResult result;
        try {
          result = await Process.run(file.path, [arguments]);
        } on Exception catch (_) {
          logNotifier.error('Failed to run command: ${file.path} $arguments');
          continue;
        }
        if (result.exitCode == 0) {
          final version = _parseVersion(result.stdout.toString(), info, false);
          if (version != null) {
            notifier.updateVersion(coreName, version);
            final destPath = p.join(binPath, info.binFileName);
            // delete old core
            await deleteCore(info);
            // copy new core
            logNotifier.info('Copying $file to \'$destPath\'');
            file.copySync(destPath);
            return true;
          }
        }
      }
    } else {
      return null;
    }
    return false;
  }

  Future<void> deleteCore(ProxyResInfo coreInfo) async {
    final coreName = coreInfo.name;
    final binPath = IoHelper.binPath;
    if (coreName == ProxyRes.singRules) {
      final geoipFilePath = p.join(binPath, 'geoip.db');
      final geositeFilePath = p.join(binPath, 'geosite.db');
      await IoHelper.deleteFileIfExists(
          geoipFilePath, 'Deleting file: $geoipFilePath');
      await IoHelper.deleteFileIfExists(
          geositeFilePath, 'Deleting file: $geositeFilePath');
    } else if (coreName == ProxyRes.v2rayRules) {
      final geoipFilePath = p.join(binPath, 'geoip.dat');
      final geositeFilePath = p.join(binPath, 'geosite.dat');
      await IoHelper.deleteFileIfExists(
          geoipFilePath, 'Deleting file: $geoipFilePath');
      await IoHelper.deleteFileIfExists(
          geositeFilePath, 'Deleting file: $geositeFilePath');
    } else {
      final binFileName = coreInfo.binFileName;
      final coreFilePath = p.join(binPath, binFileName);
      await IoHelper.deleteFileIfExists(
          coreFilePath, 'Deleting file: $coreFilePath');
    }
  }

  Future<void> updateCore({
    required ProxyResInfo coreInfo,
    required String latestVersion,
  }) async {
    final coreName = coreInfo.name;
    final versionConfigNotifier =
        ref.read(versionConfigNotifierProvider.notifier);
    if (coreName == ProxyRes.singRules || coreName == ProxyRes.v2rayRules) {
      try {
        await _updateGeoFiles(coreName);
      } on Exception catch (e) {
        logNotifier.error('Failed to update: $coreName\n$e');
        throw Exception('Failed to update: $coreName\n$e');
      }
      logNotifier.info('Updated $coreName to $latestVersion successfully');
      versionConfigNotifier.updateVersion(coreName, latestVersion);
    } else {
      try {
        final coreArchiveFileName = coreInfo.getArchiveFileName(latestVersion);
        final binFileName = coreInfo.binFileName;
        final downloadUrl =
            '${coreInfo.repoUrl}/releases/download/$latestVersion/$coreArchiveFileName';
        final networkHelper = ref.read(networkHelperProvider.notifier);
        final bytes = await networkHelper.downloadFile(downloadUrl);

        // Stop all cores
        final coreStateNotifier = ref.read(coreStateNotifierProvider.notifier);
        await coreStateNotifier.stopCores();
        // Replace core
        await _replaceCore(
          coreArchiveFileName: coreArchiveFileName,
          coreBinFileName: binFileName,
          bytes: bytes,
        );

        if (!await coreInfo.exists()) {
          logNotifier.error('Core not found: $coreName');
          throw Exception('Core not found: $coreName');
        }
      } on Exception catch (e) {
        logNotifier.error('Failed to update: $coreName\n$e');
        throw Exception('Failed to update: $coreName\n$e');
      }
      logNotifier.info('Updated $coreName to $latestVersion successfully');
      versionConfigNotifier.updateVersion(coreName, latestVersion);
    }
  }

  Future<void> _updateGeoFiles(ProxyRes coreName) async {
    late final String geositeFilePath;
    late final String geoipFilePath;
    late final String geositeFileUrl;
    late final String geoipFileUrl;
    final binPath = IoHelper.binPath;

    if (coreName == ProxyRes.singRules) {
      geositeFilePath = p.join(binPath, 'geosite.db');
      geoipFilePath = p.join(binPath, 'geoip.db');
      final singBoxRules = proxyResInfoList[4] as SingBoxRulesInfo;
      geositeFileUrl = singBoxRules.geositeDBUrl;
      geoipFileUrl = singBoxRules.geoipDBUrl;
    } else if (coreName == ProxyRes.v2rayRules) {
      geositeFilePath = p.join(binPath, 'geosite.dat');
      geoipFilePath = p.join(binPath, 'geoip.dat');
      final v2rayRulesDat = proxyResInfoList[5] as V2rayRulesDatInfo;
      geositeFileUrl = v2rayRulesDat.geositeDatUrl;
      geoipFileUrl = v2rayRulesDat.geoipDatUrl;
    } else {
      throw Exception('Unsupported core: $coreName');
    }

    final geositeDatFile = File(geositeFilePath);
    final geoipDatFile = File(geoipFilePath);
    final networkHelper = ref.read(networkHelperProvider.notifier);
    try {
      final geositeDatBytes = await networkHelper.downloadFile(geositeFileUrl);
      final geoipDatBytes = await networkHelper.downloadFile(geoipFileUrl);
      final coreStateNotifier = ref.read(coreStateNotifierProvider.notifier);
      await coreStateNotifier.stopCores();
      await geositeDatFile.writeAsBytes(geositeDatBytes);
      await geoipDatFile.writeAsBytes(geoipDatBytes);
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> _replaceCore({
    required String coreArchiveFileName,
    required String coreBinFileName,
    required Uint8List bytes,
  }) async {
    final binPath = IoHelper.binPath;
    final tempPath = IoHelper.tempPath;
    final tempFile = File(p.join(tempPath, coreArchiveFileName));
    late final Archive archive;
    bool flag = false;

    await tempFile.writeAsBytes(bytes);
    if (coreArchiveFileName.endsWith('zip')) {
      archive = ZipDecoder().decodeBytes(bytes);
    } else if (coreArchiveFileName.endsWith('tar.xz')) {
      archive = TarDecoder().decodeBytes(XZDecoder().decodeBytes(bytes));
    } else if (coreArchiveFileName.endsWith('tar.gz')) {
      archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
    } else {
      if (coreArchiveFileName.contains('hysteria')) {
        final coreBinaryFile = File(p.join(binPath, coreBinFileName));
        if (await coreBinaryFile.exists()) {
          await coreBinaryFile.delete();
        }
        tempFile.copySync(p.join(binPath, coreBinFileName));
        setExecutablePermissionSync(p.join(binPath, coreBinFileName));
        await tempFile.delete();
        return;
      } else {
        logNotifier.error('Unsupported archive format');
        throw Exception('Unsupported archive format');
      }
    }

    final coreBinaryFile = File(p.join(binPath, coreBinFileName));
    if (await coreBinaryFile.exists()) {
      await coreBinaryFile.delete();
    }

    for (var file in archive) {
      final filename = file.name;
      if (file.isFile && filename == coreBinFileName) {
        final data = file.content as List<int>;
        File(p.join(binPath, coreBinFileName))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
        flag = true;
        break;
      }
    }

    final extractDir = Directory(p.join(tempPath, 'extracted'));
    if (!flag) {
      await extractArchiveToDisk(archive, extractDir.path);
      final extractedFile = _findFile(extractDir, coreBinFileName);
      if (extractedFile != null) {
        extractedFile.copySync(p.join(binPath, coreBinFileName));
        extractDir.deleteSync(recursive: true);
      }
    }

    setExecutablePermissionSync(p.join(binPath, coreBinFileName));
    await tempFile.delete();
  }

  String? _parseVersion(String buffer, ProxyResInfo coreInfo, bool logError) {
    late final String result;
    final regex = RegExp(coreInfo.versionPattern!);
    final match = regex.firstMatch(buffer);
    if (match != null) {
      result = match.group(1)!;
    }

    if (result.isEmpty) {
      if (logError) {
        logNotifier.error('Failed to parse version info for ${coreInfo.name}');
      }
      return null;
    }
    return 'v$result';
  }

  File? _findFile(Directory dir, String fileName) {
    File? file;
    for (FileSystemEntity entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith(fileName)) {
        file = entity;
        break;
      } else if (entity is Directory) {
        file = _findFile(entity, fileName);
        break;
      }
    }
    return file;
  }
}
