import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/network.dart';
import 'package:sphia/core/core_info.dart';
import 'package:sphia/core/sphia/core_info.dart';
import 'package:sphia/view/page/about.dart';
import 'package:updat/updat.dart';

class SphiaUpdatWidget extends ConsumerWidget with ProxyResInfoList {
  final bool darkMode;

  SphiaInfo get sphiaInfo => proxyResInfoList.last as SphiaInfo;

  const SphiaUpdatWidget(this.darkMode, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UpdatWidget(
      updateChipBuilder: _updatChip,
      currentVersion: sphiaFullVersion,
      getLatestVersion: () async {
        final networkHelper = ref.read(networkHelperProvider.notifier);
        return await networkHelper.getLatestVersion(sphiaInfo);
      },
      getBinaryUrl: (version) async {
        final coreArchiveFileName = sphiaInfo.getArchiveFileName(version!);
        return '${sphiaInfo.repoUrl}/releases/download/v$version/$coreArchiveFileName';
      },
      getDownloadFileLocation: (version) async {
        final coreArchiveFileName = sphiaInfo.getArchiveFileName(version!);
        final networkHelper = ref.read(networkHelperProvider.notifier);
        final bytes = await networkHelper.downloadFile(
            '${sphiaInfo.repoUrl}/releases/download/v$version/$coreArchiveFileName');
        final tempFile = File(p.join(IoHelper.tempPath, coreArchiveFileName));
        await tempFile.writeAsBytes(bytes);
        return tempFile;
      },
      appName: 'Sphia',
      getChangelog: (_, __) async {
        final networkHelper = ref.read(networkHelperProvider.notifier);
        final changelog = await networkHelper.getSphiaChangeLog();
        return changelog;
      },
      closeOnInstall: true,
    );
  }

  Widget _updatChip({
    required BuildContext context,
    required String? latestVersion,
    required String appVersion,
    required UpdatStatus status,
    required void Function() checkForUpdate,
    required void Function() openDialog,
    required void Function() startUpdate,
    required Future<void> Function() launchInstaller,
    required void Function() dismissUpdate,
  }) {
    if (UpdatStatus.available == status ||
        UpdatStatus.availableWithChangelog == status) {
      return _getUpdatWidgetFloatingButton(
        onPressed: openDialog,
        icon: const Icon(
          Symbols.system_update_alt_rounded,
          color: Color.fromARGB(230, 128, 128, 128),
        ),
      );
    }

    if (UpdatStatus.downloading == status) {
      return _getUpdatWidgetFloatingButton(
        onPressed: () {},
        icon: const SizedBox(
          width: 15,
          height: 15,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (UpdatStatus.readyToInstall == status) {
      return _getUpdatWidgetFloatingButton(
        onPressed: launchInstaller,
        icon: const Icon(
          Symbols.check_circle,
          color: Color.fromARGB(230, 128, 128, 128),
        ),
      );
    }

    if (UpdatStatus.error == status) {
      return _getUpdatWidgetFloatingButton(
        onPressed: startUpdate,
        icon: const Icon(
          Symbols.warning,
          color: Color.fromARGB(230, 128, 128, 128),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _getUpdatWidgetFloatingButton({
    required Function() onPressed,
    required Widget icon,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: FloatingActionButton(
        isExtended: true,
        elevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        hoverElevation: 0,
        disabledElevation: 0,
        foregroundColor: darkMode ? Colors.white : Colors.black,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        focusColor: Colors.transparent,
        onPressed: onPressed,
        child: icon,
      ),
    );
  }
}
