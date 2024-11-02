import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/helper/proxy.dart';
import 'package:sphia/app/helper/tray.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/notifier/traffic.dart';
import 'package:sphia/app/provider/core.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/core_info.dart';
import 'package:sphia/server/custom_config/server.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/xray/server.dart';
import 'package:sphia/view/dialog/custom_config.dart';

part 'core_state.g.dart';

@Riverpod(keepAlive: true)
class CoreStateNotifier extends _$CoreStateNotifier {
  @override
  Future<CoreState> build() async => const CoreState(cores: []);

  LogNotifier get logNotifier => ref.read(logNotifierProvider.notifier);

  Future<void> toggleCores(ServerModel selectedServer) async {
    try {
      final currentState = state.valueOrNull;
      if (currentState == null) {
        return;
      }
      if (currentState.cores.isNotEmpty) {
        final runningServer = await getRunningServerModel();
        if (selectedServer == runningServer) {
          await stopCores();
        } else {
          await stopCores(keepSysProxy: true);
          // Keep the changes to the system proxy if the user changes it during use.
          await startCores(selectedServer);
        }
      } else {
        await startCores(selectedServer);
      }
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> startCores(ServerModel server) async {
    final preState = state.valueOrNull;
    if (preState == null) {
      return;
    }

    state = const AsyncValue.loading();
    final cores = await _addCores(server);
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    late final ProxyRes routingProvider;

    final isCustom = server.protocol == Protocol.custom;

    try {
      logNotifier.info('Starting cores');
      if (isCustom) {
        cores.first.servers.add(server);
        final jsonString = (server as CustomConfigServer).configString;
        await cores.first.writeConfig(jsonString);
        await cores.first.start(manual: true);
        routingProvider = cores.first.name;
      } else {
        if (cores.length == 1) {
          // Only routing core
          cores.first.servers.add(server);
          await cores.first.start();
          routingProvider = cores.first.name;
        } else {
          for (int i = 0; i < cores.length; i++) {
            if (cores[i].isRouting) {
              await cores[i].start();
              routingProvider = cores[i].name;
            } else {
              cores[i].servers.add(server);
              await cores[i].start();
            }
          }
        }
      }
    } on Exception catch (_) {
      for (var core in cores) {
        await core.stop();
      }
      state = const AsyncValue.data(CoreState(cores: []));
      rethrow;
    }
    state = AsyncValue.data(CoreState(cores: cores));

    late final int httpPort;
    if (isCustom) {
      httpPort = state.value!.customHttpPort;
      if (httpPort == portUnset) {
        final proxyNotifier = ref.read(proxyNotifierProvider.notifier);
        proxyNotifier
          ..setCoreRunning(true)
          ..setCustomConfig(true);
        await TrayHelper.setIcon(coreRunning: true);
        await TrayHelper.setToolTip(server.remark);
        return;
      }
    } else {
      if (routingProvider == ProxyRes.sing) {
        httpPort = sphiaConfig.mixedPort;
      } else {
        httpPort = sphiaConfig.httpPort;
      }
    }
    final proxyNotifier = ref.read(proxyNotifierProvider.notifier);
    final localServerAvailable = await NetworkHelper.isServerAvailable(
      httpPort,
      maxRetry: 10,
    );
    if (!localServerAvailable) {
      // stop cores
      await stopCores();
      logNotifier.error('Local port $httpPort is not available');
      throw Exception('Local port $httpPort is not available');
    }

    final isTun = !isCustom && sphiaConfig.enableTun;

    if (isTun) {
      proxyNotifier.setTunMode(true);
    }

    proxyNotifier
      ..setCoreRunning(true)
      ..setCustomConfig(isCustom);
    await TrayHelper.setIcon(coreRunning: true);
    await TrayHelper.setToolTip(server.remark);

    final enableStatistics = isCustom || sphiaConfig.enableStatistics;
    // try to check statistics availability when using custom config
    if (enableStatistics) {
      final trafficNotifier = ref.read(trafficNotifierProvider.notifier);
      await trafficNotifier.start();
    }

    final proxyHelper = ref.read(proxyHelperProvider.notifier);
    if (isTun) {
      // do not enable system proxy in tun mode
      await proxyHelper.disableSystemProxy();
      proxyNotifier.setSystemProxy(false);
    } else {
      proxyNotifier.setTunMode(false);
      if (sphiaConfig.autoConfigureSystemProxy) {
        await proxyHelper.enableSystemProxy();
        proxyNotifier.setSystemProxy(true);
      }
    }
  }

  Future<List<Core>> _addCores(ServerModel server) async {
    if (server.protocol == Protocol.custom) {
      server = server as CustomConfigServer;
      final coreProviderIdx = server.protocolProvider;
      if (coreProviderIdx == null) {
        logNotifier.error('Custom server must have a protocol provider');
        throw Exception('Custom server must have a protocol provider');
      }
      final coreProvider = CustomServerProvider.values[coreProviderIdx];
      final core = switch (coreProvider) {
        CustomServerProvider.sing => ref.read(singBoxCoreProvider)
          ..configFileName = 'sing-box.${server.configFormat}',
        CustomServerProvider.xray => ref.read(xrayCoreProvider)
          ..configFileName = 'xray.${server.configFormat}',
        CustomServerProvider.hysteria => ref.read(hysteriaCoreProvider)
          ..configFileName = 'hysteria.${server.configFormat}',
      };
      return [core..isRouting = true];
    }

    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final protocol = server.protocol;
    final routingProviderIdx =
        server.routingProvider ?? sphiaConfig.routingProvider.index;
    final protocolProviderIdx = server.protocolProvider;
    ServerModel? additionalServer;
    final cores = <Core>[];

    if (sphiaConfig.enableTun) {
      cores.add(ref.read(singBoxCoreProvider)..isRouting = true);
    } else if (sphiaConfig.multiOutboundSupport) {
      if (sphiaConfig.routingProvider == RoutingProvider.sing) {
        cores.add(ref.read(singBoxCoreProvider)..isRouting = true);
      } else {
        cores.add(ref.read(xrayCoreProvider)..isRouting = true);
      }
    } else {
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
            ShadowsocksProvider.ssrust => ref.read(shadowsocksRustCoreProvider),
            _ => null
          },
        Protocol.trojan => TrojanProvider.values[
                    protocolProviderIdx ?? sphiaConfig.trojanProvider.index] ==
                TrojanProvider.xray
            ? ref.read(xrayCoreProvider)
            : ref.read(singBoxCoreProvider),
        Protocol.hysteria => HysteriaProvider.values[protocolProviderIdx ??
                    sphiaConfig.hysteriaProvider.index] ==
                HysteriaProvider.sing
            ? ref.read(singBoxCoreProvider)
            : ref.read(hysteriaCoreProvider),
        _ => null,
      };
      if (core == null) {
        logNotifier.error('Unsupported protocol: $protocol');
        throw Exception('Unsupported protocol: $protocol');
      }
      final routingProvider = _getProviderCore(routingProviderIdx).toString();
      // if routing provider is different from the selected server's provider
      if (routingProvider != core.name.toString()) {
        cores.add(core);
        late final int additionalServerPort;
        // determine the additional server port
        // if protocol provider is sing-box or xray-core
        // use the socks port or mixed port as the additional server port
        // otherwise use the additional socks port
        if (routingProviderIdx == RoutingProvider.sing.index) {
          cores.add(ref.read(singBoxCoreProvider)..isRouting = true);
          if (core.name == ProxyRes.xray) {
            additionalServerPort = sphiaConfig.socksPort;
          } else {
            additionalServerPort = sphiaConfig.additionalSocksPort;
          }
        } else if (routingProviderIdx == RoutingProvider.xray.index) {
          cores.add(ref.read(xrayCoreProvider)..isRouting = true);
          if (core.name == ProxyRes.sing) {
            additionalServerPort = sphiaConfig.mixedPort;
          } else {
            additionalServerPort = sphiaConfig.additionalSocksPort;
          }
        }
        additionalServer = XrayServer.socksDefaults()
          ..remark = 'Additional Socks Server'
          ..address = sphiaConfig.listen
          ..port = additionalServerPort;
      } else {
        // mark the first core as routing
        cores.add(core..isRouting = true);
      }
    }
    if (additionalServer != null) {
      // add additional server to the routing core
      final index = cores.indexWhere((core) => core.isRouting);
      if (index != -1) {
        cores[index].servers.add(additionalServer);
      }
    }
    return cores;
  }

  Future<void> stopCores({bool keepSysProxy = false}) async {
    final preState = state.valueOrNull;
    if (preState == null) {
      return;
    }
    if (preState.cores.isNotEmpty) {
      state = const AsyncValue.loading();
      final proxyNotifier = ref.read(proxyNotifierProvider.notifier);
      final proxyHelper = ref.read(proxyHelperProvider.notifier);
      if (!keepSysProxy) {
        if (proxyHelper.isSystemProxyEnabled()) {
          // automatically disable system proxy
          proxyHelper.disableSystemProxy();
          proxyNotifier.setSystemProxy(false);
        }
      }
      // wait for collecting traffic data
      await Future.delayed(const Duration(milliseconds: 200));
      final trafficNotifier = ref.read(trafficNotifierProvider.notifier);
      await trafficNotifier.stop();
      final notifier = ref.read(logNotifierProvider.notifier);
      notifier.info('Stopping cores');
      final isCustom =
          ref.read(proxyNotifierProvider.select((value) => value.customConfig));
      if (isCustom) {
        proxyNotifier
          ..setCoreRunning(false)
          ..setCustomConfig(false);
        // only one core
        await preState.cores.first.stop(checkPorts: false);
      } else {
        proxyNotifier.setCoreRunning(false);
        for (var core in preState.cores) {
          await core.stop();
        }
      }
      await TrayHelper.setIcon(coreRunning: false);
      await TrayHelper.setToolTip('Sphia');
      proxyNotifier.setTunMode(false);
      state = const AsyncValue.data(CoreState(cores: []));
    }
  }

  // switch to another rule group will restart cores
  Future<void> restartCores() async {
    final currState = state.valueOrNull;
    if (currState == null) {
      return;
    }
    if (currState.cores.isNotEmpty) {
      final runningServer = await getRunningServerModel();
      try {
        await stopCores(keepSysProxy: true);
        await startCores(runningServer);
      } on Exception catch (_) {
        rethrow;
      }
    }
  }

  RoutingProvider _getProviderCore(int index) {
    return RoutingProvider.values[index];
  }

  int _getRunningServerId() {
    final currentState = state.valueOrNull;
    if (currentState == null) {
      logNotifier.error('No proxy state');
      throw Exception('No proxy state');
    }
    if (currentState.cores.isEmpty) {
      logNotifier.error('No running server');
      throw Exception('No running server');
    }
    // only single server is supported
    return currentState.proxy.runningServer.id;
  }

  Future<ServerModel> getRunningServerModel() async {
    final runningServerId = _getRunningServerId();
    // do not get server from coreProvider, because it may has been modified
    final runningServerModel =
        await serverDao.getServerModelById(runningServerId);
    if (runningServerModel == null) {
      logNotifier.error('Failed to get running server');
      throw Exception('Failed to get running server');
    }
    return runningServerModel;
  }
}
