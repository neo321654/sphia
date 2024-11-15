import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/helper/system.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/locale.dart';
import 'package:sphia/app/notifier/visible.dart';
import 'package:sphia/app/provider/l10n.dart';
import 'package:sphia/app/theme.dart';
import 'package:sphia/l10n/generated/l10n.dart';
import 'package:sphia/view/page/about.dart';
import 'package:sphia/view/page/dashboard.dart';
import 'package:sphia/view/page/log.dart';
import 'package:sphia/view/page/rule.dart';
import 'package:sphia/view/page/server.dart';
import 'package:sphia/view/page/setting.dart';
import 'package:sphia/view/page/update.dart';
import 'package:sphia/view/widget/window_caption.dart';
import 'package:sphia/view/wrapper/tray.dart';
import 'package:window_manager/window_manager.dart';

part 'app.g.dart';

@riverpod
class NavigationIndexNotifier extends _$NavigationIndexNotifier {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

class SphiaApp extends ConsumerStatefulWidget {
  const SphiaApp({
    super.key,
  });

  @override
  ConsumerState<SphiaApp> createState() => _SphiaAppState();
}

class _SphiaAppState extends ConsumerState<SphiaApp>
    with WindowListener, SystemHelper {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(localeNotifierProvider.notifier).setLocale(_locale);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _init() async {
    if (!isMacOS) {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    } else {
      await windowManager.setTitle('Sphia - $sphiaVersion');
    }
    await windowManager.setPreventClose(true); // wtf
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = ref
        .watch(sphiaConfigNotifierProvider.select((value) => value.darkMode));
    final themeColor = ref
        .watch(sphiaConfigNotifierProvider.select((value) => value.themeColor));

    final titleTextStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
          fontSize: 14.5,
          fontFamily: 'Verdana',
          color: Colors.grey[500],
        );

    final titleText = Text(
      'Sphia - $sphiaVersion',
      style: titleTextStyle,
      textAlign: isMacOS ? TextAlign.center : TextAlign.start,
    );

    // on macOS, the title bar is handled by the system
    // else, use the custom title bar
    final titleBar = PreferredSize(
      preferredSize: const Size.fromHeight(kWindowCaptionHeight),
      child: isMacOS
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: titleText,
            )
          : SphiaWindowCaption(
              title: titleText,
              backgroundColor: Colors.transparent,
              brightness: darkMode ? Brightness.dark : Brightness.light,
            ),
    );

    return MaterialApp(
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L10n.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (supportedLocales
            .map((e) => e.languageCode)
            .contains(deviceLocale?.languageCode)) {
          _locale = deviceLocale;
        } else {
          _locale = const Locale('en', '');
        }
        return _locale;
      },
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: SphiaTheme.lightTheme(
        themeColor,
        context,
      ),
      darkTheme: SphiaTheme.darkTheme(
        themeColor,
        context,
      ),
      home: TrayWrapper(
        child: Scaffold(
          appBar: titleBar,
          body: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Consumer(
                  builder: (context, ref, child) {
                    final index = ref.watch(navigationIndexNotifierProvider);
                    final l10n = ref.watch(l10nProvider).value!;
                    return NavigationDrawer(
                      selectedIndex: index,
                      onDestinationSelected: (idx) {
                        ref
                            .read(navigationIndexNotifierProvider.notifier)
                            .setIndex(idx);
                      },
                      children: [
                        _getNavigationDrawerDestination(
                          Symbols.dashboard,
                          l10n.dashboard,
                          themeColor,
                        ),
                        _getNavigationDrawerDestination(
                          Symbols.webhook,
                          l10n.servers,
                          themeColor,
                        ),
                        _getNavigationDrawerDestination(
                          Symbols.rule,
                          l10n.rules,
                          themeColor,
                        ),
                        _getNavigationDrawerDestination(
                          Symbols.description,
                          l10n.log,
                          themeColor,
                        ),
                        _getNavigationDrawerDestination(
                          Symbols.settings,
                          l10n.settings,
                          themeColor,
                        ),
                        _getNavigationDrawerDestination(
                          Symbols.upgrade,
                          l10n.update,
                          themeColor,
                        ),
                        _getNavigationDrawerDestination(
                          Symbols.info,
                          l10n.about,
                          themeColor,
                        ),
                      ],
                    );
                  },
                ),
              ),
              VerticalDivider(
                width: 3,
                thickness: 3,
                color: Color(themeColor),
              ),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final index = ref.watch(navigationIndexNotifierProvider);
                    return IndexedStack(
                      index: index,
                      children: const [
                        Dashboard(),
                        ServerPage(),
                        RulePage(),
                        LogPage(),
                        SettingPage(),
                        UpdatePage(),
                        SlideAboutPage(),
                      ],
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  NavigationDrawerDestination _getNavigationDrawerDestination(
      IconData icon, String text, int color) {
    return NavigationDrawerDestination(
      icon: Icon(
        icon,
        color: const Color.fromARGB(230, 128, 128, 128),
      ),
      selectedIcon: Icon(
        icon,
        color: Color(color),
      ),
      label: Flexible(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Color.fromARGB(230, 128, 128, 128),
          ),
        ),
      ),
    );
  }

  @override
  void onWindowFocus() {
    super.onWindowFocus();
    final visibleNotifier = ref.read(visibleNotifierProvider.notifier);
    visibleNotifier.set(true);
  }

  @override
  void onWindowClose() async {
    final visibleNotifier = ref.read(visibleNotifierProvider.notifier);
    visibleNotifier.set(false);
    // Prevent close
    await windowManager.hide();
  }
}
