import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' as p;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/latency.dart';
import 'package:sphia/app/helper/server.dart';
import 'package:sphia/app/helper/uri/uri.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/data/server.dart';
import 'package:sphia/app/provider/core.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/custom_config/server.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/server/xray/server.dart';
import 'package:sphia/view/card/dashboard_card/chart.dart';
import 'package:sphia/view/card/shadow_card.dart';
import 'package:sphia/view/widget/widget.dart';

part 'server_card.g.dart';

enum ShareOption {
  qrCode,
  clipboard,
  configuration,
}

@riverpod
ServerModel currentServer(Ref ref) => throw UnimplementedError();

class ServerCard extends ConsumerWidget with ServerHelper {
  const ServerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = Color(ref.watch(
        sphiaConfigNotifierProvider.select((value) => value.themeColor)));
    final server = ref.watch(currentServerProvider);
    final isSelected = ref.watch(serverConfigNotifierProvider
        .select((value) => value.selectedServerId == server.id));

    return ShadowCard(
      color: isSelected ? themeColor : null,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        title: Text(server.remark),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final showTransport = ref.watch(sphiaConfigNotifierProvider
                    .select((value) => value.showTransport));
                String serverInfo = server.protocol.name;
                if (showTransport) {
                  if (server is XrayServer) {
                    serverInfo += ' - ${server.transport}';
                    if (server.tls != 'none') {
                      serverInfo += ' + ${server.tls}';
                    }
                  } else if (server is ShadowsocksServer &&
                      server.plugin != null) {
                    if (server.plugin == 'obfs-local' ||
                        server.plugin == 'simple-obfs') {
                      serverInfo += ' - http';
                    } else if (server.plugin == 'simple-obfs-tls') {
                      serverInfo += ' - tls';
                    }
                  } else if (server is TrojanServer) {
                    serverInfo += ' - tcp';
                  } else if (server is HysteriaServer) {
                    serverInfo += ' - ${server.hysteriaProtocol}';
                  }
                }
                return Text(serverInfo);
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                final showAddress = ref.watch(sphiaConfigNotifierProvider
                    .select((value) => value.showAddress));
                if (showAddress && server.protocol != Protocol.custom) {
                  return Text('${server.address}:${server.port}');
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (server.latency != null) ...[
                  Consumer(
                    builder: (context, ref, child) {
                      final darkMode = ref.watch(sphiaConfigNotifierProvider
                          .select((value) => value.darkMode));
                      return RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: server.latency == latencyFailure
                                    ? 'timeout'
                                    : '${server.latency} ms',
                                style: TextStyle(
                                    color: darkMode
                                        ? Colors.white
                                        : Colors.black)),
                            TextSpan(
                              text: '  ◉',
                              style: TextStyle(
                                color: _getLatencyColor(server.latency!),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ],
                if (server.uplink != null && server.downlink != null)
                  _getServerTrafficWidget(
                    server.uplink!.toDouble(),
                    server.downlink!.toDouble(),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            SphiaWidget.iconButton(
              icon: Symbols.edit,
              onTap: () async {
                late final ServerModel? newServer;
                if ((newServer = await _editServer(
                      server: server,
                      ref: ref,
                    )) !=
                    null) {
                  final notifier = ref.read(serverNotifierProvider.notifier);
                  notifier.updateServerData(newServer!);
                }
              },
            ),
            const SizedBox(width: 16),
            SphiaWidget.popupMenuIconButton<ShareOption>(
              icon: Symbols.share,
              items: [
                if (server.protocol != Protocol.custom) ...[
                  PopupMenuItem(
                    value: ShareOption.qrCode,
                    child: Text(L10n.of(context)!.qrCode),
                  ),
                  PopupMenuItem(
                    value: ShareOption.clipboard,
                    child: Text(L10n.of(context)!.exportToClipboard),
                  ),
                ],
                PopupMenuItem(
                  value: ShareOption.configuration,
                  child: Text(L10n.of(context)!.configuration),
                )
              ],
              onItemSelected: (value) async {
                if (await _shareServer(
                  option: value,
                  server: server,
                  ref: ref,
                )) {
                  if (value == ShareOption.configuration) {
                    if (!context.mounted) {
                      return;
                    }
                    final tempPath = IoHelper.tempPath;
                    await SphiaWidget.showDialogWithMsg(
                      context: context,
                      message:
                          '${L10n.of(context)!.exportToFile}: ${p.join(tempPath, 'export.json')}',
                    );
                  }
                } else {
                  if (value == ShareOption.configuration) {
                    if (!context.mounted) {
                      return;
                    }
                    await SphiaWidget.showDialogWithMsg(
                      context: context,
                      message: L10n.of(context)!.noConfigurationFileGenerated,
                    );
                  }
                }
              },
            ),
            const SizedBox(width: 16),
            SphiaWidget.iconButton(
              icon: Symbols.delete,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(L10n.of(context)!.deleteServer),
                    content: Text(
                        L10n.of(context)!.deleteServerConfirm(server.remark)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(L10n.of(context)!.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(L10n.of(context)!.delete),
                      ),
                    ],
                  ),
                );
                if (confirm == null || !confirm) {
                  return;
                }
                logger.i('Deleting Server: ${server.id}');
                await serverDao.deleteServer(server.id);
                await serverDao.refreshServersOrder(server.groupId);
                final serverNotifier =
                    ref.read(serverNotifierProvider.notifier);
                serverNotifier.removeServer(server);
              },
            )
          ],
        ),
        onTap: () {
          final serverConfig = ref.read(serverConfigNotifierProvider);
          final notifier = ref.read(serverConfigNotifierProvider.notifier);
          if (server.id == serverConfig.selectedServerId) {
            notifier.updateValue('selectedServerId', 0);
          } else {
            notifier.updateValue('selectedServerId', server.id);
          }
        },
      ),
    );
  }

  Widget _getServerTrafficWidget(double uplink, double downlink) {
    if (uplink == 0 && downlink == 0) {
      return const SizedBox.shrink();
    }

    final str = '${formatBytes(uplink)}↑ ${formatBytes(downlink)}↓';
    return Text(str);
  }

  Color _getLatencyColor(int latency) {
    // use A400 color
    const red = Color.fromARGB(255, 255, 61, 0);
    const yellow = Color.fromARGB(255, 255, 234, 0);
    const green = Color.fromARGB(255, 118, 255, 3);
    if (latency == latencyFailure || latency < 0) {
      return red;
    }
    if (latency <= latencyGreen) {
      return green;
    } else if (latency <= latencyYellow) {
      return yellow;
    } else {
      return red;
    }
  }

  Future<ServerModel?> _editServer({
    required ServerModel server,
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final ServerModel? editedServer = await getEditedServer(
      server: server,
      context: context,
    );
    if (editedServer == null || editedServer == server) {
      return null;
    }
    logger.i('Editing Server: ${server.id}');
    await serverDao.updateServer(editedServer);
    return editedServer;
  }

  Future<bool> _shareServer({
    required ShareOption option,
    required ServerModel server,
    required WidgetRef ref,
  }) async {
    switch (option) {
      case ShareOption.qrCode:
        String? uri = UriHelper.getUri(server);
        final context = ref.context;
        if (uri != null && context.mounted) {
          _shareQRCode(uri: uri, context: context);
        }
        return true;
      case ShareOption.clipboard:
        String? uri = UriHelper.getUri(server);
        if (uri != null) {
          UriHelper.exportUriToClipboard(uri);
        }
        return true;
      case ShareOption.configuration:
        return _shareConfiguration(
          server: server,
          ref: ref,
        );
      default:
        return false;
    }
  }

  void _shareQRCode({
    required String uri,
    required BuildContext context,
  }) async {
    logger.i('Sharing QRCode: $uri');
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              data: uri,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _shareConfiguration({
    required ServerModel server,
    required WidgetRef ref,
  }) async {
    final protocol = server.protocol;

    if (protocol == Protocol.custom) {
      server = server as CustomConfigServer;
      final tempPath = IoHelper.tempPath;
      final file = File(p.join(tempPath, 'export.${server.configFormat}'));
      if (file.existsSync()) {
        file.deleteSync();
      }
      await file.writeAsString(server.configString);
      return true;
    }

    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final protocolProviderIdx = server.protocolProvider;
    final core = switch (protocol) {
      Protocol.vmess => VMessProvider.values[
                  protocolProviderIdx ?? sphiaConfig.vmessProvider.index] ==
              VMessProvider.xray
          ? ref.read(xrayCoreProvider)
          : ref.read(singBoxCoreProvider),
      Protocol.vless => VlessProvider.values[
                  protocolProviderIdx ?? sphiaConfig.vlessProvider.index] ==
              VlessProvider.xray
          ? ref.read(xrayCoreProvider)
          : ref.read(singBoxCoreProvider),
      Protocol.shadowsocks => switch (ShadowsocksProvider.values[
            protocolProviderIdx ?? sphiaConfig.shadowsocksProvider.index]) {
          ShadowsocksProvider.xray => ref.read(xrayCoreProvider),
          ShadowsocksProvider.sing => ref.read(singBoxCoreProvider),
          _ => null,
        },
      Protocol.trojan => TrojanProvider.values[
                  protocolProviderIdx ?? sphiaConfig.trojanProvider.index] ==
              TrojanProvider.xray
          ? ref.read(xrayCoreProvider)
          : ref.read(singBoxCoreProvider),
      Protocol.hysteria => HysteriaProvider.values[
                  protocolProviderIdx ?? sphiaConfig.hysteriaProvider.index] ==
              HysteriaProvider.sing
          ? ref.read(singBoxCoreProvider)
          : ref.read(hysteriaCoreProvider),
      _ => null
    };
    if (core == null) {
      logger.e('No supported core for protocol: $protocol');
      return false;
    }
    core.configFileName = 'export.json';
    core.isRouting = true;
    core.servers.add(server);
    logger.i('Sharing Configuration: ${server.id}');
    await core.configure();
    return true;
  }
}
