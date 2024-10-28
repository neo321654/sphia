import 'dart:convert';
import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/hysteria/config.dart';
import 'package:sphia/core/hysteria/core_info.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/server/server_model.dart';

class HysteriaCore extends Core with ProxyCore {
  HysteriaCore(Ref ref)
      : super(
          info: const HysteriaInfo(),
          args: ['-c', p.join(IoHelper.tempPath, 'hysteria.json')],
          configFileName: 'hysteria.json',
          ref: ref,
        );

  @override
  Future<void> configure() async {
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final parameters = HysteriaConfigParameters(
      server: runningServer as HysteriaServer,
      additionalSocksPort: sphiaConfig.additionalSocksPort,
      enableUdp: sphiaConfig.enableUdp,
    );
    final jsonString = await generateConfig(parameters);
    await writeConfig(jsonString);
  }

  @override
  Future<String> generateConfig(CoreConfigParameters parameters) async {
    final paras = parameters as HysteriaConfigParameters;
    final server = paras.server;
    if (server.protocol == Protocol.hysteria) {
      final hysteriaConfig = HysteriaConfig(
        server: '${server.address}:${server.port}',
        protocol: server.hysteriaProtocol,
        obfs: server.obfs,
        alpn: server.alpn,
        auth: server.authType != 'none'
            ? (server.authType == 'base64' ? server.authPayload : null)
            : null,
        authStr: server.authType != 'none'
            ? (server.authType == 'str' ? server.authPayload : null)
            : null,
        serverName: server.serverName,
        insecure: server.insecure,
        upMbps: server.upMbps,
        downMbps: server.downMbps,
        recvWindowConn: server.recvWindowConn,
        recvWindow: server.recvWindow,
        disableMtuDiscovery: server.disableMtuDiscovery,
        socks5: Socks5(
          listen: '127.0.0.1:${paras.additionalSocksPort}',
          timeout: 300,
          disableUdp: !paras.enableUdp,
        ),
      );
      usedPorts.add(paras.additionalSocksPort);

      return jsonEncode(hysteriaConfig.toJson());
    } else {
      throw Exception(
          'Hyteria does not support this server type: ${server.protocol}');
    }
  }
}

class HysteriaConfigParameters extends CoreConfigParameters {
  final HysteriaServer server;
  final int additionalSocksPort;
  final bool enableUdp;

  const HysteriaConfigParameters({
    required this.server,
    required this.additionalSocksPort,
    required this.enableUdp,
  });
}
