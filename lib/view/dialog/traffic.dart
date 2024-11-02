import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/data/server.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/view/page/server.dart';

class TrafficDialog extends ConsumerWidget {
  final ActionRange range;

  const TrafficDialog({
    super.key,
    required this.range,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final Future<void> operation = clearTraffic(range, ref);
      await operation;
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
    return AlertDialog(
      title: Text(L10n.of(context)!.clearTraffic),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Future<void> clearTraffic(ActionRange option, WidgetRef ref) async {
    try {
      switch (option) {
        case ActionRange.selectedServer:
          final notifier = ref.read(serverNotifierProvider.notifier);
          final serverConfig = ref.read(serverConfigNotifierProvider);
          final id = serverConfig.selectedServerId;
          final server = await serverDao.getServerModelById(id);
          if (server == null) {
            return;
          }
          if (server.protocol == Protocol.custom) {
            return;
          }
          await serverDao.updateTraffic(server.id, null, null);
          notifier.updateServerState(
            server.withTraffic(
              null,
              null,
            ),
          );
          break;
        case ActionRange.currentGroup:
          final servers = ref.read(serverNotifierProvider).valueOrNull ?? [];
          servers.removeWhere((server) => server.protocol == Protocol.custom);
          if (servers.isEmpty) {
            return;
          }
          final notifier = ref.read(serverNotifierProvider.notifier);
          for (var i = 0; i < servers.length; i++) {
            if (!ref.context.mounted) {
              return;
            }
            await serverDao.updateTraffic(servers[i].id, null, null);
            notifier.updateServerState(
              servers[i].withTraffic(
                null,
                null,
              ),
            );
          }
          break;
        default:
          return;
      }
    } catch (_) {}
  }
}
