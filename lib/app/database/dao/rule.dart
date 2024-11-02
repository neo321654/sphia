import 'package:drift/drift.dart';
import 'package:sphia/app/database/dao/config.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/core/rule/rule_model.dart';

const outboundProxyId = -2;
const outboundDirectId = -1;
const outboundBlockId = 0;

class RuleDao {
  final Database _db;

  const RuleDao(this._db);

  Future<List<Rule>> getRulesByGroupId(int groupId) {
    return (_db.select(_db.rules)..where((tbl) => tbl.groupId.equals(groupId)))
        .get();
  }

  Future<List<RuleModel>> getRuleModelsByGroupId(int groupId) {
    return getRulesByGroupId(groupId).then((value) {
      return value.map(RuleModel.fromRule).toList();
    });
  }

  Future<List<Rule>> getOrderedRulesByGroupId(int groupId) {
    return getOrderedList(() => getRulesOrder(groupId),
        () => getRulesByGroupId(groupId), (rule) => rule.id);
  }

  Future<List<RuleModel>> getOrderedRuleModelsByGroupId(int groupId) async {
    final order = await getRulesOrder(groupId);
    final rules = await getRuleModelsByGroupId(groupId);
    final ruleMap = {for (var rule in rules) rule.id: rule};

    return order
        .map((id) => ruleMap[id])
        .where((rule) => rule != null)
        .cast<RuleModel>()
        .toList();
  }

  Future<Rule?> getRuleById(int id) {
    return (_db.select(_db.rules)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertRule(RuleModel rule) {
    return _db.into(_db.rules).insert(rule.toCompanion());
  }

  Future<void> updateRule(RuleModel rule) async {
    await (_db.update(_db.rules)..where((tbl) => tbl.id.equals(rule.id)))
        .write(rule.toRule());
  }

  Future<void> updateEnabled(int id, bool enabled) async {
    await (_db.update(_db.rules)..where((tbl) => tbl.id.equals(id)))
        .write(RulesCompanion(enabled: Value(enabled)));
  }

  Future<void> deleteRule(int id) {
    return (_db.delete(_db.rules)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<int>> getRulesOrder(int groupId) async {
    final value = await _db.select(_db.rulesOrder).get();
    if (value.isEmpty) return [];

    final data = value.firstWhere((element) => element.groupId == groupId).data;
    if (data.isEmpty) return [];

    return data.split(',').map(int.parse).toList();
  }

  Future<void> createEmptyRulesOrder(int groupId) async {
    await _db.into(_db.rulesOrder).insert(
          RulesOrderCompanion.insert(
            groupId: groupId,
            data: '',
          ),
        );
  }

  Future<void> updateRulesOrder(int groupId, List<int> order) async {
    final data = order.join(',');
    (_db.update(_db.rulesOrder)..where((tbl) => tbl.groupId.equals(groupId)))
        .write(RulesOrderCompanion(data: Value(data)));
  }

  Future<void> refreshRulesOrder(int groupId) async {
    final rules = await getRulesByGroupId(groupId);
    final order = rules.map((e) => e.id).toList();
    await updateRulesOrder(groupId, order);
  }

  Future<void> deleteRulesOrder(int groupId) async {
    (_db.delete(_db.rulesOrder)..where((tbl) => tbl.groupId.equals(groupId)))
        .go();
  }
}
