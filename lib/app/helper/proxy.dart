import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/view/dialog/custom_config.dart';

part 'proxy.g.dart';

@riverpod
class ProxyHelper extends _$ProxyHelper with SystemHelper {
  @override
  void build() {}

  Future<void> enableSystemProxy() async {
    final coreState = ref.read(coreStateNotifierProvider).valueOrNull;
    final notifier = ref.read(logNotifierProvider.notifier);
    if (coreState == null) {
      notifier.error('Core state is null');
      return;
    }
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final listen = sphiaConfig.listen;
    final routingProvider = coreState.routingProvider;
    final isCustom = ref.read(proxyNotifierProvider).customConfig;
    final customHttpPort = coreState.customHttpPort;
    final httpPort = isCustom && customHttpPort != portUnset
        ? coreState.customHttpPort
        : (routingProvider == RoutingProvider.sing
            ? sphiaConfig.mixedPort
            : sphiaConfig.httpPort);

    if (httpPort == -1) {
      notifier.warning('HTTP port is not set');
      return;
    }

    if (isWindows) {
      await _enableWindowsProxy(listen, httpPort);
    } else if (isLinux) {
      await _enableLinuxProxy(listen, httpPort);
    } else if (isMacOS) {
      await _enableMacOSProxy(listen, httpPort);
    }
    ref.read(proxyNotifierProvider.notifier).setSystemProxy(true);
    notifier.info('System proxy enabled: $listen:$httpPort');
  }

  Future<void> disableSystemProxy() async {
    if (isWindows) {
      await _disableWindowsProxy();
    } else if (isLinux) {
      await _disableLinuxProxy();
    } else if (isMacOS) {
      await _disableMacOSProxy();
    }
    ref.read(proxyNotifierProvider.notifier).setSystemProxy(false);
    ref.read(logNotifierProvider.notifier).info('System proxy disabled');
  }

  bool isSystemProxyEnabled() {
    if (isWindows) {
      final result = Process.runSync('reg', [
        'query',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
        '/v',
        'ProxyEnable',
      ]);
      if (result.exitCode == 0) {
        final regex = RegExp(r'ProxyEnable\s+REG_DWORD\s+(0x\d)');
        final match = regex.firstMatch(result.stdout.toString());
        return match?.group(1) == '0x1';
      } else {
        return false;
      }
    } else if (isLinux) {
      if (linuxDe == 'GNOME') {
        final result = Process.runSync('gsettings', [
          'get',
          'org.gnome.system.proxy',
          'mode',
        ]);
        if (result.exitCode == 0) {
          final value = result.stdout.toString().trim();
          return value == '\'manual\'';
        } else {
          return false;
        }
      } else if (linuxDe == 'KDE') {
        final configPath = p.join(Platform.environment['HOME']!, '.config');
        final result = Process.runSync('kreadconfig5', [
          '--file',
          p.join(configPath, 'kioslaverc'),
          '--group',
          'Proxy Settings',
          '--key',
          'ProxyType',
        ]);
        if (result.exitCode == 0) {
          final value = result.stdout.toString().trim();
          return value == '1';
        } else {
          return false;
        }
      } else {
        ref
            .read(logNotifierProvider.notifier)
            .error('Unsupported desktop environment: $linuxDe');
        return false;
      }
    } else if (isMacOS) {
      final result = Process.runSync('networksetup', ['-getwebproxy', 'wi-fi']);
      if (result.exitCode == 0) {
        final value = result.stdout
            .toString()
            .trim()
            .split('\n')[0]
            .split(RegExp(r'\s+'))[1];
        return value == 'Yes';
      } else {
        return false;
      }
    }
    return false;
  }

  Future<void> _enableWindowsProxy(String listen, int httpPort) async {
    await runCommand('reg', [
      'add',
      'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
      '/v',
      'ProxyEnable',
      '/t',
      'REG_DWORD',
      '/d',
      '1',
      '/f'
    ]);
    await runCommand('reg', [
      'add',
      'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
      '/v',
      'ProxyServer',
      '/d',
      '$listen:$httpPort',
      '/f'
    ]);
    await runCommand('reg', [
      'add',
      'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
      '/v',
      'ProxyOverride',
      '/d',
      '127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*',
      '/f'
    ]);
  }

  Future<void> _disableWindowsProxy() async {
    await runCommand('reg', [
      'add',
      'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings',
      '/v',
      'ProxyEnable',
      '/t',
      'REG_DWORD',
      '/d',
      '0',
      '/f'
    ]);
  }

  Future<void> _enableLinuxProxy(
    String listen,
    int httpPort,
  ) async {
    if (linuxDe == 'GNOME') {
      await runCommand('gsettings', [
        'set',
        'org.gnome.system.proxy.http',
        'host',
        listen,
      ]);
      await runCommand('gsettings', [
        'set',
        'org.gnome.system.proxy.http',
        'port',
        httpPort.toString(),
      ]);
      await runCommand('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'mode',
        'manual',
      ]);
    } else if (linuxDe == 'KDE') {
      final configPath = p.join(Platform.environment['HOME']!, '.config');
      await runCommand('kwriteconfig5', [
        '--file',
        p.join(configPath, 'kioslaverc'),
        '--group',
        'Proxy Settings',
        '--key',
        'httpProxy',
        'http://$listen:$httpPort',
      ]);
      await runCommand('kwriteconfig5', [
        '--file',
        p.join(configPath, 'kioslaverc'),
        '--group',
        'Proxy Settings',
        '--key',
        'ProxyType',
        '1',
      ]);
    } else {
      ref
          .read(logNotifierProvider.notifier)
          .error('Unsupported desktop environment: $linuxDe');
      return;
    }
  }

  Future<void> _disableLinuxProxy() async {
    if (linuxDe == 'GNOME') {
      await runCommand('gsettings', [
        'set',
        'org.gnome.system.proxy',
        'mode',
        'none',
      ]);
    } else if (linuxDe == 'KDE') {
      final configPath = p.join(Platform.environment['HOME']!, '.config');
      await runCommand('kwriteconfig5', [
        '--file',
        p.join(configPath, 'kioslaverc'),
        '--group',
        'Proxy Settings',
        '--key',
        'ProxyType',
        '0',
      ]);
    } else {
      ref
          .read(logNotifierProvider.notifier)
          .error('Unsupported desktop environment: $linuxDe');
      return;
    }
  }

  Future<void> _enableMacOSProxy(String listen, int httpPort) async {
    await runCommand(
        'networksetup', ['-setwebproxy', 'wi-fi', listen, httpPort.toString()]);
    await runCommand('networksetup',
        ['-setsecurewebproxy', 'wi-fi', listen, httpPort.toString()]);
    await runCommand('networksetup', ['-setwebproxystate', 'wi-fi', 'on']);
    await runCommand(
        'networksetup', ['-setsecurewebproxystate', 'wi-fi', 'on']);
  }

  Future<void> _disableMacOSProxy() async {
    await runCommand('networksetup', ['-setwebproxystate', 'wi-fi', 'off']);
    await runCommand(
        'networksetup', ['-setsecurewebproxystate', 'wi-fi', 'off']);
  }
}
