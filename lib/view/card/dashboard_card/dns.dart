import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/state/core_state.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/dashboard_card/card.dart';

class DnsCard extends ConsumerWidget {
  const DnsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configureDns = ref.watch(
        sphiaConfigNotifierProvider.select((value) => value.configureDns));
    final dnsCard = CardData(
      title: Text(L10n.of(context)!.dns),
      horizontalPadding: false,
      icon: Symbols.dns,
      widget: configureDns
          ? SingleChildScrollView(
              child: Column(
                children: [
                  buildInkWellTile(
                    title: Text(
                      L10n.of(context)!.dnsResolver,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Consumer(builder: (context, ref, child) {
                      final dnsResolver = ref.watch(
                        sphiaConfigNotifierProvider.select(
                          (value) => value.dnsResolver,
                        ),
                      );
                      return Text(
                        dnsResolver,
                        style: const TextStyle(
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onTap: () async {
                      final dnsResolverController = TextEditingController();
                      dnsResolverController.text = ref.read(
                        sphiaConfigNotifierProvider.select(
                          (value) => value.dnsResolver,
                        ),
                      );
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(L10n.of(context)!.dnsResolver),
                            content: TextFormField(
                              controller: dnsResolverController,
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
                                onPressed: () async {
                                  final notifier = ref.read(
                                      sphiaConfigNotifierProvider.notifier);
                                  notifier.updateValue(
                                    'dnsResolver',
                                    dnsResolverController.text,
                                  );
                                  Navigator.of(context).pop();
                                  final coreState = ref
                                      .read(coreStateNotifierProvider)
                                      .valueOrNull;
                                  if (coreState?.routingProvider ==
                                      RoutingProvider.sing) {
                                    await ref
                                        .read(
                                            coreStateNotifierProvider.notifier)
                                        .restartCores();
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  buildInkWellTile(
                    title: Text(
                      L10n.of(context)!.remoteDns,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Consumer(builder: (context, ref, child) {
                      final remoteDns = ref.watch(
                        sphiaConfigNotifierProvider.select(
                          (value) => value.remoteDns,
                        ),
                      );
                      return Text(
                        remoteDns,
                        style: const TextStyle(
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onTap: () async {
                      final remoteDnsController = TextEditingController();
                      remoteDnsController.text = ref.read(
                        sphiaConfigNotifierProvider.select(
                          (value) => value.remoteDns,
                        ),
                      );
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(L10n.of(context)!.remoteDns),
                            content: TextFormField(
                              controller: remoteDnsController,
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
                                onPressed: () async {
                                  final notifier = ref.read(
                                      sphiaConfigNotifierProvider.notifier);
                                  notifier.updateValue(
                                    'remoteDns',
                                    remoteDnsController.text,
                                  );
                                  Navigator.of(context).pop();
                                  await ref
                                      .read(coreStateNotifierProvider.notifier)
                                      .restartCores();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  buildInkWellTile(
                    title: Text(
                      L10n.of(context)!.directDns,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Consumer(builder: (context, ref, child) {
                      final directDns = ref.watch(
                        sphiaConfigNotifierProvider.select(
                          (value) => value.directDns,
                        ),
                      );
                      return Text(
                        directDns,
                        style: const TextStyle(
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    onTap: () async {
                      final directDnsController = TextEditingController();
                      directDnsController.text = ref.read(
                        sphiaConfigNotifierProvider.select(
                          (value) => value.directDns,
                        ),
                      );
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(L10n.of(context)!.directDns),
                            content: TextFormField(
                              controller: directDnsController,
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
                                onPressed: () async {
                                  final notifier = ref.read(
                                      sphiaConfigNotifierProvider.notifier);
                                  notifier.updateValue(
                                    'directDns',
                                    directDnsController.text,
                                  );
                                  Navigator.of(context).pop();
                                  await ref
                                      .read(coreStateNotifierProvider.notifier)
                                      .restartCores();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            )
          : Center(
              child: IconButton(
                icon: const Icon(
                  Symbols.block,
                  color: Colors.grey,
                ),
                tooltip: L10n.of(context)!.dnsIsNotConfigured,
                onPressed: null,
              ),
            ),
    );

    return buildMultipleRowCard(dnsCard);
  }
}
