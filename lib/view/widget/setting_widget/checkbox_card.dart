import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';

class CheckboxCard extends ConsumerWidget {
  final String title;
  final bool Function(SphiaConfig value) selector;
  final void Function(bool value) updater;
  final bool enabled;
  final String? tooltip;

  const CheckboxCard({
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
      trailing: Container(
        alignment: Alignment.centerRight,
        width: 20,
        child: Checkbox(
          value: value,
          onChanged: enabled ? (value) => updater(value!) : null,
        ),
      ),
      onTap: enabled ? () => updater(!value) : null,
    );
    return Tooltip(
      message: tooltip ?? '',
      waitDuration: const Duration(milliseconds: 500),
      child: listTile,
    );
  }
}
