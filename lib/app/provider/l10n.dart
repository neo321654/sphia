import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/notifier/locale.dart';
import 'package:sphia/l10n/generated/l10n.dart';

part 'l10n.g.dart';

@riverpod
Future<L10n> l10n(Ref ref) {
  final locale = ref.watch(localeNotifierProvider);
  return L10n.delegate.load(locale);
}
