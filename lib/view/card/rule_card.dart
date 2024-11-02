import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/rule.dart';
import 'package:sphia/app/notifier/data/outbound_tag.dart';
import 'package:sphia/app/notifier/data/rule.dart';
import 'package:sphia/core/rule/rule_model.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/shadow_card.dart';
import 'package:sphia/view/widget/widget.dart';

part 'rule_card.g.dart';

@riverpod
RuleModel currentRule(Ref ref) => throw UnimplementedError();

class RuleCard extends ConsumerWidget with RuleHelper {
  const RuleCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule = ref.watch(currentRuleProvider);
    return ShadowCard(
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        title: Text(rule.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final outboundTag = ref.watch(outboundTagNotifierProvider
                    .select((value) => value[rule.outboundTag]));
                return Text(
                  'Outbound Tag: ${outboundTag ?? 'null'}',
                );
              },
            ),
            if (rule.domain != null)
              Text(
                'Domain: ${rule.domain}',
              ),
            if (rule.ip != null)
              Text(
                'IP: ${rule.ip}',
              ),
            if (rule.port != null)
              Text(
                'Port: ${rule.port}',
              ),
            if (rule.source != null)
              Text(
                'Source: ${rule.source}',
              ),
            if (rule.sourcePort != null)
              Text(
                'Source Port: ${rule.sourcePort}',
              ),
            if (rule.network != null)
              Text(
                'Network: ${rule.network}',
              ),
            if (rule.protocol != null)
              Text(
                'Protocol: ${rule.protocol}',
              ),
            if (rule.processName != null)
              Text(
                'Process Name: ${rule.processName}',
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: rule.enabled,
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                final notifier = ref.read(ruleNotifierProvider.notifier);
                await ruleDao.updateEnabled(rule.id, value);
                notifier.updateRuleEnabled(rule.id, value);
              },
            ),
            const SizedBox(width: 16),
            SphiaWidget.iconButton(
              icon: Symbols.edit,
              onTap: () async {
                late final RuleModel? newRule;
                if ((newRule = await _editRule(rule: rule, ref: ref)) != null) {
                  final notifier = ref.read(ruleNotifierProvider.notifier);
                  notifier.updateRule(newRule!);
                }
              },
            ),
            const SizedBox(width: 16),
            SphiaWidget.iconButton(
              icon: Symbols.delete,
              onTap: () async {
                await ruleDao.deleteRule(rule.id);
                await ruleDao.refreshRulesOrder(rule.groupId);
                final notifier = ref.read(ruleNotifierProvider.notifier);
                notifier.removeRule(rule.id);
              },
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }

  Future<RuleModel?> _editRule({
    required RuleModel rule,
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final RuleModel? editedRule = await showEditRuleDialog(
      title: '${L10n.of(context)!.edit} ${L10n.of(context)!.rule}',
      rule: rule,
      context: context,
    );
    if (editedRule == null || editedRule == rule) {
      return null;
    }
    await ruleDao.updateRule(editedRule);
    // await ruleDao.refreshRulesOrderByGroupId(editedRule.groupId);
    return editedRule;
  }
}
