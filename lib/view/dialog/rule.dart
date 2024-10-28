import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/notifier/data/outbound_tag.dart';
import 'package:sphia/core/rule/rule_model.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/widget/widget.dart';

const _networkList = [
  '',
  'tcp',
  'udp',
];

class RuleDialog extends HookConsumerWidget {
  final String title;
  final RuleModel rule;

  const RuleDialog({
    super.key,
    required this.title,
    required this.rule,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: rule.name);
    final outboundTag = useState(rule.outboundTag);
    final domainController = useTextEditingController(text: rule.domain ?? '');
    final ipController = useTextEditingController(text: rule.ip ?? '');
    final portController = useTextEditingController(text: rule.port ?? '');
    final sourceController = useTextEditingController(text: rule.source ?? '');
    final sourcePortController =
        useTextEditingController(text: rule.sourcePort ?? '');
    final network = useState(rule.network ?? '');
    final protocolController =
        useTextEditingController(text: rule.protocol ?? '');
    final processNameController =
        useTextEditingController(text: rule.processName ?? '');

    final outboundTags = ref.watch(outboundTagNotifierProvider);
    if (!outboundTags.containsKey(rule.outboundTag)) {
      // maybe the outbound tag is deleted
      outboundTag.value = outboundProxyId;
    }

    final widgets = [
      SphiaWidget.textInput(
        controller: nameController,
        labelText: L10n.of(context)!.name,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return L10n.of(context)!.nameEnterMsg;
          }
          return null;
        },
      ),
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Outbound Tag'),
        value: outboundTag.value,
        items: outboundTags.entries
            .map(
              (entry) => DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            outboundTag.value = value;
          }
        },
      ),
      SphiaWidget.textInput(
        controller: domainController,
        labelText: 'Domain',
      ),
      SphiaWidget.textInput(
        controller: ipController,
        labelText: 'IP',
      ),
      SphiaWidget.textInput(
        controller: portController,
        labelText: 'Port',
      ),
      SphiaWidget.textInput(
        controller: sourceController,
        labelText: 'Source',
      ),
      SphiaWidget.textInput(
        controller: sourcePortController,
        labelText: 'Source Port',
      ),
      SphiaWidget.dropdownButton(
        value: network.value,
        labelText: 'Network',
        items: _networkList,
        onChanged: (value) {
          if (value != null) {
            network.value = value;
          }
        },
      ),
      SphiaWidget.textInput(
        controller: protocolController,
        labelText: 'Protocol',
      ),
      SphiaWidget.textInput(
        controller: processNameController,
        labelText: 'Process Name',
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
              final rule = RuleModel(
                id: this.rule.id,
                groupId: this.rule.groupId,
                enabled: this.rule.enabled,
                name: nameController.text,
                outboundTag: outboundTag.value,
                domain: domainController.text.isEmpty
                    ? null
                    : domainController.text,
                ip: ipController.text.isEmpty ? null : ipController.text,
                port: portController.text.isEmpty ? null : portController.text,
                source: sourceController.text.isEmpty
                    ? null
                    : sourceController.text,
                sourcePort: sourcePortController.text.isEmpty
                    ? null
                    : sourcePortController.text,
                network: network.value.isEmpty ? null : network.value,
                protocol: protocolController.text.isEmpty
                    ? null
                    : protocolController.text,
                processName: processNameController.text.isEmpty
                    ? null
                    : processNameController.text,
              );
              Navigator.pop(context, rule);
            }
          },
          child: Text(L10n.of(context)!.save),
        ),
      ],
    );
  }
}
