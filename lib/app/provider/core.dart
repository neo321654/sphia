import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sphia/core/hysteria/core.dart';
import 'package:sphia/core/sing/core.dart';
import 'package:sphia/core/ssrust/core.dart';
import 'package:sphia/core/xray/core.dart';

part 'core.g.dart';

@riverpod
SingBoxCore singBoxCore(Ref ref) => SingBoxCore(ref);

@riverpod
SingBoxCore latencyTestCore(Ref ref) => SingBoxCore.latencyTest(ref);

@riverpod
XrayCore xrayCore(Ref ref) => XrayCore(ref);

@riverpod
ShadowsocksRustCore shadowsocksRustCore(Ref ref) => ShadowsocksRustCore(ref);

@riverpod
HysteriaCore hysteriaCore(Ref ref) => HysteriaCore(ref);
