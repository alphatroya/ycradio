# Ycradio

A macOS menu bar radio for
[YourClassical Radio](https://ycradio.stream.publicradio.org/ycradio.aac).

- Left click toggles play / pause. The icon shows the state: `music.note` (playing),
  `hourglass` (buffering), `pause` (paused).
- Pausing keeps the buffered stream for 15 s: resuming inside that window plays
  instantly from where it stopped. Resume later and it reconnects at the live edge.
- Media keys (play / pause / toggle) work through the Now Playing center.
- Hovering the icon shows the state and, while playing, the current track.
- Right click opens the stream menu: pick any
  [YourClassical stream](https://www.yourclassical.org/listen/streams) (15 of them,
  the current one checked). The choice is remembered between launches, the icon
  tooltip shows it, and the current-track feed follows it.
- Right click also has **Quit**.
- Long press (0.45 s) shows the current track in a small floating panel.

## Build and run

```sh
make test        # Swift Testing suite
make app         # release build into Ycradio.app
make run         # build and open
```

The app is a menu bar extra only (`LSUIElement`), so `swift run` also works,
but media keys are more reliable from the `.app` bundle.

## Layout

- `Sources/YcradioCore` – the stream catalogue (`RadioStream`), playback
  (`RadioPlayer`), its state and icon mapping, and the current-track feed
  (`NowPlayingClient`, the same websocket feed yourclassical.org uses).
- `Sources/Ycradio` – AppKit status item, SwiftUI track panel, media keys.
- `Support/Info.plist` – bundle metadata used by `make app`.
- `Support/AppIcon.icns` – app icon, drawn by `Support/MakeIcon.swift` (`make icon`).
