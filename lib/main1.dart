import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/server/custom_config/server.dart';
import 'package:sphia/server/hysteria/server.dart';
import 'package:sphia/server/server_model.dart';
import 'package:sphia/server/shadowsocks/server.dart';
import 'package:sphia/server/trojan/server.dart';
import 'package:sphia/server/xray/server.dart';
import 'package:sphia/view/dialog/custom_config.dart';
import 'package:sphia/view/dialog/hysteria.dart';
import 'package:sphia/view/dialog/shadowsocks.dart';
import 'package:sphia/view/dialog/trojan.dart';
import 'package:sphia/view/dialog/xray.dart';
import 'package:sphia/view/widget/widget.dart';

import 'app/database/database.dart';
import 'app/notifier/config/server_config.dart';
import 'app/notifier/core_state.dart';
import 'app/notifier/proxy.dart';
import 'flutter_v2ray/lib/flutter_v2ray.dart';
import 'l10n/generated/l10n.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
      
        title: 'Flutter V2Ray',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const Scaffold(
          body: HomePage(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
    },
  );
  final config = TextEditingController();
  bool proxyOnly = false;
  final bypassSubnetController = TextEditingController();
  List<String> bypassSubnets = [];
  String? coreVersion;

  String remark = "Default Remark";

  void connect() async {
    if (await flutterV2ray.requestPermission()) {
      flutterV2ray.startV2Ray(
        remark: remark,
        config: config.text,
        proxyOnly: proxyOnly,
        bypassSubnets: bypassSubnets,
        notificationDisconnectButtonName: "DISCONNECT",
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission Denied'),
          ),
        );
      }
    }
  }

  void importConfig() async {
    if (await Clipboard.hasStrings()) {
      try {
        final String link =
            (await Clipboard.getData('text/plain'))?.text?.trim() ?? '';
        final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(link);

        remark = v2rayURL.remark;
        config.text = v2rayURL.getFullConfiguration();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Success',
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $error',
              ),
            ),
          );
        }
      }
    }
  }

  void delay() async {
    late int delay;
    if (v2rayStatus.value.state == 'CONNECTED') {
      delay = await flutterV2ray.getConnectedServerDelay();
    } else {
      delay = await flutterV2ray.getServerDelay(config: config.text);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${delay}ms',
        ),
      ),
    );
  }

  void bypassSubnet() {
    bypassSubnetController.text = bypassSubnets.join("\n");
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Subnets:',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: bypassSubnetController,
                maxLines: 5,
                minLines: 5,
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  bypassSubnets =
                      bypassSubnetController.text.trim().split('\n');
                  if (bypassSubnets.first.isEmpty) {
                    bypassSubnets = [];
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // flutterV2ray
    //     .initializeV2Ray(
    //   notificationIconResourceType: "mipmap",
    //   notificationIconResourceName: "ic_launcher",
    // )
    //     .then((value) async {
    //   coreVersion = await flutterV2ray.getCoreVersion();
    //   setState(() {});
    // });

    flutterV2ray
        .initializeV2Ray(
      notificationIconResourceType: "mipmap",
      notificationIconResourceName: "ic_launcher",
    );



      // coreVersion =  flutterV2ray.getCoreVersion();

  }

  @override
  void dispose() {
    config.dispose();
    bypassSubnetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            const Text(
              'V2Ray Config (json):',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: config,
              maxLines: 10,
              minLines: 10,
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: v2rayStatus,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Text(value.state),
                    const SizedBox(height: 10),
                    Text(value.duration),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Speed:'),
                        const SizedBox(width: 10),
                        Text(value.uploadSpeed.toString()),
                        const Text('↑'),
                        const SizedBox(width: 10),
                        Text(value.downloadSpeed.toString()),
                        const Text('↓'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Traffic:'),
                        const SizedBox(width: 10),
                        Text(value.upload.toString()),
                        const Text('↑'),
                        const SizedBox(width: 10),
                        Text(value.download.toString()),
                        const Text('↓'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Core Version: $coreVersion'),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  ElevatedButton(
                    // onPressed: connect,
                    onPressed: (){
                      _toggleServer(context);
                    },
                    child: const Text('Connect'),
                  ),
                  ElevatedButton(
                    onPressed: () => flutterV2ray.stopV2Ray(),
                    child: const Text('Disconnect'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => proxyOnly = !proxyOnly),
                    child: Text(proxyOnly ? 'Proxy Only' : 'VPN Mode'),
                  ),
                  ElevatedButton(
                    onPressed: importConfig,
                    child: const Text(
                      'Import from v2ray share link (clipboard)',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: delay,
                    child: const Text('Server Delay'),
                  ),
                  ElevatedButton(
                    onPressed: bypassSubnet,
                    child: const Text('Bypass Subnet'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _toggleServer(context) async {
  // final context = ref.context;
  // final serverConfig = ref.read(serverConfigNotifierProvider);
  // final coreStateNotifier = ref.read(coreStateNotifierProvider.notifier);
  // final id = serverConfig.selectedServerId;
  // final server = await serverDao.getServerModelById(id);
  // if (server == null) {
  //   final proxyState = ref.read(proxyNotifierProvider);
  //   if (proxyState.coreRunning) {
  //     await coreStateNotifier.stopCores();
  //   } else {
  //     if (!context.mounted) {
  //       return;
  //     }
  //     await SphiaWidget.showDialogWithMsg(
  //       context: context,
  //       message: L10n.of(context)!.noServerSelected,
  //     );
  //   }
  //   return;
  // }
  // try {
  //   await coreStateNotifier.toggleCores(server);
  // } on Exception catch (e) {
  //   if (!context.mounted) {
  //     return;
  //   }
  //   await SphiaWidget.showDialogWithMsg(
  //     context: context,
  //     message: '${L10n.of(context)!.coreStartFailed}: $e',
  //   );
  // }

  // await coreStateNotifier.toggleCores(server);
  late final ServerModel? server;

  server = await _showEditServerDialog(
    title:
    // '${L10n.of(context)!.add} ${L10n.of(context)!.customConfig} ${L10n.of(context)!.server}',
    'Title dialog',
    server: CustomConfigServer.defaults()..groupId = 1,
    context: context,
  );



}




Future<ServerModel?> _showEditServerDialog({
  required String title,
  required ServerModel server,
  required BuildContext context,
}) async {
  if (server.protocol == Protocol.vmess ||
      server.protocol == Protocol.vless) {
    return showDialog<ServerModel>(
      context: context,
      builder: (context) =>
          XrayServerDialog(title: title, server: server as XrayServer),
    );
  } else if (server.protocol == Protocol.shadowsocks) {
    return showDialog<ServerModel>(
      context: context,
      builder: (context) => ShadowsocksServerDialog(
          title: title, server: server as ShadowsocksServer),
    );
  } else if (server.protocol == Protocol.trojan) {
    return showDialog<ServerModel>(
      context: context,
      builder: (context) =>
          TrojanServerDialog(title: title, server: server as TrojanServer),
    );
  } else if (server.protocol == Protocol.hysteria) {
    return showDialog<ServerModel>(
      context: context,
      builder: (context) => HysteriaServerDialog(
          title: title, server: server as HysteriaServer),
    );
  } else if (server.protocol == Protocol.custom) {
    return showDialog<ServerModel>(
      context: context,
      builder: (context) => CustomConfigServerDialog(
          title: title, server: server as CustomConfigServer),
    );
  }
  return null;
}


String jsonConfig = """
{
  "log": {
    "access": "",
    "error": "",
    "loglevel": "error",
    "dnsLog": false
  },
  "inbounds": [
    {
      "tag": "in_proxy",
      "port": 1080,
      "protocol": "socks",
      "listen": "127.0.0.1",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "userLevel": 8
      },
      "sniffing": {
        "enabled": false
      }
    }
  ],
  "outbounds": [
    {
      "tag": "proxy",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "netherlands-07.ptu.ink",
            "port": 443,
            "users": [
              {
                "id": "0f64c99d-bca6-49ba-8766-efe50b2e745c",
                "security": "auto",
                "level": 8,
                "encryption": "none",
                "flow": "xtls-rprx-vision"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "tcpSettings": {
          "header": {
            "type": "none"
          }
        },
        "realitySettings": {
          "allowInsecure": true,
          "serverName": "www.microsoft.com",
          "fingerprint": "chrome",
          "show": false,
          "publicKey": "4e6cn5kOyJ8z_KUcrXNbJ1P2MhYSpLtbf46xe5ntU2w",
          "shortId": "b37ca0618a39587e",
          "spiderX": ""
        }
      },
      "mux": {
        "enabled": false,
        "concurrency": 8
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIp"
      }
    },
    {
      "tag": "blackhole",
      "protocol": "blackhole"
    }
  ],
  "dns": {
    "servers": [
      "8.8.8.8",
      "8.8.4.4"
    ]
  },
  "routing": {
    "domainStrategy": "UseIp"
  }
}""";