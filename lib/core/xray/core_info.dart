import 'package:sphia/core/core_info.dart';

class XrayInfo extends ProxyResInfo {
  @override
  final ProxyRes name = ProxyRes.xray;

  @override
  final String repoUrl = 'https://github.com/xtls/xray-core';

  @override
  final String versionArg = 'version';

  @override
  final String versionPattern = r'Xray (\d+\.\d+\.\d+)';

  const XrayInfo();
}
