import 'package:sphia/core/core_info.dart';

class HysteriaInfo extends ProxyResInfo {
  @override
  final ProxyRes name = ProxyRes.hysteria;

  @override
  final String repoUrl = 'https://github.com/apernet/hysteria';

  @override
  final String versionArg = '--version';

  @override
  final String versionPattern = r'hysteria version v(\d+\.\d+\.\d+)';

  const HysteriaInfo();
}
