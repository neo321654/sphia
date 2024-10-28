import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';
import 'package:sphia/view/widget/widget.dart';

class LocalPortCard extends StatelessWidget {
  const LocalPortCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final localPortCard = CardData(
      icon: Symbols.send,
      widget: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _getPortColumn(
            'Socks',
            (value) => value.socksPort,
            (ref, value) {
              final notifier = ref.read(sphiaConfigNotifierProvider.notifier);
              notifier.updateValue('socksPort', value);
            },
          ),
          const SizedBox(width: 8),
          const _Separator(),
          const SizedBox(width: 8),
          _getPortColumn(
            'HTTP',
            (value) => value.httpPort,
            (ref, value) {
              final notifier = ref.read(sphiaConfigNotifierProvider.notifier);
              notifier.updateValue('httpPort', value);
            },
          ),
          const SizedBox(width: 8),
          const _Separator(),
          const SizedBox(width: 8),
          _getPortColumn(
            'Mixed',
            (value) => value.mixedPort,
            (ref, value) {
              final notifier = ref.read(sphiaConfigNotifierProvider.notifier);
              notifier.updateValue('mixedPort', value);
            },
          ),
        ],
      ),
    );
    return buildMultipleRowCard(localPortCard);
  }

  Widget _getPortColumn(
    String title,
    int Function(SphiaConfig) portSelector,
    void Function(WidgetRef ref, int value) updater,
  ) {
    return Flexible(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Consumer(
            builder: (context, ref, child) {
              final port =
                  ref.watch(sphiaConfigNotifierProvider.select(portSelector));
              return UnderlineText(
                text: port.toString(),
                textStyle: const TextStyle(
                  fontSize: 16,
                ),
                onTap: () async {
                  final controller =
                      TextEditingController(text: port.toString());
                  final value = await showDialog<String>(
                    context: context,
                    barrierDismissible: false,
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
                  late final int? newValue;
                  if (value != null) {
                    if ((newValue = int.tryParse(value)) == null ||
                        newValue! < 0 ||
                        newValue > 65535) {
                      if (context.mounted) {
                        SphiaWidget.showDialogWithMsg(
                          context: context,
                          message: L10n.of(context)!.portInvalidMsg,
                        );
                      }
                      return;
                    }
                    updater(ref, newValue);
                    final coreState =
                        ref.read(coreStateNotifierProvider).valueOrNull;
                    if (coreState?.routingProvider != null) {
                      final notifier =
                          ref.read(coreStateNotifierProvider.notifier);
                      switch (coreState!.routingProvider) {
                        case RoutingProvider.sing:
                          if (title == 'Mixed') {
                            notifier.restartCores();
                          }
                          break;
                        case RoutingProvider.xray:
                          if (title == 'Socks' || title == 'HTTP') {
                            notifier.restartCores();
                          }
                          break;
                        case RoutingProvider.none:
                          break;
                      }
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          ' / ',
          style: TextStyle(fontSize: 16),
        )
      ],
    );
  }
}
