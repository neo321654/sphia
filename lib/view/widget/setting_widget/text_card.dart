import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/l10n/generated/l10n.dart';

class TextCard extends ConsumerWidget {
  final String title;
  final String Function(SphiaConfig value) selector;
  final void Function(String value) updater;
  final bool enabled;
  final String? tooltip;

  const TextCard({
    super.key,
    required this.title,
    required this.selector,
    required this.updater,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(sphiaConfigNotifierProvider.select(selector));
    final listTile = ListTile(
      enabled: enabled,
      title: Text(title),
      trailing: Text(value),
      onTap: () async {
        final controller = TextEditingController(text: value);
        final newValue = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: TextFormField(
                controller: controller,
              ),
              actions: [
                TextButton(
                  child: Text(L10n.of(context)!.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(L10n.of(context)!.save),
                  onPressed: () {
                    Navigator.of(context).pop(controller.text);
                  },
                ),
              ],
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
