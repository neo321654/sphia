import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

class TrayHelper {
  static Future<void> setIcon({required bool coreRunning}) async {
    await trayManager.setIcon(getIconPath(coreRunning));
  }

  static String getIconPath(bool coreRunning) {
    if (coreRunning) {
      if (Platform.isMacOS) {
        return 'assets/tray_no_color_on.png';
      } else {
        return 'assets/tray_color_on.ico';
      }
    } else {
      if (Platform.isMacOS) {
        return 'assets/tray_no_color_off.png';
      } else {
        return 'assets/tray_color_off.ico';
      }
    }
  }

  static Future<void> setToolTip(String toolTip) async {
    if (Platform.isLinux) {
      return;
    }
    await trayManager.setToolTip(toolTip);
  }
}
