import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/view/dialog/xray.dart';
import 'package:sphia/view/widget/widget.dart';

class TrojanServerDialog extends HookWidget {
  final String title;
  final TrojanServer server;

  const TrojanServerDialog({
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
    final sniController =
        useTextEditingController(text: server.serverName ?? '');
    final fingerprint = useState(server.fingerprint ?? 'none');
    final allowInsecure = useState(server.allowInsecure.toString());
    final routingProvider = useState(
      RoutingProvider
          .values[server.routingProvider ?? RoutingProvider.none.index],
    );
    final protocolProvider = useState(
      TrojanProvider
          .values[server.protocolProvider ?? TrojanProvider.none.index],
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
      SphiaWidget.textInput(
        controller: sniController,
        labelText: L10n.of(context)!.sni,
      ),
      SphiaWidget.dropdownButton(
        value: fingerprint.value,
        labelText: L10n.of(context)!.fingerPrint,
        items: fingerPrintList,
        onChanged: (value) {
          if (value != null) {
            fingerprint.value = value;
          }
        },
      ),
      SphiaWidget.dropdownButton(
        value: allowInsecure.value,
        labelText: L10n.of(context)!.allowInsecure,
        items: allowInsecureList,
        onChanged: (value) {
          if (value != null) {
            allowInsecure.value = value;
          }
        },
      ),
      SphiaWidget.routingDropdownButton(
        value: routingProvider.value,
        labelText: L10n.of(context)!.routingProvider,
        onChanged: (value) {
          routingProvider.value = value;
        },
      ),
      SphiaWidget.trojanDropdownButton(
        value: protocolProvider.value,
        labelText: L10n.of(context)!.trojanProvider,
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
              final server = TrojanServer(
                id: this.server.id,
                groupId: this.server.groupId,
                protocol: this.server.protocol,
                address: addressController.text,
                port: int.parse(portController.text),
                uplink: this.server.uplink,
                downlink: this.server.downlink,
                remark: remarkController.text,
                authPayload: passwordController.text,
                serverName: sniController.text.trim().isNotEmpty
                    ? sniController.text
                    : null,
                fingerprint:
                    fingerprint.value != 'none' ? fingerprint.value : null,
                allowInsecure: allowInsecure.value == 'true',
                routingProvider: routingProvider.value == RoutingProvider.none
                    ? null
                    : routingProvider.value.index,
                protocolProvider: protocolProvider.value == TrojanProvider.none
                    ? null
                    : protocolProvider.value.index,
                tls: 'tls',
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
