import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    return const Locale('en', '');
  }

  void setLocale(Locale? locale) {
    if (locale == null) {
      return;
    }
    state = locale;
  }
}
