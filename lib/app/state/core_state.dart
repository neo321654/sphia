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

  Stream<String> get logStream {
    if (routing is SingBoxCore) {
      return (routing as SingBoxCore).logStream;
    } else if (routing is XrayCore) {
      return (routing as XrayCore).logStream;
    } else {
      throw Exception('Unknown core type');
    }
  }
}
