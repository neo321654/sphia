import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sphia/app/app.dart';
import 'package:sphia/app/config/rule.dart';
import 'package:sphia/app/config/server.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/helper/tray.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/provider/config.dart';
import 'package:sphia/app/provider/data.dart';
import 'package:sphia/app/state/io_info.dart';
import 'package:sphia/view/page/about.dart';
import 'package:window_manager/window_manager.dart';

class InitHelper with SystemHelper {
  const InitHelper();

  Future<IoInfo> getIoInfo() async {
    String execPath;
    String appPath;
    if (isLinux && Platform.environment.containsKey('APPIMAGE')) {
      execPath = Platform.environment['APPIMAGE']!;
    } else {
      execPath = Platform.resolvedExecutable;
    }
    if (const bool.fromEnvironment('dart.vm.product')) {
      if (isLinux || isMacOS) {
        appPath = await _getAppPathForUnix();
      } else {
        appPath =
            execPath.substring(0, execPath.lastIndexOf(Platform.pathSeparator));
      }
    } else {
      if (Platform.isMacOS) {
        // For debug
        appPath = execPath.substring(0, execPath.lastIndexOf('/Sphia.app'));
      } else {
        appPath =
            execPath.substring(0, execPath.lastIndexOf(Platform.pathSeparator));
      }
    }
    return IoInfo(execPath: execPath, appPath: appPath);
  }

  Future<String> _getAppPathForUnix() async {
    final rootPath = Platform.isLinux ? '/root/' : '/var/root/';
    final userPath = Platform.isLinux
        ? '/home/${Platform.environment['SUDO_USER']}/'
        : '/Users/${Platform.environment['SUDO_USER']}/';
    final appPath = (await getApplicationSupportDirectory()).path;
    final rootIndex = appPath.indexOf(rootPath);
    if (rootIndex != -1) {
      return appPath.replaceFirst(rootPath, userPath, rootIndex);
    } else {
      return appPath;
    }
  }

  Future<void> configureApp() async {
    final initLogs = <SphiaLogEntry>[];

    // Get paths
    final ioInfo = await getIoInfo();
    IoHelper.init(ioInfo);

    // Check dir exists
    IoHelper.createDirectorySync(ioInfo.binPath);
    IoHelper.createDirectorySync(ioInfo.configPath);
    IoHelper.createDirectorySync(ioInfo.logPath);
    IoHelper.createDirectorySync(ioInfo.tempPath);

    String infoLog = '''
OS: $osName
Architecture: $archName''';
    if (isLinux) {
      infoLog += '\nDesktop Environment: $linuxDe';
    }

    final sphiaInfoLog = '''Init Sphia:
Sphia - a Proxy Handling Intuitive Application
Full version: $sphiaFullVersion
Last commit hash: $sphiaLastCommitHash
System Info: $infoLog
App Path: ${ioInfo.appPath}
Exec Path: ${ioInfo.execPath}
Bin path: ${ioInfo.binPath}
Config path: ${ioInfo.configPath}
Log path: ${ioInfo.logPath}
Temp path: ${ioInfo.tempPath}''';
    initLogs.add(SphiaLogEntry(SphiaLogLevel.info, sphiaInfoLog));

    // Init database
    await SphiaDatabase.init(ioInfo.configPath);
    // Enable foreign keys
    await SphiaDatabase.enableForeignKeys();

    // Check write permission
    final dirs = [
      ioInfo.binPath,
      ioInfo.configPath,
      ioInfo.logPath,
      ioInfo.tempPath,
    ];
    try {
      for (final dir in dirs) {
        IoHelper.checkDirectoryWritableSync(dir);
      }
    } catch (e, st) {
      await showErrorMsg(
        'An error occurred while checking write permission: $e',
        st.toString(),
      );
      return;
    }

    late final SphiaConfig sphiaConfig;
    late final ServerConfig serverConfig;
    late final RuleConfig ruleConfig;
    late final VersionConfig versionConfig;

    // Load config
    try {
      sphiaConfig = await sphiaConfigDao.loadConfig();
      serverConfig = await serverConfigDao.loadConfig();
      ruleConfig = await ruleConfigDao.loadConfig();
      versionConfig = await versionConfigDao.loadConfig();
    } catch (e, st) {
      await SphiaDatabase.backupDatabase(ioInfo.configPath);
      final errorMsg = '''
      An error occurred while loading config: $e
      Current database file has been backuped to ${p.join(ioInfo.tempPath, 'sphia.db.bak')}
      Please restart Sphia to create a new database file''';
      await showErrorMsg(errorMsg, st.toString());
      return;
    }

    // Print versions of cores
    final versions = versionConfig.generateLog();
    if (versions.isNotEmpty) {
      initLogs.add(SphiaLogEntry(SphiaLogLevel.info, 'Versions:\n$versions'));
    }

    // Load data
    final serverGroups = await serverGroupDao.getOrderedServerGroups();
    final ruleGroups = await ruleGroupDao.getOrderedRuleGroups();

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1152, 720),
      center: true,
      minimumSize: Size(980, 720),
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAlignment(Alignment.center);
      await windowManager.setMinimumSize(const Size(980, 720));
      await windowManager.show();
      await windowManager.focus();
    });

    if (!isLinux) {
      // Build tray
      await TrayHelper.setIcon(coreRunning: false);
      await TrayHelper.setToolTip('Sphia');
    }

    // Run app
    runApp(
      ProviderScope(
        overrides: [
          sphiaConfigProvider.overrideWithValue(sphiaConfig),
          serverConfigProvider.overrideWithValue(serverConfig),
          ruleConfigProvider.overrideWithValue(ruleConfig),
          versionConfigProvider.overrideWithValue(versionConfig),
          serverGroupsProvider.overrideWithValue(serverGroups),
          ruleGroupsProvider.overrideWithValue(ruleGroups),
          initLogsProvider.overrideWithValue(initLogs),
        ],
        child: const SphiaApp(),
      ),
    );
  }

  Future<void> showErrorMsg(String e, String st) async {
    await windowManager.ensureInitialized();
    const errorWindowOptions = WindowOptions(
      size: Size(400, 300),
      center: true,
      minimumSize: Size(400, 300),
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(errorWindowOptions, () async {
      await windowManager.setAlignment(Alignment.center);
      await windowManager.setMinimumSize(const Size(600, 450));
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.show();
      await windowManager.focus();
    });
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Text('$e\n$st'),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              exit(1);
            },
            child: const Icon(Symbols.check),
          ),
        ),
      ),
    );
  }
}
