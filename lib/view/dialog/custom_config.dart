import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/custom_config/server.dart';
import 'package:sphia/view/widget/widget.dart';

const _configFormatList = ['json'];
const portUnset = 131071;

class CustomConfigServerDialog extends HookConsumerWidget {
  final String title;
  final CustomConfigServer server;

  const CustomConfigServerDialog({
    super.key,
    required this.title,
    required this.server,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final remarkController = useTextEditingController(text: server.remark);
    final portInDb = server.port;
    final port = portInDb & 0x1FFFF;
    final httpPortController = useTextEditingController(
      text: port == portUnset ? '-1' : port.toString(),
    );
    final apiPort = (portInDb >> 17) & 0x1FFFF;
    final apiPortController = useTextEditingController(
      text: apiPort == portUnset ? '-1' : apiPort.toString(),
    );
    final configFilePathController = useTextEditingController();
    final tempConfigFile = useState<File?>(null);

    useEffect(() {
      if (server.configString.isEmpty) {
        configFilePathController.text = '';
      } else {
        final tempPath = IoHelper.tempPath;
        tempConfigFile.value =
            File(p.join(tempPath, 'tempCustom.${server.configFormat}'));
        if (tempConfigFile.value!.existsSync()) {
          tempConfigFile.value!.deleteSync();
        }
        tempConfigFile.value!.writeAsStringSync(server.configString);
        configFilePathController.text = tempConfigFile.value!.path;
      }
      return () {
        if (tempConfigFile.value != null) {
          tempConfigFile.value!.deleteSync();
        }
      };
    }, []);

    final configFormat = useState(server.configFormat);
    final coreProvider = useState(
      CustomServerProvider
          .values[server.protocolProvider ?? CustomServerProvider.sing.index],
    );

    final widgets = [
      SphiaWidget.textInput(
        controller: remarkController,
        labelText: L10n.of(context)!.remark,
      ),
      SphiaWidget.textInput(
        controller: httpPortController,
        labelText: L10n.of(context)!.customHttpPort,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.portEnterMsg;
          }
          final newValue = int.tryParse(value);
          if (newValue == null || newValue < -1 || newValue > 65535) {
            return L10n.of(context)!.portInvalidMsg;
          }
          return null;
        },
      ),
      SphiaWidget.textInput(
        controller: apiPortController,
        labelText: L10n.of(context)!.customCoreApiPort,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.portEnterMsg;
          }
          final newValue = int.tryParse(value);
          if (newValue == null || newValue < -1 || newValue > 65535) {
            return L10n.of(context)!.portInvalidMsg;
          }
          return null;
        },
      ),
      SphiaWidget.pathInput(
        controller: configFilePathController,
        labelText: L10n.of(context)!.configFilePath,
        configFromat: configFormat.value,
        validator: (value) {
          if (value != null) {
            if (value.isEmpty) {
              return L10n.of(context)!.pathCannotBeEmpty;
            }
            if (!File(value).existsSync()) {
              return L10n.of(context)!.fileDoesNotExist;
            }
          }
          return null;
        },
        editorPath: ref.read(sphiaConfigNotifierProvider).editorPath,
      ),
      SphiaWidget.dropdownButton(
        value: configFormat.value,
        labelText: L10n.of(context)!.configFormat,
        items: _configFormatList,
        onChanged: (value) {
          if (value != null) {
            configFormat.value = value;
          }
        },
      ),
      SphiaWidget.customConfigServerDropdownButton(
        value: coreProvider.value,
        labelText: L10n.of(context)!.coreProvider,
        onChanged: (value) {
          coreProvider.value = value;
        },
      ),
    ];

    return AlertDialog(
      title: Text(title),
      scrollable: true,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState?.validate() == true) {
              final configFile = File(configFilePathController.text);
              late final String configString;
              try {
                configString = configFile.readAsStringSync();
              } catch (e) {
                SphiaWidget.showDialogWithMsg(
                  context: context,
                  message: L10n.of(context)!.readConfigFileFailed(e.toString()),
                );
                return;
              }
              final port = int.parse(httpPortController.text);
              final apiPort = int.parse(apiPortController.text);
              final portInDb = (port == portUnset ? portUnset : port) |
                  ((apiPort == portUnset ? portUnset : apiPort) << 17);
              final server = CustomConfigServer(
                id: this.server.id,
                groupId: this.server.groupId,
                protocol: this.server.protocol,
                address: '',
                port: portInDb,
                uplink: this.server.uplink,
                downlink: this.server.downlink,
                remark: remarkController.text,
                protocolProvider: coreProvider.value.index,
                configString: configString,
                configFormat: configFormat.value,
              );
              Navigator.pop(context, server);
            }
          },
          child: Text(L10n.of(context)!.save),
        ),
      ],
    );
  }
}
