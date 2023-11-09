import 'package:json_annotation/json_annotation.dart';
import 'package:sphia/server/server_base.dart';

part 'server.g.dart';

@JsonSerializable(includeIfNull: false)
class HysteriaServer extends ServerBase {
  String hysteriaProtocol;
  String? obfs;
  String? alpn;
  String authType;
  String? authPayload;
  @JsonKey(name: 'server_name')
  String? serverName;
  bool insecure;
  @JsonKey(name: 'up_mbps')
  int upMbps;
  @JsonKey(name: 'down_mbps')
  int downMbps;
  @JsonKey(name: 'recv_window_conn')
  int? recvWindowConn;
  @JsonKey(name: 'recv_window')
  int? recvWindow;
  @JsonKey(name: 'disable_mtu_discovery')
  bool disableMtuDiscovery;

  HysteriaServer({
    required String protocol,
    required String address,
    required int port,
    required String remark,
    required this.hysteriaProtocol,
    this.obfs,
    this.alpn,
    required this.authType,
    this.authPayload,
    this.serverName,
    required this.insecure,
    required this.upMbps,
    required this.downMbps,
    this.recvWindowConn,
    this.recvWindow,
    required this.disableMtuDiscovery,
    int? routingProvider,
    int? protocolProvider,
  }) : super(
          protocol: protocol,
          address: address,
          port: port,
          remark: remark,
          routingProvider: routingProvider,
          protocolProvider: protocolProvider,
        );

  factory HysteriaServer.defaults() => HysteriaServer(
        protocol: 'hysteria',
        address: '',
        port: 0,
        remark: '',
        hysteriaProtocol: 'udp',
        authType: 'none',
        insecure: false,
        upMbps: 10,
        downMbps: 50,
        recvWindowConn: 15728640,
        recvWindow: 67108864,
        disableMtuDiscovery: false,
      );

  factory HysteriaServer.fromJson(Map<String, dynamic> json) =>
      _$HysteriaServerFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$HysteriaServerToJson(this);
}
