import 'package:drift/drift.dart';
import 'package:sphia/server/server_model.dart';

class Config extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get config => text()();
}

class ServerGroups extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get subscription => text()();
}

class Servers extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(ServerGroups, #id, onDelete: KeyAction.cascade)();

  TextColumn get protocol => textEnum<Protocol>()();

  TextColumn get remark => text()();

  TextColumn get address => text()();

  IntColumn get port => integer()();

  IntColumn get uplink => integer().nullable()();

  IntColumn get downlink => integer().nullable()();

  IntColumn get routingProvider => integer().nullable()();

  IntColumn get protocolProvider => integer().nullable()();

  TextColumn get authPayload => text()();

  IntColumn get alterId => integer().nullable()();

  TextColumn get encryption => text().nullable()();

  TextColumn get flow => text().nullable()();

  TextColumn get transport => text().nullable()();

  TextColumn get host => text().nullable()();

  TextColumn get path => text().nullable()();

  TextColumn get grpcMode => text().nullable()();

  TextColumn get serviceName => text().nullable()();

  TextColumn get tls => text().nullable()();

  TextColumn get serverName => text().nullable()();

  TextColumn get fingerprint => text().nullable()();

  TextColumn get publicKey => text().nullable()();

  TextColumn get shortId => text().nullable()();

  TextColumn get spiderX => text().nullable()();

  BoolColumn get allowInsecure => boolean().nullable()();

  TextColumn get plugin => text().nullable()();

  TextColumn get pluginOpts => text().nullable()();

  TextColumn get hysteriaProtocol => text().nullable()();

  TextColumn get obfs => text().nullable()();

  TextColumn get alpn => text().nullable()();

  TextColumn get authType => text().nullable()();

  IntColumn get upMbps => integer().nullable()();

  IntColumn get downMbps => integer().nullable()();

  IntColumn get recvWindowConn => integer().nullable()();

  IntColumn get recvWindow => integer().nullable()();

  BoolColumn get disableMtuDiscovery => boolean().nullable()();

  IntColumn get latency => integer().nullable()();

  TextColumn get configString => text().nullable()();

  TextColumn get configFormat => text().nullable()();
}

class RuleGroups extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();
}

class Rules extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(RuleGroups, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();

  BoolColumn get enabled => boolean()();

  IntColumn get outboundTag => integer()();

  TextColumn get domain => text().nullable()();

  TextColumn get ip => text().nullable()();

  TextColumn get port => text().nullable()();

  TextColumn get source => text().nullable()();

  TextColumn get sourcePort => text().nullable()();

  TextColumn get network => text().nullable()();

  TextColumn get protocol => text().nullable()();

  TextColumn get processName => text().nullable()();
}

class GroupsOrder extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get data => text()();
}

class ServersOrder extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(ServerGroups, #id, onDelete: KeyAction.cascade)();

  TextColumn get data => text()();
}

class RulesOrder extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(RuleGroups, #id, onDelete: KeyAction.cascade)();

  TextColumn get data => text()();
}
