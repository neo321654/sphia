import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/core/rule/rule_model.dart';

part 'rule.g.dart';

@Riverpod(keepAlive: true)
class RuleNotifier extends _$RuleNotifier {
  @override
  Future<List<RuleModel>> build() async {
    final selectedRuleGroupId = ref.watch(ruleConfigNotifierProvider
        .select((value) => value.selectedRuleGroupId));
    return await ruleDao.getOrderedRuleModelsByGroupId(selectedRuleGroupId);
  }

  void addRule(RuleModel rule) {
    state.whenData((s) {
      state = AsyncValue.data([...s, rule]);
    });
  }

  void removeRule(int id) {
    state.whenData((s) {
      state = AsyncValue.data(s.where((rule) => rule.id != id).toList());
    });
  }

  void updateRule(RuleModel rule) {
    state.whenData((s) {
      state = AsyncValue.data(s.map((r) {
        if (r.id == rule.id) {
          return rule;
        }
        return r;
      }).toList());
    });
  }

  void updateRuleEnabled(int id, bool enabled) {
    state.whenData((s) {
      state = AsyncValue.data(s.map((r) {
        if (r.id == id) {
          return r.copyWith(enabled: enabled);
        }
        return r;
      }).toList());
    });
  }

  void setRules(List<RuleModel> rules) {
    state = AsyncValue.data([...rules]);
  }

  void reorderRules(List<int> order) {
    state.whenData((s) {
      state = AsyncValue.data(order.map((i) => s[i]).toList());
    });
  }

  void clearRules() {
    state = const AsyncValue.data([]);
  }
}
