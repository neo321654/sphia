import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/proxy.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';
import 'package:sphia/view/widget/widget.dart';

class ProxyCard extends ConsumerWidget {
  const ProxyCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreRunning =
        ref.watch(proxyNotifierProvider.select((value) => value.coreRunning));
    final proxyCard = CardData(
      icon: Symbols.hub,
      widget: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  L10n.of(context)!.coreStatus,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                const ToggleButton(),
              ],
            ),
            Row(
              children: [
                Text(
                  L10n.of(context)!.autoConfigureSystemProxy,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Consumer(
                  builder: (context, ref, child) {
                    final autoConfigureSystemProxy = ref.watch(
                        sphiaConfigNotifierProvider
                            .select((value) => value.autoConfigureSystemProxy));
                    return Checkbox(
                      value: autoConfigureSystemProxy,
                      onChanged: coreRunning
                          ? null
                          : (value) {
                              final notifier = ref
                                  .read(sphiaConfigNotifierProvider.notifier);
                              notifier.updateValue(
                                  'autoConfigureSystemProxy', value!);
                              if (value) {
                                notifier.updateValue('enableTun', false);
                              }
                            },
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'TUN',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Consumer(
                  builder: (context, ref, child) {
                    final tunMode = ref.watch(proxyNotifierProvider
                            .select((value) => value.tunMode)) ||
                        ref.watch(sphiaConfigNotifierProvider
                            .select((value) => value.enableTun));
                    return Checkbox(
                      value: tunMode,
                      onChanged: coreRunning
                          ? null
                          : (value) {
                              final notifier = ref
                                  .read(sphiaConfigNotifierProvider.notifier);
                              notifier.updateValue('enableTun', value!);
                              if (value) {
                                notifier.updateValue(
                                  'autoConfigureSystemProxy',
                                  false,
                                );
                              }
                            },
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  L10n.of(context)!.systemProxy,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Consumer(
                  builder: (context, ref, child) {
                    final systemProxy = ref.watch(proxyNotifierProvider
                        .select((value) => value.systemProxy));
                    final tunMode = ref.watch(proxyNotifierProvider
                            .select((value) => value.tunMode)) ||
                        ref.watch(sphiaConfigNotifierProvider
                            .select((value) => value.enableTun));
                    return Checkbox(
                      value: systemProxy,
                      onChanged: (!coreRunning || tunMode)
                          ? null
                          : (value) {
                              final notifier =
                                  ref.read(proxyHelperProvider.notifier);
                              if (value!) {
                                notifier.enableSystemProxy();
                              } else {
                                notifier.disableSystemProxy();
                              }
                            },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return buildMultipleRowCard(proxyCard);
  }
}

class ToggleButton extends ConsumerWidget {
  const ToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(coreStateNotifierProvider).isLoading;
    return GestureDetector(
      onTap: isLoading ? null : () => _toggleServer(ref),
      child: MouseRegion(
        cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          color: Colors.transparent,
          child: Consumer(
            builder: (context, ref, child) {
              return ref.watch(coreStateNotifierProvider).when(
                    data: (state) {
                      late final IconData icon;
                      if (state.cores.isEmpty) {
                        icon = Symbols.play_arrow_rounded;
                      } else {
                        icon = Symbols.stop_rounded;
                      }
                      return Tooltip(
                        message: state.cores.isEmpty
                            ? L10n.of(context)!.coreStart
                            : L10n.of(context)!.coreStop,
                        child: Icon(
                          icon,
                          size: 30,
                          opticalSize: 30,
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stackTrace) {
                      return Tooltip(
                        message: '$error',
                        child: const Icon(
                          Symbols.stop,
                          size: 30,
                          opticalSize: 30,
                        ),
                      );
                    },
                  );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggleServer(WidgetRef ref) async {
    final context = ref.context;
    final serverConfig = ref.read(serverConfigNotifierProvider);
    final coreStateNotifier = ref.read(coreStateNotifierProvider.notifier);
    final id = serverConfig.selectedServerId;
    final server = await serverDao.getServerModelById(id);
    if (server == null) {
      final proxyState = ref.read(proxyNotifierProvider);
      if (proxyState.coreRunning) {
        await coreStateNotifier.stopCores();
      } else {
        if (!context.mounted) {
          return;
        }
        await SphiaWidget.showDialogWithMsg(
          context: context,
          message: L10n.of(context)!.noServerSelected,
        );
      }
      return;
    }
    try {
      await coreStateNotifier.toggleCores(server);
    } on Exception catch (e) {
      if (!context.mounted) {
        return;
      }
      await SphiaWidget.showDialogWithMsg(
        context: context,
        message: '${L10n.of(context)!.coreStartFailed}: $e',
      );
    }
  }
}
