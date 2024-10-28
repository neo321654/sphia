import 'package:drift/drift.dart';
import 'package:sphia/app/database/dao/config.dart';
import 'package:sphia/app/database/database.dart';

const ruleGroupsOrderId = 2;

class RuleGroupDao {
  final Database _db;

  const RuleGroupDao(this._db);

  Future<List<RuleGroup>> getRuleGroups() {
    return _db.select(_db.ruleGroups).get();
  }

  Future<List<RuleGroup>> getOrderedRuleGroups() {
    return getOrderedList(
        getRuleGroupsOrder, getRuleGroups, (group) => group.id);
  }

  Future<RuleGroup?> getRuleGroupById(int id) {
    return (_db.select(_db.ruleGroups)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> getDefaultRuleGroupId() {
    return (_db.select(_db.ruleGroups)
          ..where((tbl) => tbl.name.equals('Default')))
        .getSingle()
        .then((value) => value.id);
  }

  Future<int> insertRuleGroup(String name) async {
    final groupId = await _db.into(_db.ruleGroups).insert(
          RuleGroupsCompanion.insert(
            name: name,
          ),
        );
    await ruleDao.createEmptyRulesOrder(groupId);
    return groupId;
  }

  Future<void> updateRuleGroup(int id, String name) {
    return _db.update(_db.ruleGroups).replace(
          RuleGroupsCompanion(
            id: Value(id),
            name: Value(name),
          ),
        );
  }

  Future<void> deleteRuleGroup(int id) {
    return _db.transaction(() async {
      await (_db.delete(_db.ruleGroups)..where((tbl) => tbl.id.equals(id)))
          .go();
    });
  }

  Future<List<int>> getRuleGroupsOrder() {
    return _db.select(_db.groupsOrder).get().then((value) {
      if (value.isEmpty) {
        return [];
      }
      return value.last.data.split(',').map(int.parse).toList();
    });
  }

  Future<void> updateRuleGroupsOrder(List<int> order) async {
    final data = order.join(',');
    (_db.update(_db.groupsOrder)
          ..where((tbl) => tbl.id.equals(ruleGroupsOrderId)))
        .write(GroupsOrderCompanion(data: Value(data)));
  }

  Future<void> refreshRuleGroupsOrder() async {
    final groups = await getRuleGroups();
    final order = groups.map((e) => e.id).toList();
    await updateRuleGroupsOrder(order);
  }

  Future<void> clearRuleGroupsOrder() async {
    (_db.update(_db.groupsOrder)
          ..where((tbl) => tbl.id.equals(ruleGroupsOrderId)))
        .write(const GroupsOrderCompanion(data: Value('')));
  }
}
