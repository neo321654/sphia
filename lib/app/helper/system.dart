import 'dart:async';
import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:sphia/app/log.dart';

mixin SystemHelper {
  String get osName => Platform.operatingSystem;

  String get archName => isArm ? 'arm64' : 'x86_64';

  String get execExt => Platform.isWindows ? '.exe' : '';

  Map<String, String> get _env => Platform.environment;

  String? get linuxDe => _env['XDG_CURRENT_DESKTOP'];

  bool get isWindows => Platform.isWindows;

  bool get isLinux => Platform.isLinux;

  bool get isMacOS => Platform.isMacOS;

  bool get isX86 => Platform.version.contains('x86');

  bool get isArm => Platform.version.contains('arm');

  Future<void> configureStartup(String execPath, bool enabled) async {
    launchAtStartup.setup(
      appName: 'Sphia',
      appPath: execPath,
    );
    if (enabled) {
      logger.i('Enabling startup');
      await launchAtStartup.enable();
    } else {
      logger.i('Disabling startup');
      await launchAtStartup.disable();
    }
  }

  Future<void> killProcess(int pid) async {
    if (isWindows) {
      await Process.run('taskkill', ['/F', '/PID', pid.toString()]);
    } else {
      await Process.run('kill', [pid.toString()]);
    }
  }

  void setExecutablePermissionSync(String fileName) {
    if (!isWindows) {
      runCommandSync('chmod', ['+x', fileName]);
    }
  }

  Future<void> runCommand(String executable, List<String> arguments) async {
    final result = await Process.run(executable, arguments, runInShell: true);
    if (result.exitCode != 0) {
      logger.e('Failed to run command: $executable $arguments');
      throw Exception('Failed to run command: $executable $arguments');
    }
  }

  void runCommandSync(String executable, List<String> arguments) {
    final result = Process.runSync(executable, arguments, runInShell: true);
    if (result.exitCode != 0) {
      logger.e('Failed to run command: $executable $arguments');
      throw Exception('Failed to run command: $executable $arguments');
    }
  }
}
