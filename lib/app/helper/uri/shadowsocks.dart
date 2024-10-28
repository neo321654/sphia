import 'dart:convert';
import 'dart:core';

import 'package:sphia/app/helper/uri/uri.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/view/dialog/shadowsocks.dart';

class ShadowsocksHelper {
  static String getUri(ShadowsocksServer server) {
    final userInfo = base64Url
        .encode(utf8.encode('${server.encryption}:${server.authPayload}'));
    final uri = Uri(
      scheme: 'ss',
      userInfo: userInfo,
      host: server.address,
      port: server.port,
      queryParameters: server.plugin != null
          ? {
              'plugin':
                  '${server.plugin}${server.pluginOpts != null ? ';${server.pluginOpts}' : ''}'
            }
          : null,
      fragment: server.remark,
    );

    return uri.toString();
  }

  static ShadowsocksServer parseUri(String uriString) {
    final uri = Uri.parse(uriString);
    final server = ShadowsocksServer.defaults();

    server.remark = uri.hasFragment ? Uri.decodeComponent(uri.fragment) : '';

    if (uri.hasQuery && uri.queryParameters.containsKey('plugin')) {
      final pluginParts = uri.queryParameters['plugin']!.split(';');
      server.plugin = pluginParts[0];
      if (pluginParts.length > 1) {
        server.pluginOpts = pluginParts.sublist(1).join(';');
      }

      switch (server.plugin) {
        case 'obfs-local':
        case 'simple-obfs':
          if (!server.pluginOpts!.contains('obfs=')) {
            server.pluginOpts = 'obfs=http;obfs-host=${server.pluginOpts}';
          }
          break;
        case 'simple-obfs-tls':
          if (!server.pluginOpts!.contains('obfs=')) {
            server.pluginOpts = 'obfs=tls;obfs-host=${server.pluginOpts}';
          }
          break;
      }
    }

    final userInfoDecoded = UriHelper.decodeBase64(uri.userInfo);
    final userInfoParts = userInfoDecoded.split(':');
    if (userInfoParts.length != 2) {
      throw const FormatException('Invalid user info in Shadowsocks URI');
    }

    server.encryption = userInfoParts[0];
    server.authPayload = userInfoParts[1];
    server.address = uri.host;
    server.port = uri.port;

    if (!shadowsocksEncryptionList.contains(server.encryption)) {
      throw FormatException(
          'Shadowsocks does not support this encryption: ${server.encryption}');
    }

    return server;
  }
}
