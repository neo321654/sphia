import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

@JsonSerializable(createFactory: false)
class HysteriaConfig {
  final String server;
  final String protocol;
  final String? obfs;
  final String? alpn;
  final String? auth;
  @JsonKey(name: 'auth_str')
  final String? authStr;
  @JsonKey(name: 'server_name')
  final String? serverName;
  final bool insecure;
  @JsonKey(name: 'up_mbps')
  final int upMbps;
  @JsonKey(name: 'down_mbps')
  final int downMbps;
  @JsonKey(name: 'recv_window_conn')
  final int? recvWindowConn;
  @JsonKey(name: 'recv_window')
  final int? recvWindow;
  @JsonKey(name: 'disable_mtu_discovery')
  final bool disableMtuDiscovery;
  final Socks5 socks5;

  const HysteriaConfig({
    required this.server,
    required this.protocol,
    this.obfs,
    this.alpn,
    this.auth,
    this.authStr,
    this.serverName,
    required this.insecure,
    required this.upMbps,
    required this.downMbps,
    this.recvWindowConn,
    this.recvWindow,
    required this.disableMtuDiscovery,
    required this.socks5,
  });

  Map<String, dynamic> toJson() => _$HysteriaConfigToJson(this);
}

@JsonSerializable(createFactory: false)
class Socks5 {
  final String listen;
  final int? timeout;
  @JsonKey(name: 'disable_udp')
  final bool disableUdp;

  const Socks5({
    required this.listen,
    this.timeout,
    required this.disableUdp,
  });

  Map<String, dynamic> toJson() => _$Socks5ToJson(this);
}
