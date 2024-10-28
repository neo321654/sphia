import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:quiver/collection.dart';
import 'package:sphia/app/database/database.dart';
import 'package:sphia/app/helper/rule.dart';
import 'package:sphia/app/notifier/data/rule.dart';
import 'package:sphia/app/notifier/data/rule_group.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/rule_card.dart';
import 'package:sphia/view/widget/widget.dart';

enum MenuAction { reorderGroup, resetRules }

class RulePage extends ConsumerWidget with RuleHelper {
  const RulePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appBar = AppBar(
      title: Text(
        L10n.of(context)!.rules,
        textAlign: TextAlign.center,
      ),
      elevation: 0,
    );
    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          _getToolbar(ref),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 32,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: _getListView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getToolbar(WidgetRef ref) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final ruleGroupName =
                                ref.watch(selectedRuleGroupProvider).name;
                            return Text(
                              ruleGroupName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: SphiaWidget.iconButton(
                            icon: Symbols.move_group,
                            tooltip: L10n.of(ref.context)!.switchGroup,
                            onTap: () => switchGroup(ref: ref),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 2,
                  color: Theme.of(ref.context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 1,
            child: Row(
              children: [
                Spacer(),
                ButtonGroup(),
                SizedBox(width: 8),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _getListView() {
    return Consumer(
      builder: (context, ref, child) {
        final rules = ref.watch(ruleNotifierProvider);
        return rules.maybeWhen(
          data: (rules) {
            return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              proxyDecorator: (child, index, animation) => child,
              onReorder: (int oldIndex, int newIndex) async {
                final oldOrder = rules.map((e) => e.id).toList();
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final rule = rules.removeAt(oldIndex);
                rules.insert(newIndex, rule);
                final newOrder = rules.map((e) => e.id).toList();
                if (listsEqual(oldOrder, newOrder)) {
                  return;
                }
                final ruleGroup = ref.read(selectedRuleGroupProvider);
                await ruleDao.updateRulesOrder(
                  ruleGroup.id,
                  newOrder,
                );
                final notifier = ref.read(ruleNotifierProvider.notifier);
                notifier.setRules(rules);
              },
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Padding(
                  key: ValueKey(index),
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: RepaintBoundary(
                    child: ReorderableDragStartListener(
                      index: index,
                      child: ProviderScope(
                        overrides: [
                          currentRuleProvider.overrideWithValue(rule),
                        ],
                        child: const RuleCard(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          orElse: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      },
    );
  }
}

class ButtonGroup extends ConsumerWidget with RuleHelper {
  const ButtonGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SphiaWidget.iconButton(
            icon: Symbols.edit_square,
            tooltip: L10n.of(context)!.editGroup,
            minSize: 40,
            onTap: () async {
              await editGroup(ref: ref);
            },
          ),
          _getDivider(),
          SphiaWidget.iconButton(
            icon: Symbols.create_new_folder,
            tooltip: L10n.of(context)!.addGroup,
            minSize: 40,
            onTap: () async {
              await addGroup(ref: ref);
            },
          ),
          _getDivider(),
          SphiaWidget.iconButton(
            icon: Symbols.folder_delete,
            tooltip: L10n.of(context)!.deleteGroup,
            minSize: 40,
            onTap: () async {
              await deleteGroup(ref: ref);
            },
          ),
          _getDivider(),
          SphiaWidget.iconButton(
            icon: Symbols.new_window,
            tooltip: L10n.of(context)!.addRule,
            minSize: 40,
            onTap: () async {
              await addRule(ref: ref);
            },
          ),
          _getDivider(),
          Builder(
            builder: (context) {
              return SphiaWidget.iconButton(
                icon: Symbols.tune,
                tooltip: L10n.of(context)!.more,
                minSize: 40,
                onTap: () {
                  _showMenu<MenuAction>(
                    context: context,
                    items: [
                      PopupMenuItem(
                        value: MenuAction.reorderGroup,
                        child: Text(L10n.of(context)!.reorderGroup),
                      ),
                      PopupMenuItem(
                        value: MenuAction.resetRules,
                        child: Text(L10n.of(context)!.resetRules),
                      ),
                    ],
                  ).then((value) async {
                    switch (value) {
                      case MenuAction.reorderGroup:
                        await reorderGroup(ref: ref);
                        break;
                      case MenuAction.resetRules:
                        await resetRules(ref: ref);
                        break;
                      default:
                        break;
                    }
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _getDivider() {
    return Container(
      width: 2,
      height: 24,
      color: Colors.grey,
    );
  }

  Future<T?> _showMenu<T>({
    required BuildContext context,
    required List<PopupMenuEntry<T>> items,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    return await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + renderBox.size.width,
        position.dy + renderBox.size.height,
      ),
      items: items,
    );
  }
}
