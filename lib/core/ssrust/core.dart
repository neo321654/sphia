import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/ssrust/core_info.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';

class ShadowsocksRustCore extends Core with ProxyCore {
  ShadowsocksRustCore(Ref ref)
      : super(
          info: const ShadowsocksRustInfo(),
          args: [],
          ref: ref,
        );

  @override
  Future<void> configure() async {
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final server = runningServer as ShadowsocksServer;
    if (server.protocol == Protocol.shadowsocks) {
      final arguments = [
        '-s',
        '${server.address}:${server.port}',
        '-b',
        '127.0.0.1:${sphiaConfig.additionalSocksPort}',
        '-m',
        server.encryption,
        '-k',
        server.authPayload,
      ];
      usedPorts.add(sphiaConfig.additionalSocksPort);
      args.addAll(arguments);
    } else {
      throw Exception(
          'Shadowsocks-Rust does not support this server type: ${server.protocol}');
    }
  }

  @override
  Future<String> generateConfig(CoreConfigParameters parameters) {
    throw UnimplementedError();
  }

  String convertPluginOpts(String pluginOpts) {
    String result = '';
    final opts = pluginOpts.split(';');
    for (var opt in opts) {
      if (opt.contains('=')) {
        result += '${opt.split('=')[0]}=${opt.split('=')[1]}&';
      } else {
        result += '$opt&';
      }
    }
    return result.substring(0, result.length - 1);
  }
}
