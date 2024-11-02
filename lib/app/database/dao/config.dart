import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:sphia/app/config/rule.dart';
import 'package:sphia/app/config/server.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/database/database.dart';

const sphiaConfigId = 1;
const serverConfigId = 2;
const ruleConfigId = 3;
const versionConfigId = 4;

class SphiaConfigDao {
  final Database _db;

  const SphiaConfigDao(this._db);

  Future<String> getConfigJson() async {
    final sphiaConfig = await (_db.select(_db.config)
          ..where((tbl) => tbl.id.equals(sphiaConfigId)))
        .getSingleOrNull();
    if (sphiaConfig == null) {
      await (_db.into(_db.config).insert(
            ConfigCompanion.insert(
              id: const Value(sphiaConfigId),
              config: const JsonEncoder().convert(const SphiaConfig()),
            ),
          ));
      return const JsonEncoder().convert(const SphiaConfig().toJson());
    }
    return sphiaConfig.config;
  }

  Future<SphiaConfig> loadConfig() async {
    const defaultConfig = SphiaConfig();
    try {
      final json = await getConfigJson();
      var data = jsonDecode(json);
      final defaultData = defaultConfig.toJson();
      defaultData.forEach((key, value) {
        if (data[key] == null) {
          data[key] = value;
        }
      });
      late final SphiaConfig sphiaConfig;
      try {
        sphiaConfig = SphiaConfig.fromJson(data);
      } catch (e) {
        sphiaConfig = defaultConfig;
        await (_db.update(_db.config)
              ..where((tbl) => tbl.id.equals(sphiaConfigId)))
            .write(ConfigCompanion(config: Value(jsonEncode(sphiaConfig))));
      }
      return sphiaConfig;
    } catch (_) {
      rethrow;
    }
  }

  void saveConfig(SphiaConfig sphiaConfig) async {
    final jsonString = jsonEncode(sphiaConfig.toJson());
    try {
      await (_db.update(_db.config)
            ..where((tbl) => tbl.id.equals(sphiaConfigId)))
          .write(ConfigCompanion(config: Value(jsonString)));
    } catch (e) {
      rethrow;
    }
  }
}

class ServerConfigDao {
  final Database _db;

  const ServerConfigDao(this._db);

  Future<String> getConfigJson() async {
    final serverConfig = await (_db.select(_db.config)
          ..where((tbl) => tbl.id.equals(serverConfigId)))
        .getSingleOrNull();
    if (serverConfig == null) {
      await (_db.into(_db.config).insert(
            ConfigCompanion.insert(
              id: const Value(serverConfigId),
              config: const JsonEncoder().convert(const ServerConfig()),
            ),
          ));
      return const JsonEncoder().convert(const ServerConfig().toJson());
    }
    return serverConfig.config;
  }

  Future<ServerConfig> loadConfig() async {
    const defaultConfig = ServerConfig();
    try {
      final json = await getConfigJson();
      var data = jsonDecode(json);
      final defaultData = defaultConfig.toJson();
      defaultData.forEach((key, value) {
        if (data[key] == null) {
          data[key] = value;
        }
      });
      return ServerConfig.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }

  void saveConfig(ServerConfig serverConfig) async {
    final jsonString = jsonEncode(serverConfig.toJson());
    try {
      await (_db.update(_db.config)
            ..where((tbl) => tbl.id.equals(serverConfigId)))
          .write(ConfigCompanion(config: Value(jsonString)));
    } catch (e) {
      rethrow;
    }
  }
}

class RuleConfigDao {
  final Database _db;

  const RuleConfigDao(this._db);

  Future<String> getConfigJson() async {
    final ruleConfig = await (_db.select(_db.config)
          ..where((tbl) => tbl.id.equals(ruleConfigId)))
        .getSingleOrNull();
    if (ruleConfig == null) {
      await (_db.into(_db.config).insert(
            ConfigCompanion.insert(
              id: const Value(ruleConfigId),
              config: const JsonEncoder().convert(const RuleConfig()),
            ),
          ));
      return const JsonEncoder().convert(const RuleConfig().toJson());
    }
    return ruleConfig.config;
  }

  Future<RuleConfig> loadConfig() async {
    const defaultConfig = RuleConfig();
    try {
      final json = await getConfigJson();
      var data = jsonDecode(json);
      final defaultData = defaultConfig.toJson();
      defaultData.forEach((key, value) {
        if (data[key] == null) {
          data[key] = value;
        }
      });
      return RuleConfig.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }

  void saveConfig(RuleConfig ruleConfig) async {
    final jsonString = jsonEncode(ruleConfig.toJson());
    try {
      await (_db.update(_db.config)
            ..where((tbl) => tbl.id.equals(ruleConfigId)))
          .write(ConfigCompanion(config: Value(jsonString)));
    } catch (e) {
      rethrow;
    }
  }
}

class VersionConfigDao {
  final Database _db;

  const VersionConfigDao(this._db);

  Future<String> getConfigJson() async {
    final versionConfig = await (_db.select(_db.config)
          ..where((tbl) => tbl.id.equals(versionConfigId)))
        .getSingleOrNull();
    if (versionConfig == null) {
      await (_db.into(_db.config).insert(
            ConfigCompanion.insert(
              id: const Value(versionConfigId),
              config: const JsonEncoder().convert(const VersionConfig()),
            ),
          ));
      return const JsonEncoder().convert(const VersionConfig().toJson());
    }
    return versionConfig.config;
  }

  Future<VersionConfig> loadConfig() async {
    try {
      final json = await getConfigJson();
      var data = jsonDecode(json);
      return VersionConfig.fromJson(data);
    } catch (_) {
      rethrow;
    }
  }

  void saveConfig(VersionConfig versionConfig) async {
    final jsonString = jsonEncode(versionConfig.toJson());
    try {
      await (_db.update(_db.config)
            ..where((tbl) => tbl.id.equals(versionConfigId)))
          .write(ConfigCompanion(config: Value(jsonString)));
    } catch (e) {
      rethrow;
    }
  }
}

Future<List<T>> getOrderedList<T>(Future<List<int>> Function() getOrder,
    Future<List<T>> Function() getGroups, int Function(T) getId) async {
  final order = await getOrder();
  final groups = await getGroups();
  final groupMap = {for (var group in groups) getId(group): group};

  return order
      .map((id) => groupMap[id])
      .where((item) => item != null)
      .cast<T>()
      .toList();
}
