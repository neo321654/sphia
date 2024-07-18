import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sphia/app/database/dao/rule.dart';
import 'package:sphia/app/notifier/data/outbound_tag.dart';
import 'package:sphia/core/rule/rule_model.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/widget/widget.dart';

const network = [
  '',
  'tcp',
  'udp',
];
const protocol = [
  '',
  'http',
  'tls',
];

class RuleDialog extends ConsumerStatefulWidget {
  final String title;
  final RuleModel rule;

  const RuleDialog({
    super.key,
    required this.title,
    required this.rule,
  });

  @override
  ConsumerState<RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends ConsumerState<RuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late int _outboundTag = widget.rule.outboundTag;
  final _domainController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _sourceController = TextEditingController();
  final _sourcePortController = TextEditingController();
  String _network = '';
  final _protocolController = TextEditingController();
  final _processNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outboundTags = ref.watch(outboundTagNotifierProvider);
    if (!outboundTags.containsKey(widget.rule.outboundTag)) {
      // maybe the outbound tag is deleted
      _outboundTag = outboundProxyId;
    }

    final widgets = [
      SphiaWidget.textInput(
        controller: _nameController,
        labelText: S.of(context).name,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return S.of(context).nameEnterMsg;
          }
          return null;
        },
      ),
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Outbound Tag'),
        value: _outboundTag,
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
            setState(() {
              _outboundTag = value;
            });
          }
        },
      ),
      SphiaWidget.textInput(
        controller: _domainController,
        labelText: 'Domain',
      ),
      SphiaWidget.textInput(
        controller: _ipController,
        labelText: 'IP',
      ),
      SphiaWidget.textInput(
        controller: _portController,
        labelText: 'Port',
      ),
      SphiaWidget.textInput(
        controller: _sourceController,
        labelText: 'Source',
      ),
      SphiaWidget.textInput(
        controller: _sourcePortController,
        labelText: 'Source Port',
      ),
      SphiaWidget.dropdownButton(
        value: _network,
        labelText: 'Network',
        items: network,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _network = value;
            });
          }
        },
      ),
      SphiaWidget.textInput(
        controller: _protocolController,
        labelText: 'Protocol',
      ),
      SphiaWidget.textInput(
        controller: _processNameController,
        labelText: 'Process Name',
      ),
    ];
    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, null);
          },
          child: Text(S.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              final rule = RuleModel(
                id: widget.rule.id,
                groupId: widget.rule.groupId,
                enabled: widget.rule.enabled,
                name: _nameController.text,
                outboundTag: _outboundTag,
                domain: _domainController.text.isEmpty
                    ? null
                    : _domainController.text,
                ip: _ipController.text.isEmpty ? null : _ipController.text,
                port:
                    _portController.text.isEmpty ? null : _portController.text,
                source: _sourceController.text.isEmpty
                    ? null
                    : _sourceController.text,
                sourcePort: _sourcePortController.text.isEmpty
                    ? null
                    : _sourcePortController.text,
                network: _network.isEmpty ? null : _network,
                protocol: _protocolController.text.isEmpty
                    ? null
                    : _protocolController.text,
                processName: _processNameController.text.isEmpty
                    ? null
                    : _processNameController.text,
              );
              Navigator.pop(context, rule);
            }
          },
          child: Text(S.of(context).save),
        ),
      ],
    );
  }

  void _initControllers() {
    _nameController.text = widget.rule.name;
    _domainController.text = widget.rule.domain ?? '';
    _ipController.text = widget.rule.ip ?? '';
    _portController.text = widget.rule.port ?? '';
    _sourceController.text = widget.rule.source ?? '';
    _sourcePortController.text = widget.rule.sourcePort ?? '';
    _network = widget.rule.network ?? '';
    _protocolController.text = widget.rule.protocol ?? '';
    _processNameController.text = widget.rule.processName ?? '';
  }

  void _disposeControllers() {
    _nameController.dispose();
    _domainController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _sourceController.dispose();
    _sourcePortController.dispose();
    _protocolController.dispose();
    _processNameController.dispose();
  }
}
