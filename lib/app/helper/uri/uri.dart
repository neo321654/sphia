import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sphia/app/helper/uri/hysteria.dart';
import 'package:sphia/app/helper/uri/shadowsocks.dart';
import 'package:sphia/app/helper/uri/trojan.dart';
import 'package:sphia/app/helper/uri/vless.dart';
import 'package:sphia/app/helper/uri/vmess.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/server/xray/server.dart';

class UriHelper {
  static String? getUri(ServerModel server) {
    switch (server.protocol) {
      case Protocol.vless:
        return VlessHelper.getUri(server as XrayServer);
      case Protocol.vmess:
        return VMessHelper.getUri(server as XrayServer);
      case Protocol.shadowsocks:
        return ShadowsocksHelper.getUri(server as ShadowsocksServer);
      case Protocol.trojan:
        return TrojanHelper.getUri(server as TrojanServer);
      case Protocol.hysteria:
        return HysteriaHelper.getUri(server as HysteriaServer);
      case Protocol.custom:
      case Protocol.socks:
      case Protocol.clipboard:
        return null;
    }
  }

  static ServerModel? parseUri(String uriString) {
    try {
      uriString = uriString.trim();
      final scheme = uriString.split('://')[0];
      switch (scheme) {
        case 'vless':
          return VlessHelper.parseUri(uriString);
        case 'vmess':
          return VMessHelper.parseUri(uriString);
        case 'ss':
          return ShadowsocksHelper.parseUri(uriString);
        case 'trojan':
          return TrojanHelper.parseUri(uriString);
        case 'hysteria':
          return HysteriaHelper.parseUri(uriString);
      }
    } on Exception catch (e) {
      logger.e('$e: $uriString');
      throw Exception('$e: $uriString');
    }
    return null;
  }

  static void exportUriToClipboard(String uri) async {
    logger.i('Exporting to clipboard: $uri');
    Clipboard.setData(ClipboardData(text: uri));
  }

  static Future<List<String>> importUriFromClipboard() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      final text = clipboardData.text!.trim();
      final uris = text.split('\n');
      return uris;
    } else {
      logger.w('Clipboard is empty');
      return [];
    }
  }

  static Map<String, String> extractPluginOpts(String pluginOpts) {
    return Map.fromEntries(
      pluginOpts
          .split(';')
          .map((pair) => pair.split('='))
          .where((pair) => pair.length == 2)
          .map(
            (pair) => MapEntry(pair[0], pair[1]),
          ),
    );
  }

  static String decodeBase64(String base64UrlString) {
    try {
      return utf8.decode(base64Url.decode(base64UrlString));
    } on Exception catch (_) {
      try {
        final base64String = _convertBase64UrlToBase64(base64UrlString);
        return utf8.decode(base64Url.decode(base64String));
      } on Exception catch (_) {
        logger.e('Failed to decode base64');
        throw Exception('Failed to decode base64');
      }
    }
  }

  static String _convertBase64UrlToBase64(String base64Url) {
    String base64 = base64Url.replaceAll('-', '+').replaceAll('_', '/');
    int padLength = 4 - (base64.length % 4);
    base64 = base64.padRight(base64.length + padLength, '=');
    return base64;
  }
}
