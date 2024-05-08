import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/data/rule_group.dart';
import 'package:sphia/app/notifier/data/server_lite.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/server_model_lite.dart';
import 'package:sphia/util/system.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'tray_menu.g.dart';

@Riverpod(keepAlive: true)
class TrayMenuNotifier extends _$TrayMenuNotifier {
  @override
  List<MenuItem> build() {
    final coreRunning =
        ref.watch(proxyNotifierProvider.select((value) => value.coreRunning));
    final systemProxy =
        ref.watch(proxyNotifierProvider.select((value) => value.systemProxy));
    final servers = ref.watch(serverLiteNotifierProvider);
    final ruleGroups = ref.watch(ruleGroupNotifierProvider);
    return [
      MenuItem.checkbox(
        label: S.current.coreStart,
        checked: coreRunning,
        onClick: (menuItem) async {
          final serverConfig = ref.read(serverConfigNotifierProvider);
          final proxyState = ref.read(proxyNotifierProvider);
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          final id = serverConfig.selectedServerId;
          final server = await serverDao.getServerModelById(id);
          if (server == null) {
            logger.w('Selected server not exists');
            return;
          }
          if (!proxyState.coreRunning) {
            await coreStateNotifier.toggleCores(server);
          }
        },
      ),
      MenuItem.checkbox(
        label: S.current.coreStop,
        checked: !coreRunning,
        onClick: (menuItem) async {
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          await coreStateNotifier.stopCores();
        },
      ),
      MenuItem.checkbox(
        label: S.current.systemProxy,
        checked: systemProxy,
        onClick: (menuItem) async {
          final proxyStateNotifier = ref.read(proxyNotifierProvider.notifier);
          if (menuItem.checked != null && menuItem.checked!) {
            SystemUtil.disableSystemProxy();
            proxyStateNotifier.setSystemProxy(false);
          } else {
            final proxyState = ref.read(proxyNotifierProvider);
            if (!proxyState.coreRunning || proxyState.tunMode) {
              return;
            }
            final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
            int socksPort = sphiaConfig.socksPort;
            int httpPort = sphiaConfig.httpPort;
            final coreState = ref.read(coreStateNotifierProvider).valueOrNull;
            final routingName = coreState?.routing.name;
            if (routingName == null) {
              logger.e('Core state is null');
              throw Exception('Core state is null');
            }
            if (routingName == 'sing-box') {
              socksPort = sphiaConfig.mixedPort;
              httpPort = sphiaConfig.mixedPort;
            }
            SystemUtil.enableSystemProxy(
              sphiaConfig.listen,
              socksPort,
              httpPort,
            );
            proxyStateNotifier.setSystemProxy(true);
          }
        },
      ),
      MenuItem.separator(),
      MenuItem.submenu(
        label: S.current.server,
        submenu: Menu(
          items: _generateServerItems(servers),
        ),
      ),
      MenuItem.submenu(
        label: S.current.rules,
        submenu: Menu(
          items: _generateRuleItems(ruleGroups),
        ),
      ),
      MenuItem.separator(),
      MenuItem(
        label: S.current.show,
        onClick: (menuItem) async {
          await windowManager.show();
        },
      ),
      MenuItem(
        label: S.current.hide,
        onClick: (menuItem) async {
          await windowManager.close();
        },
      ),
      MenuItem(
        label: S.current.exit,
        onClick: (menuItem) async {
          logger.i('Exiting Sphia');
          // Stop cores
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          await coreStateNotifier.stopCores();
          // Close database
          await SphiaDatabase.close();
          // Destory tray
          await trayManager.destroy();
          // Close logger
          logger.close();
          // Destory window
          await windowManager.destroy();
        },
      ),
    ];
  }

  List<MenuItem> _generateServerItems(List<ServerModelLite> servers) {
    final items = <MenuItem>[];
    for (final server in servers) {
      final menuItem = MenuItem.checkbox(
        label: server.remark,
        checked: ref.watch(serverConfigNotifierProvider
            .select((value) => value.selectedServerId == server.id)),
        onClick: (menuItem) async {
          if (menuItem.checked == null) {
            return;
          }
          final serverConfigNotifier =
              ref.read(serverConfigNotifierProvider.notifier);
          final proxyState = ref.read(proxyNotifierProvider);
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          if (!(menuItem.checked!)) {
            serverConfigNotifier.updateValue('selectedServerId', server.id);
            if (proxyState.coreRunning) {
              await coreStateNotifier.stopCores(keepSysProxy: true);
              await coreStateNotifier.startCores(await server.toServerModel());
            }
          } else {
            serverConfigNotifier.updateValue('selectedServerId', 0);
          }
        },
      );
      items.add(menuItem);
    }
    return items;
  }

  List<MenuItem> _generateRuleItems(List<RuleGroup> ruleGroups) {
    final items = <MenuItem>[];
    for (final ruleGroup in ruleGroups) {
      final menuItem = MenuItem.checkbox(
        label: ruleGroup.name,
        checked: ref.watch(ruleConfigNotifierProvider
            .select((value) => value.selectedRuleGroupId == ruleGroup.id)),
        onClick: (menuItem) async {
          if (menuItem.checked == null) {
            return;
          }
          final ruleConfigNotifier =
              ref.read(ruleConfigNotifierProvider.notifier);
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          // if put proxyStateNotifier into if statement, it will cause error
          if (!(menuItem.checked!)) {
            logger.i('Switching rule group to ${ruleGroup.name}');
            ruleConfigNotifier.updateSelectedRuleGroupId(ruleGroup.id);
            await coreStateNotifier.restartCores();
          }
        },
      );
      items.add(menuItem);
    }
    return items;
  }
}