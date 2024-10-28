import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/provider/config.dart';
import 'package:sphia/core/core_info.dart';

part 'version_config.g.dart';

@Riverpod(keepAlive: true)
class VersionConfigNotifier extends _$VersionConfigNotifier {
  @override
  VersionConfig build() {
    final config = ref.read(versionConfigProvider);
    return config;
  }

  void updateVersion(ProxyRes coreName, String version) async {
    switch (coreName) {
      case ProxyRes.sing:
        state = state.copyWith(singBoxVersion: version);
        break;
      case ProxyRes.xray:
        state = state.copyWith(xrayCoreVersion: version);
        break;
      case ProxyRes.ssrust:
        state = state.copyWith(shadowsocksRustVersion: version);
        break;
      case ProxyRes.hysteria:
        state = state.copyWith(hysteriaVersion: version);
        break;
      case ProxyRes.singRules:
        state = state.copyWith(singBoxRulesVersion: version);
        break;
      case ProxyRes.v2rayRules:
        state = state.copyWith(v2rayRulesVersion: version);
        break;
      default:
        break;
    }
    versionConfigDao.saveConfig(state);
  }

  void removeVersion(ProxyRes coreName) {
    switch (coreName) {
      case ProxyRes.sing:
        state = state.copyWith(singBoxVersion: null);
        break;
      case ProxyRes.xray:
        state = state.copyWith(xrayCoreVersion: null);
        break;
      case ProxyRes.ssrust:
        state = state.copyWith(shadowsocksRustVersion: null);
        break;
      case ProxyRes.hysteria:
        state = state.copyWith(hysteriaVersion: null);
        break;
      case ProxyRes.singRules:
        state = state.copyWith(singBoxRulesVersion: null);
        break;
      case ProxyRes.v2rayRules:
        state = state.copyWith(v2rayRulesVersion: null);
        break;
      default:
        break;
    }
    versionConfigDao.saveConfig(state);
  }
}
