import 'dart:convert';
import 'dart:core';

import 'package:sphia/server/xray/server.dart';

class VMessHelper {
  static String getUri(XrayServer server) {
    final Map<String, dynamic> vmessJson = {
      'v': 2,
      'ps': server.remark,
      'add': server.address,
      'port': server.port,
      'id': server.authPayload,
      'aid': server.alterId,
      'scy': server.encryption,
      'net': server.transport,
      'type': 'none',
      'host': server.host,
      'path': server.transport == 'grpc' ? server.serviceName : server.path,
      'tls': server.tls,
      'sni': server.serverName,
      'fp': server.fingerprint,
    };
    vmessJson.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty));

    final jsonString = json.encode(vmessJson);

    return 'vmess://${base64UrlEncode(utf8.encode(jsonString))}';
  }

  static XrayServer parseUri(String uriString) {
    late final String vmessJson;
    final server = XrayServer.vmessDefaults();

    try {
      vmessJson = utf8.decode(base64Url.decode(uriString.substring(8)));
    } on Exception catch (_) {
      throw const FormatException('Failed to parse vmess URI');
    }

    try {
      final vmess = json.decode(vmessJson) as Map<String, dynamic>;
      server.remark = vmess['ps'] ?? '';
      server.address = vmess['add'];
      server.port =
          vmess['port'] is String ? int.parse(vmess['port']) : vmess['port'];
      server.authPayload = vmess['id'];
      server.alterId =
          vmess['aid'] is String ? int.parse(vmess['aid']) : vmess['aid'];
      if (vmess.containsKey('scy')) {
        server.encryption = vmess['scy'];
      }
      if (vmess.containsKey('type')) {
        server.encryption = vmess['type'];
      }
      server.transport = vmess['net'];
      switch (server.transport) {
        case 'grpc':
          server.serviceName = vmess['path'];
          break;
        default:
          server.path = vmess['path'];
          break;
      }
      server.host = vmess['host'];
      server.tls = vmess['tls'] ?? 'none';
      server.serverName = vmess['sni'];
      server.fingerprint = vmess['fp'];
    } on Exception catch (_) {
      throw const FormatException('Failed to parse vmess URI');
    }
    return server;
  }
}
