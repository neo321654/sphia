import 'package:sphia/core/core_info.dart';

class ShadowsocksRustInfo extends ProxyResInfo {
  @override
  final ProxyRes name = ProxyRes.ssrust;

  @override
  final String repoUrl = 'https://github.com/shadowsocks/shadowsocks-rust';

  @override
  final String versionArg = '--version';

  @override
  final String versionPattern = r'shadowsocks (\d+\.\d+\.\d+)';

  const ShadowsocksRustInfo();
}
