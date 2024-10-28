import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/notifier/data/rule_group.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';
import 'package:sphia/view/widget/rule_group_list_tile.dart';
import 'package:sphia/view/widget/widget.dart';

part 'rule_group.g.dart';

@riverpod
RuleGroup currentRuleGroup(Ref ref) => throw UnimplementedError();

class RuleGroupCard extends ConsumerWidget {
  const RuleGroupCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coreRunning =
        ref.watch(proxyNotifierProvider.select((value) => value.coreRunning));
    final customConfig =
        ref.watch(proxyNotifierProvider.select((value) => value.customConfig));
    final ruleGroupName = ref.watch(selectedRuleGroupProvider).name;
    final disabled = coreRunning && customConfig;
    final style = disabled
        ? const TextStyle(fontSize: 16, color: Colors.grey)
        : const TextStyle(fontSize: 16);

    final rulesCard = CardData(
      title: Text(ruleGroupName, style: style),
      icon: Symbols.alt_route,
      widget: SphiaWidget.iconButton(
        icon: Symbols.move_group,
        minSize: 32,
        tooltip: L10n.of(context)!.switchGroup,
        onTap: disabled
            ? null
            : () {
                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    final ruleGroups = ref.read(ruleGroupNotifierProvider);
                    return AlertDialog(
                      content: SizedBox(
                        width: double.minPositive,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: ruleGroups.length,
                          itemBuilder: (BuildContext context, int index) {
                            final ruleGroup = ruleGroups[index];
                            return ProviderScope(
                              overrides: [
                                currentRuleGroupProvider
                                    .overrideWithValue(ruleGroup),
                              ],
                              child: const RuleGroupListTile(),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
      ),
    );

    return buildSingleRowCard(rulesCard);
  }
}
