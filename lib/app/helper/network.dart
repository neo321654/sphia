import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/core/core_info.dart';
import 'package:validator_regex/validator_regex.dart';

part 'network.g.dart';

@riverpod
class NetworkHelper extends _$NetworkHelper {
  @override
  void build() {}

  static Future<bool> isLocalPortInUse(int port) async {
    const timeout = Duration(milliseconds: 10);
    // send a request to the port
    try {
      final socket = await Socket.connect('127.0.0.1', port).timeout(timeout);
      socket.destroy();
      return true;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    }
  }

  static Future<bool> isServerAvailable(int port, {int maxRetry = 3}) async {
    for (var i = 0; i < maxRetry; i++) {
      try {
        final socket = await Socket.connect('localhost', port);
        await socket.close();
        return true;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    return false;
  }

  Future<HttpClientResponse> getHttpResponse(String url) async {
    final client = _getHttpClient(url);
    final uri = Uri.parse(url);
    try {
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 3));
      final response = await request.close();
      client.close();
      return response;
    } on Exception catch (e) {
      throw Exception('Failed to get response from $url\n$e');
    }
  }

  Future<Uint8List> downloadFile(String url) async {
    try {
      final notifier = ref.read(logNotifierProvider.notifier);
      notifier.info('Downloading file from $url');
      final response = await getHttpResponse(url);
      final bytes = await consolidateHttpClientResponseBytes(response);
      notifier.info('Downloaded ${bytes.length} bytes from $url');
      return bytes;
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<String> getIp() async {
    try {
      final response = await getHttpResponse('https://api.ip.sb/ip');
      final responseBody =
          (await response.transform(utf8.decoder).join()).trim();
      final isValidIp = Validator.ipAddress(responseBody);
      if (!isValidIp) {
        throw Exception('Invalid ip: $responseBody');
      }
      return responseBody;
    } on Exception catch (e) {
      ref.read(logNotifierProvider.notifier).error('Failed to get ip: $e');
      throw Exception('Failed to get ip: $e');
    }
  }

  Future<int> getLatency() async {
    final url = ref.read(
        sphiaConfigNotifierProvider.select((value) => value.latencyTestUrl));
    final uri = Uri.parse(url);
    final client = _getHttpClient(url);
    final notifier = ref.read(logNotifierProvider.notifier);

    try {
      final stopwatch = Stopwatch()..start();
      final request =
          await client.getUrl(uri).timeout(const Duration(seconds: 3));
      final response = await request.close();
      stopwatch.stop();
      final statusCode = response.statusCode;
      if (statusCode != 204) {
        throw Exception('Invalid status code: $statusCode');
      }
      final latency = stopwatch.elapsedMilliseconds;
      return latency;
    } on TimeoutException catch (e) {
      notifier.error('Latency test timed out: $e');
      throw Exception('Latency test timed out: $e');
    } on SocketException catch (e) {
      notifier.error('Network error while testing latency: $e');
      throw Exception('Network error while testing latency: $e');
    } catch (e) {
      notifier.error('Failed to get latency: $e');
      throw Exception('Failed to get latency: $e');
    } finally {
      client.close();
    }
  }

  HttpClient _getHttpClient(String url) {
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final latencyTestUrl = sphiaConfig.latencyTestUrl;
    final proxyState = ref.read(proxyNotifierProvider);
    final client = HttpClient();
    // init userAgent
    final userAgent = sphiaConfig.getUserAgent();
    client.userAgent = userAgent;
    if (proxyState.coreRunning &&
        (sphiaConfig.updateThroughProxy ||
            url == latencyTestUrl ||
            url == 'https://api.ip.sb/ip' ||
            url.contains('YukidouSatoru/sphia'))) {
      final coreState = ref.read(coreStateNotifierProvider).valueOrNull;
      if (coreState == null) {
        return client;
      }

      late final int port;
      if (proxyState.customConfig) {
        port = coreState.customHttpPort;
        if (port == -1) {
          ref
              .read(logNotifierProvider.notifier)
              .warning('HTTP port is not set');
        } else {
          final proxyUrl = '${sphiaConfig.listen}:${port.toString()}';
          client.findProxy = (uri) => 'PROXY $proxyUrl';
        }
      } else {
        port = coreState.routingProvider == RoutingProvider.sing
            ? sphiaConfig.mixedPort
            : sphiaConfig.httpPort;
        final proxyUrl = '${sphiaConfig.listen}:${port.toString()}';

        if (sphiaConfig.authentication) {
          final user = sphiaConfig.user;
          final password = sphiaConfig.password;
          client.findProxy = (uri) => 'PROXY $user:$password@$proxyUrl';
        } else {
          client.findProxy = (uri) => 'PROXY $proxyUrl';
        }
      }
    }
    return client;
  }

  Future<String> getLatestVersion(ProxyResInfo info) async {
    final apiUrl = info.repoApiUrl;
    final response = await getHttpResponse(apiUrl);
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final version = jsonDecode(responseBody)['tag_name'];
      if (version != null) {
        if (info.name == ProxyRes.sphia) {
          return version.split('v').last;
        }
        return version;
      } else {
        throw Exception('Failed to parse version');
      }
    } else {
      throw Exception('Failed to connect to Github');
    }
  }

  Future<String> getSphiaChangeLog() async {
    const url =
        'https://api.github.com/repos/YukidouSatoru/sphia/releases/latest';
    final response = await getHttpResponse(url);
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final changeLog = jsonDecode(responseBody)['body'];
      if (changeLog != null) {
        return changeLog;
      } else {
        throw Exception('Failed to parse change log');
      }
    } else {
      throw Exception('Failed to connect to Github');
    }
  }
}
