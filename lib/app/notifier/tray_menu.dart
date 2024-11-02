import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/proxy.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/notifier/data/rule_group.dart';
import 'package:sphia/app/notifier/data/server.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/provider/l10n.dart';
import 'package:sphia/server/server_model.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

part 'tray_menu.g.dart';

@Riverpod(keepAlive: true)
class TrayMenuNotifier extends _$TrayMenuNotifier {
  @override
  List<MenuItem> build() {
    final l10n = ref.read(l10nProvider).value!;
    final coreRunning =
        ref.watch(proxyNotifierProvider.select((value) => value.coreRunning));
    final systemProxy =
        ref.watch(proxyNotifierProvider.select((value) => value.systemProxy));
    final tunMode =
        ref.watch(proxyNotifierProvider.select((value) => value.tunMode));
    final isCustom =
        ref.watch(proxyNotifierProvider.select((value) => value.customConfig));
    final servers = ref.watch(serverNotifierProvider);
    final ruleGroups = ref.watch(ruleGroupNotifierProvider);
    return [
      MenuItem.checkbox(
        label: l10n.coreStart,
        checked: coreRunning,
        onClick: (menuItem) async {
          final serverConfig = ref.read(serverConfigNotifierProvider);
          final proxyState = ref.read(proxyNotifierProvider);
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          final id = serverConfig.selectedServerId;
          final server = await serverDao.getServerModelById(id);
          if (server == null) {
            return;
          }
          if (!proxyState.coreRunning) {
            await coreStateNotifier.startCores(server);
          }
        },
      ),
      MenuItem.checkbox(
        label: l10n.coreStop,
        checked: !coreRunning,
        onClick: (menuItem) async {
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          await coreStateNotifier.stopCores();
        },
      ),
      MenuItem.checkbox(
        label: l10n.systemProxy,
        checked: systemProxy,
        disabled: !coreRunning || tunMode, // why doesn't work on linux
        onClick: (menuItem) async {
          final proxyState = ref.read(proxyNotifierProvider);
          if (!proxyState.coreRunning) {
            return;
          }
          if (menuItem.checked != null && menuItem.checked!) {
            await ref.read(proxyHelperProvider.notifier).disableSystemProxy();
          } else {
            await ref.read(proxyHelperProvider.notifier).enableSystemProxy();
          }
        },
      ),
      MenuItem.separator(),
      MenuItem.submenu(
        label: l10n.server,
        submenu: Menu(
          items: _generateServerItems(servers.valueOrNull ?? []),
        ),
      ),
      MenuItem.submenu(
        disabled: coreRunning && isCustom,
        label: l10n.rules,
        submenu: Menu(
          items: _generateRuleItems(ruleGroups),
        ),
      ),
      MenuItem.separator(),
      MenuItem(
        label: l10n.show,
        onClick: (menuItem) async {
          await windowManager.show();
        },
      ),
      MenuItem(
        label: l10n.hide,
        onClick: (menuItem) async {
          await windowManager.close();
        },
      ),
      MenuItem(
        label: l10n.exit,
        onClick: (menuItem) async {
          // Stop cores
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          await coreStateNotifier.stopCores();
          // Close database
          await SphiaDatabase.close();
          // Destory tray
          await trayManager.destroy();
          // Destory window
          await windowManager.destroy();
        },
      ),
    ];
  }

  List<MenuItem> _generateServerItems(List<ServerModel> servers) {
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
              await coreStateNotifier.startCores(server);
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
