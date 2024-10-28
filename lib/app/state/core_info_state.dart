import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sphia/core/core_info.dart';

part 'core_info_state.freezed.dart';

@freezed
class CoreInfoState with _$CoreInfoState {
  const factory CoreInfoState({
    required ProxyResInfo info,
    String? latestVersion,
    required bool isUpdating,
  }) = _CoreInfo;
}
