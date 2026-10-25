# native notification tone smoke probe (macOS)

the probe exercises the production `NotificationToneStore`: MP3 decoding to
PCM CAF, default/silent/quiet selection, actual `AVAudioPlayer` playback,
account namespaces, invalid-file rejection and converted-file cleanup.
it does **not** sign in, change an account, ask for notification permission,
or post to Notification Center. playback is a short generated tone at 10%
volume, so don't run it if audible output would be disruptive.

from the repository root, with xcode command-line tools and `ffmpeg` installed:

```sh
work="$(mktemp -d "${TMPDIR%/}/mollygram-tone-probe.XXXXXX")"
ffmpeg -hide_banner -loglevel error -f lavfi \
  -i 'sine=frequency=880:duration=0.35' -codec:a libmp3lame "$work/probe.mp3"
swiftc packages/app/macos/Runner/NotificationToneStore.swift \
  packages/app/tool/notification_tone_probe.swift -o "$work/probe"
"$work/probe" "$work/probe.mp3" "$work/Sounds"
```

the final lines must report `PASS missing input fails closed` and
`PASS default/silent/quiet/custom PCM CAF/native playback/account isolation/cleanup`.
the MP3 is generated locally, there are no copied telegram audio assets.
this native probe complements Flutter/core tests and an actual macOS
application build, it doesn't replace them.
