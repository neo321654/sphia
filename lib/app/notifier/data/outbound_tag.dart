import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/notifier/data/server.dart';

part 'outbound_tag.g.dart';

@Riverpod(keepAlive: true)
class OutboundTagNotifier extends _$OutboundTagNotifier {
  @override
  Map<int, String> build() {
    final servers = ref.read(serverNotifierProvider).valueOrNull ?? [];
    final map = <int, String>{
      outboundProxyId: 'proxy',
      outboundDirectId: 'direct',
      outboundBlockId: 'block'
    };
    return map..addEntries(servers.map((tag) => MapEntry(tag.id, tag.remark)));
  }

  void addOutboundTag(int id, String name) {
    state = {...state, id: name};
  }

  void addOutboundTags(Map<int, String> tags) {
    state = {...state, ...tags};
  }

  void removeOutboundTag(int id) {
    state = state..remove(id);
  }

  void updateOutboundTag(int id, String name) {
    state = state..update(id, (value) => name);
  }

  void setOutboundTags(Map<int, String> tags) {
    state = {...tags};
  }

  void clearOutboundTags() {
    state = {};
  }
}
