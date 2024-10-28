import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/log.dart';
import 'package:sphia/app/notifier/config/rule_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/view/card/dashboard_card/rule_group.dart';

class RuleGroupListTile extends ConsumerWidget {
  const RuleGroupListTile({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleGroup = ref.watch(currentRuleGroupProvider);
    final isSelected = ref.watch(ruleConfigNotifierProvider
        .select((value) => value.selectedRuleGroupId == ruleGroup.id));
    return ListTile(
      title: Text(
        ruleGroup.name,
      ),
      trailing: Icon(
        isSelected ? Symbols.check : null,
      ),
      onTap: () async {
        if (!isSelected) {
          logger.i('Switching rule group to ${ruleGroup.name}');
          final ruleConfigNotifier =
              ref.read(ruleConfigNotifierProvider.notifier);
          ruleConfigNotifier.updateSelectedRuleGroupId(ruleGroup.id);
          final coreStateNotifier =
              ref.read(coreStateNotifierProvider.notifier);
          await coreStateNotifier.restartCores();
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
