import 'dart:convert';
import 'dart:core';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/xray/config.dart';
import 'package:sphia/core/xray/core_info.dart';
import 'package:sphia/core/xray/generate.dart';

class XrayCore extends Core with RoutingCore {
  XrayCore(Ref ref)
      : super(
          info: const XrayInfo(),
          args: ['run', '-c', p.join(IoHelper.tempPath, 'xray.json')],
          configFileName: 'xray.json',
          ref: ref,
        );

  @override
  Future<void> configure() async {
    final sphiaConfig = ref.read(sphiaConfigNotifierProvider);
    final ruleConfig = ref.read(ruleConfigNotifierProvider);
    final userAgent = sphiaConfig.getUserAgent();
    final outbounds = [
      genOutbound(server: runningServer, userAgent: userAgent),
    ];
    final rules =
        await ruleDao.getOrderedRulesByGroupId(ruleConfig.selectedRuleGroupId);
    late final XrayConfigParameters parameters;

    rules.removeWhere((rule) => !rule.enabled);

    if (sphiaConfig.multiOutboundSupport) {
      final serversOnRoutingId = await getRuleOutboundTagList(rules);
      final serversOnRouting =
          await serverDao.getServerModelsByIdList(serversOnRoutingId);
      for (final server in serversOnRouting) {
        outbounds.add(
          genOutbound(
            server: server,
            userAgent: userAgent,
            outboundTag: 'proxy-${server.id}',
          ),
        );
      }
      servers.addAll(serversOnRouting);
    } else {
      rules.removeWhere((rule) =>
          rule.outboundTag != outboundProxyId &&
          rule.outboundTag != outboundDirectId &&
          rule.outboundTag != outboundBlockId);
    }

    final configureDns = sphiaConfig.configureDns && isRouting;
    final enableApi = sphiaConfig.enableStatistics && isRouting;
    parameters = XrayConfigParameters(
      outbounds: outbounds,
      rules: rules,
      configureDns: configureDns,
      enableApi: enableApi,
      sphiaConfig: sphiaConfig,
    );

    final jsonString = await generateConfig(parameters);
    await writeConfig(jsonString);
  }

  @override
  Future<String> generateConfig(CoreConfigParameters parameters) async {
    final paras = parameters as XrayConfigParameters;
    final sphiaConfig = paras.sphiaConfig;
    final log = Log(
      access: sphiaConfig.saveCoreLog ? SphiaLog.getLogPath(name) : null,
      loglevel: sphiaConfig.logLevel.name,
    );

    Dns? dns;
    if (paras.configureDns) {
      dns = genDns(sphiaConfig.remoteDns, sphiaConfig.directDns);
    }

    final inbounds = [
      genInbound(
        protocol: 'socks',
        port: sphiaConfig.socksPort,
        listen: sphiaConfig.listen,
        enableSniffing: sphiaConfig.enableSniffing,
        isAuth: sphiaConfig.authentication,
        user: sphiaConfig.user,
        pass: sphiaConfig.password,
        enableUdp: sphiaConfig.enableUdp,
      ),
      genInbound(
        protocol: 'http',
        port: sphiaConfig.httpPort,
        listen: sphiaConfig.listen,
        enableSniffing: sphiaConfig.enableSniffing,
        isAuth: sphiaConfig.authentication,
        user: sphiaConfig.user,
        pass: sphiaConfig.password,
        enableUdp: sphiaConfig.enableUdp,
      ),
    ];
    usedPorts.addAll([sphiaConfig.socksPort, sphiaConfig.httpPort]);

    Routing? routing;
    if (isRouting) {
      routing = genRouting(
        domainStrategy: sphiaConfig.domainStrategy.name,
        domainMatcher: sphiaConfig.domainMatcher.name,
        rules: paras.rules,
        enableApi: sphiaConfig.enableStatistics,
      );
    }

    final outbounds = paras.outbounds;

    outbounds.addAll([
      const Outbound(tag: 'direct', protocol: 'freedom'),
      const Outbound(tag: 'block', protocol: 'blackhole'),
    ]);

    Api? api;
    Policy? policy;
    Stats? stats;
    if (paras.enableApi) {
      api = const Api(
        tag: 'api',
        services: ['StatsService'],
      );
      policy = const Policy(
        system: System(
          statsOutboundDownlink: true,
          statsOutboundUplink: true,
        ),
      );
      stats = const Stats();
      inbounds.add(genDokodemoInbound(sphiaConfig.coreApiPort));
      usedPorts.add(sphiaConfig.coreApiPort);
    }

    final xrayConfig = XrayConfig(
      log: log,
      dns: dns,
      inbounds: inbounds,
      outbounds: outbounds,
      routing: routing,
      api: api,
      policy: policy,
      stats: stats,
    );

    return jsonEncode(xrayConfig.toJson());
  }
}

class XrayConfigParameters extends CoreConfigParameters {
  final List<Outbound> outbounds;
  final List<Rule> rules;
  final bool configureDns;
  final bool enableApi;
  final SphiaConfig sphiaConfig;

  const XrayConfigParameters({
    required this.outbounds,
    required this.rules,
    required this.configureDns,
    required this.enableApi,
    required this.sphiaConfig,
  });
}
