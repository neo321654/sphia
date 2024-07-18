import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/notifier/data/outbound_tag.dart';
import 'package:sphia/app/provider/data.dart';
import 'package:sphia/server/server_model.dart';

part 'server.g.dart';

@Riverpod(keepAlive: true)
class ServerNotifier extends _$ServerNotifier {
  @override
  List<ServerModel> build() {
    final servers = ref.read(serversProvider);
    return servers;
  }

  void addServer(ServerModel server) {
    state = [...state, server];
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.addOutboundTag(server.id, server.remark);
  }

  void addServers(List<ServerModel> servers) {
    state = [...state, ...servers];
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.addOutboundTags(
        Map.fromEntries(servers.map((s) => MapEntry(s.id, s.remark))));
  }

  void removeServer(ServerModel server) {
    state = state.where((s) => s.id != server.id).toList();
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.removeOutboundTag(server.id);
  }

  void updateServer(ServerModel server, {bool shouldUpdateLite = true}) {
    state = state.map((s) {
      if (s.id == server.id) {
        return server;
      }
      return s;
    }).toList();
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.updateOutboundTag(server.id, server.remark);
  }

  void setServers(List<ServerModel> servers) {
    state = [...servers];
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.setOutboundTags(
        Map.fromEntries(servers.map((s) => MapEntry(s.id, s.remark))));
  }

  void clearServers() {
    state = [];
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.clearOutboundTags();
  }
}
