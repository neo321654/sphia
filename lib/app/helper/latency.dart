import 'dart:convert';
import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/core/sing/config.dart';
import 'package:sphia/core/sing/core.dart';
import 'package:sphia/core/sing/generate.dart';
import 'package:sphia/server/server_model.dart';

const latencyGreen = 200;
const latencyYellow = 500;
const latencyFailure = -1;
const timeout = Duration(seconds: 1);
const latencyApiPort = 11109; // prevent conflict with other ports
const latencyCacheDbFileName = 'latency.db';

class IcmpLatency {
  static Future<int> testIcmpLatency(String address) async {
    try {
      final result = await Ping(
        address,
        count: 1,
        timeout: timeout.inSeconds,
        forceCodepage: true,
      ).stream.first;
      final latency = result.response?.time?.inMilliseconds;
      if (latency != null) {
        return latency;
      } else {
        throw Exception('Failed to get ICMP latency for $address: $result');
      }
    } catch (e) {
      throw Exception('Failed to get ICMP latency for $address: $e');
    }
  }
}

class TcpLatency {
  static Future<int> testTcpLatency(String address, int port) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(address, port, timeout: timeout);
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      await socket.close();
      return latency;
    } catch (e) {
      throw Exception('Failed to get TCP latency for $address:$port: $e');
    }
  }
}

class UrlLatency {
  final List<ServerModel> servers;
  late final String url;
  late final Map<String, String> params;
  final client = HttpClient();
  final SingBoxCore core;

  UrlLatency({
    required this.servers,
    required String testUrl,
    required this.core,
  }) {
    url = 'http://localhost:$latencyApiPort/proxies';
    params = {'timeout': timeout.inMilliseconds.toString(), 'url': testUrl};
  }

  Future<int> testUrlLatency(String tag) async {
    try {
      final uri = Uri.parse('$url/$tag/delay').replace(queryParameters: params);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
            'Failed to get real link latency for $tag: ${response.statusCode}');
      }
      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);
      final latency = json['delay'] as int?;
      if (latency != null) {
        return latency;
      } else {
        throw Exception('Failed to get real link latency for $tag: $json');
      }
    } catch (e) {
      throw Exception('Failed to get real link latency for $tag: $e');
    }
  }

  Future<void> init(
      SphiaConfig sphiaConfig, VersionConfig versionConfig) async {
    final outbounds = <Outbound>[];
    for (final server in servers) {
      outbounds.add(
        core.genOutbound(server: server, outboundTag: 'proxy-${server.id}'),
      );
    }
    const tmpId = 1; // just take place
    const rules = [
      Rule(
        id: tmpId,
        groupId: tmpId,
        name: 'Proxy',
        enabled: true,
        outboundTag: outboundProxyId,
        port: '0-65535',
      ),
    ];

    final parameters = SingConfigParameters(
      outbounds: outbounds,
      rules: rules,
      configureDns: false,
      enableApi: true,
      coreApiPort: latencyApiPort,
      enableTun: false,
      addMixedInbound: false,
      sphiaConfig: sphiaConfig.copyWith(enableCoreLog: false),
      versionConfig: versionConfig,
      cacheDbFileName: latencyCacheDbFileName,
    );
    try {
      core.servers.addAll(servers);
      final jsonString = await core.generateConfig(parameters);
      await core.writeConfig(jsonString);
      await core.start(manual: true);
    } catch (e) {
      client.close();
      await core.stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    await core.stop();
    client.close();
  }
}
