import 'package:sphia/core/core_info.dart';

class SingBoxInfo extends ProxyResInfo {
  @override
  final ProxyRes name = ProxyRes.sing;

  @override
  final String repoUrl = 'https://github.com/SagerNet/sing-box';

  @override
  final String versionArg = 'version';

  @override
  final String versionPattern = r'sing-box version (\d+\.\d+\.\d+)';

  const SingBoxInfo();
}
