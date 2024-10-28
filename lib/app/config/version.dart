import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sphia/core/core_info.dart';

part 'version.freezed.dart';
part 'version.g.dart';

@freezed
class VersionConfig with _$VersionConfig {
  const factory VersionConfig({
    String? singBoxVersion,
    String? xrayCoreVersion,
    String? shadowsocksRustVersion,
    String? hysteriaVersion,
    String? singBoxRulesVersion,
    String? v2rayRulesVersion,
  }) = _VersionConfig;

  factory VersionConfig.fromJson(Map<String, dynamic> json) =>
      _$VersionConfigFromJson(json);
}

extension VersionConfigExtension on VersionConfig {
  String? getVersion(ProxyRes coreName) {
    switch (coreName) {
      case ProxyRes.sing:
        return singBoxVersion;
      case ProxyRes.xray:
        return xrayCoreVersion;
      case ProxyRes.ssrust:
        return shadowsocksRustVersion;
      case ProxyRes.hysteria:
        return hysteriaVersion;
      case ProxyRes.singRules:
        return singBoxRulesVersion;
      case ProxyRes.v2rayRules:
        return v2rayRulesVersion;
      default:
        return null;
    }
  }

  String generateLog() {
    final json = toJson();
    return json.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }
}
