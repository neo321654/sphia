import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/app/provider/data.dart';

part 'rule_group.g.dart';

@Riverpod(keepAlive: true)
class RuleGroupNotifier extends _$RuleGroupNotifier {
  @override
  List<RuleGroup> build() {
    final ruleGroups = ref.read(ruleGroupsProvider);
    return ruleGroups;
  }

  void addGroup(RuleGroup group) {
    state = [...state, group];
  }

  void removeGroup(int id) {
    state = state.where((s) => s.id != id).toList();
  }

  void updateGroup(RuleGroup group) {
    state = state.map((s) {
      if (s.id == group.id) {
        return group;
      }
      return s;
    }).toList();
  }

  void setGroups(List<RuleGroup> groups) {
    state = [...groups];
  }

  void clearGroups() {
    state = [];
  }
}

@Riverpod(keepAlive: true)
RuleGroup selectedRuleGroup(Ref ref) {
  final selectedGroupId = ref.watch(
      ruleConfigNotifierProvider.select((value) => value.selectedRuleGroupId));
  final ruleGroup = ref.watch(
    ruleGroupNotifierProvider.select(
      (value) => value.firstWhere(
        (group) => group.id == selectedGroupId,
      ),
    ),
  );
  return ruleGroup;
}
