import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiver/collection.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/subscription.dart';
import 'package:sphia/app/helper/uri/uri.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/data/server.dart';
import 'package:sphia/app/notifier/data/server_group.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/custom_config/server.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/server/xray/server.dart';
import 'package:sphia/view/dialog/custom_config.dart';
import 'package:sphia/view/dialog/hysteria.dart';
import 'package:sphia/view/dialog/server_group.dart';
import 'package:sphia/view/dialog/shadowsocks.dart';
import 'package:sphia/view/dialog/trojan.dart';
import 'package:sphia/view/dialog/xray.dart';
import 'package:sphia/view/page/server.dart';
import 'package:sphia/view/widget/widget.dart';

mixin ServerHelper {
  Future<void> addServer({
    required Protocol protocol,
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final serverGroup = ref.read(selectedServerGroupProvider);
    final groupId = serverGroup.id;
    late final ServerModel? server;
    switch (protocol) {
      case Protocol.vmess:
      case Protocol.vless:
        server = await _showEditServerDialog(
          title: protocol == Protocol.vmess
              ? '${L10n.of(context)!.add} VMess ${L10n.of(context)!.server}'
              : '${L10n.of(context)!.add} Vless ${L10n.of(context)!.server}',
          server: protocol == Protocol.vmess
              ? (XrayServer.vmessDefaults()..groupId = groupId)
              : (XrayServer.vlessDefaults()..groupId = groupId),
          context: context,
        );
        break;
      case Protocol.shadowsocks:
        server = await _showEditServerDialog(
          title:
              '${L10n.of(context)!.add} Shadowsocks ${L10n.of(context)!.server}',
          server: ShadowsocksServer.defaults()..groupId = groupId,
          context: context,
        );
        break;
      case Protocol.trojan:
        server = await _showEditServerDialog(
          title: '${L10n.of(context)!.add} Trojan ${L10n.of(context)!.server}',
          server: TrojanServer.defaults()..groupId = groupId,
          context: context,
        );
        break;
      case Protocol.hysteria:
        server = await _showEditServerDialog(
          title:
              '${L10n.of(context)!.add} Hysteria ${L10n.of(context)!.server}',
          server: HysteriaServer.defaults()..groupId = groupId,
          context: context,
        );
        break;
      case Protocol.custom:
        server = await _showEditServerDialog(
          title:
              '${L10n.of(context)!.add} ${L10n.of(context)!.customConfig} ${L10n.of(context)!.server}',
          server: CustomConfigServer.defaults()..groupId = groupId,
          context: context,
        );
      case Protocol.clipboard:
        final uris = await UriHelper.importUriFromClipboard();
        if (uris.isNotEmpty) {
          List<ServerModel> servers = [];
          for (var uri in uris) {
            try {
              final server = UriHelper.parseUri(uri);
              if (server != null) {
                servers.add(server..groupId = groupId);
              }
            } on Exception catch (e) {
              ref
                  .read(logNotifierProvider.notifier)
                  .error('Failed to parse URI: $e');
            }
          }
          if (servers.isEmpty) {
            return;
          }
          final idList = await serverDao.insertServers(servers);
          await serverDao.refreshServersOrder(groupId);
          final notifier = ref.read(serverNotifierProvider.notifier);
          notifier.addServers(servers
            ..asMap().forEach((index, server) {
              server.id = idList[index];
            }));
        }
        return;
      default:
        break;
    }
    if (server == null) {
      return;
    }
    final serverId = await serverDao.insertServer(server);
    await serverDao.refreshServersOrder(groupId);
    final notifier = ref.read(serverNotifierProvider.notifier);
    notifier.addServer(server..id = serverId);
  }

  Future<ServerModel?> getEditedServer({
    required ServerModel server,
    required BuildContext context,
  }) async {
    if (server.protocol == Protocol.vmess ||
        server.protocol == Protocol.vless) {
      return await _showEditServerDialog(
        title: server.protocol == Protocol.vmess
            ? '${L10n.of(context)!.edit} VMess ${L10n.of(context)!.server}'
            : '${L10n.of(context)!.edit} Vless ${L10n.of(context)!.server}',
        server: server,
        context: context,
      );
    } else if (server.protocol == Protocol.shadowsocks) {
      return await _showEditServerDialog(
        title:
            '${L10n.of(context)!.edit} Shadowsocks ${L10n.of(context)!.server}',
        server: server,
        context: context,
      );
    } else if (server.protocol == Protocol.trojan) {
      return await _showEditServerDialog(
        title: '${L10n.of(context)!.edit} Trojan ${L10n.of(context)!.server}',
        server: server,
        context: context,
      );
    } else if (server.protocol == Protocol.hysteria) {
      return await _showEditServerDialog(
        title: '${L10n.of(context)!.edit} Hysteria ${L10n.of(context)!.server}',
        server: server,
        context: context,
      );
    } else if (server.protocol == Protocol.custom) {
      return await _showEditServerDialog(
        title:
            '${L10n.of(context)!.edit} ${L10n.of(context)!.customConfig} ${L10n.of(context)!.server}',
        server: server,
        context: context,
      );
    }
    return null;
  }

  void switchGroup({
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final serverGroups = ref.read(serverGroupNotifierProvider);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10n.of(context)!.switchGroup),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: serverGroups.length,
              itemBuilder: (context, index) {
                final group = serverGroups[index];
                return Card(
                  color: Colors.transparent,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  child: ListTile(
                    title: Text(group.name),
                    onTap: () {
                      final notifier =
                          ref.read(serverConfigNotifierProvider.notifier);
                      notifier.updateValue('selectedServerGroupId', group.id);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> addGroup({
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final serverGroupRecord = await _showEditServerGroupDialog(
      title: L10n.of(context)!.addGroup,
      groupName: '',
      subscription: '',
      context: context,
    );
    if (serverGroupRecord == null) {
      return;
    }
    final newGroupName = serverGroupRecord.$1;
    final subscription = serverGroupRecord.$2;
    final fetchSubscription = serverGroupRecord.$3;
    final groupId =
        await serverGroupDao.insertServerGroup(newGroupName, subscription);
    await serverGroupDao.refreshServerGroupsOrder();
    final serverGroupNotifier = ref.read(serverGroupNotifierProvider.notifier);
    serverGroupNotifier.addGroup(ServerGroup(
      id: groupId,
      name: newGroupName,
      subscription: subscription,
    ));
    final serverConfigNotifier =
        ref.read(serverConfigNotifierProvider.notifier);
    serverConfigNotifier.updateValue('selectedServerGroupId', groupId);
    if (fetchSubscription && subscription.isNotEmpty) {
      try {
        await updateGroup(range: ActionRange.currentGroup, ref: ref);
      } on Exception catch (e) {
        if (context.mounted) {
          await SphiaWidget.showDialogWithMsg(
            context: context,
            message: '${L10n.of(context)!.updateGroupFailed}: $e',
          );
        }
      }
    }
    return;
  }

  Future<void> editGroup({
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final serverGroup = ref.read(selectedServerGroupProvider);
    if (serverGroup.name == 'Default') {
      await _showErrorDialog(groupName: serverGroup.name, context: context);
      return;
    }
    final serverGroupRecord = await _showEditServerGroupDialog(
        title: L10n.of(context)!.editGroup,
        groupName: serverGroup.name,
        subscription: serverGroup.subscription,
        context: context);
    if (serverGroupRecord == null) {
      return;
    }
    final newGroupName = serverGroupRecord.$1;
    final subscription = serverGroupRecord.$2;
    if ((newGroupName == serverGroup.name &&
        subscription == serverGroup.subscription)) {
      return;
    }
    await serverGroupDao.updateServerGroup(
        serverGroup.id, newGroupName, subscription);
    final notifier = ref.read(serverGroupNotifierProvider.notifier);
    notifier.updateGroup(ServerGroup(
      id: serverGroup.id,
      name: newGroupName,
      subscription: subscription,
    ));
    return;
  }

  Future<void> updateGroup({
    required ActionRange range,
    required WidgetRef ref,
  }) async {
    final subscriptionHelper = ref.read(subscriptionHelperProvider.notifier);
    switch (range) {
      case ActionRange.currentGroup:
        final serverGroup = ref.read(selectedServerGroupProvider);
        final id = serverGroup.id;
        final subscription = serverGroup.subscription;
        if (subscription.isEmpty) {
          return;
        }
        final groupName = serverGroup.name;
        try {
          await subscriptionHelper.updateSingleGroup(
            groupId: id,
            subscription: subscription,
          );
        } on Exception catch (e) {
          ref
              .read(logNotifierProvider.notifier)
              .error('Failed to update group $groupName: $e');
          rethrow;
        }
        final serverNotifier = ref.read(serverNotifierProvider.notifier);
        final servers = await serverDao.getOrderedServerModelsByGroupId(id);
        final curId = ref.read(serverConfigNotifierProvider
            .select((value) => value.selectedServerGroupId));
        if (curId == id) {
          serverNotifier.setServers(servers);
        }
        final context = ref.context;
        if (context.mounted) {
          SphiaWidget.showDialogWithMsg(
            context: context,
            message: L10n.of(context)!.updatedGroupSuccessfully,
          );
        }
        return;
      case ActionRange.allGroups:
        int count = 0;
        bool flag = false;
        final serverGroups = await serverGroupDao.getOrderedServerGroups();
        final subscriptionHelper =
            ref.read(subscriptionHelperProvider.notifier);
        for (var serverGroup in serverGroups) {
          final subscription = serverGroup.subscription;
          if (subscription.isEmpty) {
            continue;
          }
          try {
            await subscriptionHelper.updateSingleGroup(
              groupId: serverGroup.id,
              subscription: subscription,
            );
            flag = true;
            count++;
          } on Exception catch (e) {
            ref
                .read(logNotifierProvider.notifier)
                .error('Failed to update group ${serverGroup.name}: $e');
            continue;
          }
        }
        if (flag) {
          final serverConfig = ref.read(serverConfigNotifierProvider);
          final id = serverConfig.selectedServerGroupId;
          final servers = await serverDao.getOrderedServerModelsByGroupId(id);
          final serverNotifier = ref.read(serverNotifierProvider.notifier);
          serverNotifier.setServers(servers);
        }
        final context = ref.context;
        if (context.mounted) {
          final total = serverGroups.length;
          SphiaWidget.showDialogWithMsg(
            context: context,
            message:
                L10n.of(context)!.numSubscriptionsHaveBeenUpdated(count, total),
          );
        }
      default:
        return;
    }
  }

  Future<void> deleteGroup({
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final serverGroup = ref.read(selectedServerGroupProvider);
    final groupId = serverGroup.id;
    final groupName = serverGroup.name;
    if (groupName == 'Default') {
      if (context.mounted) {
        await _showErrorDialog(groupName: groupName, context: ref.context);
      }
      return;
    }
    await serverGroupDao.deleteServerGroup(groupId);
    await serverGroupDao.refreshServerGroupsOrder();
    final notifier = ref.read(serverGroupNotifierProvider.notifier);
    notifier.removeGroup(groupId);
    if (ref.read(serverConfigNotifierProvider).selectedServerGroupId ==
        groupId) {
      final notifier = ref.read(serverConfigNotifierProvider.notifier);
      notifier.updateValue('selectedServerGroupId', 1);
    }
    return;
  }

  Future<bool> reorderGroup({
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final serverGroups = ref.read(serverGroupNotifierProvider);
    final oldOrder = serverGroups.map((e) => e.id).toList();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10n.of(context)!.reorderGroup),
          content: SizedBox(
            width: double.minPositive,
            child: ReorderableListView.builder(
              proxyDecorator: (child, index, animation) => child,
              shrinkWrap: true,
              itemCount: serverGroups.length,
              itemBuilder: (context, index) {
                final group = serverGroups[index];
                return RepaintBoundary(
                  key: ValueKey(group.name),
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Card(
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      child: ListTile(
                        title: Text(group.name),
                      ),
                    ),
                  ),
                );
              },
              onReorder: (int oldIndex, int newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final group = serverGroups.removeAt(oldIndex);
                serverGroups.insert(newIndex, group);
              },
            ),
          ),
        );
      },
    );
    final newOrder = serverGroups.map((e) => e.id).toList();
    if (listsEqual(oldOrder, newOrder)) {
      return false;
    }
    await serverGroupDao.updateServerGroupsOrder(newOrder);
    final notifier = ref.read(serverGroupNotifierProvider.notifier);
    notifier.setGroups(serverGroups);
    return true;
  }

  Future<ServerModel?> _showEditServerDialog({
    required String title,
    required ServerModel server,
    required BuildContext context,
  }) async {
    if (server.protocol == Protocol.vmess ||
        server.protocol == Protocol.vless) {
      return showDialog<ServerModel>(
        context: context,
        builder: (context) =>
            XrayServerDialog(title: title, server: server as XrayServer),
      );
    } else if (server.protocol == Protocol.shadowsocks) {
      return showDialog<ServerModel>(
        context: context,
        builder: (context) => ShadowsocksServerDialog(
            title: title, server: server as ShadowsocksServer),
      );
    } else if (server.protocol == Protocol.trojan) {
      return showDialog<ServerModel>(
        context: context,
        builder: (context) =>
            TrojanServerDialog(title: title, server: server as TrojanServer),
      );
    } else if (server.protocol == Protocol.hysteria) {
      return showDialog<ServerModel>(
        context: context,
        builder: (context) => HysteriaServerDialog(
            title: title, server: server as HysteriaServer),
      );
    } else if (server.protocol == Protocol.custom) {
      return showDialog<ServerModel>(
        context: context,
        builder: (context) => CustomConfigServerDialog(
            title: title, server: server as CustomConfigServer),
      );
    }
    return null;
  }

  Future<(String, String, bool)?> _showEditServerGroupDialog({
    required String title,
    required String groupName,
    required String subscription,
    required BuildContext context,
  }) async {
    return showDialog<(String, String, bool)>(
      context: context,
      builder: (context) => ServerGroupDialog(
        title: title,
        serverGroup: (groupName, subscription),
      ),
    );
  }

  Future<void> _showErrorDialog({
    required String groupName,
    required BuildContext context,
  }) async {
    final title = '${L10n.of(context)!.cannotEditOrDeleteGroup}: $groupName';
    return SphiaWidget.showDialogWithMsg(context: context, message: title);
  }
}
