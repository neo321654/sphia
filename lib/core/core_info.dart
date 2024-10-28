import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/core/hysteria/core_info.dart';
import 'package:sphia/core/rules_dat/core_info.dart';
import 'package:sphia/core/sing/core_info.dart';
import 'package:sphia/core/sphia/core_info.dart';
import 'package:sphia/core/ssrust/core_info.dart';
import 'package:sphia/core/xray/core_info.dart';

enum ProxyRes {
  sing('sing-box'),
  xray('xray-core'),
  ssrust('shadowsocks-rust'),
  hysteria('hysteria'),
  sphia('sphia'),
  singRules('sing-box-rules'),
  v2rayRules('v2ray-rules-dat'),
  none('');

  @override
  String toString() => _value;

  final String _value;

  const ProxyRes(this._value);
}

abstract class ProxyResInfo with SystemHelper {
  abstract final ProxyRes name;
  abstract final String repoUrl;
  abstract final String? versionArg;
  abstract final String? versionPattern;

  String get repoApiUrl =>
      '${repoUrl.replaceAll('https://github.com', 'https://api.github.com/repos')}/releases/latest';

  bool get isCore => versionArg != null;

  bool get isRulesDat => versionArg == null;

  const ProxyResInfo();

  String get binFileName {
    switch (name) {
      case ProxyRes.sing:
        return 'sing-box$execExt';
      case ProxyRes.xray:
        return 'xray$execExt';
      case ProxyRes.ssrust:
        return 'sslocal$execExt';
      case ProxyRes.hysteria:
        final plat = isMacOS ? 'darwin' : osName;
        final arch = isArm ? 'arm64' : 'amd64';
        return 'hysteria-$plat-$arch$execExt';
      case ProxyRes.sphia:
        return 'sphia$execExt';
      default:
        throw Exception('Unsupported core: $name');
    }
  }

  String getArchiveFileName(String latestVersion) {
    switch (name) {
      case ProxyRes.sing:
        if (latestVersion.startsWith('v')) {
          latestVersion = latestVersion.substring(1);
        }
        final plat = isMacOS ? 'darwin' : osName;
        final arch = isArm ? 'arm64' : 'amd64';
        final ext = isWindows ? '.zip' : '.tar.gz';
        return 'sing-box-$latestVersion-$plat-$arch$ext';
      case ProxyRes.xray:
        final arch = isArm ? 'arm64-v8a' : '64';
        return 'Xray-$osName-$arch.zip';
      case ProxyRes.ssrust:
        late final String plat;
        if (isWindows) {
          plat = 'pc-windows-gnu';
        } else if (isLinux) {
          plat = 'unknown-linux-gnu';
        } else if (isMacOS) {
          plat = 'apple-darwin';
        }
        final arch = isArm ? 'aarch64' : 'x86_64';
        final ext = isWindows ? '.zip' : '.tar.xz';
        return 'shadowsocks-$latestVersion.$arch-$plat$ext';
      case ProxyRes.hysteria:
        return binFileName;
      case ProxyRes.sphia:
        late final String arch;
        late final String ext;
        if (isWindows) {
          arch = isArm ? 'arm64' : 'amd64';
          ext = '.exe';
        } else if (isLinux) {
          arch = isArm ? 'arm64' : 'amd64';
          ext = '.AppImage';
        } else if (isMacOS) {
          arch = 'universal';
          ext = '.dmg';
        }
        return 'sphia-$osName-$arch$ext';
      default:
        throw Exception('Unsupported core: $name');
    }
  }

  Future<bool> exists() async {
    final binPath = IoHelper.binPath;
    Future<bool> fileExists(String path) async {
      return File(path).exists();
    }

    if (name == ProxyRes.singRules) {
      return await fileExists(p.join(binPath, 'geoip.db')) &&
          await fileExists(p.join(binPath, 'geosite.db'));
    } else if (name == ProxyRes.v2rayRules) {
      return await fileExists(p.join(binPath, 'geoip.dat')) &&
          await fileExists(p.join(binPath, 'geosite.dat'));
    } else {
      return fileExists(p.join(binPath, binFileName));
    }
  }

  bool existsSync() {
    final binPath = IoHelper.binPath;
    bool fileExistsSync(String path) {
      return File(path).existsSync();
    }

    if (name == ProxyRes.singRules) {
      return fileExistsSync(p.join(binPath, 'geoip.db')) &&
          fileExistsSync(p.join(binPath, 'geosite.db'));
    } else if (name == ProxyRes.v2rayRules) {
      return fileExistsSync(p.join(binPath, 'geoip.dat')) &&
          fileExistsSync(p.join(binPath, 'geosite.dat'));
    } else {
      return fileExistsSync(p.join(binPath, binFileName));
    }
  }
}

mixin ProxyResInfoList {
  List<ProxyResInfo> get proxyResInfoList => const [
        SingBoxInfo(),
        XrayInfo(),
        ShadowsocksRustInfo(),
        HysteriaInfo(),
        SingBoxRulesInfo(),
        V2rayRulesDatInfo(),
        SphiaInfo(),
      ];
}
