import 'package:json_annotation/json_annotation.dart';

part 'sing.g.dart';

@JsonSerializable(createFactory: false)
class SingBoxRule {
  final String? inbound;
  final String? outbound;
  final List<String>? geosite;
  final List<String>? domain;
  final List<String>? geoip;
  @JsonKey(name: 'ip_cidr')
  final List<String>? ipCidr;
  final List<int>? port;
  @JsonKey(name: 'port_range')
  final List<String>? portRange;
  @JsonKey(name: 'source_geoip')
  final List<String>? sourceGeoip;
  @JsonKey(name: 'source_ip_cidr')
  final List<String>? sourceIpCidr;
  @JsonKey(name: 'source_port')
  final List<int>? sourcePort;
  @JsonKey(name: 'source_port_range')
  final List<String>? sourcePortRange;
  final String? network;
  final List<String>? protocol;
  @JsonKey(name: 'process_name')
  final List<String>? processName;

  const SingBoxRule({
    this.inbound,
    this.outbound,
    this.domain,
    this.geosite,
    this.ipCidr,
    this.geoip,
    this.port,
    this.portRange,
    this.network,
    this.sourceGeoip,
    this.sourceIpCidr,
    this.sourcePort,
    this.sourcePortRange,
    this.protocol,
    this.processName,
  });

  Map<String, dynamic> toJson() => _$SingBoxRuleToJson(this);
}

@JsonSerializable(createFactory: false)
class SingBoxDnsRule {
  final List<String>? geosite;
  final List<String>? geoip;
  final List<String>? domain;
  final String? server;
  @JsonKey(name: 'disable_cache')
  final bool? disableCache;
  final List<String>? outbound;

  const SingBoxDnsRule({
    this.geosite,
    this.geoip,
    this.domain,
    this.server,
    this.disableCache,
    this.outbound,
  });

  Map<String, dynamic> toJson() => _$SingBoxDnsRuleToJson(this);
}
