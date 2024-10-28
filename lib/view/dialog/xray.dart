import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sphia/app/config/sphia.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/xray/server.dart';
import 'package:sphia/view/widget/widget.dart';

const _vmessEncryptionList = [
  'auto',
  'aes-128-gcm',
  'chacha20-poly1305',
  'none',
  'zero',
];
const _vlessEncryptionList = ['none'];
const _vlessFlowList = ['none', 'xtls-rprx-vision'];
const _vProtocolTransportList = ['tcp', 'ws', 'grpc', 'httpupgrade'];
const _grpcModeList = ['gun', 'multi'];
const _tlsList = ['none', 'tls', 'reality'];
const fingerPrintList = [
  'none',
  'random',
  'randomized',
  'chrome',
  'firefox',
  'safari',
  'ios',
  'android',
  'edge',
  '360',
  'qq',
];
const _realityFingerPrintList = [
  'random',
  'randomized',
  'chrome',
  'firefox',
  'safari',
  'ios',
  'android',
  'edge',
  '360',
  'qq',
];
const allowInsecureList = ['false', 'true'];

class XrayServerDialog extends HookWidget {
  final String title;
  final XrayServer server;

  const XrayServerDialog({
    super.key,
    required this.title,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final protocol = useState(server.protocol);
    final remarkController = useTextEditingController(text: server.remark);
    final addressController = useTextEditingController(text: server.address);
    final portController =
        useTextEditingController(text: server.port.toString());
    final uuidController = useTextEditingController(text: server.authPayload);
    final alterIdController = useTextEditingController(
        text: server.alterId == null ? '0' : server.alterId.toString());
    final encryption = useState(server.encryption);
    final flow = useState(server.flow ?? 'none');
    final transport = useState(server.transport);
    final hostController = useTextEditingController(text: server.host ?? '');
    final pathController = useTextEditingController(text: server.path ?? '');
    final grpcMode = useState(server.grpcMode ?? 'gun');
    final serviceNameController =
        useTextEditingController(text: server.serviceName ?? '');
    final tls = useState(server.tls);
    final sniController =
        useTextEditingController(text: server.serverName ?? '');
    final fingerprint = useState(server.fingerprint ?? 'none');
    final publicKeyController =
        useTextEditingController(text: server.publicKey ?? '');
    final shortIdController =
        useTextEditingController(text: server.shortId ?? '');
    final spiderXController =
        useTextEditingController(text: server.spiderX ?? '');
    final allowInsecure = useState(server.allowInsecure.toString());
    final routingProvider = useState(
      RoutingProvider
          .values[server.routingProvider ?? RoutingProvider.none.index],
    );
    final vmessProvider = useState(
      VMessProvider.values[server.protocolProvider ?? VMessProvider.none.index],
    );
    final vlessProvider = useState(
      VlessProvider.values[server.protocolProvider ?? VlessProvider.none.index],
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
        controller: uuidController,
        labelText: L10n.of(context)!.uuid,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.uuidEnterMsg;
          }
          return null;
        },
        obscureText: obscureText.value,
        onToggle: (value) {
          obscureText.value = value;
        },
      ),
      if (protocol.value == Protocol.vmess) ...[
        SphiaWidget.textInput(
          controller: alterIdController,
          labelText: L10n.of(context)!.alterId,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return L10n.of(context)!.alterIdEnterMsg;
            }
            if (int.tryParse(value) == null) {
              return L10n.of(context)!.alterIdInvalidMsg;
            }
            return null;
          },
        ),
      ],
      SphiaWidget.dropdownButton(
        value: encryption.value,
        labelText: L10n.of(context)!.encryption,
        items: protocol.value == Protocol.vmess
            ? _vmessEncryptionList
            : _vlessEncryptionList,
        onChanged: (value) {
          if (value != null) {
            encryption.value = value;
          }
        },
      ),
      if (protocol.value == Protocol.vless) ...[
        SphiaWidget.dropdownButton(
          value: flow.value,
          labelText: L10n.of(context)!.flow,
          items: _vlessFlowList,
          onChanged: (value) {
            if (value != null) {
              flow.value = value;
            }
          },
        ),
      ],
      SphiaWidget.dropdownButton(
        value: transport.value,
        labelText: L10n.of(context)!.transport,
        items: _vProtocolTransportList,
        onChanged: (value) {
          if (value != null) {
            transport.value = value;
          }
        },
      ),
      if (transport.value == 'grpc') ...[
        SphiaWidget.dropdownButton(
          value: grpcMode.value,
          labelText: L10n.of(context)!.grpcMode,
          items: _grpcModeList,
          onChanged: (value) {
            if (value != null) {
              grpcMode.value = value;
            }
          },
        ),
        SphiaWidget.textInput(
          controller: serviceNameController,
          labelText: L10n.of(context)!.grpcServiceName,
        ),
      ],
      if (transport.value == 'ws' || transport.value == 'httpupgrade') ...[
        SphiaWidget.textInput(
          controller: hostController,
          labelText: L10n.of(context)!.host,
        ),
        SphiaWidget.textInput(
          controller: pathController,
          labelText: L10n.of(context)!.path,
        ),
      ],
      SphiaWidget.dropdownButton(
        value: tls.value,
        labelText: L10n.of(context)!.tls,
        items: _tlsList,
        onChanged: (value) {
          if (value != null) {
            if (value == 'reality') {
              fingerprint.value =
                  _realityFingerPrintList.contains(fingerprint.value)
                      ? fingerprint.value
                      : 'random';
            } else {
              fingerprint.value = fingerPrintList.contains(fingerprint.value)
                  ? fingerprint.value
                  : 'none';
            }
            tls.value = value;
          }
        },
      ),
      if (tls.value == 'tls') ...[
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
      ],
      if (tls.value == 'reality') ...[
        SphiaWidget.textInput(
          controller: sniController,
          labelText: L10n.of(context)!.sni,
        ),
        SphiaWidget.dropdownButton(
          value: fingerprint.value,
          labelText: L10n.of(context)!.fingerPrint,
          items: _realityFingerPrintList,
          onChanged: (value) {
            if (value != null) {
              fingerprint.value = value;
            }
          },
        ),
        SphiaWidget.textInput(
          controller: publicKeyController,
          labelText: L10n.of(context)!.publicKey,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return L10n.of(context)!.publicKeyEnterMsg;
            }
            return null;
          },
        ),
        SphiaWidget.textInput(
          controller: shortIdController,
          labelText: L10n.of(context)!.shortId,
        ),
        SphiaWidget.textInput(
          controller: spiderXController,
          labelText: L10n.of(context)!.spiderX,
        ),
      ],
      SphiaWidget.routingDropdownButton(
        value: routingProvider.value,
        labelText: L10n.of(context)!.routingProvider,
        onChanged: (value) {
          routingProvider.value = value;
        },
      ),
      if (protocol.value == Protocol.vmess) ...[
        SphiaWidget.vmessDropdownButton(
          value: vmessProvider.value,
          labelText: L10n.of(context)!.vmessProvider,
          onChanged: (value) {
            vmessProvider.value = value;
          },
        ),
      ],
      if (protocol.value == Protocol.vless) ...[
        SphiaWidget.vlessDropdownButton(
          value: vlessProvider.value,
          labelText: L10n.of(context)!.vlessProvider,
          onChanged: (value) {
            vlessProvider.value = value;
          },
        ),
      ],
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
              final server = XrayServer(
                id: this.server.id,
                groupId: this.server.groupId,
                protocol: protocol.value,
                address: addressController.text,
                port: int.parse(portController.text),
                uplink: this.server.uplink,
                downlink: this.server.downlink,
                remark: remarkController.text,
                authPayload: uuidController.text,
                alterId: protocol.value == Protocol.vmess
                    ? int.parse(alterIdController.text)
                    : null,
                encryption: protocol.value == Protocol.vmess
                    ? encryption.value
                    : 'none',
                flow: protocol.value == Protocol.vless
                    ? flow.value != 'none'
                        ? flow.value
                        : null
                    : null,
                transport: transport.value,
                host:
                    transport.value == 'ws' || transport.value == 'httpupgrade'
                        ? (hostController.text.trim().isNotEmpty
                            ? hostController.text
                            : null)
                        : null,
                path:
                    transport.value == 'ws' || transport.value == 'httpupgrade'
                        ? (pathController.text.trim().isNotEmpty
                            ? pathController.text
                            : null)
                        : null,
                grpcMode: transport.value == 'grpc' ? grpcMode.value : null,
                serviceName: transport.value == 'grpc'
                    ? (serviceNameController.text.trim().isNotEmpty
                        ? serviceNameController.text
                        : null)
                    : null,
                tls: tls.value,
                serverName: sniController.text.trim().isNotEmpty
                    ? sniController.text
                    : null,
                fingerprint: tls.value == 'tls' || tls.value == 'reality'
                    ? fingerprint.value != 'none'
                        ? fingerprint.value
                        : null
                    : null,
                publicKey: tls.value == 'reality'
                    ? publicKeyController.text.trim()
                    : null,
                shortId: tls.value == 'reality'
                    ? (shortIdController.text.trim().isNotEmpty
                        ? shortIdController.text
                        : null)
                    : null,
                spiderX: tls.value == 'reality'
                    ? (spiderXController.text.trim().isNotEmpty
                        ? spiderXController.text
                        : null)
                    : null,
                allowInsecure: allowInsecure.value == 'true',
                routingProvider: routingProvider.value == RoutingProvider.none
                    ? null
                    : routingProvider.value.index,
                protocolProvider: protocol.value == Protocol.vmess
                    ? vmessProvider.value == VMessProvider.none
                        ? null
                        : vmessProvider.value.index
                    : protocol.value == Protocol.vless
                        ? vlessProvider.value == VlessProvider.none
                            ? null
                            : vlessProvider.value.index
                        : null,
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
