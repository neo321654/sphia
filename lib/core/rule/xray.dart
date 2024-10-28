import 'package:json_annotation/json_annotation.dart';

part 'xray.g.dart';

@JsonSerializable(createFactory: false)
class XrayRule {
  final String type = 'field';
  final String? inboundTag;
  final String? outboundTag;
  final List<String>? domain;
  final List<String>? ip;
  final String? port;
  final List<String>? source;
  final String? sourcePort;
  final String? network;
  final List<String>? protocol;

  const XrayRule({
    this.inboundTag,
    this.outboundTag,
    this.domain,
    this.ip,
    this.port,
    this.sourcePort,
    this.network,
    this.protocol,
    this.source,
  });

  Map<String, dynamic> toJson() => _$XrayRuleToJson(this);
}
