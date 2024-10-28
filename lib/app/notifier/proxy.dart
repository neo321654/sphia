import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/state/proxy.dart';

part 'proxy.g.dart';

@Riverpod(keepAlive: true)
class ProxyNotifier extends _$ProxyNotifier {
  @override
  ProxyState build() => const ProxyState();

  void setCoreRunning(bool coreRunning) {
    state = state.copyWith(coreRunning: coreRunning);
  }

  void setCustomConfig(bool customConfig) {
    state = state.copyWith(customConfig: customConfig);
  }

  void setSystemProxy(bool systemProxy) {
    state = state.copyWith(systemProxy: systemProxy);
  }

  void setTunMode(bool tunMode) {
    state = state.copyWith(tunMode: tunMode);
  }
}
