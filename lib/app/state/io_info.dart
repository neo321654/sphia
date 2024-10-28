import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:path/path.dart' as p;

part 'io_info.freezed.dart';

@freezed
class IoInfo with _$IoInfo {
  const factory IoInfo({
    required String execPath,
    required String appPath,
  }) = _IOInfo;
}

extension PathExtension on IoInfo {
  String get binPath => p.join(appPath, 'bin');

  String get configPath => p.join(appPath, 'config');

  String get logPath => p.join(appPath, 'log');

  String get tempPath => p.join(appPath, 'temp');
}
