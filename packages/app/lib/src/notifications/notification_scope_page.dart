import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import '../../l10n/app_localizations.dart';
import '../session/providers.dart';
import '../settings/settings_style.dart';
import '../settings/settings_window.dart';
import 'notification_audio.dart';
import 'notification_sounds_page.dart';

/// The account's server-backed notification defaults, not the local banner
/// and Dock switches kept in notifications.json.
final notificationControllerProvider = Provider<NotificationController>(
  (ref) => ref.watch(telegramSessionProvider).requireValue.notifications,
);

/// Reloads just the category changed on another device. Listening before
/// loading also catches updates that arrive while the request is in flight.
final scopeNotificationSettingsProvider = FutureProvider.autoDispose
    .family<td.ScopeNotificationSettings, NotificationScope>((ref, scope) {
      final controller = ref.watch(notificationControllerProvider);
      final subscription = controller.scopeChanges
          .where((changed) => changed == scope)
          .listen((_) => ref.invalidateSelf());
      ref.onDispose(subscription.cancel);
      return controller.scopeSettings(scope);
    });

String notificationScopeTitle(AppLocalizations l10n, NotificationScope scope) =>
    switch (scope) {
      NotificationScope.privateChats => l10n.notificationsPrivateChats,
      NotificationScope.groups => l10n.notificationsGroups,
      NotificationScope.channels => l10n.notificationsChannels,
    };

/// The defaults used by chats without their own notification overrides.
/// Saves are acknowledged by Telegram before the controls become editable
/// again; a failed save restores the loaded values and leaves a retryable row.
class NotificationScopePage extends ConsumerStatefulWidget {
  const NotificationScopePage({super.key, required this.scope});

  final NotificationScope scope;

  @override
  ConsumerState<NotificationScopePage> createState() =>
      _NotificationScopePageState();
}

class _NotificationScopePageState extends ConsumerState<NotificationScopePage> {
  ({bool? enabled, bool? showPreview})? _pending;
  String? _error;

  Future<void> _save({bool? enabled, bool? showPreview}) async {
    if (_pending != null) return;
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(notificationControllerProvider);
    final provider = scopeNotificationSettingsProvider(widget.scope);
    setState(() {
      _pending = (enabled: enabled, showPreview: showPreview);
      _error = null;
    });
    var saved = false;
    try {
      await controller.updateScopeSettings(
        widget.scope,
        enabled: enabled,
        showPreview: showPreview,
      );
      saved = true;
      if (!mounted ||
          !identical(ref.read(notificationControllerProvider), controller)) {
        return;
      }
      // Also reload after acknowledgement if TDLib emitted no scope update.
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on Object {
      // A failed readback has its own load-error row and retry action; the
      // acknowledged write must not be reported as an unsuccessful save.
      if (mounted &&
          !saved &&
          identical(ref.read(notificationControllerProvider), controller)) {
        setState(() => _error = l10n.saveFailed);
      }
    } finally {
      if (mounted &&
          identical(ref.read(notificationControllerProvider), controller)) {
        setState(() => _pending = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(notificationControllerProvider, (_, _) {
      setState(() {
        _pending = null;
        _error = null;
      });
    });
    final tones = ref.watch(savedNotificationSoundsProvider).value ?? [];
    final loaded = ref.watch(scopeNotificationSettingsProvider(widget.scope));
    final settings = loaded.value;
    if (loaded.hasError || settings == null) {
      return SettingsPage(
        children: [
          SettingsGroup(
            children: [
              SettingsRow(
                title: loaded.hasError
                    ? l10n.notificationsLoadFailed
                    : notificationScopeTitle(l10n, widget.scope),
                trailing: loaded.hasError
                    ? SettingsButton(
                        label: l10n.tryAgain,
                        onPressed: () => ref.invalidate(
                          scopeNotificationSettingsProvider(widget.scope),
                        ),
                      )
                    : const SettingsSpinner(),
              ),
            ],
          ),
        ],
      );
    }
    final pending = _pending;
    final busy = pending != null;
    final enabled = pending?.enabled ?? settings.muteFor == 0;
    return SettingsPage(
      children: [
        SettingsGroup(
          title: notificationScopeTitle(l10n, widget.scope),
          footer: SettingsFooter(l10n.notificationsScopeHint),
          children: [
            SettingsSwitchRow(
              title: l10n.notificationsShow,
              value: enabled,
              onChanged: busy ? null : (v) => unawaited(_save(enabled: v)),
            ),
            SettingsSwitchRow(
              title: l10n.notificationsPreview,
              value: pending?.showPreview ?? settings.showPreview,
              onChanged: busy || !enabled
                  ? null
                  : (v) => unawaited(_save(showPreview: v)),
            ),
            SettingsRow(
              title: l10n.notificationSoundTitle,
              trailing: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  notificationSoundTitle(
                    l10n,
                    settings.soundId,
                    tones
                        .where((t) => t.id == settings.soundId)
                        .firstOrNull
                        ?.title,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mgTextStyle(
                    MgColors.of(context),
                    color: MgColors.of(context).fg2,
                  ),
                ),
              ),
              chevron: true,
              onTap: busy || !enabled
                  ? null
                  : () => SettingsNavigation.of(context).push(
                      l10n.notificationSoundTitle,
                      (_) => NotificationSoundsPage(scope: widget.scope),
                    ),
            ),
          ],
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.only(top: MgSpace.m),
            child: Align(
              alignment: Alignment.centerRight,
              child: SettingsSpinner(),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: MgSpace.m),
            child: SettingsFooter(_error!, error: true),
          ),
      ],
    );
  }
}
