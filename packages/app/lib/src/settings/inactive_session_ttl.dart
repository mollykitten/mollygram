import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

import '../../l10n/app_localizations.dart';
import 'selection_check.dart';
import 'settings_style.dart';

/// Telegram macOS RecentSessionsController's presets. Other server values
/// remain exact day counts rather than being rounded into one of these.
const inactiveSessionTtlChoices = [7, 30, 90, 180, 365];

String inactiveSessionTtlLabel(AppLocalizations l10n, int days) =>
    switch (days) {
      7 => l10n.sessionTtlWeek,
      30 || 90 || 180 => l10n.ttlMonths(days ~/ 30),
      365 => l10n.ttlYears(1),
      _ => l10n.ttlDays(days),
    };

enum _Failure { load, write, readback }

/// The session inactivity setting, not the account-deletion timer.
/// Only menu selection writes. Acknowledgement and readback both finish
/// before it becomes editable again; retry always reads, never resends.
class InactiveSessionTtlSettings extends StatefulWidget {
  const InactiveSessionTtlSettings({super.key, required this.account});

  final AccountSettings account;

  @override
  State<InactiveSessionTtlSettings> createState() =>
      _InactiveSessionTtlSettingsState();
}

class _InactiveSessionTtlSettingsState
    extends State<InactiveSessionTtlSettings> {
  int? _days;
  var _busy = true;
  var _checking = false;
  var _generation = 0;
  _Failure? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(InactiveSessionTtlSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.account, widget.account)) unawaited(_load());
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  bool _current(int generation) => mounted && generation == _generation;

  Future<void> _load() async {
    final generation = ++_generation;
    final account = widget.account;
    setState(() {
      _busy = true;
      _checking = false;
      _days = null;
      _failure = null;
    });
    try {
      final days = await account.inactiveSessionTtlDays();
      if (_current(generation)) setState(() => _days = days);
    } catch (_) {
      if (_current(generation)) setState(() => _failure = _Failure.load);
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  Future<void> _save(int days, int menuGeneration) async {
    // A menu may outlive its account or page, and a double activation may
    // arrive before the disabled row is painted.
    if (!_current(menuGeneration) || _busy || days == _days) return;
    final account = widget.account;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _checking = false;
      _failure = null;
    });
    var acknowledged = false;
    try {
      await account.setInactiveSessionTtlDays(days);
      acknowledged = true;
      if (!_current(generation)) return;
      setState(() => _checking = true);
      final confirmed = await account.inactiveSessionTtlDays();
      if (_current(generation)) setState(() => _days = confirmed);
    } catch (_) {
      if (_current(generation)) {
        setState(() {
          // Even a failed write can have an uncertain network outcome.
          // Do not present the old value as current until a fresh read.
          _days = null;
          _failure = acknowledged ? _Failure.readback : _Failure.write;
        });
      }
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  void _openMenu(BuildContext anchorContext) {
    final days = _days;
    if (_busy || days == null) return;
    final generation = _generation;
    final l10n = AppLocalizations.of(context);
    unawaited(
      showMgDropdown(
        context,
        anchor: mgAnchorOf(anchorContext),
        items: [
          for (final value in {...inactiveSessionTtlChoices, days})
            MgMenuItem(
              label: inactiveSessionTtlLabel(l10n, value),
              leading: SelectionCheck(checked: value == days),
              onSelected: () => unawaited(_save(value, generation)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = MgColors.of(context);
    final days = _days;
    final failure = _failure;
    final error = switch (failure) {
      _Failure.load => l10n.sessionTtlLoadFailed,
      _Failure.write => l10n.sessionTtlWriteFailed,
      _Failure.readback => l10n.sessionTtlReadbackFailed,
      null => null,
    };
    return SettingsGroup(
      title: l10n.sessionTtlTitle,
      footer: Semantics(
        liveRegion: true,
        child: SettingsFooter(
          error ?? l10n.sessionTtlHint,
          error: error != null,
        ),
      ),
      children: [
        Builder(
          builder: (context) => SettingsRow(
            key: const ValueKey('sessionTtlPeriod'),
            title: l10n.sessionTtlPeriod,
            subtitle: _busy && days != null
                ? (_checking ? l10n.sessionTtlChecking : l10n.sessionTtlSaving)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (days != null)
                  Text(
                    inactiveSessionTtlLabel(l10n, days),
                    style: mgTextStyle(c, color: c.fg2),
                  ),
                if (_busy) ...[
                  if (days != null) const SizedBox(width: MgSpace.s),
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      // Indeterminate progress repeats forever in Flutter;
                      // reduced motion uses a stable, non-ticking ring.
                      value: MediaQuery.disableAnimationsOf(context)
                          ? 0.65
                          : null,
                      strokeWidth: 1.6,
                      color: c.fg2,
                    ),
                  ),
                ],
                if (failure != null)
                  SettingsButton(
                    label: l10n.tryAgain,
                    onPressed: () => unawaited(_load()),
                  ),
              ],
            ),
            chevron: !_busy && days != null,
            onTap: _busy || days == null ? null : () => _openMenu(context),
          ),
        ),
      ],
    );
  }
}
