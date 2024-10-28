import 'package:freezed_annotation/freezed_annotation.dart';

part 'proxy.freezed.dart';

@freezed
class ProxyState with _$ProxyState {
  const factory ProxyState({
    @Default(false) bool coreRunning,
    @Default(false) bool systemProxy,
    @Default(false) bool tunMode,
    @Default(false) bool customConfig,
  }) = _proxyState;
}
