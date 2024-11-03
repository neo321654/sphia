import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/log.dart';
import 'package:sphia/app/notifier/proxy.dart';
import 'package:sphia/l10n/generated/l10n.dart';

class LogPage extends HookConsumerWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logNotifierProvider);
    final scrollController = useScrollController();
    final isUserScrolling = useState<bool>(false);

    useEffect(() {
      void scrollListener() {
        if (scrollController.position.userScrollDirection !=
            ScrollDirection.idle) {
          isUserScrolling.value = true;
        } else {
          final maxScroll = scrollController.position.maxScrollExtent;
          final currentScroll = scrollController.position.pixels;
          if (currentScroll >= maxScroll * 0.9) {
            isUserScrolling.value = false;
          }
        }
      }

      scrollController.addListener(scrollListener);
      return () => scrollController.removeListener(scrollListener);
    }, []);

    useEffect(() {
      if (!isUserScrolling.value) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      }
      return () {};
    }, [logs]);

    ref.listen<bool>(
      proxyNotifierProvider.select((value) => value.coreRunning),
      (previous, next) {
        final enableCoreLog = ref.read(
          sphiaConfigNotifierProvider.select((value) => value.enableCoreLog),
        );
        final saveCoreLog = ref.read(
          sphiaConfigNotifierProvider.select((value) => value.saveCoreLog),
        );
        if (next && enableCoreLog && (!saveCoreLog)) {
          ref.read(logNotifierProvider.notifier).listenToCoreLogs();
        } else {
          ref.read(logNotifierProvider.notifier).stopListeningToCoreLogs();
        }
      },
    );

    final logLines = logs.map((log) {
      final message = log.message;
      if (log.level == SphiaLogLevel.none) {
        return TextSpan(
          text: '$message\n',
        );
      }
      final color = log.level.color;
      final prefix = '[${log.level.prefix}]';
      return TextSpan(
        children: [
          TextSpan(
            text: prefix,
            style: TextStyle(color: color),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: '$message\n'),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.of(context)!.log,
          textAlign: TextAlign.center,
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            controller: scrollController,
            child: SelectableText.rich(
              TextSpan(
                children: logLines,
              ),
              style: const TextStyle(
                fontFamily: 'Courier New',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
