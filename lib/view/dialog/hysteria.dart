import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/view/dialog/xray.dart';
import 'package:sphia/view/widget/widget.dart';

const _hysteriaProtocolList = ['udp', 'wechat-video', 'faketcp'];
const _authTypeList = ['none', 'base64', 'str'];
const _disableMtuDiscoveryList = ['false', 'true'];

class HysteriaServerDialog extends HookWidget {
  final String title;
  final HysteriaServer server;

  const HysteriaServerDialog({
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
    final hysteriaProtocol = useState(server.hysteriaProtocol);
    final obfsController = useTextEditingController(text: server.obfs ?? '');
    final alpnController = useTextEditingController(text: server.alpn ?? '');
    final authType = useState(server.authType);
    final authPayloadController =
        useTextEditingController(text: server.authPayload);
    final sniController =
        useTextEditingController(text: server.serverName ?? '');
    final insecure = useState(server.insecure.toString());
    final upMbpsController =
        useTextEditingController(text: server.upMbps.toString());
    final downMbpsController =
        useTextEditingController(text: server.downMbps.toString());
    final recvWindowConnController = useTextEditingController(
        text: server.recvWindowConn != null
            ? server.recvWindowConn.toString()
            : '');
    final recvWindowController = useTextEditingController(
        text: server.recvWindow != null ? server.recvWindow.toString() : '');
    final disableMtuDiscovery = useState(server.disableMtuDiscovery.toString());
    final routingProvider = useState(
      RoutingProvider
          .values[server.routingProvider ?? RoutingProvider.none.index],
    );
    final protocolProvider = useState(
      HysteriaProvider
          .values[server.protocolProvider ?? HysteriaProvider.none.index],
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
      SphiaWidget.dropdownButton(
        value: hysteriaProtocol.value,
        labelText: L10n.of(context)!.hysteriaProtocol,
        items: _hysteriaProtocolList,
        onChanged: (value) {
          if (value != null) {
            hysteriaProtocol.value = value;
          }
        },
      ),
      SphiaWidget.textInput(
        controller: obfsController,
        labelText: L10n.of(context)!.obfs,
      ),
      SphiaWidget.textInput(
        controller: alpnController,
        labelText: L10n.of(context)!.alpn,
      ),
      SphiaWidget.dropdownButton(
        value: authType.value,
        labelText: L10n.of(context)!.authType,
        items: _authTypeList,
        onChanged: (value) {
          if (value != null) {
            authType.value = value;
          }
        },
      ),
      SphiaWidget.passwordTextInput(
        controller: authPayloadController,
        labelText: L10n.of(context)!.authPayload,
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
        value: insecure.value,
        labelText: L10n.of(context)!.allowInsecure,
        items: allowInsecureList,
        onChanged: (value) {
          if (value != null) {
            insecure.value = value;
          }
        },
      ),
      SphiaWidget.textInput(
        controller: upMbpsController,
        labelText: L10n.of(context)!.upMbps,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.upMbpsEnterMsg;
          }
          if (int.tryParse(value) == null) {
            return L10n.of(context)!.upMbpsInvalidMsg;
          }
          return null;
        },
      ),
      SphiaWidget.textInput(
        controller: downMbpsController,
        labelText: L10n.of(context)!.downMbps,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.downMbpsEnterMsg;
          }
          if (int.tryParse(value) == null) {
            return L10n.of(context)!.downMbpsInvalidMsg;
          }
          return null;
        },
      ),
      SphiaWidget.textInput(
        controller: recvWindowConnController,
        labelText: L10n.of(context)!.recvWindowConn,
        validator: (value) {
          if (value != null && value.trim().isNotEmpty) {
            if (int.tryParse(value) == null) {
              return L10n.of(context)!.recvWindowConnInvalidMsg;
            }
          }
          return null;
        },
      ),
      SphiaWidget.textInput(
        controller: recvWindowController,
        labelText: L10n.of(context)!.recvWindow,
        validator: (value) {
          if (value != null && value.trim().isNotEmpty) {
            if (int.tryParse(value) == null) {
              return L10n.of(context)!.recvWindowInvalidMsg;
            }
          }
          return null;
        },
      ),
      SphiaWidget.dropdownButton(
        value: disableMtuDiscovery.value,
        labelText: L10n.of(context)!.disableMtuDiscovery,
        items: _disableMtuDiscoveryList,
        onChanged: (value) {
          if (value != null) {
            disableMtuDiscovery.value = value;
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
      SphiaWidget.hysteriaDropdownButton(
        value: protocolProvider.value,
        labelText: L10n.of(context)!.hysteriaProvider,
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
              final server = HysteriaServer(
                id: this.server.id,
                groupId: this.server.groupId,
                protocol: this.server.protocol,
                address: addressController.text,
                port: int.parse(portController.text),
                uplink: this.server.uplink,
                downlink: this.server.downlink,
                remark: remarkController.text,
                hysteriaProtocol: hysteriaProtocol.value,
                obfs: obfsController.text.trim().isNotEmpty
                    ? obfsController.text
                    : null,
                alpn: alpnController.text.trim().isNotEmpty
                    ? alpnController.text
                    : null,
                authType: authType.value,
                authPayload: authPayloadController.text.trim().isNotEmpty
                    ? authPayloadController.text
                    : '',
                serverName: sniController.text.trim().isNotEmpty
                    ? sniController.text
                    : null,
                insecure: insecure.value == 'true',
                upMbps: int.parse(upMbpsController.text),
                downMbps: int.parse(downMbpsController.text),
                recvWindowConn: recvWindowConnController.text.trim().isNotEmpty
                    ? int.parse(recvWindowConnController.text)
                    : null,
                recvWindow: recvWindowController.text.trim().isNotEmpty
                    ? int.parse(recvWindowController.text)
                    : null,
                disableMtuDiscovery: disableMtuDiscovery.value == 'true',
                routingProvider: routingProvider.value == RoutingProvider.none
                    ? null
                    : routingProvider.value.index,
                protocolProvider:
                    protocolProvider.value == HysteriaProvider.none
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
