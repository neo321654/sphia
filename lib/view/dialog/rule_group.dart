import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/widget/widget.dart';

class RuleGroupDialog extends HookWidget {
  final String title;
  final String groupName;

  const RuleGroupDialog({
    super.key,
    required this.title,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    final groupNameController = useTextEditingController(text: groupName);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return AlertDialog(
      title: Text(title),
      scrollable: true,
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SphiaWidget.textInput(
              controller: groupNameController,
              labelText: L10n.of(context)!.groupName,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return L10n.of(context)!.groupNameEnterMsg;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(L10n.of(context)!.cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(L10n.of(context)!.save),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                groupNameController.text.trim(),
              );
            }
          },
        ),
      ],
    );
  }
}
