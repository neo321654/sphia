import 'dart:collection';
import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/helper/traffic/traffic.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/traffic.dart';
import 'package:sphia/app/notifier/visible.dart';

part 'chart.g.dart';

const List<String> _units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
const List<int> _unitRates = [
  1,
  1024,
  1048576,
  1073741824,
  1099511627776,
  1125899906842624
];

int _getUnit(int byte) {
  if (byte < _unitRates[1]) {
    return 0;
  } else if (byte < _unitRates[2]) {
    return 1;
  } else if (byte < _unitRates[3]) {
    return 2;
  } else if (byte < _unitRates[4]) {
    return 3;
  } else {
    return 4;
  }
}

String formatBytes(double speedInBytes) {
  speedInBytes = max(speedInBytes, 0);
  final unit = _getUnit(speedInBytes.toInt());
  final speedInUnit = speedInBytes / _unitRates[unit];
  return '${speedInUnit.toStringAsFixed(1)} ${_units[unit]}';
}

class TrafficHistory {
  final upSpeeds = Queue<(int, int)>();
  final downSpeeds = Queue<(int, int)>();

  TrafficHistory();

  void addData(int timestamp, int upSpeed, int downSpeed) {
    upSpeeds.addLast((timestamp, upSpeed));
    downSpeeds.addLast((timestamp, downSpeed));

    while (upSpeeds.isNotEmpty && timestamp - upSpeeds.first.$1 > 60000) {
      upSpeeds.removeFirst();
    }
    while (downSpeeds.isNotEmpty && timestamp - downSpeeds.first.$1 > 60000) {
      downSpeeds.removeFirst();
    }
  }

  double get maxSpeed {
    final maxUp = upSpeeds.isEmpty
        ? 0.0
        : upSpeeds.map((e) => e.$2).reduce(max).toDouble();
    final maxDown = downSpeeds.isEmpty
        ? 0.0
        : downSpeeds.map((e) => e.$2).reduce(max).toDouble();
    return max(maxUp, maxDown);
  }
}

@Riverpod(keepAlive: true)
class TrafficHistoryNotifier extends _$TrafficHistoryNotifier {
  @override
  TrafficHistory build() => TrafficHistory();

  void addData({
    required int timestamp,
    required int upSpeed,
    required int downSpeed,
    required bool shouldRebuild,
  }) {
    state.addData(timestamp, upSpeed, downSpeed);
    if (shouldRebuild) {
      state = TrafficHistory()
        ..upSpeeds.addAll(state.upSpeeds)
        ..downSpeeds.addAll(state.downSpeeds);
    }
  }

  void clearHistory() {
    state = TrafficHistory();
  }
}

class NetworkChart extends ConsumerWidget {
  const NetworkChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleNotifierProvider);
    final enableSpeedChart = ref.watch(
        sphiaConfigNotifierProvider.select((value) => value.enableSpeedChart));

    final shouldRebuild = visible && enableSpeedChart;

    final trafficStream = ref.watch(trafficStreamProvider);
    final trafficHistory = ref.watch(trafficHistoryNotifierProvider);

    ref.listen<AsyncValue<TrafficData>>(trafficStreamProvider, (_, next) {
      if (enableSpeedChart) {
        next.whenData((traffic) {
          if (traffic.$1 == -1 &&
              traffic.$2 == -1 &&
              traffic.$3 == -1 &&
              traffic.$4 == -1) {
            ref.read(trafficHistoryNotifierProvider.notifier).clearHistory();
          } else {
            final currentTime = DateTime.now().millisecondsSinceEpoch;
            ref.read(trafficHistoryNotifierProvider.notifier).addData(
                  timestamp: currentTime,
                  upSpeed: traffic.$3,
                  downSpeed: traffic.$4,
                  shouldRebuild: shouldRebuild,
                );
          }
        });
      } else {
        ref.read(trafficHistoryNotifierProvider.notifier).clearHistory();
      }
    });

    final rawMaxY = _calculateMaxY(trafficHistory.maxSpeed);
    final maxY = (rawMaxY / 10).ceil() * 10.0;
    final interval = maxY / 10;

    return Stack(
      children: [
        BarChart(
          BarChartData(
            barGroups: trafficStream.hasValue
                ? _createBarGroups(trafficHistory, maxY)
                : [],
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value % 10 == 0) {
                      return Text(
                        '${60 - value.toInt()}s',
                        style: const TextStyle(fontSize: 10),
                      );
                    }
                    return const SizedBox();
                  },
                  reservedSize: 20,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    if (value == maxY * 0.3 || value == maxY * 0.8) {
                      return Text(
                        '${formatBytes(value)}/s',
                        style: const TextStyle(fontSize: 10),
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawHorizontalLine: true,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) {
                if (value == maxY * 0.3 || value == maxY * 0.8) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                }
                return FlLine(
                  color: Colors.grey.withOpacity(0.1),
                  strokeWidth: 0.5,
                );
              },
            ),
            maxY: maxY,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final speedLabel = rodIndex == 0 ? '↑' : '↓';
                  return BarTooltipItem(
                    '${formatBytes(rod.toY)}$speedLabel',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (trafficStream.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (trafficStream.hasError)
          Center(
            child: Text(
              '${trafficStream.error}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  double _calculateMaxY(double maxSpeed) {
    if (maxSpeed <= 0) {
      return 10;
    }
    final unit = _getUnit(maxSpeed.toInt());
    final maxInUnit = maxSpeed / _unitRates[unit];
    return (maxInUnit.ceil() * 1.2 * _unitRates[unit]).roundToDouble();
  }

  List<BarChartGroupData> _createBarGroups(
    TrafficHistory history,
    double maxY,
  ) {
    final currTime = DateTime.now().millisecondsSinceEpoch;
    final groups = <BarChartGroupData>[];

    for (int i = 0; i < 60; i++) {
      final targetTime = currTime - (59 - i) * 1000;
      final upSpeed = history.upSpeeds
          .lastWhere((e) => e.$1 <= targetTime, orElse: () => (0, 0))
          .$2
          .toDouble();
      final downSpeed = history.downSpeeds
          .lastWhere((e) => e.$1 <= targetTime, orElse: () => (0, 0))
          .$2
          .toDouble();

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: upSpeed, color: Colors.green, width: 2),
            BarChartRodData(toY: downSpeed, color: Colors.blue, width: 2),
          ],
        ),
      );
    }

    return groups;
  }
}
