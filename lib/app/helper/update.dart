import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/config/version.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/app/notifier/config/version_config.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/app/state/core_info_state.dart';
import 'package:sphia/core/core_info.dart';
import 'package:sphia/core/updater.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/widget/widget.dart';

part 'update.g.dart';

const hysteriaLatestVersion = 'v1.3.5';

@riverpod
class CoreInfoStateList extends _$CoreInfoStateList with ProxyResInfoList {
  @override
  List<CoreInfoState> build() {
    return proxyResInfoList
        .map(
          (info) => CoreInfoState(
            info: info,
            latestVersion: null,
            isUpdating: false,
          ),
        )
        .toList();
  }

  void updateLatestVersion(ProxyRes coreName, String version) {
    state = state.map((infoState) {
      if (infoState.info.name == coreName) {
        return infoState.copyWith(latestVersion: version);
      }
      return infoState;
    }).toList();
  }

  void removeLatestVersion(ProxyRes coreName) {
    state = state.map((infoState) {
      if (infoState.info.name == coreName) {
        return infoState.copyWith(latestVersion: null);
      }
      return infoState;
    }).toList();
  }

  void updateIsUpdating(ProxyRes coreName, bool isUpdating) {
    state = state.map((infoState) {
      if (infoState.info.name == coreName) {
        return infoState.copyWith(isUpdating: isUpdating);
      }
      return infoState;
    }).toList();
  }
}

mixin UpdateHelper {
  Future<void> checkUpdate({
    required ProxyResInfo coreInfo,
    required bool showDialog,
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final config = ref.read(versionConfigNotifierProvider);
    final coreName = coreInfo.name;
    final coreExists = await coreInfo.exists();
    if (!coreExists) {
      final notifier = ref.read(versionConfigNotifierProvider.notifier);
      notifier.removeVersion(coreName);
    }
    final coreInfoNotifier = ref.read(coreInfoStateListProvider.notifier);
    final logNotifier = ref.read(logNotifierProvider.notifier);
    if (coreName == ProxyRes.hysteria) {
      if (config.getVersion(coreName) == hysteriaLatestVersion && coreExists) {
        if (context.mounted) {
          await SphiaWidget.showDialogWithMsg(
            context: context,
            message:
                '${L10n.of(context)!.alreadyLatestVersion}: hysteria $hysteriaLatestVersion',
          );
        }
        return;
      }
      logNotifier.info('Latest version of hysteria: $hysteriaLatestVersion');
      coreInfoNotifier.updateLatestVersion(
          ProxyRes.hysteria, hysteriaLatestVersion);
      if (showDialog && context.mounted) {
        await SphiaWidget.showDialogWithMsg(
          context: context,
          message:
              '${L10n.of(context)!.latestVersion}: hysteria $hysteriaLatestVersion',
        );
      }
      return;
    }
    logNotifier.info('Checking update: $coreName');

    final networkHelper = ref.read(networkHelperProvider.notifier);
    try {
      try {
        // check github connection
        await networkHelper.getHttpResponse('https://github.com').timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Connection timed out'));
      } on Exception catch (e) {
        logNotifier.error('Failed to connect to Github: $e');
        if (!context.mounted) {
          return;
        }
        await SphiaWidget.showDialogWithMsg(
          context: context,
          message: '${L10n.of(context)!.connectToGithubFailed}: $e',
        );
        return;
      }
      final latestVersion = await networkHelper.getLatestVersion(coreInfo);
      logNotifier.info('Latest version of $coreName: $latestVersion');
      if (config.getVersion(coreName) == latestVersion && coreExists) {
        if (!context.mounted) {
          return;
        }
        await SphiaWidget.showDialogWithMsg(
          context: context,
          message:
              '${L10n.of(context)!.alreadyLatestVersion}: $coreName $latestVersion',
        );
      } else {
        coreInfoNotifier.updateLatestVersion(coreName, latestVersion);
        if (showDialog && context.mounted) {
          await SphiaWidget.showDialogWithMsg(
            context: context,
            message:
                '${L10n.of(context)!.latestVersion}: $coreName $latestVersion',
          );
        }
      }
    } on Exception catch (e) {
      logNotifier.error('Failed to check update: $e');
      if (!context.mounted) {
        return;
      }
      await SphiaWidget.showDialogWithMsg(
        context: context,
        message: '${L10n.of(context)!.checkUpdateFailed}: $e',
      );
      return;
    }
  }

  Future<void> updateCore({
    required ProxyResInfo coreInfo,
    required String? currentVersion,
    required bool shouldUpdate,
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final coreName = coreInfo.name;
    if (shouldUpdate) {
      await checkUpdate(
        coreInfo: coreInfo,
        showDialog: false,
        ref: ref,
      );
    }
    final newCoreInfo = ref
        .read(coreInfoStateListProvider)
        .firstWhere((infoState) => infoState.info.name == coreName);
    final latestVersion = newCoreInfo.latestVersion;
    if (latestVersion != null) {
      if (latestVersion == currentVersion) {
        return;
      }
      try {
        await ref.read(coreUpdaterProvider.notifier).updateCore(
              coreInfo: coreInfo,
              latestVersion: latestVersion,
            );
      } on Exception catch (e) {
        if (!context.mounted) {
          return;
        }
        await SphiaWidget.showDialogWithMsg(
            context: context, message: '${L10n.of(context)!.updateFailed}: $e');
        return;
      }
      final coreInfoStateListNotifier =
          ref.read(coreInfoStateListProvider.notifier);
      coreInfoStateListNotifier.removeLatestVersion(coreName);
      final versionConfigNotifier =
          ref.read(versionConfigNotifierProvider.notifier);
      versionConfigNotifier.updateVersion(coreName, latestVersion);
      if (!context.mounted) {
        return;
      }
      await SphiaWidget.showDialogWithMsg(
        context: context,
        message: L10n.of(context)!.updatedSuccessfully(coreName, latestVersion),
      );
    }
  }

  Future<void> deleteCore({
    required ProxyResInfo coreInfo,
    required WidgetRef ref,
  }) async {
    final context = ref.context;
    final notifier = ref.read(versionConfigNotifierProvider.notifier);
    // check if core exists
    final coreName = coreInfo.name;
    if (!await coreInfo.exists()) {
      if (context.mounted) {
        await SphiaWidget.showDialogWithMsg(
          context: context,
          message: L10n.of(context)!.coreNotFound(coreName),
        );
      }
      notifier.removeVersion(coreName);
      return;
    }
    // check if core is running
    final proxyState = ref.read(proxyNotifierProvider);
    if (proxyState.coreRunning) {
      if (context.mounted) {
        await SphiaWidget.showDialogWithMsg(
          context: context,
          message: L10n.of(context)!.stopCoreBeforeDelete,
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context)!.deleteCore),
        content: Text(L10n.of(context)!.deleteCoreConfirm(coreName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(L10n.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(L10n.of(context)!.delete),
          ),
        ],
      ),
    );
    if (confirm == null || !confirm) {
      return;
    }
    try {
      await ref.read(coreUpdaterProvider.notifier).deleteCore(coreInfo);
    } on Exception catch (e) {
      if (!context.mounted) {
        return;
      }
      await SphiaWidget.showDialogWithMsg(
        context: context,
        message: '${L10n.of(context)!.deleteCoreFailed}: $e',
      );
      return;
    }
    notifier.removeVersion(coreName);
    if (!context.mounted) {
      return;
    }
    await SphiaWidget.showDialogWithMsg(
      context: context,
      message: L10n.of(context)!.deletedCoreSuccessfully(coreName),
    );
  }
}
