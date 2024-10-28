import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/notifier/config/server_config.dart';
import 'package:sphia/app/notifier/data/outbound_tag.dart';
import 'package:sphia/server/server_model.dart';

part 'server.g.dart';

@Riverpod(keepAlive: true)
class ServerNotifier extends _$ServerNotifier {
  @override
  Future<List<ServerModel>> build() async {
    final selectedServerGroupId = ref.watch(serverConfigNotifierProvider
        .select((value) => value.selectedServerGroupId));
    return await serverDao
        .getOrderedServerModelsByGroupId(selectedServerGroupId);
  }

  void addServer(ServerModel server) {
    state.whenData((s) {
      state = AsyncValue.data([...s, server]);
      final notifier = ref.read(outboundTagNotifierProvider.notifier);
      notifier.addOutboundTag(server.id, server.remark);
    });
  }

  void addServers(List<ServerModel> servers) {
    state.whenData((s) {
      state = AsyncValue.data([...s, ...servers]);
      final notifier = ref.read(outboundTagNotifierProvider.notifier);
      notifier.addOutboundTags(
          Map.fromEntries(servers.map((s) => MapEntry(s.id, s.remark))));
    });
  }

  void removeServer(ServerModel server) {
    state.whenData((s) {
      state = AsyncValue.data(s.where((item) => item.id != server.id).toList());
      final notifier = ref.read(outboundTagNotifierProvider.notifier);
      notifier.removeOutboundTag(server.id);
    });
  }

  void updateServerData(ServerModel server) {
    state.whenData((s) {
      state = AsyncValue.data(s.map((r) {
        if (r.id == server.id) {
          return server;
        }
        return r;
      }).toList());
      final notifier = ref.read(outboundTagNotifierProvider.notifier);
      notifier.updateOutboundTag(server.id, server.remark);
    });
  }

  void updateServerState(ServerModel server) {
    state.whenData((s) {
      state = AsyncValue.data(s.map((r) {
        if (r.id == server.id) {
          return server;
        }
        return r;
      }).toList());
    });
  }

  void setServers(List<ServerModel> servers) {
    state = AsyncValue.data([...servers]);
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.setOutboundTags(
        Map.fromEntries(servers.map((s) => MapEntry(s.id, s.remark))));
  }

  void clearServers() {
    state = const AsyncValue.data([]);
    final notifier = ref.read(outboundTagNotifierProvider.notifier);
    notifier.clearOutboundTags();
  }
}
