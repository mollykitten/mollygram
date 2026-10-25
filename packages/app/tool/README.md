# Native notification tone smoke probe (macOS)

The probe exercises the production `NotificationToneStore`: MP3 decoding to
PCM CAF, default/silent/quiet selection, actual `AVAudioPlayer` playback,
account namespaces, invalid-file rejection and converted-file cleanup.
It does **not** sign in, change an account, ask for notification permission,
or post to Notification Center. Playback is a short generated tone at 10%
volume; do not run it if audible output would be disruptive.

From the repository root, with Xcode command-line tools and `ffmpeg` installed:

```sh
work="$(mktemp -d "${TMPDIR%/}/mollygram-tone-probe.XXXXXX")"
ffmpeg -hide_banner -loglevel error -f lavfi \
  -i 'sine=frequency=880:duration=0.35' -codec:a libmp3lame "$work/probe.mp3"
swiftc packages/app/macos/Runner/NotificationToneStore.swift \
  packages/app/tool/notification_tone_probe.swift -o "$work/probe"
"$work/probe" "$work/probe.mp3" "$work/Sounds"
```

The final lines must report `PASS missing input fails closed` and
`PASS default/silent/quiet/custom PCM CAF/native playback/account isolation/cleanup`.
The MP3 is generated locally; there are no copied Telegram audio assets.
This native probe complements, rather than replaces, Flutter/core tests and
an actual macOS application build.
