import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mollygram/src/notifications/system_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'macOS channel preserves int64 custom ID and resolved path, but quiet wins',
    () async {
      const channel = MethodChannel('mollygram/notifications');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final system = MacosNotifications();
      await system.show(
        const SystemNotification(
          id: 'one',
          chatId: 1,
          messageId: 2,
          title: '',
          body: '',
          sound: true,
          soundId: 9876543210123456,
          soundPath: '/local/tone.mp3',
          soundSession: 'account-one',
          quiet: true,
        ),
      );
      final args = calls.single.arguments as Map;
      expect(args['soundId'], '9876543210123456');
      expect(args['soundPath'], '/local/tone.mp3');
      expect(args['soundSession'], 'account-one');
      expect(args['quiet'], isTrue);
      expect(args['soundFallbackDefault'], isFalse);
    },
  );
}
