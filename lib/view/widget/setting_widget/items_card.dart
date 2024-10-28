import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';

class ItemsCard<T extends Enum> extends ConsumerWidget {
  final String title;
  final List<T> items;
  final int Function(SphiaConfig value) idxSelector;
  final void Function(T value) updater;
  final String? tooltip;

  const ItemsCard({
    super.key,
    required this.title,
    required this.items,
    required this.idxSelector,
    required this.updater,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sphiaConfigNotifierProvider.select(idxSelector));
    final currItem = items[value];
    final listTile = ListTile(
      title: Text(title),
      trailing: Text(currItem.toString()),
      onTap: () async {
        final newValue = await showDialog<T>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.minPositive,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.toString()),
                      trailing: Icon(
                        index == value ? Symbols.check : null,
                      ),
                      onTap: () {
                        Navigator.of(context).pop(item);
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
        if (newValue != null) {
          updater(newValue);
        }
      },
    );
    return Tooltip(
      message: tooltip ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: listTile,
    );
  }
}
