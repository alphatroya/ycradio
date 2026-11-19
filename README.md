# Ycradio

A macOS menu bar radio for
[YourClassical Radio](https://ycradio.stream.publicradio.org/ycradio.aac).

- Left click toggles play / pause. The icon shows the state: `music.note` (playing),
  `hourglass` (buffering), `pause` (paused).
- Media keys (play / pause / toggle) work through the Now Playing center.
- Right click opens a menu with **Quit**.
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

- `Sources/YcradioCore` – playback (`RadioPlayer`), its state and icon mapping,
  and the current-track feed (`NowPlayingClient`, the same websocket feed
  yourclassical.org uses).
- `Sources/Ycradio` – AppKit status item, SwiftUI track panel, media keys.
- `Support/Info.plist` – bundle metadata used by `make app`.
