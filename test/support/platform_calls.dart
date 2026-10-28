import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafia/features/timer/data/timer_feedback.dart';

class PlatformCalls {
  final List<bool> wakeLock = [];
  final List<MethodCall> system = [];
  final List<MethodCall> finishSound = [];
  static const _wakeChannel =
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

  void install() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler(_wakeChannel, (message) async {
      final args = const WakeLockCodec().decodeMessage(message) as List;
      wakeLock.add((args.single as List).single as bool);
      return const StandardMessageCodec().encodeMessage([null]);
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      system.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel(TimerFeedback.channelName),
      (call) async {
        finishSound.add(call);
        return null;
      },
    );
    addTearDown(() {
      messenger.setMockMessageHandler(_wakeChannel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(
        const MethodChannel(TimerFeedback.channelName),
        null,
      );
    });
  }
}

class WakeLockCodec extends StandardMessageCodec {
  const WakeLockCodec();

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) =>
      type == 129 ? readValue(buffer) : super.readValueOfType(type, buffer);
}
