import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/helper/update.dart';
import 'package:sphia/app/notifier/config/version_config.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/state/core_info_state.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/shadow_card.dart';
import 'package:sphia/view/widget/widget.dart';
import 'package:url_launcher/url_launcher.dart';

part 'core_card.g.dart';

@riverpod
CoreInfoState currentCore(Ref ref) => throw UnimplementedError();

class CoreInfoCard extends ConsumerWidget with UpdateHelper {
  const CoreInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoState = ref.watch(currentCoreProvider);
    final coreInfo = infoState.info;
    final latestVersion = infoState.latestVersion;
    return ShadowCard(
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        title: Text(coreInfo.name.toString()),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: '${L10n.of(context)!.repoUrl}: ${coreInfo.repoUrl}',
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    try {
                      await launchUrl(Uri.parse(coreInfo.repoUrl));
                    } on Exception catch (e) {
                      ref
                          .read(logNotifierProvider.notifier)
                          .error('Failed to launch URL: $e');
                      if (!context.mounted) {
                        return;
                      }
                      await SphiaWidget.showDialogWithMsg(
                        context: context,
                        message: '${L10n.of(context)!.launchUrlFailed}: $e',
                      );
                    }
                  },
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                String? displayVersion;
                final currentVersion = ref.watch(versionConfigNotifierProvider
                    .select((value) => value.getVersion(infoState.info.name)));
                if (currentVersion != null) {
                  displayVersion = currentVersion;
                } else {
                  if (coreInfo.existsSync()) {
                    displayVersion = L10n.of(context)!.unknown;
                  }
                }
                if (displayVersion != null) {
                  return Text(
                      '${L10n.of(context)!.currentVersion}: $displayVersion');
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            if (latestVersion != null) ...[
              Text('${L10n.of(context)!.latestVersion}: $latestVersion')
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: L10n.of(context)!.checkUpdate,
              child: SphiaWidget.iconButton(
                icon: Symbols.refresh,
                onTap: () async {
                  final notifier = ref.read(coreInfoStateListProvider.notifier);
                  notifier.updateIsUpdating(coreInfo.name, true);
                  await checkUpdate(
                    coreInfo: coreInfo,
                    showDialog: true,
                    ref: ref,
                  );
                  notifier.updateIsUpdating(coreInfo.name, false);
                },
                enabled: !infoState.isUpdating,
              ),
            ),
            const SizedBox(width: 16),
            Tooltip(
              message: L10n.of(context)!.update,
              child: SphiaWidget.iconButton(
                icon: Symbols.update,
                onTap: () async {
                  final notifier = ref.read(coreInfoStateListProvider.notifier);
                  notifier.updateIsUpdating(coreInfo.name, true);
                  final currentVersion = ref.read(
                      versionConfigNotifierProvider.select(
                          (value) => value.getVersion(infoState.info.name)));
                  await updateCore(
                    coreInfo: coreInfo,
                    currentVersion: currentVersion,
                    shouldUpdate: latestVersion == null,
                    ref: ref,
                  );
                  notifier.updateIsUpdating(coreInfo.name, false);
                },
                enabled: !infoState.isUpdating,
              ),
            ),
            const SizedBox(width: 16),
            Tooltip(
              message: L10n.of(context)!.delete,
              child: SphiaWidget.iconButton(
                icon: Symbols.delete,
                onTap: () async => await deleteCore(
                  coreInfo: coreInfo,
                  ref: ref,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
