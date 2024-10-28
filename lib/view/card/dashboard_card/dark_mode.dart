import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';

class DarkModeCard extends ConsumerWidget {
  const DarkModeCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref
        .watch(sphiaConfigNotifierProvider.select((value) => value.darkMode));
    final darkModeCard = CardData(
      title: Text(L10n.of(context)!.darkMode,
          style: const TextStyle(fontSize: 16)),
      icon: Symbols.brightness_4,
      widget: Checkbox(
        value: darkMode,
        onChanged: (value) {
          ref.read(sphiaConfigNotifierProvider.notifier).updateValue(
                'darkMode',
                value,
              );
        },
      ),
    );
    return buildSingleRowCard(darkModeCard);
  }
}
