import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/app/notifier/config/sphia_config.dart';
import 'package:sphia/app/notifier/core_state.dart';
import 'package:sphia/app/provider/data.dart';
import 'package:sphia/app/state/core_state.dart';

part 'log.g.dart';

enum SphiaLogLevel {
  debug,
  info,
  warning,
  error,
  none,
}

extension SphiaLogLevelExtension on SphiaLogLevel {
  Color get color {
    switch (this) {
      case SphiaLogLevel.debug:
        return Colors.grey;
      case SphiaLogLevel.info:
        return Colors.blue;
      case SphiaLogLevel.warning:
        return Colors.orange;
      case SphiaLogLevel.error:
        return Colors.red;
      case SphiaLogLevel.none:
        return Colors.transparent;
    }
  }

  String get prefix {
    switch (this) {
      case SphiaLogLevel.debug:
        return 'DEBUG';
      case SphiaLogLevel.info:
        return 'INFO';
      case SphiaLogLevel.warning:
        return 'WARNING';
      case SphiaLogLevel.error:
        return 'ERROR';
      case SphiaLogLevel.none:
        return '';
    }
  }
}

class SphiaLogEntry {
  final SphiaLogLevel level;
  final String message;

  const SphiaLogEntry(this.level, this.message);

  factory SphiaLogEntry.withTimestamp(SphiaLogLevel level, String message) {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    return SphiaLogEntry(level, '[$now] $message');
  }
}

@Riverpod(keepAlive: true)
class LogNotifier extends _$LogNotifier {
  StreamSubscription<String>? _logSubscription;

  @override
  Queue<SphiaLogEntry> build() {
    ref.onDispose(() {
      _logSubscription?.cancel();
    });
    final initLogs = ref.read(initLogsProvider);
    return Queue.of(initLogs);
  }

  void addLog(SphiaLogEntry entry) {
    state.addLast(entry);
    final logMaxCount = ref
        .read(sphiaConfigNotifierProvider.select((value) => value.maxLogCount));
    while (state.length > logMaxCount) {
      state.removeFirst();
    }
    state = Queue.of(state);
  }

  void addLogs(List<SphiaLogEntry> entries) {
    state.addAll(entries);
    final logMaxCount = ref
        .read(sphiaConfigNotifierProvider.select((value) => value.maxLogCount));
    while (state.length > logMaxCount) {
      state.removeFirst();
    }
    state = Queue.of(state);
  }

  void debug(String message) {
    addLog(SphiaLogEntry.withTimestamp(SphiaLogLevel.debug, message));
  }

  void info(String message) {
    addLog(SphiaLogEntry.withTimestamp(SphiaLogLevel.info, message));
  }

  void warning(String message) {
    addLog(SphiaLogEntry.withTimestamp(SphiaLogLevel.warning, message));
  }

  void error(String message) {
    addLog(SphiaLogEntry.withTimestamp(SphiaLogLevel.error, message));
  }

  void listenToCoreLogs() {
    final coreState = ref.read(coreStateNotifierProvider).valueOrNull;
    if (coreState != null) {
      if (coreState.cores.isEmpty) {
        return;
      }
      addLogs(coreState.routingPreLogList
          .map((log) => SphiaLogEntry(SphiaLogLevel.none, log))
          .toList());
      _logSubscription?.cancel();
      _logSubscription = coreState.logStream.listen((log) {
        addLog(SphiaLogEntry(SphiaLogLevel.none, log));
      });
    }
  }

  void stopListeningToCoreLogs() {
    _logSubscription?.cancel();
    _logSubscription = null;
  }
}
