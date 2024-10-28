import 'package:json_annotation/json_annotation.dart';
import 'package:sphia/core/rule/sing.dart';

part 'config.g.dart';

@JsonSerializable(createFactory: false)
class SingBoxConfig {
  final Log? log;
  final Dns? dns;
  final Route? route;
  final List<Inbound>? inbounds;
  final List<Outbound>? outbounds;
  final Experimental? experimental;

  const SingBoxConfig({
    this.log,
    this.dns,
    this.route,
    this.inbounds,
    this.outbounds,
    this.experimental,
  });

  Map<String, dynamic> toJson() => _$SingBoxConfigToJson(this);
}

@JsonSerializable(createFactory: false)
class Log {
  final bool disabled;
  final String? level;
  final String? output;
  final bool timestamp;

  const Log({
    required this.disabled,
    this.level,
    this.output,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => _$LogToJson(this);
}

@JsonSerializable(createFactory: false)
class Dns {
  final List<DnsServer> servers;
  final List<SingBoxDnsRule> rules;
  @JsonKey(name: 'final')
  final String? finalTag;

  const Dns({
    required this.servers,
    required this.rules,
    this.finalTag,
  });

  Map<String, dynamic> toJson() => _$DnsToJson(this);
}

@JsonSerializable(createFactory: false)
class DnsServer {
  final String tag;
  final String address;
  @JsonKey(name: 'address_resolver')
  final String? addressResolver;
  final String? strategy;
  final String? detour;

  const DnsServer({
    required this.tag,
    required this.address,
    this.addressResolver,
    this.strategy,
    this.detour,
  });

  Map<String, dynamic> toJson() => _$DnsServerToJson(this);
}

@JsonSerializable(createFactory: false)
class Route {
  final Geoip? geoip;
  final Geosite? geosite;
  final List<SingBoxRule> rules;
  @JsonKey(name: 'auto_detect_interface')
  final bool autoDetectInterface;
  @JsonKey(name: 'final')
  final String? finalTag;

  const Route({
    this.geoip,
    this.geosite,
    required this.rules,
    required this.autoDetectInterface,
    this.finalTag,
  });

  Map<String, dynamic> toJson() => _$RouteToJson(this);
}

@JsonSerializable(createFactory: false)
class Geoip {
  final String path;

  const Geoip({
    required this.path,
  });

  Map<String, dynamic> toJson() => _$GeoipToJson(this);
}

@JsonSerializable(createFactory: false)
class Geosite {
  final String path;

  const Geosite({
    required this.path,
  });

  Map<String, dynamic> toJson() => _$GeositeToJson(this);
}

@JsonSerializable(createFactory: false)
class Inbound {
  final String type;
  final String? tag;
  final String? listen;
  @JsonKey(name: 'listen_port')
  final int? listenPort;
  final List<User>? users;
  @JsonKey(name: 'interface_name')
  final String? interfaceName;
  @JsonKey(name: 'inet4_address')
  final String? inet4Address;
  @JsonKey(name: 'inet6_address')
  final String? inet6Address;
  final int? mtu;
  @JsonKey(name: 'auto_route')
  final bool? autoRoute;
  @JsonKey(name: 'strict_route')
  final bool? strictRoute;
  final String? stack;
  final bool? sniff;
  @JsonKey(name: 'endpoint_independent_nat')
  final bool? endpointIndependentNat;
  @JsonKey(name: 'domain_strategy')
  final String? domainStrategy;

  const Inbound({
    required this.type,
    this.tag,
    this.listen,
    this.listenPort,
    this.users,
    this.interfaceName,
    this.inet4Address,
    this.inet6Address,
    this.mtu,
    this.autoRoute,
    this.strictRoute,
    this.stack,
    this.sniff,
    this.endpointIndependentNat,
    this.domainStrategy,
  });

  Map<String, dynamic> toJson() => _$InboundToJson(this);
}

@JsonSerializable(createFactory: false)
class Outbound {
  final String type;
  final String? tag;
  final String? server;
  @JsonKey(name: 'server_port')
  final int? serverPort;
  final String? version;
  final String? username;
  final String? method;
  final String? password;
  final String? plugin;
  @JsonKey(name: 'plugin_opts')
  final String? pluginOpts;
  final String? uuid;
  final String? flow;
  final String? security;
  @JsonKey(name: 'alter_id')
  final int? alterId;
  final String? network;
  final Tls? tls;
  final Transport? transport;
  @JsonKey(name: 'up_mbps')
  final int? upMbps;
  @JsonKey(name: 'down_mbps')
  final int? downMbps;
  final String? obfs;
  final String? auth;
  @JsonKey(name: 'auth_str')
  final String? authStr;
  @JsonKey(name: 'recv_window_conn')
  final int? recvWindowConn;
  @JsonKey(name: 'recv_window')
  final int? recvWindow;
  @JsonKey(name: 'disable_mtu_discovery')
  final int? disableMtuDiscovery;

  const Outbound({
    required this.type,
    this.tag,
    this.server,
    this.serverPort,
    this.version,
    this.username,
    this.method,
    this.password,
    this.plugin,
    this.pluginOpts,
    this.uuid,
    this.flow,
    this.security,
    this.alterId,
    this.network,
    this.tls,
    this.transport,
    this.upMbps,
    this.downMbps,
    this.obfs,
    this.auth,
    this.authStr,
    this.recvWindowConn,
    this.recvWindow,
    this.disableMtuDiscovery,
  });

  Map<String, dynamic> toJson() => _$OutboundToJson(this);
}

@JsonSerializable(createFactory: false)
class Tls {
  final bool enabled;
  @JsonKey(name: 'server_name')
  final String serverName;
  final bool insecure;
  final List<String>? alpn;
  final UTls? utls;
  final Reality? reality;

  const Tls({
    required this.enabled,
    required this.serverName,
    required this.insecure,
    this.alpn,
    this.utls,
    this.reality,
  });

  Map<String, dynamic> toJson() => _$TlsToJson(this);
}

@JsonSerializable(createFactory: false)
class UTls {
  final bool enabled;
  final String? fingerprint;

  const UTls({
    required this.enabled,
    this.fingerprint,
  });

  Map<String, dynamic> toJson() => _$UTlsToJson(this);
}

@JsonSerializable(createFactory: false)
class Reality {
  final bool enabled;
  @JsonKey(name: 'public_key')
  final String publicKey;
  @JsonKey(name: 'short_id')
  final String? shortId;

  const Reality({
    required this.enabled,
    required this.publicKey,
    this.shortId,
  });

  Map<String, dynamic> toJson() => _$RealityToJson(this);
}

@JsonSerializable(createFactory: false)
class Transport {
  final String type;
  final String? host;
  final String? path;
  @JsonKey(name: 'service_name')
  final String? serviceName;
  @JsonKey(name: 'max_early_data')
  final int? maxEarlyData;
  @JsonKey(name: 'early_data_header_name')
  final String? earlyDataHeaderName;
  final Headers? headers;

  const Transport({
    required this.type,
    this.host,
    this.path,
    this.serviceName,
    this.maxEarlyData,
    this.earlyDataHeaderName,
    this.headers,
  });

  Map<String, dynamic> toJson() => _$TransportToJson(this);
}

@JsonSerializable(createFactory: false)
class Headers {
  @JsonKey(name: 'Host')
  final String host;

  const Headers({
    required this.host,
  });

  Map<String, dynamic> toJson() => _$HeadersToJson(this);
}

@JsonSerializable(createFactory: false)
class User {
  final String? username;
  final String? password;

  const User({
    this.username,
    this.password,
  });

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(createFactory: false)
class Experimental {
  @JsonKey(name: 'clash_api')
  final ClashApi? clashApi;
  @JsonKey(name: 'cache_file')
  final CacheFile? cacheFile;

  const Experimental({
    this.clashApi,
    this.cacheFile,
  });

  Map<String, dynamic> toJson() => _$ExperimentalToJson(this);
}

@JsonSerializable(createFactory: false)
class ClashApi {
  @JsonKey(name: 'external_controller')
  final String externalController;
  @JsonKey(name: 'store_selected')
  final bool? storeSelected; // deprecated since v1.8.0
  @JsonKey(name: 'cache_file')
  final String? cacheFile; // deprecated since v1.8.0

  const ClashApi({
    required this.externalController,
    this.storeSelected,
    this.cacheFile,
  });

  Map<String, dynamic> toJson() => _$ClashApiToJson(this);
}

@JsonSerializable(createFactory: false)
class CacheFile {
  final bool enabled;
  final String path;

  const CacheFile({
    required this.enabled,
    required this.path,
  });

  Map<String, dynamic> toJson() => _$CacheFileToJson(this);
}
