import 'package:path/path.dart' as p;
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/core/rule/extension.dart';
import 'package:sphia/core/rule/sing.dart';
import 'package:sphia/core/sing/config.dart';
import 'package:sphia/core/sing/core.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/server/xray/server.dart';

extension SingBoxGenerate on SingBoxCore {
  Future<Dns> genDns({
    required String remoteDns,
    required String directDns,
    required String dnsResolver,
    required String serverAddress,
    required bool ipv4Only,
  }) async {
    if (directDns.contains('+local://')) {
      directDns = directDns.replaceFirst('+local', '');
    }

    final dnsRules = [
      if (serverAddress != '127.0.0.1') ...[
        SingBoxDnsRule(
          domain: [serverAddress],
          server: 'local',
        )
      ],
      const SingBoxDnsRule(
        domain: ['geosite:geolocation-!cn'],
        server: 'remote',
      ),
      const SingBoxDnsRule(
        domain: ['geosite:cn'],
        server: 'local',
      ),
    ];

    return Dns(
      servers: [
        DnsServer(
          tag: 'remote',
          address: remoteDns,
          addressResolver: 'resolver',
          detour: 'proxy',
          strategy: ipv4Only ? 'ipv4_only' : null,
        ),
        DnsServer(
          tag: 'local',
          address: directDns,
          addressResolver: 'resolver',
          detour: 'direct',
          strategy: ipv4Only ? 'ipv4_only' : null,
        ),
        DnsServer(
          tag: 'resolver',
          address: dnsResolver,
          detour: 'direct',
        ),
      ],
      rules: dnsRules,
      finalTag: 'remote',
    );
  }

  Route genRoute(List<Rule> rules, bool configureDns) {
    final singBoxRules = <SingBoxRule>[];
    singBoxRules.add(SingBoxRule(
      processName: _getCoreFileNames(),
      outbound: 'direct',
    ));
    if (configureDns) {
      singBoxRules.add(
        const SingBoxRule(
          protocol: ['dns'],
          outbound: 'dns-out',
        ),
      );
    }
    for (var rule in rules) {
      singBoxRules
          .add(rule.toSingBoxRule(determineOutboundTag(rule.outboundTag)));
    }
    final binPath = IoHelper.binPath;
    return Route(
      geoip: Geoip(path: p.join(binPath, 'geoip.db')),
      geosite: Geosite(path: p.join(binPath, 'geosite.db')),
      rules: singBoxRules,
      autoDetectInterface: true,
      finalTag: 'proxy',
    );
  }

  List<String> _getCoreFileNames() {
    final fileNames = <String>[];
    for (var info in proxyResInfoList) {
      if (info.isCore) {
        fileNames.add(info.binFileName);
      }
    }
    return fileNames;
  }

  Inbound genMixedInbound(String listen, int listenPort, List<User>? users) {
    return Inbound(
      type: 'mixed',
      listen: listen,
      listenPort: listenPort,
      users: users,
      domainStrategy: 'prefer_ipv4',
    );
  }

  Inbound genTunInbound({
    required String? inet4Address,
    required String? inet6Address,
    required int mtu,
    required String stack,
    required bool autoRoute,
    required bool strictRoute,
    required bool sniff,
    required bool endpointIndependentNat,
  }) {
    return Inbound(
      type: 'tun',
      inet4Address: inet4Address,
      inet6Address: inet6Address,
      mtu: mtu,
      autoRoute: autoRoute,
      strictRoute: strictRoute,
      stack: stack,
      sniff: sniff,
      endpointIndependentNat: endpointIndependentNat,
    );
  }

  Outbound genOutbound({required ServerModel server, String? outboundTag}) {
    final tag = outboundTag ?? 'proxy';
    switch (server.protocol) {
      case Protocol.socks:
      case Protocol.vmess:
      case Protocol.vless:
        return _genXrayOutbound(server as XrayServer, tag);
      case Protocol.shadowsocks:
        return _genShadowsocksOutbound(server as ShadowsocksServer, tag);
      case Protocol.trojan:
        return _genTrojanOutbound(server as TrojanServer, tag);
      case Protocol.hysteria:
        return _genHysteriaOutbound(server as HysteriaServer, tag);
      default:
        throw Exception(
            'Sing-Box does not support this server type: ${server.protocol}');
    }
  }

  Outbound _genXrayOutbound(XrayServer server, String outboundTag) {
    if (server.protocol == Protocol.socks) {
      return _genSocksOutbound(server, outboundTag);
    } else if (server.protocol == Protocol.vmess ||
        server.protocol == Protocol.vless) {
      return _genVProtocolOutbound(server, outboundTag);
    } else {
      throw Exception(
          'Sing-Box does not support this server type: ${server.protocol}');
    }
  }

  Outbound _genSocksOutbound(XrayServer server, String outboundTag) {
    return Outbound(
      type: 'socks',
      server: server.address,
      serverPort: server.port,
      version: '5',
      tag: outboundTag,
    );
  }

  Outbound _genVProtocolOutbound(XrayServer server, String outboundTag) {
    final utls = UTls(
      enabled: server.fingerprint != null && server.fingerprint != 'none',
      fingerprint: server.fingerprint,
    );
    final reality = Reality(
      enabled: server.tls == 'reality',
      publicKey: server.publicKey ?? '',
      shortId: server.shortId,
    );
    final tls = Tls(
      enabled: server.tls == 'tls',
      serverName: server.serverName ?? server.address,
      insecure: server.allowInsecure,
      utls: utls,
      reality: reality,
    );
    Transport? transport;
    if (server.transport != 'tcp') {
      if (server.transport == 'ws') {
        if (server.path != null && server.path!.contains('?ed=')) {
          final splitPath = server.path!.split('?ed=');
          final path = splitPath.first;
          final earlyData = int.tryParse(splitPath.last);
          transport = Transport(
            type: 'ws',
            earlyDataHeaderName: 'Sec-WebSocket-Protocol',
            maxEarlyData: earlyData,
            path: path,
            headers: Headers(
              host: server.host ?? server.address,
            ),
          );
        } else {
          transport = Transport(
            type: 'ws',
            path: (server.path ?? '/'),
          );
        }
      } else {
        transport = Transport(
          type: server.transport,
          host: server.transport == 'httpupgrade'
              ? (server.host ?? server.address)
              : null,
          path: server.transport == 'httpupgrade' ? (server.path ?? '/') : null,
          serviceName:
              server.transport == 'grpc' ? (server.serviceName ?? '/') : null,
        );
      }
    }
    return Outbound(
      type: server.protocol.name,
      server: server.address,
      serverPort: server.port,
      uuid: server.authPayload,
      flow: server.flow,
      alterId: server.protocol == Protocol.vmess ? server.alterId : null,
      security: server.protocol == Protocol.vmess ? server.encryption : null,
      tls: tls,
      transport: transport,
      tag: outboundTag,
    );
  }

  Outbound _genShadowsocksOutbound(
    ShadowsocksServer server,
    String outboundTag,
  ) {
    return Outbound(
      type: 'shadowsocks',
      server: server.address,
      serverPort: server.port,
      method: server.encryption,
      password: server.authPayload,
      plugin: server.plugin,
      pluginOpts: server.plugin,
      tag: outboundTag,
    );
  }

  Outbound _genTrojanOutbound(TrojanServer server, String outboundTag) {
    final tls = Tls(
      enabled: true,
      serverName: server.serverName ?? server.address,
      insecure: server.allowInsecure,
    );
    return Outbound(
      type: 'trojan',
      server: server.address,
      serverPort: server.port,
      password: server.authPayload,
      network: 'tcp',
      tls: tls,
      tag: outboundTag,
    );
  }

  Outbound _genHysteriaOutbound(HysteriaServer server, String outboundTag) {
    final tls = Tls(
      enabled: true,
      serverName: server.serverName ?? server.address,
      insecure: server.insecure,
      alpn: server.alpn?.split(','),
    );
    return Outbound(
      type: 'hysteria',
      server: server.address,
      serverPort: server.port,
      upMbps: server.upMbps,
      downMbps: server.downMbps,
      obfs: server.obfs,
      auth: server.authType == 'base64' ? server.authPayload : null,
      authStr: server.authType == 'str' ? server.authPayload : null,
      recvWindowConn: server.recvWindowConn,
      recvWindow: server.recvWindow,
      tls: tls,
      tag: outboundTag,
    );
  }
}
