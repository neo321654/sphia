import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/view/widget/widget.dart';

const shadowsocksEncryptionList = [
  'none',
  'plain',
  'aes-128-gcm',
  'aes-192-gcm',
  'aes-256-gcm',
  'chacha20-ietf-poly1305',
  'xchacha20-ietf-poly1305',
  '2022-blake3-aes-128-gcm',
  '2022-blake3-aes-256-gcm',
  '2022-blake3-chacha20-poly1305',
  'aes-128-ctr',
  'aes-192-ctr',
  'aes-256-ctr',
  'aes-128-cfb',
  'aes-192-cfb',
  'aes-256-cfb',
  'rc4-md5',
  'chacha20-ietf',
  'xchacha20',
];

class ShadowsocksServerDialog extends HookWidget {
  final String title;
  final ShadowsocksServer server;

  const ShadowsocksServerDialog({
    super.key,
    required this.title,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final remarkController = useTextEditingController(text: server.remark);
    final addressController = useTextEditingController(text: server.address);
    final portController =
        useTextEditingController(text: server.port.toString());
    final passwordController =
        useTextEditingController(text: server.authPayload);
    final encryption = useState(server.encryption);
    final pluginController =
        useTextEditingController(text: server.plugin ?? '');
    final pluginOptsController =
        useTextEditingController(text: server.pluginOpts ?? '');
    final routingProvider = useState(
      RoutingProvider
          .values[server.routingProvider ?? RoutingProvider.none.index],
    );
    final protocolProvider = useState(
      ShadowsocksProvider
          .values[server.protocolProvider ?? ShadowsocksProvider.none.index],
    );
    final obscureText = useState(true);

    final widgets = [
      SphiaWidget.textInput(
        controller: remarkController,
        labelText: L10n.of(context)!.remark,
      ),
      SphiaWidget.textInput(
        controller: addressController,
        labelText: L10n.of(context)!.address,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.addressEnterMsg;
          }
          return null;
        },
      ),
      SphiaWidget.textInput(
        controller: portController,
        labelText: L10n.of(context)!.port,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.portEnterMsg;
          }
          late final int? newValue;
          if ((newValue = int.tryParse(value)) == null ||
              newValue! < 0 ||
              newValue > 65535) {
            return L10n.of(context)!.portInvalidMsg;
          }
          return null;
        },
      ),
      SphiaWidget.passwordTextInput(
        controller: passwordController,
        labelText: L10n.of(context)!.password,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.passwordEnterMsg;
          }
          return null;
        },
        obscureText: obscureText.value,
        onToggle: (value) {
          obscureText.value = value;
        },
      ),
      SphiaWidget.dropdownButton(
        value: encryption.value,
        labelText: L10n.of(context)!.encryption,
        items: shadowsocksEncryptionList,
        onChanged: (value) {
          if (value != null) {
            encryption.value = value;
          }
        },
      ),
      SphiaWidget.textInput(
        controller: pluginController,
        labelText: L10n.of(context)!.plugin,
      ),
      SphiaWidget.textInput(
        controller: pluginOptsController,
        labelText: L10n.of(context)!.pluginOpts,
      ),
      SphiaWidget.routingDropdownButton(
        value: routingProvider.value,
        labelText: L10n.of(context)!.routingProvider,
        onChanged: (value) {
          routingProvider.value = value;
        },
      ),
      SphiaWidget.shadowsocksDropdownButton(
        value: protocolProvider.value,
        labelText: L10n.of(context)!.shadowsocksProvider,
        onChanged: (value) {
          protocolProvider.value = value;
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
              final server = ShadowsocksServer(
                id: this.server.id,
                groupId: this.server.groupId,
                protocol: this.server.protocol,
                address: addressController.text,
                port: int.parse(portController.text),
                uplink: this.server.uplink,
                downlink: this.server.downlink,
                remark: remarkController.text,
                authPayload: passwordController.text,
                encryption: encryption.value,
                plugin: pluginController.text.trim().isNotEmpty
                    ? pluginController.text
                    : null,
                pluginOpts: pluginOptsController.text.trim().isNotEmpty
                    ? pluginOptsController.text
                    : null,
                routingProvider: routingProvider.value == RoutingProvider.none
                    ? null
                    : routingProvider.value.index,
                protocolProvider:
                    protocolProvider.value == ShadowsocksProvider.none
                        ? null
                        : protocolProvider.value.index,
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
