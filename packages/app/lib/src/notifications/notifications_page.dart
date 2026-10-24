import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_style.dart';
import '../settings/settings_window.dart';
import 'notification_scope_page.dart';
import 'notification_settings.dart';
import 'system_notifications.dart';

/// Whether macOS lets Mollygram show notifications; read again each time
/// the page opens, since the user may have changed it in System Settings.
final notificationPermissionProvider =
    FutureProvider.autoDispose<NotificationPermission>(
      (ref) => ref.watch(systemNotificationsProvider).permission(),
    );

/// Notifications settings, a page of the settings window like the others.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static final _systemSettings = Uri.parse(
    'x-apple.systempreferences:com.apple.Notifications-Settings.extension',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final denied =
        ref.watch(notificationPermissionProvider).value ==
        NotificationPermission.denied;
    void update(NotificationSettings Function(NotificationSettings) change) =>
        ref.read(notificationSettingsProvider.notifier).update(change);
    ValueChanged<bool>? when(
      bool enabled,
      NotificationSettings Function(NotificationSettings, bool) change,
    ) => enabled ? (v) => update((s) => change(s, v)) : null;

    return SettingsPage(
      children: [
        if (denied)
          SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.notificationsDenied,
                trailing: SettingsButton(
                  label: l10n.notificationsOpenSystemSettings,
                  onPressed: () => unawaited(launchUrl(_systemSettings)),
                ),
              ),
            ],
          ),
        SettingsGroup(
          title: l10n.notificationsSectionAlerts,
          children: [
            SettingsSwitchRow(
              title: l10n.notificationsShow,
              subtitle: l10n.notificationsShowHint,
              value: settings.enabled,
              onChanged: when(true, (s, v) => s.copyWith(enabled: v)),
            ),
            SettingsSwitchRow(
              title: l10n.notificationsPreview,
              subtitle: l10n.notificationsPreviewHint,
              value: settings.showPreview,
              onChanged: when(
                settings.enabled,
                (s, v) => s.copyWith(showPreview: v),
              ),
            ),
            SettingsSwitchRow(
              title: l10n.notificationsSound,
              value: settings.sound,
              onChanged: when(settings.enabled, (s, v) => s.copyWith(sound: v)),
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.notificationsSectionChats,
          children: [
            for (final scope in NotificationScope.values)
              _NotificationScopeRow(scope: scope),
          ],
        ),
        SettingsGroup(
          title: l10n.notificationsSectionBadge,
          children: [
            SettingsSwitchRow(
              title: l10n.notificationsBadge,
              value: settings.badge,
              onChanged: when(true, (s, v) => s.copyWith(badge: v)),
            ),
            SettingsSwitchRow(
              title: l10n.notificationsBadgeMuted,
              value: settings.badgeIncludesMuted,
              onChanged: when(
                settings.badge,
                (s, v) => s.copyWith(badgeIncludesMuted: v),
              ),
            ),
            SettingsSwitchRow(
              title: l10n.notificationsBadgeMessages,
              value: settings.badgeCountsMessages,
              onChanged: when(
                settings.badge,
                (s, v) => s.copyWith(badgeCountsMessages: v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationScopeRow extends ConsumerWidget implements SettingsGroupRow {
  const _NotificationScopeRow({required this.scope});

  final NotificationScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = MgColors.of(context);
    final loaded = ref.watch(scopeNotificationSettingsProvider(scope));
    final settings = loaded.value;
    final title = notificationScopeTitle(l10n, scope);
    return SettingsRow(
      key: ValueKey(('notificationScope', scope)),
      title: title,
      subtitle: loaded.hasError ? l10n.notificationsLoadFailed : null,
      trailing: settings == null
          ? loaded.hasError
                ? null
                : const SettingsSpinner(size: 14)
          : Text(
              settings.muteFor == 0
                  ? l10n.notificationsOn
                  : l10n.notificationsOff,
              style: mgTextStyle(c, color: c.fg2),
            ),
      chevron: true,
      onTap: () =>
          SettingsNavigation.of(context)
              .push(title, (context) => NotificationScopePage(scope: scope)),
    );
  }
}
