import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/core/core_info.dart';
import 'package:sphia/server/server_model.dart';

abstract class Core with SystemHelper {
  final ProxyResInfo info;
  final List<String> args;
  String? configFileName;
  bool isRouting = false;
  final Ref ref;
  Process? _process;
  final List<int> usedPorts = [];
  final List<ServerModel> servers = [];

  ServerModel get runningServer => servers.first;

  String get _configFilePath => p.join(IoHelper.tempPath, configFileName!);

  ProxyRes get name => info.name;

  Core({
    required this.info,
    required this.args,
    this.configFileName,
    required this.ref,
  });

  Future<void> start({bool manual = false}) async {
    if (!await info.exists()) {
      logger.e('Core $name does not exist');
      throw Exception('Core $name does not exist');
    }

    if (!manual) {
      await configure();
    }

    logger.i('Starting core: $name');
    try {
      _process = await _runCore();
    } on ProcessException catch (e) {
      logger.e('Failed to start $name: ${e.message}');
      throw Exception('Failed to start $name: ${e.message}');
    }

    if (_process == null) {
      logger.e('Core Process is null');
      throw Exception('Core Process is null');
    }
  }

  Future<Process> _runCore() async {
    final binPath = IoHelper.binPath;
    return Process.start(
      p.join(binPath, info.binFileName),
      args,
    );
  }

  Future<void> stop({bool checkPorts = true}) async {
    if (_process == null) {
      logger.w('Core process is null');
      return;
    }
    logger.i('Stopping core: $name');
    _process!.kill();
    final pid = _process!.pid;
    _process = null;
    // check if port is still in use
    await Future.delayed(const Duration(milliseconds: 100));
    if (checkPorts && await _isRunning(usedPorts)) {
      logger.w('Detected core $name is still running, killing process: $pid');
      await killProcess(pid);
    }

    if (configFileName != null) {
      await IoHelper.deleteFileIfExists(
        _configFilePath,
        'Deleting config file: $configFileName',
      );
    }
  }

  Future<bool> _isRunning(List<int> ports) async {
    for (var port in ports) {
      if (await NetworkHelper.isLocalPortInUse(port)) {
        return true;
      }
    }
    return false;
  }

  Future<void> configure();

  Future<String> generateConfig(CoreConfigParameters parameters);

  Future<void> writeConfig(String configString) async {
    if (configFileName == null) {
      return;
    }
    await IoHelper.deleteFileIfExists(p.join(_configFilePath, configFileName!),
        'Deleting config file: $configFileName');
    logger.i('Writing config file: $configFileName');
    final file = File(_configFilePath);
    await file.writeAsString(configString);
  }
}

abstract class CoreConfigParameters {
  const CoreConfigParameters();
}

mixin RoutingCore on Core {
  StreamSubscription? _logSubscription;
  final _logStreamController = StreamController<String>.broadcast();
  bool _isPreLog = true;
  final List<String> preLogList = [];

  Stream<String> get logStream => _logStreamController.stream;

  void listenToProcessStream(Stream<List<int>> stream) {
    _logSubscription = stream.transform(utf8.decoder).listen((data) {
      if (data.trim().isNotEmpty) {
        _logStreamController.add(data);
        if (_isPreLog) {
          preLogList.add(data);
        }
      }
    });
  }

  @override
  Future<void> start({bool manual = false}) async {
    await super.start(manual: manual);

    listenToProcessStream(_process!.stdout);
    listenToProcessStream(_process!.stderr);

    try {
      if (await _process?.exitCode.timeout(const Duration(milliseconds: 500)) !=
          0) {
        throw Exception('\n${preLogList.join('\n')}');
      }
    } on TimeoutException catch (_) {
      _isPreLog = false;
    }
  }

  @override
  Future<void> stop({bool checkPorts = true}) async {
    await super.stop(checkPorts: checkPorts);
    await _logSubscription?.cancel();
    if (!_logStreamController.isClosed) {
      await _logStreamController.close();
    }
    // preLogList.clear();
  }

  Future<List<int>> getRuleOutboundTagList(List<Rule> rules) async {
    final outboundTags = <int>[];
    for (final rule in rules) {
      if (rule.outboundTag != outboundProxyId &&
          rule.outboundTag != outboundDirectId &&
          rule.outboundTag != outboundBlockId) {
        outboundTags.add(rule.outboundTag);
      }
    }
    return outboundTags;
  }

  String determineOutboundTag(int outboundTag) {
    if (outboundTag == outboundProxyId) {
      return 'proxy';
    } else if (outboundTag == outboundDirectId) {
      return 'direct';
    } else if (outboundTag == outboundBlockId) {
      return 'block';
    } else {
      return 'proxy-$outboundTag';
    }
  }
}

mixin ProxyCore on Core {}
