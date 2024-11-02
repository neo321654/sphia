import 'dart:async';
import 'dart:convert';

import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/helper/traffic/xray/command.pbgrpc.dart';

typedef TrafficData = (
  int uplink,
  int downlink,
  int up,
  int down,
);

abstract class TrafficHelper {
  final int apiPort;
  int uplink = 0;
  int downlink = 0;

  final _apiStreamController = StreamController<TrafficData>.broadcast();

  Stream<TrafficData> get apiStream => _apiStreamController.stream;

  TrafficHelper(this.apiPort);

  Future<void> start() async {
    if (!await NetworkHelper.isServerAvailable(apiPort)) {
      throw Exception('API server is not available');
    }
  }

  Future<void> stop();
}

class XrayTrafficHelper extends TrafficHelper {
  late final ClientChannel _channel;
  late final StatsServiceClient _client;
  late final Timer _timer;
  final bool _isMultiOutboundSupport;

  XrayTrafficHelper(int apiPort, this._isMultiOutboundSupport)
      : super(apiPort) {
    _channel = ClientChannel(
      'localhost',
      port: apiPort,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
      ),
    );
    _client = StatsServiceClient(_channel);
  }

  @override
  Future<void> start() async {
    await super.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        late final int curUplink;
        late final int curDownlink;
        if (!_isMultiOutboundSupport) {
          curUplink = await queryOutboundUplink('proxy');
          curDownlink = await queryOutboundDownlink('proxy');
        } else {
          final totalProxyLink = await _queryTotalProxyLink();
          (curUplink, curDownlink) = totalProxyLink;
        }

        final up = curUplink - uplink;
        final down = curDownlink - downlink;

        _apiStreamController.add((uplink, downlink, up, down));

        uplink = curUplink;
        downlink = curDownlink;
      } catch (_) {
        _timer.cancel();
        rethrow;
      }
    });
  }

  @override
  Future<void> stop() async {
    _timer.cancel();
    await _apiStreamController.close();
    await _channel.shutdown();
  }

  Future<(int, int)> _queryTotalProxyLink() async {
    final uplinkRequest = QueryStatsRequest();
    final response = await _client.queryStats(uplinkRequest);
    final stats = response.writeToJsonMap()['1'];
    int totalUplink = 0;
    int totalDownlink = 0;
    for (final stat in stats) {
      final name = stat['1'];
      final value = stat['2'];
      // ignore direct and block
      if (name.contains('direct') || name.contains('block')) {
        continue;
      }
      if (name.contains('uplink')) {
        totalUplink += int.parse(value ?? '0');
      } else if (name.contains('downlink')) {
        totalDownlink += int.parse(value ?? '0');
      }
    }
    return (totalUplink, totalDownlink);
  }

  Future<(int, int)> queryProxyLinkByOutboundTag(String outboundTag) async {
    final uplink = await queryOutboundUplink(outboundTag);
    final downlink = await queryOutboundDownlink(outboundTag);
    return (uplink, downlink);
  }

  Future<int> _queryOutboundData(String type, String outboundTag) {
    final request = QueryStatsRequest()
      ..pattern = 'outbound>>>$outboundTag>>>traffic>>>$type';
    return _client.queryStats(request).then((response) {
      try {
        final data =
            int.tryParse(response.writeToJsonMap()['1'][0]['2'] ?? '0');
        return data!;
      } catch (e) {
        return 0;
      }
    });
  }

  Future<int> queryOutboundUplink(String outboundTag) {
    return _queryOutboundData('uplink', outboundTag);
  }

  Future<int> queryOutboundDownlink(String outboundTag) {
    return _queryOutboundData('downlink', outboundTag);
  }
}

class SingBoxTrafficHelper extends TrafficHelper {
  late final Uri _url;
  final _client = http.Client();
  StreamSubscription? _subscription;

  SingBoxTrafficHelper(int apiPort) : super(apiPort) {
    _url = Uri.parse('http://localhost:$apiPort/traffic');
  }

  @override
  Future<void> start() async {
    await super.start();
    try {
      final request = http.Request('GET', _url);
      final response = await _client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
      _subscription = response.stream.listen((data) {
        final decoded = utf8.decode(data);
        final json = jsonDecode(decoded);
        final int up = json['up'] ?? 0;
        final int down = json['down'] ?? 0;
        uplink += up;
        downlink += down;
        _apiStreamController.add((uplink, downlink, up, down));
      }, onError: (e) {
        throw Exception('Failed to get response: $e');
      });
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    await _apiStreamController.close();
    _client.close();
  }
}
