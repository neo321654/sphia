import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:quiver/collection.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/server.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/data/server.dart';
import 'package:sphia/app/notifier/data/server_group.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/view/card/server_card.dart';
import 'package:sphia/view/dialog/latency.dart';
import 'package:sphia/view/dialog/traffic.dart';
import 'package:sphia/view/widget/widget.dart';

enum MenuAction {
  // addServer,
  // switchGroup,
  // addGroup,
  // editGroup,
  updateGroup,
  // deleteGroup,
  reorderGroup,
  latencyTest,
  clearLatency,
  clearTraffic,
}

enum ActionRange { selectedServer, currentGroup, allGroups }

class ServerPage extends HookConsumerWidget with ServerHelper {
  const ServerPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBar = AppBar(
      title: Text(
        L10n.of(context)!.servers,
        textAlign: TextAlign.center,
      ),
      elevation: 0,
    );
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          _getToolbar(ref),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 32,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: _getListView(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await _toggleServer(ref),
        child: ref.watch(coreStateNotifierProvider).when(
          data: (coreState) {
            if (coreState.cores.isEmpty) {
              return const Icon(Icons.flash_off);
            } else {
              return const Icon(Icons.flash_on);
            }
          },
          error: (error, _) {
            return const Icon(Icons.flash_off);
          },
          loading: () {
            return const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            );
          },
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

  Widget _getToolbar(WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final serverGroupName =
                                ref.watch(selectedServerGroupProvider).name;
                            return Text(
                              serverGroupName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: SphiaWidget.iconButton(
                            icon: Symbols.move_group,
                            tooltip: L10n.of(ref.context)!.switchGroup,
                            onTap: () => switchGroup(ref: ref),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 2,
                  color: Theme.of(ref.context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Row(
              children: [
                Spacer(),
                ButtonGroup(),
                SizedBox(width: 8),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _getListView() {
    return Consumer(
      builder: (context, ref, child) {
        final servers = ref.watch(serverNotifierProvider);
        return servers.maybeWhen(
          data: (servers) {
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => child,
              // https://github.com/flutter/flutter/issues/63527
              onReorder: (int oldIndex, int newIndex) async {
                final oldOrder = servers.map((e) => e.id).toList();
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final server = servers.removeAt(oldIndex);
                servers.insert(newIndex, server);
                final newOrder = servers.map((e) => e.id).toList();
                if (listsEqual(oldOrder, newOrder)) {
                  return;
                }
                final serverGroup = ref.read(selectedServerGroupProvider);
                await serverDao.updateServersOrder(
                  serverGroup.id,
                  newOrder,
                );
                final notifier = ref.read(serverNotifierProvider.notifier);
                notifier.setServers(servers);
              },
              itemCount: servers.length,
              itemBuilder: (context, index) {
                final server = servers[index];
                return Padding(
                  key: ValueKey(index),
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: RepaintBoundary(
                    child: ReorderableDragStartListener(
                      index: index,
                      child: ProviderScope(
                        overrides: [
                          currentServerProvider.overrideWithValue(server),
                        ],
                        child: const ServerCard(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          orElse: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      },
    );
  }
}

class ButtonGroup extends ConsumerWidget with ServerHelper {
  const ButtonGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SphiaWidget.iconButton(
            icon: Symbols.edit_square,
            tooltip: L10n.of(context)!.editGroup,
            minSize: 40,
            onTap: () async {
              await editGroup(ref: ref);
            },
          ),
          _getDivider(),
          SphiaWidget.iconButton(
            icon: Symbols.create_new_folder,
            tooltip: L10n.of(context)!.addGroup,
            minSize: 40,
            onTap: () async {
              await addGroup(ref: ref);
            },
          ),
          _getDivider(),
          SphiaWidget.iconButton(
            icon: Symbols.folder_delete,
            tooltip: L10n.of(context)!.deleteGroup,
            minSize: 40,
            onTap: () async {
              await deleteGroup(ref: ref);
            },
          ),
          _getDivider(),
          Builder(
            builder: (context) {
              return SphiaWidget.iconButton(
                icon: Symbols.new_window,
                tooltip: L10n.of(context)!.addServer,
                minSize: 40,
                onTap: () {
                  _showMenu<Protocol>(
                    context: context,
                    items: [
                      const PopupMenuItem(
                        value: Protocol.vmess,
                        child: Text('VMess'),
                      ),
                      const PopupMenuItem(
                        value: Protocol.vless,
                        child: Text('Vless'),
                      ),
                      const PopupMenuItem(
                        value: Protocol.shadowsocks,
                        child: Text('Shadowsocks'),
                      ),
                      const PopupMenuItem(
                        value: Protocol.trojan,
                        child: Text('Trojan'),
                      ),
                      const PopupMenuItem(
                        value: Protocol.hysteria,
                        child: Text('Hysteria'),
                      ),
                      const PopupMenuItem(
                        value: Protocol.custom,
                        child: Text('Custom'),
                      ),
                      PopupMenuItem(
                        value: Protocol.clipboard,
                        child: Text(L10n.of(context)!.importFromClipboard),
                      ),
                    ],
                  ).then((value) async {
                    if (value == null) {
                      return;
                    }
                    await addServer(protocol: value, ref: ref);
                  });
                },
              );
            },
          ),
          _getDivider(),
          Builder(
            builder: (context) {
              return SphiaWidget.iconButton(
                icon: Symbols.tune,
                tooltip: L10n.of(context)!.more,
                minSize: 40,
                onTap: () {
                  final selectedServerId =
                      ref.read(serverConfigNotifierProvider).selectedServerId;
                  _showMenu<MenuAction>(
                    context: context,
                    items: [
                      PopupMenuItem(
                        value: MenuAction.updateGroup,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(L10n.of(context)!.updateGroup),
                            const Icon(Icons.arrow_left),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: MenuAction.reorderGroup,
                        child: Text(L10n.of(context)!.reorderGroup),
                      ),
                      PopupMenuItem(
                        value: MenuAction.latencyTest,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(L10n.of(context)!.latencyTest),
                            if (selectedServerId != 0) ...[
                              const Icon(Icons.arrow_left),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: MenuAction.clearLatency,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(L10n.of(context)!.clearLatency),
                            if (selectedServerId != 0) ...[
                              const Icon(Icons.arrow_left),
                            ],
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: MenuAction.clearTraffic,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(L10n.of(context)!.clearTraffic),
                            if (selectedServerId != 0) ...[
                              const Icon(Icons.arrow_left),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ).then((value) async {
                    if (!context.mounted || value == null) {
                      return;
                    }
                    switch (value) {
                      case MenuAction.updateGroup:
                        _showMenu<ActionRange>(
                          context: context,
                          items: [
                            PopupMenuItem(
                              value: ActionRange.currentGroup,
                              child: Text(L10n.of(context)!.currentGroup),
                            ),
                            PopupMenuItem(
                              value: ActionRange.allGroups,
                              child: Text(L10n.of(context)!.allGroups),
                            ),
                          ],
                        ).then((value) async {
                          if (value == null) {
                            return;
                          }
                          try {
                            await updateGroup(range: value, ref: ref);
                          } on Exception catch (e) {
                            if (!context.mounted) {
                              return;
                            }
                            await SphiaWidget.showDialogWithMsg(
                              context: context,
                              message:
                                  '${L10n.of(context)!.updateGroupFailed}: $e',
                            );
                          }
                        });
                        break;
                      case MenuAction.reorderGroup:
                        await reorderGroup(ref: ref);
                        break;
                      case MenuAction.latencyTest:
                        _showMenu<ActionRange>(
                          context: context,
                          items: [
                            if (selectedServerId != 0) ...[
                              PopupMenuItem(
                                value: ActionRange.selectedServer,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      L10n.of(context)!.selectedServer,
                                    ),
                                    const Icon(Icons.arrow_left),
                                  ],
                                ),
                              ),
                            ],
                            PopupMenuItem(
                              value: ActionRange.currentGroup,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(L10n.of(context)!.currentGroup),
                                  const Icon(Icons.arrow_left),
                                ],
                              ),
                            ),
                          ],
                        ).then((value) {
                          if (!context.mounted || value == null) {
                            return;
                          }
                          final range = value;
                          _showMenu<LatencyType>(
                            context: context,
                            items: [
                              const PopupMenuItem(
                                value: LatencyType.icmp,
                                child: Text('ICMP'),
                              ),
                              const PopupMenuItem(
                                value: LatencyType.tcp,
                                child: Text('TCP'),
                              ),
                              const PopupMenuItem(
                                value: LatencyType.url,
                                child: Text('Url'),
                              ),
                            ],
                          ).then((value) async {
                            if (!context.mounted || value == null) {
                              return;
                            }
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => LatencyDialog(
                                options: (LatencyAction.test, range, value),
                              ),
                            );
                          });
                        });
                        break;
                      case MenuAction.clearLatency:
                        final selectedServerId = ref
                            .read(serverConfigNotifierProvider)
                            .selectedServerId;
                        _showMenu<ActionRange>(
                          context: context,
                          items: [
                            if (selectedServerId != 0) ...[
                              PopupMenuItem(
                                value: ActionRange.selectedServer,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      L10n.of(context)!.selectedServer,
                                    ),
                                    const Icon(Icons.arrow_left),
                                  ],
                                ),
                              ),
                            ],
                            PopupMenuItem(
                              value: ActionRange.currentGroup,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(L10n.of(context)!.currentGroup),
                                  const Icon(Icons.arrow_left),
                                ],
                              ),
                            ),
                          ],
                        ).then((value) async {
                          if (!context.mounted || value == null) {
                            return;
                          }
                          final range = value;
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => LatencyDialog(
                              options: (
                                LatencyAction.clear,
                                range,
                                null,
                              ),
                            ),
                          );
                        });
                      case MenuAction.clearTraffic:
                        _showMenu<ActionRange>(
                          context: context,
                          items: [
                            if (selectedServerId != 0) ...[
                              PopupMenuItem(
                                value: ActionRange.selectedServer,
                                child: Text(L10n.of(context)!.selectedServer),
                              ),
                            ],
                            PopupMenuItem(
                              value: ActionRange.currentGroup,
                              child: Text(L10n.of(context)!.currentGroup),
                            ),
                          ],
                        ).then((value) async {
                          if (!context.mounted || value == null) {
                            return;
                          }
                          await showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => TrafficDialog(
                              range: value,
                            ),
                          );
                        });
                        break;
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getDivider() {
    return Container(
      width: 2,
      height: 24,
      color: Colors.grey,
    );
  }

  Future<T?> _showMenu<T>({
    required BuildContext context,
    required List<PopupMenuEntry<T>> items,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    return await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: items,
    );
  }
}
