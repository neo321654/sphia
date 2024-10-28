import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/helper/uri/uri.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/server/server_model.dart';

part 'subscription.g.dart';

@riverpod
class SubscriptionHelper extends _$SubscriptionHelper {
  @override
  void build() {}

  Future<List<String>> _importUriFromSubscription(String subscription) async {
    try {
      final networkHelper = ref.read(networkHelperProvider.notifier);
      final response = await networkHelper.getHttpResponse(subscription);
      final responseBody =
          (await response.transform(utf8.decoder).join()).trim();
      late final String decodedContent;
      try {
        decodedContent = UriHelper.decodeBase64(responseBody);
      } on Exception catch (e) {
        logger.e('Failed to parse response: $e');
        throw Exception('Failed to parse response: $e');
      }
      final text = decodedContent.trim();
      final uris = text.split('\n');
      return uris;
    } on Exception catch (_) {
      rethrow;
    }
  }

  Future<void> updateSingleGroup({
    required int groupId,
    required String subscription,
  }) async {
    try {
      final uris = await _importUriFromSubscription(subscription);
      final oldServers = await serverDao.getServersByGroupId(groupId);
      final oldOrder = oldServers.map((e) => e.id).toList();
      final newOrder = <int>[];

      for (final uri in uris) {
        final newServer = UriHelper.parseUri(uri);
        if (newServer is ServerModel) {
          final oldIndex = oldServers.indexWhere(
            (e) =>
                e.remark == newServer.remark &&
                e.address == newServer.address &&
                e.port == newServer.port &&
                e.protocol == newServer.protocol,
          );
          if (oldIndex != -1) {
            newOrder.add(oldOrder[oldIndex]);
            oldOrder.removeAt(oldIndex);
            oldServers.removeAt(oldIndex);
          } else {
            newOrder.add(
                await serverDao.insertServer(newServer..groupId = groupId));
          }
        }
      }
      for (final oldServer in oldServers) {
        await serverDao.deleteServer(oldServer.id);
      }
      await serverDao.updateServersOrder(groupId, newOrder);
    } on Exception catch (_) {
      rethrow;
    }
  }
}
