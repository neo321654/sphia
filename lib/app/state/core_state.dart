import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sphia/core/core.dart';
import 'package:sphia/core/sing/core.dart';
import 'package:sphia/core/xray/core.dart';

part 'core_state.freezed.dart';

@freezed
class CoreState with _$CoreState {
  const factory CoreState({
    @Default([]) List<Core> cores,
  }) = _CoreState;
}

extension CoreStateExt on CoreState {
  Core get proxy {
    if (cores.length == 1) {
      return cores.first;
    } else {
      return cores.firstWhere((core) => !core.isRouting);
    }
  }

  Core get routing {
    return cores.firstWhere((core) => core.isRouting);
  }

  int get customHttpPort {
    final portInDb = routing.servers.first.port;
    return portInDb & 0x1FFFF;
  }

  int get customApiPort {
    final portInDb = routing.servers.first.port;
    return (portInDb >> 17) & 0x1FFFF;
  }

  Stream<String> get logStream {
    return switch (routing) {
      SingBoxCore singBoxCore => singBoxCore.logStream,
      XrayCore xrayCore => xrayCore.logStream,
      _ => throw Exception('Unknown core type'),
    };
  }
}
