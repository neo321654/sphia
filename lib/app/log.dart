import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:sphia/core/core_info.dart';

class MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

late final Logger logger;

class SphiaLog {
  static final DateFormat formatter = DateFormat('yyyy-MM-dd-HH-mm-ss');
  static late final String logPath;

  set setLogPath(String path) {
    logPath = path;
  }

  static String getLogPath(ProxyRes coreName) {
    final now = formatter.format(DateTime.now());
    return p.join(logPath, '${coreName.toString()}-$now.log');
  }

  static void initLogger(bool saveLog, int methodCount, int errorMethodCount) {
    logger = Logger(
      level: Level.trace,
      filter: MyFilter(),
      printer: PrettyPrinter(
        colors: false,
        errorMethodCount: errorMethodCount,
        methodCount: methodCount,
        noBoxingByDefault: true,
      ),
      output:
          saveLog ? FileOutput(file: File(getLogPath(ProxyRes.sphia))) : null,
    );
  }
}
