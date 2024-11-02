import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/notifier/log.dart';

part 'data.g.dart';

@riverpod
List<SphiaLogEntry> initLogs(Ref ref) => throw UnimplementedError();

@riverpod
List<ServerGroup> serverGroups(Ref ref) => throw UnimplementedError();

@riverpod
List<RuleGroup> ruleGroups(Ref ref) => throw UnimplementedError();
