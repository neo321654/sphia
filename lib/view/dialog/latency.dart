import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/latency.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/config/version_config.dart';
import 'package:sphia/app/notifier/data/server.dart';
import 'package:sphia/app/provider/core.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/view/page/server.dart';

part 'latency.g.dart';

enum LatencyAction { clear, test }

enum LatencyType { icmp, tcp, url }

typedef LatencyOptions = (
  LatencyAction action,
  ActionRange range,
  LatencyType? type
);

@riverpod
class LatencyDialogCancelNotifier extends _$LatencyDialogCancelNotifier {
  @override
  bool build() {
    return false;
  }

  void updateValue(bool value) {
    state = value;
  }
}

class LatencyDialog extends HookConsumerWidget {
  final LatencyOptions options;

  const LatencyDialog({
    super.key,
    required this.options,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completer = useMemoized(() => Completer<void>());
    final isCancel = ref.watch(latencyDialogCancelNotifierProvider);

    Future<void> latencyTest() async {
      final range = options.$2;
      final type = options.$3!;
      logger.i('Testing Latency: range=${range.name}, type=${type.name}');

      final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
      final testUrl = sphiaConfig.latencyTestUrl;
      final serverConfig = ref.read(serverConfigNotifierProvider);
      switch (range) {
        case ActionRange.selectedServer:
          final notifier = ref.read(serverNotifierProvider.notifier);
          final id = serverConfig.selectedServerId;
          final server = await serverDao.getServerModelById(id);
          if (server == null) {
            logger.w('Selected server not exists');
            completer.complete();
            return;
          }
          if (server.protocol == Protocol.custom) {
            logger.w('Custom config server does not support latency test');
            completer.complete();
            return;
          }
          //
          late final int latency;
          switch (type) {
            case LatencyType.icmp:
              latency = await IcmpLatency.testIcmpLatency(server.address);
              break;
            case LatencyType.tcp:
              latency =
                  await TcpLatency.testTcpLatency(server.address, server.port);
              break;
            case LatencyType.url:
              final core = ref.read(latencyTestCoreProvider);
              final urlLatency =
                  UrlLatency(servers: [server], testUrl: testUrl, core: core);
              final tag = 'proxy-${server.id}';
              final versionConfig = ref.read(versionConfigNotifierProvider);
              await urlLatency.init(sphiaConfig, versionConfig).catchError((e) {
                logger.e('Failed to init UrlLatency: $e');
                completer.complete();
              });
              latency = await urlLatency.testUrlLatency(tag);
              urlLatency.stop();
              break;
          }
          await serverDao.updateLatency(server.id, latency);
          notifier.updateServerState(
            server.withLatency(latency),
          );
          break;
        case ActionRange.currentGroup:
          final servers = ref.read(serverNotifierProvider).valueOrNull ?? [];
          servers.removeWhere((server) => server.protocol == Protocol.custom);
          if (servers.isEmpty) {
            logger.w('No server to test latency');
            completer.complete();
            return;
          }
          final isUrl = type == LatencyType.url;
          late final UrlLatency urlLatency;
          if (isUrl) {
            final core = ref.read(latencyTestCoreProvider);
            urlLatency =
                UrlLatency(servers: servers, testUrl: testUrl, core: core);
            final versionConfig = ref.read(versionConfigNotifierProvider);
            await urlLatency.init(sphiaConfig, versionConfig).catchError((e) {
              logger.e('Failed to init UrlLatency: $e');
              completer.complete();
            });
          }
          final notifier = ref.read(serverNotifierProvider.notifier);
          for (var i = 0; i < servers.length; i++) {
            if (completer.isCompleted) {
              if (isUrl) {
                await urlLatency.stop();
              }
              return;
            }
            final server = servers[i];
            late final int latency;
            switch (type) {
              case LatencyType.icmp:
                latency = await IcmpLatency.testIcmpLatency(server.address);
                break;
              case LatencyType.tcp:
                latency = await TcpLatency.testTcpLatency(
                    server.address, server.port);
                break;
              case LatencyType.url:
                final tag = 'proxy-${server.id}';
                latency = await urlLatency.testUrlLatency(tag);
                break;
            }
            await serverDao.updateLatency(server.id, latency);
            notifier.updateServerState(
              server.withLatency(latency),
            );
          }
          if (isUrl) {
            await urlLatency.stop();
          }
          break;
        default:
          completer.complete();
          return;
      }
      completer.complete();
    }

    Future<void> clearLatency() async {
      final range = options.$2;
      logger.i('Clearing Latency: range=${range.name}');

      final serverConfig = ref.read(serverConfigNotifierProvider);
      switch (range) {
        case ActionRange.selectedServer:
          final notifier = ref.read(serverNotifierProvider.notifier);
          final id = serverConfig.selectedServerId;
          final server = await serverDao.getServerModelById(id);
          if (server == null) {
            logger.w('Selected server not exists');
            completer.complete();
            return;
          }
          if (server.protocol == Protocol.custom) {
            logger.w('Custom config server does not support latency clearing');
            completer.complete();
            return;
          }
          await serverDao.updateLatency(server.id, null);
          notifier.updateServerState(
            server.withLatency(null),
          );
          break;
        case ActionRange.currentGroup:
          final servers = ref.read(serverNotifierProvider).valueOrNull ?? [];
          servers.removeWhere((server) => server.protocol == Protocol.custom);
          if (servers.isEmpty) {
            logger.w('No server to clear latency');
            completer.complete();
            return;
          }
          final notifier = ref.read(serverNotifierProvider.notifier);
          for (var i = 0; i < servers.length; i++) {
            if (completer.isCompleted) {
              return;
            }
            await serverDao.updateLatency(
              servers[i].id,
              null,
            );
            notifier.updateServerState(
              servers[i].withLatency(null),
            );
          }
          break;
        default:
          completer.complete();
          return;
      }
      completer.complete();
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        late final Future<void> operation;
        switch (options.$1) {
          case LatencyAction.clear:
            operation = clearLatency();
            break;
          case LatencyAction.test:
            operation = latencyTest();
            break;
        }
        await operation;
        if (completer.isCompleted && context.mounted) {
          Navigator.of(context).pop();
        }
      });
      return null;
    }, []);

    return AlertDialog(
      title: Text(L10n.of(context)!.latencyTest),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isCancel
              ? null
              : () {
                  completer.complete();
                  final notifier =
                      ref.read(latencyDialogCancelNotifierProvider.notifier);
                  notifier.updateValue(true);
                },
          child: Text(L10n.of(context)!.cancel),
        )
      ],
    );
  }
}
