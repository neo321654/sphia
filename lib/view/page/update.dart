import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sphia/app/helper/io.dart';
import 'package:sphia/app/helper/update.dart';
import 'package:sphia/core/updater.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/card/core_card.dart';
import 'package:sphia/view/widget/widget.dart';

enum MenuAction { scanCore, importCore }

enum ImportCoreAction { singleCore, multipleCores }

class UpdatePage extends ConsumerWidget with UpdateHelper {
  const UpdatePage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final appBar = AppBar(
    //   title: Text(
    //     L10n.of(context)!.update,
    //   ),
    //   elevation: 0,
    //   actions: [
    //     Builder(
    //       builder: (context) => SphiaWidget.popupMenuButton<MenuAction>(
    //         context: context,
    //         items: [
    //           PopupMenuItem(
    //             value: MenuAction.scanCore,
    //             child: Text(L10n.of(context)!.scanCores),
    //           ),
    //           PopupMenuItem(
    //             value: MenuAction.importCore,
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 Text(L10n.of(context)!.import),
    //                 const Icon(Symbols.arrow_left),
    //               ],
    //             ),
    //           ),
    //         ],
    //         onItemSelected: (value) async {
    //           switch (value) {
    //             case MenuAction.scanCore:
    //               await ref.read(coreUpdaterProvider.notifier).scanCores();
    //               if (context.mounted) {
    //                 await SphiaWidget.showDialogWithMsg(
    //                   context: context,
    //                   message: L10n.of(context)!.scanCoresCompleted,
    //                 );
    //               }
    //               break;
    //             case MenuAction.importCore:
    //               final renderBox = context.findRenderObject() as RenderBox;
    //               final position = renderBox.localToGlobal(Offset.zero);
    //               showMenu<ImportCoreAction>(
    //                 context: context,
    //                 position: RelativeRect.fromLTRB(
    //                   position.dx,
    //                   position.dy,
    //                   position.dx + renderBox.size.width,
    //                   position.dy + renderBox.size.height,
    //                 ),
    //                 items: [
    //                   PopupMenuItem(
    //                     value: ImportCoreAction.singleCore,
    //                     child: Text(L10n.of(context)!.singleCore),
    //                   ),
    //                   PopupMenuItem(
    //                     value: ImportCoreAction.multipleCores,
    //                     child: Text(L10n.of(context)!.multipleCores),
    //                   ),
    //                 ],
    //               ).then((value) async {
    //                 if (value == null) {
    //                   return;
    //                 }
    //                 switch (value) {
    //                   case ImportCoreAction.singleCore:
    //                     final res = await ref
    //                         .read(coreUpdaterProvider.notifier)
    //                         .importCore(isMulti: false);
    //                     if (res == null || !context.mounted) {
    //                       return;
    //                     }
    //                     if (res) {
    //                       await SphiaWidget.showDialogWithMsg(
    //                         context: context,
    //                         message: L10n.of(context)!.importCoreSuccessfully,
    //                       );
    //                     } else {
    //                       await SphiaWidget.showDialogWithMsg(
    //                         context: context,
    //                         message: L10n.of(context)!.importCoreFailed,
    //                       );
    //                     }
    //                     break;
    //                   case ImportCoreAction.multipleCores:
    //                     final res = await ref
    //                         .read(coreUpdaterProvider.notifier)
    //                         .importCore(isMulti: true);
    //                     if (res == null) {
    //                       return;
    //                     }
    //                     if (res) {
    //                       await ref
    //                           .read(coreUpdaterProvider.notifier)
    //                           .scanCores();
    //                       if (!context.mounted) {
    //                         return;
    //                       }
    //                       final binPath = IoHelper.binPath;
    //                       await SphiaWidget.showDialogWithMsg(
    //                         context: context,
    //                         message:
    //                             L10n.of(context)!.importMultiCoresMsg(binPath),
    //                       );
    //                     }
    //                     break;
    //                   default:
    //                     break;
    //                 }
    //               });
    //               break;
    //             default:
    //               break;
    //           }
    //         },
    //       ),
    //     )
    //   ],
    // );
    final coreInfoStateList = ref.watch(coreInfoStateListProvider);
    return Scaffold(
      // appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: ListView.builder(
          // itemCount: coreInfoStateList.length,
          itemCount: 1,
          itemBuilder: (BuildContext context, int index) {
            // final info = coreInfoStateList[index];
            final info = coreInfoStateList[1];
            return ProviderScope(
              overrides: [
                currentCoreProvider.overrideWithValue(info),
              ],
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: CoreInfoCard(),
              ),
            );
          },
        ),
      ),
    );
  }
}
