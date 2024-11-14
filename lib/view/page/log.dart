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
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final isNearBottom = currentScroll >= maxScroll * 0.9;
        if (scrollController.position.userScrollDirection !=
                ScrollDirection.idle &&
            !isNearBottom) {
          isUserScrolling.value = true;
        } else if (isNearBottom) {
          isUserScrolling.value = false;
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
            duration: const Duration(milliseconds: 300),
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
        child: SizedBox(
          width: double.infinity,
          child: SelectionArea(
            child: ListView.builder(
              controller: scrollController,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return Text.rich(
                  _getLog(logs.elementAt(index)),
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _getLog(SphiaLogEntry logEntry) {
    final message = '${logEntry.message}\r';
    if (logEntry.level == SphiaLogLevel.none) {
      return TextSpan(text: message);
    } else {
      final color = logEntry.level.color;
      final prefix = '[${logEntry.level.prefix}]';
      return TextSpan(
        children: [
          TextSpan(
            text: prefix,
            style: TextStyle(color: color),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: message),
        ],
      );
    }
  }
}
