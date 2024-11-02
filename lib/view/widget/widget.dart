import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/l10n/generated/l10n.dart';

class SphiaWidget {
  static Widget iconButton({
    required IconData icon,
    double size = 24,
    double minSize = 24,
    double opticalSize = 24,
    void Function()? onTap,
    bool enabled = true,
    String? tooltip,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled && onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          color: Colors.transparent,
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(
              icon,
              size: size,
              opticalSize: opticalSize,
              color: enabled ? null : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  static Widget popupMenuIconButton<T>({
    required IconData icon,
    required List<PopupMenuEntry<T>> items,
    required void Function(T) onItemSelected,
  }) {
    return Builder(
      builder: (context) => iconButton(
        icon: icon,
        onTap: () async {
          final renderBox = context.findRenderObject() as RenderBox;
          final position = renderBox.localToGlobal(Offset.zero);
          final result = await showMenu<T>(
            context: context,
            position: RelativeRect.fromLTRB(
              position.dx,
              position.dy,
              position.dx + renderBox.size.width,
              position.dy + renderBox.size.height,
            ),
            items: items,
          );
          if (result != null) {
            onItemSelected(result);
          }
        },
      ),
    );
  }

  static Widget popupMenuButton<T>({
    required BuildContext context,
    required List<PopupMenuItem<T>> items,
    required void Function(T) onItemSelected,
  }) {
    return PopupMenuButton<T>(
      itemBuilder: (context) => items,
      onSelected: onItemSelected,
    );
  }

  static Widget textInput({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    bool isEditable = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      validator: validator,
      enabled: isEditable,
    );
  }

  static Widget passwordTextInput({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    required bool obscureText,
    required ValueChanged<bool> onToggle,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: iconButton(
          icon: obscureText ? Symbols.visibility : Symbols.visibility_off,
          onTap: () => onToggle(!obscureText),
        ),
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }

  static Widget pathInput({
    required TextEditingController controller,
    required String labelText,
    required String configFromat,
    String? Function(String?)? validator,
    required String editorPath,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconButton(
              icon: Symbols.folder,
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [configFromat],
                  allowMultiple: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  final path = result.files.first.path;
                  if (path != null) {
                    controller.text = path;
                  }
                }
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                return popupMenuIconButton<String>(
                  icon: Symbols.edit,
                  items: [
                    const PopupMenuItem(
                      value: '/usr/bin/kate',
                      child: Text('kate'),
                    ),
                    const PopupMenuItem(
                      value: 'C:\\Windows\\System32\\notepad.exe',
                      child: Text('notepad'),
                    ),
                    PopupMenuItem(
                      value: editorPath,
                      child: Text(editorPath),
                    ),
                  ],
                  onItemSelected: (value) async {
                    final path = controller.text;
                    final notifier = ref.read(logNotifierProvider.notifier);
                    if (path.isEmpty) {
                      notifier.warning('Path is empty');
                      return;
                    }
                    if (await File(value).exists()) {
                      try {
                        await Process.start(value, [controller.text]);
                      } catch (e) {
                        notifier.error('Failed to open file: $e');
                      }
                    } else {
                      notifier.error('Invalid editor path: $value');
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
      validator: validator,
    );
  }

  static Widget dropdownButton<T>({
    required T value,
    required String labelText,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static Widget routingDropdownButton({
    required RoutingProvider value,
    required String labelText,
    required void Function(RoutingProvider) onChanged,
  }) {
    const items = RoutingProvider.values;
    return DropdownButtonFormField<RoutingProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<RoutingProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget vmessDropdownButton({
    required VMessProvider value,
    required String labelText,
    required void Function(VMessProvider) onChanged,
  }) {
    const items = VMessProvider.values;
    return DropdownButtonFormField<VMessProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<VMessProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget vlessDropdownButton({
    required VlessProvider value,
    required String labelText,
    required void Function(VlessProvider) onChanged,
  }) {
    const items = VlessProvider.values;
    return DropdownButtonFormField<VlessProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<VlessProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget shadowsocksDropdownButton({
    required ShadowsocksProvider value,
    required String labelText,
    required void Function(ShadowsocksProvider) onChanged,
  }) {
    const items = ShadowsocksProvider.values;
    return DropdownButtonFormField<ShadowsocksProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<ShadowsocksProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget trojanDropdownButton({
    required TrojanProvider value,
    required String labelText,
    required void Function(TrojanProvider) onChanged,
  }) {
    const items = TrojanProvider.values;
    return DropdownButtonFormField<TrojanProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<TrojanProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget hysteriaDropdownButton({
    required HysteriaProvider value,
    required String labelText,
    required void Function(HysteriaProvider) onChanged,
  }) {
    const items = HysteriaProvider.values;
    return DropdownButtonFormField<HysteriaProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<HysteriaProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Widget customConfigServerDropdownButton({
    required CustomServerProvider value,
    required String labelText,
    required void Function(CustomServerProvider) onChanged,
  }) {
    const items = CustomServerProvider.values;
    return DropdownButtonFormField<CustomServerProvider>(
      decoration: InputDecoration(labelText: labelText),
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<CustomServerProvider>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  static Future<void> showDialogWithMsg({
    required BuildContext context,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(message, style: const TextStyle(fontSize: 14)),
          ),
          actions: [
            TextButton(
              child: Text(L10n.of(context)!.ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
