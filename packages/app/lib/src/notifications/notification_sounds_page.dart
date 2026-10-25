import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_tdlib/mollygram_tdlib.dart' as td;
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_style.dart';
import 'notification_audio.dart';
import 'notification_scope_page.dart';

String notificationSoundTitle(AppLocalizations l10n, int id, [String? title]) =>
    id == 0
    ? l10n.notificationSoundNone
    : id < 0
    ? l10n.notificationSoundDefault
    : title?.isNotEmpty == true
    ? title!
    : l10n.notificationSoundCustom('$id');

/// Only acknowledged/read-back selections get a checkmark. Preview never writes
/// to Telegram, and failures don't silently replace the selected saved ID.
class NotificationSoundsPage extends ConsumerStatefulWidget {
  const NotificationSoundsPage({super.key, required this.scope});
  final NotificationScope scope;
  @override
  ConsumerState<NotificationSoundsPage> createState() =>
      _NotificationSoundsPageState();
}

class _NotificationSoundsPageState
    extends ConsumerState<NotificationSoundsPage> {
  int? _saving;
  int? _previewing;
  String? _error;
  NotificationAudioSession? _audio;

  bool _current(NotificationController controller) =>
      mounted &&
      identical(ref.read(notificationControllerProvider), controller);

  Future<void> _select(int id) async {
    if (_saving != null) return;
    final controller = ref.read(notificationControllerProvider);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = id;
      _error = null;
    });
    var saved = false;
    try {
      await controller.updateScopeSettings(widget.scope, soundId: id);
      saved = true;
      if (!_current(controller)) return;
      final provider = scopeNotificationSettingsProvider(widget.scope);
      ref.invalidate(provider);
      await ref.read(provider.future);
    } on Object {
      if (_current(controller) && !saved) {
        setState(() => _error = l10n.saveFailed);
      }
    } finally {
      if (_current(controller)) setState(() => _saving = null);
    }
  }

  Future<void> _preview(int id) async {
    final audio = ref.read(notificationAudioProvider);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _previewing = id;
      _error = null;
    });
    try {
      await audio.preview(id);
    } on Object {
      if (mounted && identical(_audio, audio) && _previewing == id) {
        setState(() => _error = l10n.notificationSoundUnavailable);
      }
    } finally {
      if (mounted && identical(_audio, audio) && _previewing == id) {
        setState(() => _previewing = null);
      }
    }
  }

  @override
  void dispose() {
    unawaited(
      _audio?.stopPreview().catchError((Object _) {}) ?? Future<void>.value(),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = MgColors.of(context);
    final audio = ref.watch(notificationAudioProvider);
    if (!identical(_audio, audio)) {
      _audio = audio;
      _saving = null;
      _previewing = null;
      _error = null;
    }
    final provider = scopeNotificationSettingsProvider(widget.scope);
    final scope = ref.watch(provider);
    final tones = ref.watch(savedNotificationSoundsProvider);
    final selected = scope.value?.soundId;
    final enabled = selected != null && !scope.hasError && _saving == null;

    Widget row(int id, String title) => Semantics(
      selected: selected == id,
      child: SettingsRow(
        key: ValueKey(('notificationTone', id)),
        title: title,
        leading: SizedBox(
          width: 18,
          child: selected == id
              ? MgIcon(MgIcons.check, size: 16, color: c.accent)
              : null,
        ),
        onTap: enabled && selected != id ? () => unawaited(_select(id)) : null,
        trailing: _saving == id || _previewing == id
            ? const SettingsSpinner(size: 16)
            : audio.supported && id != 0
            ? SettingsButton(
                label: l10n.notificationSoundPreview,
                onPressed: _saving == null
                    ? () => unawaited(_preview(id))
                    : null,
              )
            : null,
      ),
    );

    return SettingsPage(
      children: [
        SettingsGroup(
          title: notificationScopeTitle(l10n, widget.scope),
          footer: SettingsFooter(
            audio.supported
                ? l10n.notificationSoundHint
                : l10n.notificationSoundUnsupported,
          ),
          children: [
            row(-1, l10n.notificationSoundDefault),
            row(0, l10n.notificationSoundNone),
          ],
        ),
        SettingsGroup(
          title: l10n.notificationSoundSaved,
          children: [
            if (tones.hasError)
              SettingsRow(
                title: l10n.notificationsLoadFailed,
                trailing: SettingsButton(
                  label: l10n.tryAgain,
                  onPressed: () =>
                      ref.invalidate(savedNotificationSoundsProvider),
                ),
              )
            else if (!tones.hasValue)
              SettingsRow(
                title: l10n.notificationSoundSaved,
                trailing: const SettingsSpinner(),
              ),
            for (final tone in tones.value ?? const <td.NotificationSound>[])
              row(tone.id, notificationSoundTitle(l10n, tone.id, tone.title)),
            if (tones.hasValue && tones.value!.isEmpty)
              SettingsRow(title: l10n.notificationSoundEmpty),
            if (selected != null &&
                selected > 0 &&
                tones.hasValue &&
                !tones.value!.any((t) => t.id == selected))
              row(selected, notificationSoundTitle(l10n, selected)),
          ],
        ),
        if (scope.hasError)
          SettingsGroup(
            children: [
              SettingsRow(
                title: l10n.notificationsLoadFailed,
                trailing: SettingsButton(
                  label: l10n.tryAgain,
                  onPressed: () => ref.invalidate(provider),
                ),
              ),
            ],
          ),
        if (!scope.hasValue && !scope.hasError)
          const Center(child: SettingsSpinner()),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: MgSpace.m),
            child: SettingsFooter(_error!, error: true),
          ),
      ],
    );
  }
}
