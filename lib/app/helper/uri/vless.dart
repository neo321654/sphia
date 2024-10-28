import 'dart:core';

import 'package:sphia/server/xray/server.dart';

class VlessHelper {
  static String getUri(XrayServer server) {
    final queryParameters = {
      'type': server.transport,
      'encryption': server.encryption,
      'flow': server.flow,
      'security': server.tls != 'none' ? server.tls : null,
      'sni': server.serverName,
      'fp': server.fingerprint,
      'pbk': server.publicKey,
      'sid': server.shortId,
      'spx': server.spiderX,
    };

    if (server.transport == 'ws' || server.transport == 'httpupgrade') {
      queryParameters['path'] = server.path;
      queryParameters['host'] = server.host;
    } else if (server.transport == 'grpc') {
      queryParameters['serviceName'] = server.serviceName;
      queryParameters['mode'] = server.grpcMode ?? 'gun';
    }

    queryParameters.removeWhere((key, value) => value == null || value.isEmpty);

    final uri = Uri(
      scheme: 'vless',
      userInfo: server.authPayload,
      host: server.address,
      port: server.port,
      queryParameters: queryParameters,
      fragment: server.remark,
    );

    return uri.toString();
  }

  static XrayServer parseUri(String uriString) {
    final uri = Uri.parse(uriString);
    final server = XrayServer.vlessDefaults();

    server.address = uri.host;
    server.port = uri.port;
    server.authPayload = uri.userInfo;
    server.remark = uri.hasFragment ? Uri.decodeComponent(uri.fragment) : '';

    final queryParameters = uri.queryParameters;

    server.transport = queryParameters['type'] ?? 'tcp';
    server.encryption = queryParameters['encryption'] ?? 'none';
    server.flow = queryParameters['flow'] == 'xtls-rprx-vision'
        ? 'xtls-rprx-vision'
        : null;

    server.tls = queryParameters['security'] ?? 'none';
    if (server.tls != 'none') {
      server.serverName = queryParameters['sni'];
      server.fingerprint = queryParameters['fp'];
      if (server.tls == 'reality') {
        server.publicKey = queryParameters['pbk'];
        server.shortId = queryParameters['sid'];
        server.spiderX = queryParameters['spx'];
      }
    }

    switch (server.transport) {
      case 'ws':
      case 'httpupgrade':
        server.path = queryParameters['path'];
        server.host = queryParameters['host'];
        break;
      case 'grpc':
        server.serviceName = queryParameters['serviceName'];
        server.grpcMode = queryParameters['mode'] ?? 'gun';
        break;
    }

    return server;
  }
}
