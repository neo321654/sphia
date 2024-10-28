import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';

part 'running_server.g.dart';

class RunningServerCard extends HookConsumerWidget {
  const RunningServerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runningServerCard = CardData(
      showAccent: true,
      icon: Symbols.host,
      widget: SingleChildScrollView(
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                return ref.watch(coreStateNotifierProvider).when(
                      data: (value) {
                        final remark = value.runningServerRemark;
                        if (remark == null) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            UnderlineText(
                              text: remark,
                              textStyle: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                      loading: () => const Column(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                    );
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final autoGetIp = ref.watch(sphiaConfigNotifierProvider
                    .select((value) => value.autoGetIp));
                if (!autoGetIp) {
                  return const SizedBox.shrink();
                }
                return const Row(
                  children: [
                    Text('IP', style: TextStyle(fontSize: 16)),
                    Spacer(),
                    IpText(),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(L10n.of(context)!.latency,
                    style: const TextStyle(fontSize: 16)),
                const Spacer(),
                const LatencyText(),
              ],
            ),
          ],
        ),
      ),
    );
    return buildMultipleRowCard(runningServerCard);
  }
}

@riverpod
class CurrentIpNotifier extends _$CurrentIpNotifier {
  @override
  Future<String> build() async {
    final networkHelper = ref.read(networkHelperProvider.notifier);
    return await networkHelper.getIp();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final networkHelper = ref.read(networkHelperProvider.notifier);
      return await networkHelper.getIp();
    });
  }
}

class IpText extends ConsumerWidget {
  const IpText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(proxyNotifierProvider, (previous, next) {
      if (previous?.coreRunning != next.coreRunning) {
        ref.read(currentIpNotifierProvider.notifier).refresh();
      }
    });
    final currentIp = ref.watch(currentIpNotifierProvider);
    return currentIp.when(
      data: (data) {
        return Text(data, style: const TextStyle(fontSize: 16));
      },
      loading: () {
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(),
        );
      },
      error: (error, _) {
        return Text(
          L10n.of(context)!.getIpFailed,
          style: const TextStyle(fontSize: 16),
        );
      },
    );
  }
}

@riverpod
class LatencyNotifier extends _$LatencyNotifier {
  @override
  Future<int> build() async {
    final networkHelper = ref.read(networkHelperProvider.notifier);
    return await networkHelper.getLatency();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final networkHelper = ref.read(networkHelperProvider.notifier);
      return await networkHelper.getLatency();
    });
  }
}

class LatencyText extends ConsumerWidget {
  const LatencyText({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(proxyNotifierProvider, (previous, next) {
      if (previous?.coreRunning != next.coreRunning) {
        ref.read(latencyNotifierProvider.notifier).refresh();
      }
    });
    final latency = ref.watch(latencyNotifierProvider);
    return latency.when(
      data: (data) {
        return Text('$data ms', style: const TextStyle(fontSize: 16));
      },
      loading: () {
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(),
        );
      },
      error: (error, _) {
        return const Text(
          'Timeout',
          style: TextStyle(fontSize: 16, color: Colors.red),
        );
      },
    );
  }
}
