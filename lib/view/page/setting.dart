import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/widget/setting_widget/checkbox_card.dart';
import 'package:sphia/view/widget/setting_widget/colors_card.dart';
import 'package:sphia/view/widget/setting_widget/items_card.dart';
import 'package:sphia/view/widget/setting_widget/text_card.dart';
import 'package:sphia/view/widget/widget.dart';

class SettingPage extends ConsumerWidget with SystemHelper {
  const SettingPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(sphiaConfigNotifierProvider.notifier);
    final coreRunning =
        ref.watch(proxyNotifierProvider.select((value) => value.coreRunning));
    final sphiaWidgets = [
      CheckboxCard(
        title: L10n.of(context)!.startOnBoot,
        selector: (value) => value.startOnBoot,
        updater: (value) {
          notifier.updateValue('startOnBoot', value);
          final execPath = IoHelper.execPath;
          configureStartup(execPath, value);
        },
        tooltip: L10n.of(context)!.startOnBootMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.autoRunServer,
        selector: (value) => value.autoRunServer,
        updater: (value) {
          notifier.updateValue('autoRunServer', value);
        },
        tooltip: L10n.of(context)!.autoRunServerMsg,
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.darkMode,
        selector: (value) => value.darkMode,
        updater: (value) {
          notifier.updateValue('darkMode', value);
        },
      ),
      ColorsCard(
        items: {
          Colors.red.value: 'Red',
          Colors.orange.value: 'Orange',
          Colors.yellow.value: 'Yellow',
          Colors.green.value: 'Green',
          Colors.lightBlue.value: 'Light Blue',
          Colors.blue.value: 'Blue',
          Colors.cyan.value: 'Cyan',
          Colors.deepPurple.value: 'Deep Purple',
        },
        updater: (value) {
          notifier.updateValue('themeColor', value);
        },
        tooltip: L10n.of(context)!.themeColorMsg,
      ),
      TextCard(
        title: L10n.of(context)!.themeColorArgb,
        selector: (value) {
          return '${value.themeColor >> 24},${(value.themeColor >> 16) & 0xFF},${(value.themeColor >> 8) & 0xFF},${value.themeColor & 0xFF}';
        },
        updater: (value) {
          late int a, r, g, b;
          try {
            a = int.parse(value.split(',')[0]);
            r = int.parse(value.split(',')[1]);
            g = int.parse(value.split(',')[2]);
            b = int.parse(value.split(',')[3]);
          } on Exception catch (_) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.themeColorWarn,
            );
            return;
          }
          legalValue(int number) => (number >= 0 && number < 256);
          if (legalValue(a) &&
              legalValue(r) &&
              legalValue(g) &&
              legalValue(b)) {
            final argbValue = (a << 24) | (r << 16) | (g << 8) | b;
            notifier.updateValue('themeColor', argbValue);
          } else {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.themeColorWarn,
            );
          }
        },
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.showTransport,
        selector: (value) => value.showTransport,
        updater: (value) {
          notifier.updateValue('showTransport', value);
        },
        tooltip: L10n.of(context)!.showTransportMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.showAddress,
        selector: (value) => value.showAddress,
        updater: (value) {
          notifier.updateValue('showAddress', value);
        },
        tooltip: L10n.of(context)!.showAddressMsg,
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.enableStatistics,
        selector: (value) => value.enableStatistics,
        updater: (value) {
          notifier.updateValue('enableStatistics', value);
          if (!value) {
            notifier.updateValue('enableSpeedChart', false);
          }
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.enableStatisticsMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.enableSpeedChart,
        selector: (value) => value.enableSpeedChart,
        updater: (value) {
          notifier.updateValue('enableSpeedChart', value);
          if (value) {
            notifier.updateValue('enableStatistics', true);
          }
        },
        enabled: !coreRunning ||
            (coreRunning &&
                ref.read(sphiaConfigNotifierProvider).enableStatistics),
        tooltip: L10n.of(context)!.enableSpeedChartMsg,
      ),
      const Divider(),
      TextCard(
        title: L10n.of(context)!.latencyTestUrl,
        selector: (value) => value.latencyTestUrl,
        updater: (value) {
          notifier.updateValue('latencyTestUrl', value);
        },
        tooltip: L10n.of(context)!.latencyTestUrlMsg,
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.updateThroughProxy,
        selector: (value) => value.updateThroughProxy,
        updater: (value) {
          notifier.updateValue('updateThroughProxy', value);
        },
        tooltip: L10n.of(context)!.updateThroughProxyMsg,
      ),
      ItemsCard<UserAgent>(
        title: L10n.of(context)!.userAgent,
        items: UserAgent.values,
        idxSelector: (value) => value.userAgent.index,
        updater: (value) {
          notifier.updateValue('userAgent', value.name);
        },
        tooltip: L10n.of(context)!.userAgentMsg,
      ),
    ];
    final proxyWidgets = [
      CheckboxCard(
        title: L10n.of(context)!.autoGetIp,
        selector: (value) => value.autoGetIp,
        updater: (value) {
          notifier.updateValue('autoGetIp', value);
        },
        tooltip: L10n.of(context)!.autoGetIpMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.multiOutboundSupport,
        selector: (value) => value.multiOutboundSupport,
        updater: (value) {
          notifier.updateValue('multiOutboundSupport', value);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.multiOutboundSupportMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.autoConfigureSystemProxy,
        selector: (value) => value.autoConfigureSystemProxy,
        updater: (value) {
          notifier.updateValue('autoConfigureSystemProxy', value);
          if (value) {
            notifier.updateValue('enableTun', false);
          }
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.autoConfigureSystemProxyMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.enableTun,
        selector: (value) => value.enableTun,
        updater: (value) {
          notifier.updateValue('enableTun', value);
          if (value) {
            notifier.updateValue('autoConfigureSystemProxy', false);
          }
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.enableTunMsg,
      ),
      const Divider(),
      TextCard(
        title: L10n.of(context)!.socksPort,
        selector: (value) => value.socksPort.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null ||
              newValue! < 0 ||
              newValue > 65535) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.portInvalidMsg,
            );
            return;
          }
          notifier.updateValue('socksPort', newValue);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.socksPortMsg,
      ),
      TextCard(
        title: L10n.of(context)!.httpPort,
        selector: (value) => value.httpPort.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null ||
              newValue! < 0 ||
              newValue > 65535) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.portInvalidMsg,
            );
            return;
          }
          notifier.updateValue('httpPort', newValue);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.httpPortMsg,
      ),
      TextCard(
        title: L10n.of(context)!.mixedPort,
        selector: (value) => value.mixedPort.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null ||
              newValue! < 0 ||
              newValue > 65535) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.portInvalidMsg,
            );
            return;
          }
          notifier.updateValue('mixedPort', newValue);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.mixedPortMsg,
      ),
      TextCard(
        title: L10n.of(context)!.listen,
        selector: (value) => value.listen,
        updater: (value) {
          notifier.updateValue('listen', value);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.listenMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.enableUdp,
        selector: (value) => value.enableUdp,
        updater: (value) {
          notifier.updateValue('enableUdp', value);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.enableUdpMsg,
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.authentication,
        selector: (value) => value.authentication,
        updater: (value) {
          notifier.updateValue('authentication', value);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.authenticationMsg,
      ),
      TextCard(
        title: L10n.of(context)!.user,
        selector: (value) => value.user,
        updater: (value) {
          notifier.updateValue('user', value);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.userMsg,
      ),
      TextCard(
        title: L10n.of(context)!.password,
        selector: (value) => value.password,
        updater: (value) {
          notifier.updateValue('password', value);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.passwordMsg,
      ),
    ];
    final coreWidgets = [
      TextCard(
        title: L10n.of(context)!.coreApiPort,
        selector: (value) => value.coreApiPort.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null ||
              newValue! < 0 ||
              newValue > 65535) {
            return;
          }
          notifier.updateValue('coreApiPort', newValue);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.coreApiPortMsg,
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.enableSniffing,
        selector: (value) => value.enableSniffing,
        updater: (value) {
          notifier.updateValue('enableSniffing', value);
        },
        tooltip: L10n.of(context)!.enableSniffingMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.configureDns,
        selector: (value) => value.configureDns,
        updater: (value) {
          notifier.updateValue('configureDns', value);
        },
        tooltip: L10n.of(context)!.configureDnsMsg,
      ),
      TextCard(
        title: L10n.of(context)!.remoteDns,
        selector: (value) => value.remoteDns,
        updater: (value) {
          notifier.updateValue('remoteDns', value);
        },
        tooltip: L10n.of(context)!.remoteDnsMsg,
      ),
      TextCard(
        title: L10n.of(context)!.directDns,
        selector: (value) => value.directDns,
        updater: (value) {
          notifier.updateValue('directDns', value);
        },
        tooltip: L10n.of(context)!.directDnsMsg,
      ),
      TextCard(
        title: L10n.of(context)!.dnsResolver,
        selector: (value) => value.dnsResolver,
        updater: (value) {
          notifier.updateValue('dnsResolver', value);
        },
        tooltip: L10n.of(context)!.dnsResolverMsg,
      ),
      const Divider(),
      ItemsCard<DomainStrategy>(
        title: L10n.of(context)!.domainStrategy,
        items: DomainStrategy.values,
        idxSelector: (value) => value.domainStrategy.index,
        updater: (value) {
          notifier.updateValue('domainStrategy', value.name);
        },
        tooltip: L10n.of(context)!.domainStrategyMsg,
      ),
      ItemsCard<DomainMatcher>(
        title: L10n.of(context)!.domainMatcher,
        items: DomainMatcher.values,
        idxSelector: (value) => value.domainMatcher.index,
        updater: (value) {
          notifier.updateValue('domainMatcher', value.name);
        },
        tooltip: L10n.of(context)!.domainMatcherMsg,
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.enableCoreLog,
        selector: (value) => value.enableCoreLog,
        updater: (value) {
          notifier.updateValue('enableCoreLog', value);
        },
        tooltip: L10n.of(context)!.enableCoreLogMsg,
      ),
      ItemsCard<CoreLogLevel>(
        title: L10n.of(context)!.logLevel,
        items: CoreLogLevel.values,
        idxSelector: (value) => value.logLevel.index,
        updater: (value) {
          notifier.updateValue('logLevel', value.name);
        },
        tooltip: L10n.of(context)!.logLevelMsg,
      ),
      TextCard(
        title: L10n.of(context)!.maxLogCount,
        selector: (value) => value.maxLogCount.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null || newValue! < 0) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.enterValidNumberMsg,
            );
            return;
          }
          notifier.updateValue('maxLogCount', newValue);
        },
        tooltip: L10n.of(context)!.maxLogCountMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.saveCoreLog,
        selector: (value) => value.saveCoreLog,
        updater: (value) {
          notifier.updateValue('saveCoreLog', value);
        },
        tooltip: L10n.of(context)!.saveCoreLogMsg,
      ),
    ];

    final providerWidgets = [
      ItemsCard<RoutingProvider>(
        title: L10n.of(context)!.routingProvider,
        items: RoutingProvider.values.withoutLast,
        idxSelector: (value) => value.routingProvider.index,
        updater: (value) {
          notifier.updateValue('routingProvider', value.name);
        },
      ),
      ItemsCard<VMessProvider>(
        title: L10n.of(context)!.vmessProvider,
        items: VMessProvider.values.withoutLast,
        idxSelector: (value) => value.vmessProvider.index,
        updater: (value) {
          notifier.updateValue('vmessProvider', value.name);
        },
      ),
      ItemsCard<VlessProvider>(
        title: L10n.of(context)!.vlessProvider,
        items: VlessProvider.values.withoutLast,
        idxSelector: (value) => value.vlessProvider.index,
        updater: (value) {
          notifier.updateValue('vlessProvider', value.name);
        },
      ),
      ItemsCard<ShadowsocksProvider>(
        title: L10n.of(context)!.shadowsocksProvider,
        items: ShadowsocksProvider.values.withoutLast,
        idxSelector: (value) => value.shadowsocksProvider.index,
        updater: (value) {
          notifier.updateValue('shadowsocksProvider', value.name);
        },
      ),
      ItemsCard<TrojanProvider>(
        title: L10n.of(context)!.trojanProvider,
        items: TrojanProvider.values.withoutLast,
        idxSelector: (value) => value.trojanProvider.index,
        updater: (value) {
          notifier.updateValue('trojanProvider', value.name);
        },
      ),
      ItemsCard<HysteriaProvider>(
        title: L10n.of(context)!.hysteriaProvider,
        items: HysteriaProvider.values.withoutLast,
        idxSelector: (value) => value.hysteriaProvider.index,
        updater: (value) {
          notifier.updateValue('hysteriaProvider', value.name);
        },
      ),
      const Divider(),
      TextCard(
        title: L10n.of(context)!.editorPath,
        selector: (value) => value.editorPath,
        updater: (value) {
          notifier.updateValue('editorPath', value);
        },
      ),
      const Divider(),
      TextCard(
        title: L10n.of(context)!.additionalSocksPort,
        selector: (value) => value.additionalSocksPort.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null ||
              newValue! < 0 ||
              newValue > 65535) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.portInvalidMsg,
            );
            return;
          }
          notifier.updateValue('additionalSocksPort', newValue);
        },
        enabled: !coreRunning,
        tooltip: L10n.of(context)!.additionalSocksPortMsg,
      ),
    ];
    final tunWidgets = [
      ItemsCard<TunProvider>(
        title: L10n.of(context)!.tunProvider,
        items: TunProvider.values,
        idxSelector: (value) => value.tunProvider.index,
        updater: (value) {
          notifier.updateValue('tunProvider', value.name);
        },
      ),
      const Divider(),
      CheckboxCard(
        title: L10n.of(context)!.enableIpv4,
        selector: (value) => value.enableIpv4,
        updater: (value) {},
        enabled: false,
        tooltip: L10n.of(context)!.enableIpv4Msg,
      ),
      TextCard(
        title: L10n.of(context)!.ipv4Address,
        selector: (value) => value.ipv4Address,
        updater: (value) {
          notifier.updateValue('ipv4Address', value);
        },
        tooltip: L10n.of(context)!.ipv4AddressMsg,
      ),
      CheckboxCard(
        title: L10n.of(context)!.enableIpv6,
        selector: (value) => value.enableIpv6,
        updater: (value) {
          notifier.updateValue('enableIpv6', value);
        },
        tooltip: L10n.of(context)!.enableIpv6Msg,
      ),
      TextCard(
        title: L10n.of(context)!.ipv6Address,
        selector: (value) => value.ipv6Address,
        updater: (value) {
          notifier.updateValue('ipv6Address', value);
        },
        tooltip: L10n.of(context)!.ipv6AddressMsg,
      ),
      const Divider(),
      TextCard(
        title: L10n.of(context)!.mtu,
        selector: (value) => value.mtu.toString(),
        updater: (value) {
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null) {
            SphiaWidget.showDialogWithMsg(
              context: context,
              message: L10n.of(context)!.enterValidNumberMsg,
            );
            return;
          }
          notifier.updateValue('mtu', newValue);
        },
      ),
      CheckboxCard(
        title: L10n.of(context)!.endpointIndependentNat,
        selector: (value) => value.endpointIndependentNat,
        updater: (value) {
          notifier.updateValue('endpointIndependentNat', value);
        },
      ),
      ItemsCard<TunStack>(
        title: L10n.of(context)!.stack,
        items: TunStack.values,
        idxSelector: (value) => value.stack.index,
        updater: (value) {
          notifier.updateValue('stack', value.name);
        },
      ),
      CheckboxCard(
        title: L10n.of(context)!.autoRoute,
        selector: (value) => value.autoRoute,
        updater: (value) {
          notifier.updateValue('autoRoute', value);
        },
      ),
      CheckboxCard(
        title: L10n.of(context)!.strictRoute,
        selector: (value) => value.strictRoute,
        updater: (value) {
          notifier.updateValue('strictRoute', value);
        },
      ),
    ];

    return DefaultTabController(
      length: 5,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context)!.settings),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sphia'),
              Tab(text: 'Proxy'),
              Tab(text: 'Core'),
              Tab(text: 'Provider'),
              Tab(text: 'Tun'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              children: sphiaWidgets,
            ),
            ListView(
              children: proxyWidgets,
            ),
            ListView(
              children: coreWidgets,
            ),
            ListView(
              children: providerWidgets,
            ),
            ListView(
              children: tunWidgets,
            ),
          ],
        ),
      ),
    );
  }
}
