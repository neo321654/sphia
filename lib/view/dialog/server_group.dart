import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/widget/widget.dart';

class ServerGroupDialog extends HookWidget {
  final String title;
  final (String groupName, String subscription) serverGroup;

  const ServerGroupDialog({
    super.key,
    required this.title,
    required this.serverGroup,
  });

  @override
  Widget build(BuildContext context) {
    final groupNameController = useTextEditingController(text: serverGroup.$1);
    final subscriptionController =
        useTextEditingController(text: serverGroup.$2);
    final fetchSubscription = useState(false);
    final isEdit = serverGroup.$1.isNotEmpty;
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return AlertDialog(
      scrollable: true,
      title: Text(title),
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
            SphiaWidget.textInput(
              controller: subscriptionController,
              labelText: L10n.of(context)!.subscription,
            ),
            if (!isEdit)
              SphiaWidget.dropdownButton(
                value: L10n.of(context)!.no,
                labelText: L10n.of(context)!.fetchSubscription,
                items: [L10n.of(context)!.no, L10n.of(context)!.yes],
                onChanged: (value) {
                  if (value != null) {
                    fetchSubscription.value = value == L10n.of(context)!.yes;
                  }
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
                (
                  groupNameController.text.trim(),
                  subscriptionController.text.trim(),
                  fetchSubscription.value
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
