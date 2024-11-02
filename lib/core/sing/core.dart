import 'dart:convert';
import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/latency.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/config/version_config.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/core_info.dart';
import 'package:sphia/core/sing/config.dart';
import 'package:sphia/core/sing/core_info.dart';
import 'package:sphia/core/sing/generate.dart';

const cacheDbFileName = 'cache.db';

class SingBoxCore extends Core with RoutingCore, ProxyResInfoList {
  SingBoxCore(Ref ref, {List<String>? args})
      : super(
          info: const SingBoxInfo(),
          args: args ??
              [
                'run',
                '-c',
                p.join(IoHelper.tempPath, 'sing-box.json'),
                '--disable-color'
              ],
          configFileName: 'sing-box.json',
          ref: ref,
        );

  factory SingBoxCore.latencyTest(Ref ref) => SingBoxCore(
        ref,
        args: [
          'run',
          '-c',
          p.join(IoHelper.tempPath, 'latency.json'),
          '--disable-color'
        ],
      )
        ..isRouting = true
        ..configFileName = 'latency.json';

  @override
  Future<void> stop({bool checkPorts = true}) async {
    await super.stop();
    final tempPath = IoHelper.tempPath;
    if (configFileName == 'latency.json') {
      // do not delete cache file which currently used by other core
      await IoHelper.deleteFileIfExists(
        p.join(tempPath, latencyCacheDbFileName),
        'Deleting cache file: $latencyCacheDbFileName',
      );
    } else {
      await IoHelper.deleteFileIfExists(
        p.join(tempPath, cacheDbFileName),
        'Deleting cache file: $cacheDbFileName',
      );
    }
  }

  @override
  Future<void> configure() async {
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final ruleConfig = ref.read(ruleConfigNotifierProvider);
    final versionConfig = ref.read(versionConfigNotifierProvider);
    final outbounds = [
      genOutbound(server: runningServer),
    ];
    final rules =
        await ruleDao.getOrderedRulesByGroupId(ruleConfig.selectedRuleGroupId);
    late final SingConfigParameters parameters;

    // remove disabled rules
    rules.removeWhere((rule) => !rule.enabled);

    if (sphiaConfig.multiOutboundSupport) {
      final serversOnRoutingId = await getRuleOutboundTagList(rules);
      final serversOnRouting =
          await serverDao.getServerModelsByIdList(serversOnRoutingId);
      // add servers on routing to outbounds, outbound.tag is proxy-serverId
      for (final server in serversOnRouting) {
        outbounds.add(
          genOutbound(server: server, outboundTag: 'proxy-${server.id}'),
        );
      }
      servers.addAll(serversOnRouting);
    } else {
      rules.removeWhere((rule) =>
          rule.outboundTag != outboundProxyId &&
          rule.outboundTag != outboundDirectId &&
          rule.outboundTag != outboundBlockId);
    }

    final configureDns =
        sphiaConfig.enableTun || (sphiaConfig.configureDns && isRouting);

    parameters = SingConfigParameters(
      outbounds: outbounds,
      rules: rules,
      configureDns: configureDns,
      enableApi: sphiaConfig.enableStatistics && isRouting,
      coreApiPort: sphiaConfig.coreApiPort,
      enableTun: sphiaConfig.enableTun,
      addMixedInbound: true,
      sphiaConfig: sphiaConfig,
      versionConfig: versionConfig,
    );

    final jsonString = await generateConfig(parameters);
    await writeConfig(jsonString);
  }

  @override
  Future<String> generateConfig(CoreConfigParameters parameters) async {
    final paras = parameters as SingConfigParameters;
    final sphiaConfig = paras.sphiaConfig;

    final level = sphiaConfig.logLevel == CoreLogLevel.warning
        ? 'warn'
        : sphiaConfig.logLevel.name;
    final log = Log(
      disabled: level == 'none',
      level: level == 'none' ? null : level,
      output: sphiaConfig.saveCoreLog ? getLogPath() : null,
      timestamp: true,
    );

    Dns? dns;
    if (paras.configureDns) {
      dns = await genDns(
        remoteDns: sphiaConfig.remoteDns,
        directDns: sphiaConfig.directDns,
        dnsResolver: sphiaConfig.dnsResolver,
        serverAddress: runningServer.address,
        ipv4Only: !sphiaConfig.enableIpv6,
      );
    }

    final inbounds = <Inbound>[];
    if (paras.addMixedInbound) {
      inbounds.add(genMixedInbound(
        sphiaConfig.listen,
        sphiaConfig.mixedPort,
        sphiaConfig.authentication
            ? [
                User(
                  username: sphiaConfig.user,
                  password: sphiaConfig.password,
                )
              ]
            : null,
      ));
      usedPorts.add(sphiaConfig.mixedPort);
    }

    if (paras.enableTun) {
      inbounds.add(
        genTunInbound(
          inet4Address: sphiaConfig.enableIpv4 ? sphiaConfig.ipv4Address : null,
          inet6Address: sphiaConfig.enableIpv6 ? sphiaConfig.ipv6Address : null,
          mtu: sphiaConfig.mtu,
          stack: sphiaConfig.stack.name,
          autoRoute: sphiaConfig.autoRoute,
          strictRoute: sphiaConfig.strictRoute,
          sniff: sphiaConfig.enableSniffing,
          endpointIndependentNat: sphiaConfig.endpointIndependentNat,
        ),
      );
    }

    Route? route;
    if (paras.configureDns) {
      route = genRoute(
        paras.rules,
        paras.configureDns,
      );
    }

    final outbounds = paras.outbounds;

    if (paras.configureDns) {
      outbounds.add(
        const Outbound(type: 'dns', tag: 'dns-out'),
      );
    }
    outbounds.addAll([
      const Outbound(type: 'direct', tag: 'direct'),
      const Outbound(type: 'block', tag: 'block'),
    ]);

    Experimental? experimental;
    if (paras.enableApi) {
      final versionConfig = paras.versionConfig;
      final singBoxVersion = versionConfig.singBoxVersion?.replaceAll('v', '');
      if (singBoxVersion == null) {
        throw Exception('SingBox version is null');
      }
      final tempPath = IoHelper.tempPath;
      if (Version.parse(singBoxVersion) >= Version.parse('1.8.0')) {
        experimental = Experimental(
          clashApi: ClashApi(
            externalController: '127.0.0.1:${paras.coreApiPort}',
          ),
          cacheFile: CacheFile(
            enabled: true,
            path: p.join(tempPath, paras.cacheDbFileName),
          ),
        );
      } else {
        experimental = Experimental(
          clashApi: ClashApi(
            externalController: '127.0.0.1:${paras.coreApiPort}',
            storeSelected: true,
            cacheFile: p.join(tempPath, paras.cacheDbFileName),
          ),
        );
      }
      usedPorts.add(paras.coreApiPort);
    }

    final singBoxConfig = SingBoxConfig(
      log: log,
      dns: dns,
      route: route,
      inbounds: inbounds,
      outbounds: outbounds,
      experimental: experimental,
    );

    return jsonEncode(singBoxConfig.toJson());
  }
}

class SingConfigParameters extends CoreConfigParameters {
  final List<Outbound> outbounds;
  final List<Rule> rules;
  final bool configureDns;
  final bool enableApi;
  final int coreApiPort;
  final bool enableTun;
  final bool addMixedInbound;
  final SphiaConfig sphiaConfig;
  final VersionConfig versionConfig;
  final String cacheDbFileName;

  const SingConfigParameters({
    required this.outbounds,
    required this.rules,
    required this.configureDns,
    required this.enableApi,
    required this.coreApiPort,
    required this.enableTun,
    required this.addMixedInbound,
    required this.sphiaConfig,
    required this.versionConfig,
    this.cacheDbFileName = 'cache.db',
  });
}
