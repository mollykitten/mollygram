import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart' show monogramOf;

import '../../l10n/app_localizations.dart';
import '../home/format.dart';
import '../home/workspace.dart';
import '../session/providers.dart';
import '../settings/privacy/passcode.dart';
import 'notification_audio.dart';
import 'notification_settings.dart';
import 'system_notifications.dart';

/// Shows TDLib's message notifications in the system notification center,
/// answers their buttons and keeps the dock badge current. It lives while
/// the account is signed in (see [NotificationsHost]); signing out takes
/// every notification and the badge away.
final class NotificationService {
  NotificationService({
    required this._controller,
    required this._system,
    required this._openChat,
    this._settings = const NotificationSettings(),
    this._audio,
  });

  final NotificationController _controller;
  final NotificationAudioSession? _audio;
  var _deliveryQueue = Future<void>.value();
  final _notificationVersions = <String, Object>{};
  final _pendingDeliveries = <String, _PendingNotification>{};
  final SystemNotifications _system;
  final void Function(int chatId) _openChat;
  final _subscriptions = <StreamSubscription<Object?>>[];
  NotificationSettings _settings;
  AppLocalizations? _l10n;
  String? _badge;
  var _disposed = false;

  NotificationSettings get settings => _settings;

  /// Starts once the app's language is known; later calls only update
  /// the language of new notifications.
  Future<void> start(AppLocalizations l10n) async {
    final first = _l10n == null;
    _l10n = l10n;
    if (!first) return;
    _subscriptions
      ..add(_controller.events.listen(_onEvent))
      ..add(_controller.unreadChanges.listen((_) => _updateBadge()))
      ..add(_system.responses.listen(_onResponse));
    await _guard(
      _system.configure(
        NotificationLabels(
          reply: l10n.notificationReply,
          send: l10n.notificationSend,
          placeholder: l10n.notificationReplyPlaceholder,
          markRead: l10n.notificationMarkRead,
        ),
      ),
    );
    await _applyEnabled();
    await _updateBadge();
  }

  set settings(NotificationSettings next) {
    final previous = _settings;
    if (next == previous) return;
    _settings = next;
    if (_l10n == null) return;
    if (next.enabled != previous.enabled) {
      if (!next.enabled) {
        _notificationVersions.clear();
        _pendingDeliveries.clear();
      }
      unawaited(_applyEnabled());
    }
    unawaited(_updateBadge());
  }

  Future<void> _applyEnabled() async {
    if (_disposed) return;
    final enabled = _settings.enabled;
    if (enabled) {
      await _guard(_system.requestPermission());
    } else {
      await _guard(_system.removeAll());
    }
    if (_disposed) return;
    await _guard(_controller.setEnabled(enabled));
  }

  Future<void> _updateBadge() async {
    final counts = _controller.unreadCounts;
    final count = switch ((
      _settings.badgeCountsMessages,
      _settings.badgeIncludesMuted,
    )) {
      (false, false) => counts.unmutedChats,
      (false, true) => counts.chats,
      (true, false) => counts.unmutedMessages,
      (true, true) => counts.messages,
    };
    final label = _settings.badge && count > 0 ? '$count' : null;
    if (label == _badge || _disposed) return;
    _badge = label;
    await _guard(_system.setBadge(label));
  }

  void _onEvent(NotificationEvent event) {
    _PendingNotification? pending;
    // Invalidate in-flight sound preparation immediately, not only when its
    // queued removal eventually runs. Read/deleted notifications must not make
    // a late banner or sound after a tone download finishes.
    switch (event) {
      case NotificationPosted(:final notification):
        if (_disposed || !_settings.enabled) return;
        final existing = _pendingDeliveries[notification.key];
        if (notification.isEdit && existing != null) {
          // Update the content, not the first alert's sound/quiet policy.
          // Once native delivery starts this entry is removed, so later edits
          // follow the ordinary quiet replacement path instead.
          existing.latest = notification;
          return;
        }
        pending = _PendingNotification(notification);
        _pendingDeliveries[notification.key] = pending;
        _notificationVersions[notification.key] = pending.version;
      case NotificationsRemoved(:final keys):
        for (final key in keys) {
          _notificationVersions.remove(key);
          _pendingDeliveries.remove(key);
        }
      case NotificationsSynced(:final keys):
        _notificationVersions.removeWhere((key, _) => !keys.contains(key));
        _pendingDeliveries.removeWhere((key, _) => !keys.contains(key));
    }
    // File preparation must not let a removal overtake its notification.
    _deliveryQueue = _deliveryQueue
        .then((_) async {
          if (_disposed) return;
          switch (event) {
            case NotificationPosted(:final notification):
              final delivery = pending!;
              if (!_settings.enabled ||
                  !identical(
                    _notificationVersions[notification.key],
                    delivery.version,
                  )) {
                return;
              }
              if (_l10n case final l10n?) {
                var resource = const NotificationSoundResource();
                if (_settings.sound &&
                    notification.playSound &&
                    !notification.isEdit &&
                    notification.soundId > 0) {
                  try {
                    resource = await _controller.sounds
                        .resolve(notification.soundId)
                        .timeout(const Duration(seconds: 2));
                  } on Object {
                    // Keep the requested ID, but deliver silently if unavailable.
                  }
                }
                if (_disposed ||
                    !_settings.enabled ||
                    !identical(
                      _notificationVersions[notification.key],
                      delivery.version,
                    )) {
                  return;
                }
                _pendingDeliveries.remove(notification.key);
                await _system.show(
                  present(
                    delivery.latest,
                    _l10n ?? l10n,
                    soundResource: resource,
                    alertNotification: delivery.initial,
                  ),
                );
              }
            case NotificationsRemoved(:final keys):
              await _system.remove(keys);
            case NotificationsSynced(:final keys):
              await _system.retain(keys);
          }
        })
        .catchError((Object _) {});
  }

  void _onResponse(NotificationResponse response) {
    switch (response) {
      case NotificationOpened(:final chatId):
        _openChat(chatId);
      case NotificationReplied(:final chatId, :final messageId, :final text):
        unawaited(_guard(_controller.reply(chatId, messageId, text)));
      case NotificationMarkedRead(:final chatId, :final messageId):
        unawaited(_guard(_controller.markRead(chatId, messageId)));
    }
  }

  /// How [notification] reads in the notification center: the chat as the
  /// title, the author of a group message under it, then the text.
  SystemNotification present(
    MessageNotification notification,
    AppLocalizations l10n, {
    NotificationSoundResource soundResource = const NotificationSoundResource(),
    MessageNotification? alertNotification,
  }) {
    // Edits coalesced during preparation supply the latest content while the
    // initial new-message notification retains its original alert semantics.
    final alert = alertNotification ?? notification;
    final preview = _settings.showPreview && notification.showPreview;
    return SystemNotification(
      id: notification.key,
      chatId: notification.chatId,
      messageId: notification.messageId,
      title: notification.chatTitle,
      subtitle: preview ? notification.senderName ?? '' : '',
      body: preview
          ? notificationBody(l10n, notification)
          : l10n.notificationHiddenText,
      thread: 'chat:${notification.chatId}',
      sound:
          _settings.sound &&
          alert.playSound &&
          !alert.isEdit &&
          (alert.soundId < 0 ||
              soundResource.path != null ||
              soundResource.fallbackDefault),
      soundId: alert.soundId,
      soundPath: soundResource.path,
      soundFallbackDefault: soundResource.fallbackDefault,
      soundSession: _audio?.id ?? '',
      quiet: alert.isEdit,
      canReply: notification.canReply,
      photoPath: notification.photoPath,
      monogram: monogramOf(notification.chatTitle),
    );
  }

  /// Takes every notification and the badge away.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _notificationVersions.clear();
    _pendingDeliveries.clear();
    // Enqueue cleanup synchronously, before a replacement account can start.
    final cleanup = _l10n == null
        ? Future<void>.value()
        : Future.wait([
            _guard(_system.removeAll()),
            _guard(_system.setBadge(null)),
          ]);
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await cleanup;
  }

  /// A notification that can't be shown, or a reply TDLib refuses, is not
  /// worth an error dialog; the chat itself shows what happened.
  static Future<void> _guard(Future<Object?> operation) =>
      operation.then<void>((_) {}, onError: (Object _) {});
}

final class _PendingNotification {
  _PendingNotification(this.initial) : latest = initial;

  final Object version = Object();
  final MessageNotification initial;
  MessageNotification latest;
}

/// The message line: the text, or what kind of message it is, with the
/// caption when there is one.
String notificationBody(AppLocalizations l10n, MessageNotification n) {
  final label = kindLabel(l10n, n.kind);
  final text = n.text.trim();
  if (label.isEmpty) return text.isEmpty ? l10n.previewOther : text;
  if (n.kind == ChatPreviewKind.sticker && text.isNotEmpty) {
    return '$text $label';
  }
  return text.isEmpty ? label : '$label, $text';
}

/// The settings as notifications follow them: while the passcode lock is
/// on, or not yet known, no message text shows, as in TelegramSwift.
NotificationSettings notificationSettingsUnder(
  NotificationSettings settings,
  PasscodeState lock,
) => !lock.loaded || lock.locked
    ? settings.copyWith(showPreview: false)
    : settings;

NotificationSettings _effective(Ref ref) => notificationSettingsUnder(
  ref.read(notificationSettingsProvider),
  ref.read(passcodeLockProvider),
);

final notificationServiceProvider = Provider.autoDispose<NotificationService>((
  ref,
) {
  final session = ref.watch(telegramSessionProvider).requireValue;
  final service = NotificationService(
    controller: session.notifications,
    audio: ref.watch(notificationAudioProvider),
    system: ref.watch(systemNotificationsProvider),
    openChat: (chatId) => ref.read(workspaceControllerProvider).open(chatId),
    settings: _effective(ref),
  );
  ref
    ..listen(
      notificationSettingsProvider,
      (_, _) => service.settings = _effective(ref),
    )
    ..listen(
      passcodeLockProvider.select((lock) => (lock.loaded, lock.locked)),
      (_, _) => service.settings = _effective(ref),
    );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

/// Keeps notifications running while it is in the tree (the signed-in
/// window) and gives them the app's language.
class NotificationsHost extends ConsumerStatefulWidget {
  const NotificationsHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationsHost> createState() => _NotificationsHostState();
}

class _NotificationsHostState extends ConsumerState<NotificationsHost> {
  @override
  Widget build(BuildContext context) {
    // Starting again only passes a changed language on.
    final service = ref.watch(notificationServiceProvider);
    unawaited(service.start(AppLocalizations.of(context)));
    return widget.child;
  }
}
