import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';

class RunningCoresCard extends ConsumerWidget {
  const RunningCoresCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cores = ref.watch(coreStateNotifierProvider
        .select((value) => value.whenData((coreState) => coreState.cores)));
    final runningCoresCard = CardData(
      showAccent: true,
      horizontalPadding: false,
      icon: Symbols.memory,
      widget: cores.when(
        data: (cores) {
          if (cores.isEmpty) {
            return Center(
              child: IconButton(
                icon: const Icon(
                  Symbols.block,
                  color: Colors.grey,
                ),
                tooltip: L10n.of(context)!.noRunningCores,
                onPressed: null,
              ),
            );
          }
          return ListView.builder(
            itemCount: cores.length,
            itemBuilder: (BuildContext context, int index) {
              final core = cores[index];
              final coreName = core.name.toString();
              return buildInkWellTile(
                title: Text(
                  coreName,
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: null,
              );
            },
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: IconButton(
              icon: const Icon(
                Symbols.block,
                color: Colors.grey,
              ),
              tooltip: L10n.of(context)!.noRunningCores,
              onPressed: null,
            ),
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );

    return buildMultipleRowCard(runningCoresCard);
  }
}
