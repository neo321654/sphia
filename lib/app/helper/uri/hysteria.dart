import 'dart:core';

import 'package:sphia/server/hysteria/server.dart';

class HysteriaHelper {
  static String getUri(HysteriaServer server) {
    final queryParameters = {
      'protocol': server.hysteriaProtocol,
      'auth': server.authPayload,
      'peer': server.serverName,
      'insecure': server.insecure ? '1' : '0',
      'upmbps': server.upMbps.toString(),
      'downmbps': server.downMbps.toString(),
      'alpn': server.alpn,
      'obfsParam': server.obfs,
      'authType': server.authType,
    };
    queryParameters.removeWhere((key, value) => value == null || value.isEmpty);

    final uri = Uri(
      scheme: 'hysteria',
      host: server.address,
      port: server.port,
      queryParameters: queryParameters,
      fragment: server.remark,
    );

    return uri.toString();
  }

  static HysteriaServer parseUri(String uriString) {
    final uri = Uri.parse(uriString);
    final server = HysteriaServer.defaults();

    server.address = uri.host;
    server.port = uri.port;
    server.remark = uri.hasFragment ? Uri.decodeComponent(uri.fragment) : '';

    final queryParameters = uri.queryParameters;

    if (queryParameters.containsKey('protocol')) {
      server.hysteriaProtocol = queryParameters['protocol']!;
    }
    server.obfs = queryParameters['obfsParam'];
    server.alpn = queryParameters['alpn'];
    if (queryParameters.containsKey('authType')) {
      server.authType = queryParameters['authType']!;
    }
    if (queryParameters.containsKey('auth')) {
      server.authPayload = queryParameters['auth']!;
    }
    server.serverName = queryParameters['peer'];
    if (queryParameters.containsKey('insecure')) {
      server.insecure = queryParameters['insecure'] == '1';
    }
    if (queryParameters.containsKey('upmbps')) {
      server.upMbps = int.tryParse(queryParameters['upmbps']!) ?? 10;
    }
    if (queryParameters.containsKey('downmbps')) {
      server.downMbps = int.tryParse(queryParameters['downmbps']!) ?? 50;
    }

    return server;
  }
}
