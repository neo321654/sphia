import 'dart:core';

import 'package:sphia/server/trojan/server.dart';

class TrojanHelper {
  static String getUri(TrojanServer server) {
    final queryParameters = {
      'sni': server.serverName,
      'fp': server.fingerprint,
      'allowInsecure': server.allowInsecure ? '1' : '0',
    };
    queryParameters.removeWhere((key, value) => value == null || value.isEmpty);

    final uri = Uri(
      scheme: 'trojan',
      host: server.address,
      port: server.port,
      userInfo: server.authPayload,
      queryParameters: queryParameters,
      fragment: server.remark,
    );

    return uri.toString();
  }

  static TrojanServer parseUri(String uriString) {
    final uri = Uri.parse(uriString);
    final server = TrojanServer.defaults();

    server.address = uri.host;
    server.port = uri.port;
    server.authPayload = uri.userInfo;
    server.remark = uri.hasFragment ? Uri.decodeComponent(uri.fragment) : '';

    final queryParameters = uri.queryParameters;
    if (queryParameters.containsKey('sni')) {
      server.serverName = queryParameters['sni'] != null
          ? Uri.decodeComponent(queryParameters['sni']!)
          : null;
    } else if (queryParameters.containsKey('peer')) {
      server.serverName = queryParameters['peer'] != null
          ? Uri.decodeComponent(queryParameters['peer']!)
          : null;
    }
    if (queryParameters.containsKey('allowInsecure')) {
      server.allowInsecure = queryParameters['allowInsecure'] == '1';
    }

    return server;
  }
}
