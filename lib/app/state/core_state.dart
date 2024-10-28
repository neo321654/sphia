import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/sing/core.dart';
import 'package:sphia/core/xray/core.dart';
import 'package:sphia/server/server_model.dart';

part 'core_state.freezed.dart';

@freezed
class CoreState with _$CoreState {
  const factory CoreState({
    @Default([]) List<Core> cores,
  }) = _CoreState;
}

extension CoreStateExt on CoreState {
  String? get runningServerRemark {
    if (cores.isEmpty) {
      return null;
    }
    return cores.first.runningServer.remark;
  }

  Core get proxy {
    if (cores.length == 1) {
      return cores.first;
    } else {
      return cores.firstWhere((core) => !core.isRouting);
    }
  }

  RoutingCore get _routing {
    return cores.firstWhere((core) => core.isRouting) as RoutingCore;
  }

  List<ServerModel> get routingServers {
    return _routing.servers;
  }

  RoutingProvider get routingProvider {
    return switch (_routing) {
      SingBoxCore _ => RoutingProvider.sing,
      XrayCore _ => RoutingProvider.xray,
      _ => throw Exception('Unknown core type'),
    };
  }

  int get customHttpPort {
    final portInDb = _routing.runningServer.port;
    return portInDb & 0x1FFFF;
  }

  int get customApiPort {
    final portInDb = _routing.runningServer.port;
    return (portInDb >> 17) & 0x1FFFF;
  }

  List<String> get routingPreLogList {
    return (_routing).preLogList;
  }

  Stream<String> get logStream {
    return switch (_routing) {
      SingBoxCore singBoxCore => singBoxCore.logStream,
      XrayCore xrayCore => xrayCore.logStream,
      _ => throw Exception('Unknown core type'),
    };
  }
}
