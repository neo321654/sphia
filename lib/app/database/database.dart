import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/app/database/dao/config.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/database/dao/rule_group.dart';
import 'package:sphia/app/database/dao/server.dart';
import 'package:sphia/app/database/dao/server_group.dart';
import 'package:sphia/app/database/migration.dart';
import 'package:sphia/app/database/tables.dart';
import 'package:sphia/server/server_model.dart';

part 'database.g.dart';

final sphiaConfigDao = SphiaConfigDao(SphiaDatabase.db);
final serverConfigDao = ServerConfigDao(SphiaDatabase.db);
final ruleConfigDao = RuleConfigDao(SphiaDatabase.db);
final versionConfigDao = VersionConfigDao(SphiaDatabase.db);
final serverGroupDao = ServerGroupDao(SphiaDatabase.db);
final ruleGroupDao = RuleGroupDao(SphiaDatabase.db);
final serverDao = ServerDao(SphiaDatabase.db);
final ruleDao = RuleDao(SphiaDatabase.db);

class SphiaDatabase {
  static late final Database _database;

  static Database get db => _database;

  static Future<void> init(String configPath) async {
    _database = Database(configPath);
  }

  static Future<void> enableForeignKeys() async {
    await _database.customStatement('PRAGMA foreign_keys = ON');
  }

  static Future<void> close() async {
    await _database.close();
  }

  static Future<void> backupDatabase(String configPath) async {
    // close database before backup
    await _database.close();
    final file = File(p.join(configPath, 'sphia.db'));
    if (!await file.exists()) {
      return;
    }
    final backupFile = File(p.join(configPath, 'sphia.db.bak'));
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    await file.rename(backupFile.path);
  }
}

@DriftDatabase(tables: [
  Config,
  ServerGroups,
  Servers,
  RuleGroups,
  Rules,
  GroupsOrder,
  ServersOrder,
  RulesOrder,
])
class Database extends _$Database {
  Database(String configPath) : super(_openDatabase(configPath));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 3) {
          await Migration.from2To3(migrator, servers, rules);
        }
        if (from < 4) {
          await Migration.from3To4(
              migrator, servers, rules, serversOrder, rulesOrder);
        }
      },
    );
  }
}

QueryExecutor _openDatabase(String configPath) {
  return LazyDatabase(() async {
    final file = File(p.join(configPath, 'sphia.db'));
    if (!await file.exists()) {
      final blob = await rootBundle.load('assets/sphia.db');
      final buffer = blob.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    }
    return NativeDatabase.createInBackground(file);
  });
}
