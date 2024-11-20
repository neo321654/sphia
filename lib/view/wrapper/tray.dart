import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/helper/tray.dart';
import 'package:sphia/app/notifier/tray.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const TrayWrapper({super.key, required this.child});

  @override
  ConsumerState<TrayWrapper> createState() => _TrayWrapperState();
}

class _TrayWrapperState extends ConsumerState<TrayWrapper>
    with TrayListener, SystemHelper {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    if (isLinux) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await TrayHelper.setIcon(coreRunning: false);
      });
    }
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onTrayIconMouseDown() async {
    if (isMacOS) {
      // await trayManager.popUpContextMenu();
    } else {
      await windowManager.show();
    }
  }

  @override
  Future<void> onTrayIconRightMouseDown() async {
    if (!isMacOS) {
      await trayManager.popUpContextMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(trayNotifierProvider);
    return widget.child;
  }
}
