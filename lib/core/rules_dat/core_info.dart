import 'package:sphia/core/core_info.dart';

class SingBoxRulesInfo extends ProxyResInfo {
  @override
  final ProxyRes name = ProxyRes.singRules;

  @override
  final String repoUrl = 'https://github.com/lyc8503/sing-box-rules';

  @override
  final String? versionArg = null;

  @override
  final String? versionPattern = null;

  final String geositeDBUrl =
      'https://github.com/lyc8503/sing-box-rules/releases/latest/download/geosite.db';
  final String geoipDBUrl =
      'https://github.com/lyc8503/sing-box-rules/releases/latest/download/geoip.db';

  const SingBoxRulesInfo();
}

class V2rayRulesDatInfo extends ProxyResInfo {
  @override
  final ProxyRes name = ProxyRes.v2rayRules;

  @override
  final String repoUrl = 'https://github.com/Loyalsoldier/v2ray-rules-dat';

  @override
  final String? versionArg = null;

  @override
  final String? versionPattern = null;

  final String geositeDatUrl =
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat';
  final String geoipDatUrl =
      'https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat';

  const V2rayRulesDatInfo();
}
