import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/uri/uri.dart';
import 'package:sphia/core/rule/extension.dart';
import 'package:sphia/core/rule/xray.dart';
import 'package:sphia/core/xray/config.dart';
import 'package:sphia/core/xray/core.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/server/xray/server.dart';

extension XrayGenerate on XrayCore {
  Dns genDns(String remoteDns, String directDns) {
    return Dns(
      servers: [
        DnsServer(
          address: remoteDns,
          domains: ['geosite:geolocation-!cn'],
        ),
        DnsServer(
          address: directDns,
          domains: [
            'geosite:cn',
          ],
          skipFallback: true,
        ),
      ],
    );
  }

  Inbound genInbound({
    required String protocol,
    required int port,
    required String listen,
    required bool enableSniffing,
    required bool isAuth,
    required String user,
    required String pass,
    required bool enableUdp,
  }) {
    return Inbound(
      port: port,
      listen: listen,
      protocol: protocol,
      sniffing: enableSniffing ? const Sniffing() : null,
      settings: InboundSetting(
        auth: isAuth ? 'password' : 'noauth',
        accounts: isAuth
            ? [
                Accounts(
                  user: user,
                  pass: pass,
                ),
              ]
            : null,
        udp: enableUdp,
      ),
    );
  }

  Inbound genDokodemoInbound(int apiPort) {
    return Inbound(
      tag: 'api',
      port: apiPort,
      listen: '127.0.0.1',
      protocol: 'dokodemo-door',
      settings: const InboundSetting(address: '127.0.0.1'),
    );
  }

  Outbound genOutbound({
    required ServerModel server,
    String? userAgent,
    String? outboundTag,
  }) {
    final tag = outboundTag ?? 'proxy';
    switch (server.protocol) {
      case Protocol.socks:
      case Protocol.vmess:
      case Protocol.vless:
        return _genXrayOutbound(server as XrayServer, tag);
      case Protocol.shadowsocks:
        return _genShadowsocksOutbound(
            server as ShadowsocksServer, userAgent, tag);
      case Protocol.trojan:
        return _genTrojanOutbound(server as TrojanServer, tag);
      default:
        throw Exception(
            'Xray-Core does not support this server type: ${server.protocol}');
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
          'Xray-Core does not support this server type: ${server.protocol}');
    }
  }

  Outbound _genSocksOutbound(XrayServer server, String outboundTag) {
    return Outbound(
      protocol: 'socks',
      tag: outboundTag,
      settings: OutboundSetting(
        servers: [
          Socks(
            address: server.address,
            port: server.port,
          ),
        ],
      ),
    );
  }

  Outbound _genVProtocolOutbound(XrayServer server, String outboundTag) {
    final security = server.tls;
    final tlsSettings = security == 'tls'
        ? TlsSettings(
            allowInsecure: server.allowInsecure,
            serverName: server.serverName ?? server.address,
            fingerprint: server.fingerprint,
          )
        : null;
    final realitySettings = security == 'reality'
        ? RealitySettings(
            serverName: server.serverName ?? server.address,
            fingerprint: server.fingerprint ?? 'chrome',
            shortId: server.shortId,
            publicKey: server.publicKey ?? '',
            spiderX: server.spiderX,
          )
        : null;
    final streamSettings = StreamSettings(
      network: server.transport,
      security: security,
      tlsSettings: tlsSettings,
      realitySettings: realitySettings,
      wsSettings: server.transport == 'ws'
          ? WsSettings(
              path: server.path ?? '/',
              headers: Headers(host: server.host ?? server.address),
            )
          : null,
      grpcSettings: server.transport == 'grpc'
          ? GrpcSettings(
              serviceName: server.serviceName ?? '/',
              multiMode: server.grpcMode == 'multi',
            )
          : null,
      httpUpgradeSettings: server.transport == 'httpupgrade'
          ? HttpUpgradeSettings(
              path: server.path ?? '/',
              headers: Headers(host: server.host ?? server.address),
            )
          : null,
    );
    return Outbound(
      protocol: server.protocol.name,
      tag: outboundTag,
      settings: OutboundSetting(
        vnext: [
          Vnext(
            address: server.address,
            port: server.port,
            users: [
              User(
                id: server.authPayload,
                encryption: server.protocol == Protocol.vless
                    ? server.encryption
                    : null,
                flow: server.flow,
                security: server.protocol == Protocol.vmess
                    ? server.encryption
                    : null,
                alterId:
                    server.protocol == Protocol.vmess ? server.alterId : null,
              ),
            ],
          ),
        ],
      ),
      streamSettings: streamSettings,
    );
  }

  Outbound _genShadowsocksOutbound(
    ShadowsocksServer server,
    String? userAgent,
    String outboundTag,
  ) {
    StreamSettings? streamSettings;
    String? network;
    String security = 'none';
    TlsSettings? tlsSettings;
    String? host;
    if (server.plugin != null) {
      if (server.pluginOpts != null) {
        final pluginParameters =
            UriHelper.extractPluginOpts(server.pluginOpts!);

        if (pluginParameters['obfs'] == 'ws') {
          network = 'ws';
        } else if (pluginParameters['obfs'] == 'http') {
          network = 'tcp';
        } else if (pluginParameters['obfs'] == 'tls') {
          network = 'tcp';
        }

        if (pluginParameters['obfs'] == 'tls') {
          security = 'tls';
        }

        tlsSettings = security == 'tls'
            ? TlsSettings(
                allowInsecure: false,
                serverName: pluginParameters['obfs-host'] ?? server.address,
              )
            : null;

        host = pluginParameters['obfs-host'] ?? server.address;
      }

      if (network != null) {
        streamSettings = StreamSettings(
          network: network,
          security: security,
          tlsSettings: tlsSettings,
          tcpSettings: network == 'tcp'
              ? TcpSettings(
                  header: Header(
                    type: 'http',
                    request: Request.httpGet(
                      TcpHeaders.http(
                        host != null ? [host] : [server.address],
                        userAgent == null ? [userAgent!] : null,
                      ),
                    ),
                  ),
                )
              : null,
          wsSettings: network == 'ws'
              ? WsSettings(
                  path: '',
                  headers: Headers(
                    host: host ?? server.address,
                  ),
                )
              : null,
          grpcSettings: network == 'grpc'
              ? GrpcSettings(
                  serviceName: host ?? server.address,
                )
              : null,
        );
      }
    }
    return Outbound(
      protocol: 'shadowsocks',
      tag: outboundTag,
      settings: OutboundSetting(
        servers: [
          Shadowsocks(
            address: server.address,
            port: server.port,
            method: server.encryption,
            password: server.authPayload,
          )
        ],
      ),
      streamSettings: streamSettings,
    );
  }

  Outbound _genTrojanOutbound(TrojanServer server, String outboundTag) {
    final streamSettings = StreamSettings(
      network: 'tcp',
      security: 'tls',
      tlsSettings: TlsSettings(
        allowInsecure: server.allowInsecure,
        serverName: server.serverName ?? server.address,
      ),
    );
    return Outbound(
      protocol: 'trojan',
      tag: outboundTag,
      settings: OutboundSetting(
        servers: [
          Trojan(
            address: server.address,
            port: server.port,
            password: server.authPayload,
          ),
        ],
      ),
      streamSettings: streamSettings,
    );
  }

  Routing genRouting({
    required String domainStrategy,
    required String domainMatcher,
    required List<Rule> rules,
    required bool enableApi,
  }) {
    List<XrayRule> xrayRules = [];
    if (enableApi) {
      xrayRules.add(
        const XrayRule(
          inboundTag: 'api',
          outboundTag: 'api',
        ),
      );
    }
    for (var rule in rules) {
      xrayRules.add(rule.toXrayRule(determineOutboundTag(rule.outboundTag)));
    }
    return Routing(
      domainStrategy: domainStrategy,
      domainMatcher: domainMatcher,
      rules: xrayRules,
    );
  }
}
