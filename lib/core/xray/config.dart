import 'package:json_annotation/json_annotation.dart';
import 'package:sphia/core/rule/xray.dart';

part 'config.g.dart';

@JsonSerializable(createFactory: false)
class XrayConfig {
  final Log? log;
  final Dns? dns;
  final List<Inbound>? inbounds;
  final List<Outbound>? outbounds;
  final Routing? routing;
  final Api? api;
  final Policy? policy;
  final Stats? stats;

  const XrayConfig({
    this.log,
    this.dns,
    this.inbounds,
    this.outbounds,
    this.routing,
    this.api,
    this.policy,
    this.stats,
  });

  Map<String, dynamic> toJson() => _$XrayConfigToJson(this);
}

@JsonSerializable(createFactory: false)
class Sniffing {
  final bool enabled;
  final List<String> destOverride;

  const Sniffing({
    this.enabled = true,
    this.destOverride = const ['http', 'tls'],
  });

  Map<String, dynamic> toJson() => _$SniffingToJson(this);
}

@JsonSerializable(createFactory: false)
class Dns {
  final List<DnsServer> servers;

  const Dns({
    required this.servers,
  });

  Map<String, dynamic> toJson() => _$DnsToJson(this);
}

@JsonSerializable(createFactory: false)
class DnsServer {
  final String address;
  final List<String>? domains;
  final bool? skipFallback;

  const DnsServer({
    required this.address,
    this.domains,
    this.skipFallback,
  });

  Map<String, dynamic> toJson() => _$DnsServerToJson(this);
}

@JsonSerializable(createFactory: false)
class Log {
  final String? access;
  final String? error;
  final String loglevel;

  const Log({
    this.access,
    this.error,
    required this.loglevel,
  });

  Map<String, dynamic> toJson() => _$LogToJson(this);
}

@JsonSerializable(createFactory: false)
class Inbound {
  final String? tag;
  final int port;
  final String listen;
  final String protocol;
  final Sniffing? sniffing;
  final InboundSetting settings;

  const Inbound({
    this.tag,
    required this.port,
    required this.listen,
    required this.protocol,
    this.sniffing,
    required this.settings,
  });

  Map<String, dynamic> toJson() => _$InboundToJson(this);
}

@JsonSerializable(createFactory: false)
class InboundSetting {
  final String? auth;
  final List<Accounts>? accounts;
  final bool? udp;
  final String? address;

  const InboundSetting({
    this.auth,
    this.accounts,
    this.udp,
    this.address,
  });

  Map<String, dynamic> toJson() => _$InboundSettingToJson(this);
}

@JsonSerializable(createFactory: false)
class Accounts {
  final String user;
  final String pass;

  const Accounts({
    required this.user,
    required this.pass,
  });

  Map<String, dynamic> toJson() => _$AccountsToJson(this);
}

@JsonSerializable(createFactory: false)
class Outbound {
  final String? tag;
  final String protocol;
  final OutboundSetting? settings;
  final StreamSettings? streamSettings;
  final Mux? mux;

  const Outbound({
    this.tag,
    required this.protocol,
    this.settings,
    this.streamSettings,
    this.mux,
  });

  Map<String, dynamic> toJson() => _$OutboundToJson(this);
}

@JsonSerializable(createFactory: false)
class OutboundSetting {
  final List<Vnext>? vnext;
  final List<dynamic>? servers;

  const OutboundSetting({
    this.vnext,
    this.servers,
  });

  Map<String, dynamic> toJson() => _$OutboundSettingToJson(this);
}

@JsonSerializable(createFactory: false)
class Socks {
  final String address;
  final int port;
  final List<User>? users;

  const Socks({
    required this.address,
    required this.port,
    this.users,
  });

  Map<String, dynamic> toJson() => _$SocksToJson(this);
}

@JsonSerializable(createFactory: false)
class Vnext {
  final String address;
  final int port;
  final List<User> users;

  const Vnext({
    required this.address,
    required this.port,
    required this.users,
  });

  Map<String, dynamic> toJson() => _$VnextToJson(this);
}

@JsonSerializable(createFactory: false)
class Shadowsocks {
  final String address;
  final int port;
  final String method;
  final String password;

  const Shadowsocks({
    required this.address,
    required this.port,
    required this.method,
    required this.password,
  });

  Map<String, dynamic> toJson() => _$ShadowsocksToJson(this);
}

@JsonSerializable(createFactory: false)
class Trojan {
  final String address;
  final int port;
  final String password;

  const Trojan({
    required this.address,
    required this.port,
    required this.password,
  });

  Map<String, dynamic> toJson() => _$TrojanToJson(this);
}

@JsonSerializable(createFactory: false)
class User {
  final String? user;
  final String? pass;
  final String? id;
  final int? alterId;
  final String? security;
  final String? encryption;
  final String? flow;

  const User({
    this.user,
    this.pass,
    this.id,
    this.alterId,
    this.security,
    this.encryption,
    this.flow,
  });

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(createFactory: false)
class StreamSettings {
  final String network;
  final String security;
  final TlsSettings? tlsSettings;
  final RealitySettings? realitySettings;
  final TcpSettings? tcpSettings;
  final WsSettings? wsSettings;
  final GrpcSettings? grpcSettings;
  final HttpUpgradeSettings? httpUpgradeSettings;

  const StreamSettings({
    required this.network,
    required this.security,
    this.tlsSettings,
    this.realitySettings,
    this.tcpSettings,
    this.wsSettings,
    this.grpcSettings,
    this.httpUpgradeSettings,
  });

  Map<String, dynamic> toJson() => _$StreamSettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class TcpSettings {
  final Header? header;

  const TcpSettings({
    this.header,
  });

  Map<String, dynamic> toJson() => _$TcpSettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class Header {
  final String? type;
  final Request? request;

  const Header({
    this.type,
    this.request,
  });

  Map<String, dynamic> toJson() => _$HeaderToJson(this);
}

@JsonSerializable(createFactory: false)
class Request {
  final String? version;
  final String? method;
  final List<String>? path;
  final TcpHeaders? headers;

  const Request({
    this.version,
    this.method,
    this.path,
    this.headers,
  });

  factory Request.httpGet(TcpHeaders? headers) => Request(
        version: '1.1',
        method: 'GET',
        path: ['/'],
        headers: headers ?? TcpHeaders.http(),
      );

  Map<String, dynamic> toJson() => _$RequestToJson(this);
}

@JsonSerializable(createFactory: false)
class TcpHeaders {
  @JsonKey(name: 'Host')
  final List<String>? host;
  @JsonKey(name: 'User-Agent')
  final List<String>? userAgent;
  @JsonKey(name: 'Accept-Encoding')
  final List<String>? acceptEncoding;
  @JsonKey(name: 'Connection')
  final List<String>? connection;
  @JsonKey(name: 'Pragma')
  final String? pragma;

  const TcpHeaders({
    this.host,
    this.userAgent,
    this.acceptEncoding,
    this.connection,
    this.pragma,
  });

  factory TcpHeaders.http([List<String>? host, List<String>? userAgent]) =>
      TcpHeaders(
        host: host,
        userAgent: userAgent,
        acceptEncoding: ['gzip, deflate'],
        connection: ['keep-alive'],
        pragma: 'no-cache',
      );

  Map<String, dynamic> toJson() => _$TcpHeadersToJson(this);
}

@JsonSerializable(createFactory: false)
class GrpcSettings {
  final String? serviceName;
  final bool? multiMode;

  const GrpcSettings({
    this.serviceName,
    this.multiMode,
  });

  Map<String, dynamic> toJson() => _$GrpcSettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class WsSettings {
  final String path;
  final Headers? headers;

  const WsSettings({
    required this.path,
    this.headers,
  });

  Map<String, dynamic> toJson() => _$WsSettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class Headers {
  final String? host;

  const Headers({
    this.host,
  });

  Map<String, dynamic> toJson() => _$HeadersToJson(this);
}

@JsonSerializable(createFactory: false)
class TlsSettings {
  final bool allowInsecure;
  final String? serverName;
  final String? fingerprint;

  const TlsSettings({
    required this.allowInsecure,
    this.serverName,
    this.fingerprint,
  });

  Map<String, dynamic> toJson() => _$TlsSettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class RealitySettings {
  final String? serverName;
  final String fingerprint;
  final String? shortId;
  final String publicKey;
  final String? spiderX;

  const RealitySettings({
    this.serverName,
    required this.fingerprint,
    this.shortId,
    required this.publicKey,
    this.spiderX,
  });

  Map<String, dynamic> toJson() => _$RealitySettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class HttpUpgradeSettings {
  final String path;
  final Headers? headers;

  const HttpUpgradeSettings({
    required this.path,
    this.headers,
  });

  Map<String, dynamic> toJson() => _$HttpUpgradeSettingsToJson(this);
}

@JsonSerializable(createFactory: false)
class Mux {
  final bool enabled;
  final int concurrency;

  const Mux({
    required this.enabled,
    required this.concurrency,
  });

  Map<String, dynamic> toJson() => _$MuxToJson(this);
}

@JsonSerializable(createFactory: false)
class Routing {
  final String domainStrategy;
  final String domainMatcher;
  final List<XrayRule> rules;

  const Routing({
    required this.domainStrategy,
    required this.domainMatcher,
    required this.rules,
  });

  Map<String, dynamic> toJson() => _$RoutingToJson(this);
}

@JsonSerializable(createFactory: false)
class Api {
  final String tag;
  final List<String>? services;

  const Api({
    required this.tag,
    this.services,
  });

  Map<String, dynamic> toJson() => _$ApiToJson(this);
}

@JsonSerializable(createFactory: false)
class Policy {
  final System system;

  const Policy({
    required this.system,
  });

  Map<String, dynamic> toJson() => _$PolicyToJson(this);
}

@JsonSerializable(createFactory: false)
class System {
  final bool? statsInboundUplink;
  final bool? statsInboundDownlink;
  final bool? statsOutboundUplink;
  final bool? statsOutboundDownlink;

  const System({
    this.statsInboundUplink,
    this.statsInboundDownlink,
    this.statsOutboundUplink,
    this.statsOutboundDownlink,
  });

  Map<String, dynamic> toJson() => _$SystemToJson(this);
}

@JsonSerializable(createFactory: false)
class Stats {
  const Stats();

  Map<String, dynamic> toJson() => _$StatsToJson(this);
}
