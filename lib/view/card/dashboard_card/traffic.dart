import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/traffic.dart';
import 'package:sphia/app/notifier/visible.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';
import 'package:sphia/view/card/dashboard_card/chart.dart';

class TrafficCard extends ConsumerWidget {
  const TrafficCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(visibleNotifierProvider);
    final enableStatistics = ref.watch(
        sphiaConfigNotifierProvider.select((value) => value.enableStatistics));
    final cardTraffic = CardData(
      showAccent: true,
      icon: Symbols.data_usage,
      widget: enableStatistics && visible
          ? ref.watch(trafficStreamProvider).when(
                data: (trafficData) {
                  final (uplink, downlink, up, down) = trafficData;
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              L10n.of(context)!.upload,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatBytes(uplink.toDouble()),
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              L10n.of(context)!.download,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatBytes(downlink.toDouble()),
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              L10n.of(context)!.uploadSpeed,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${formatBytes(up.toDouble())}/s',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              L10n.of(context)!.downloadSpeed,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${formatBytes(down.toDouble())}/s',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => Center(
                  child: Tooltip(
                    message: '$error',
                    child: const Icon(
                      Symbols.block,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
          : Center(
              child: IconButton(
                icon: const Icon(
                  Symbols.block,
                  color: Colors.grey,
                ),
                tooltip: L10n.of(context)!.statisticsIsDisabled,
                onPressed: null,
              ),
            ),
    );
    return buildMultipleRowCard(cardTraffic);
  }
}
