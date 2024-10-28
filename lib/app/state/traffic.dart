import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sphia/app/helper/traffic/traffic.dart';

part 'traffic.freezed.dart';

@freezed
class TrafficState with _$TrafficState {
  const factory TrafficState({
    TrafficHelper? traffic,
  }) = _TrafficState;
}
