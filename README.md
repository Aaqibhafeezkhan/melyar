<div align="center">

# Melyar

**A local-first desktop music player with a Liquid Glass-inspired interface.**

[English](README.md) · [Türkçe](README.tr.md)

[![CI](https://github.com/MAKHMUDuz/melyar/actions/workflows/ci.yml/badge.svg)](https://github.com/MAKHMUDuz/melyar/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE-APACHE)

</div>

---

Melyar brings music discovery, playback, lyrics, queues, and a personal listening
library into one desktop application. It is built around a **Rust core**, a
**Qt/C++ desktop bridge**, and a **React + TypeScript interface**.

Playback is powered by `libmpv`, and stream/metadata resolution goes through
`yt-dlp` and the YouTube `InnerTube` API.

> **Project status: Work in progress.** Melyar is actively developed. Some UI
> interactions and provider integrations are still being refined, so expect
> changes and occasional bugs.

---

## Highlights

- Music playback powered by **mpv**, with stream resolution through `yt-dlp` for
  the current YouTube Music workflow.
- Search and discovery for music available through the currently implemented provider.
- Playback controls including play/pause, previous/next, seeking, volume, shuffle,
  and repeat where supported by the current build.
- **Synchronized LRC lyrics** with timestamped highlighting and plain-text fallback.
- Queue management for upcoming tracks, with gapless prefetch.
- Personal library views for liked tracks, listening history, songs, albums, and artists.
- **Liquid Glass-inspired UI** with translucent surfaces, artwork-focused layouts,
  and animated controls.
- Desktop integration built around native playback controls, **Linux MPRIS**
  (D-Bus) and a **zero-latency Unix socket IPC** for Waybar / Polybar / i3status.
- **Local-first direction:** Melyar does not require a Melyar account or a
  Melyar-hosted cloud service to launch.

Availability can vary by provider, track, operating system, and external service
behavior. See [Roadmap](#roadmap) for integrations that are not yet complete.

---

## Screenshots

Screenshots will be added as the interface stabilizes.

---

## Architecture

Melyar separates its interface, desktop integration, and playback logic:

```
React + TypeScript UI
        │
        │ QWebChannel
        ▼
Qt / C++ bridge
        │
        ▼
Rust core ───── Provider and metadata logic
        │
        ▼
mpv audio playback
```

The C++ ↔ Rust boundary is implemented with the [`cxx`](https://cxx.rs) bridge.
The Rust side runs on a `tokio` runtime; audio is driven synchronously by `libmpv`.

### Main areas

| Directory | Purpose |
|---|---|
| `core_rs/` | Rust core, playback coordination, track models, lyrics, provider logic, and local application data handling. |
| `ui_cpp/` | Qt/C++ integration and the bridge between the web interface and the core. |
| `ui_web/` | React + TypeScript interface, views, components, and Liquid Glass styling. |

The exact directory structure may change during development. Check the repository
before relying on internal APIs.

---

## Current functionality

The current codebase includes the following areas, although some interactions are
still being polished:

- Search and browse available tracks.
- Start playback and control playback state.
- View and manage the playback queue.
- Display synchronized LRC lyrics when timestamped lyrics are available, with
  plain-text fallback.
- Browse songs, liked tracks, history, albums, and artists.
- Use an artwork-focused player and a larger Now Playing view.
- Control playback through the application UI and supported desktop media integrations.

External streaming sources can change their APIs, availability, and access
requirements. Melyar cannot guarantee that every track or provider will always
be available.

---

## Requirements

The current Linux-oriented build requirements:

| Component | Version |
|---|---|
| Rust toolchain and Cargo | ≥ 1.75 |
| CMake | ≥ 3.25 |
| C/C++ build toolchain | C++20 support |
| Qt 6 | Core, Gui, Quick, Qml, WebEngineQuick, WebChannel |
| Node.js | ≥ 20 |
| pnpm | ≥ 9 |
| mpv | ≥ 2.x (`libmpv` development files) |
| pkg-config | — |
| yt-dlp | available on `PATH` |

Install the Qt development packages appropriate for your distribution, including
the Qt WebEngine and WebChannel components required by the project.

<details>
<summary>Distribution examples (Arch / Manjaro, Debian / Ubuntu)</summary>

**Arch / Manjaro**

```bash
sudo pacman -S base-devel cmake rust pkgconf \
    qt6-base qt6-declarative qt6-webengine qt6-webchannel mpv
```

**Debian / Ubuntu**

```bash
sudo apt install build-essential cmake pkg-config rustc cargo \
    qt6-base-dev qt6-declarative-dev qt6-webengine-dev qt6-webchannel-dev \
    libmpv-dev yt-dlp
```

</details>

### Dependency checks

Verify that the required tools are available:

```bash
rustc --version
cargo --version
cmake --version
node --version
pnpm --version
mpv --version
yt-dlp --version
```

If the application cannot resolve a stream, first confirm that `yt-dlp` is
installed, executable, and available in the environment used to launch Melyar.

---

## Build from source

```bash
git clone https://github.com/MAKHMUDuz/melyar.git
cd melyar
```

### 1. Build the web UI

```bash
cd ui_web
pnpm install
pnpm build
cd ..
```

The compiled bundle is committed under `ui_web/dist/`, so this step is only
required when the interface sources change.

### 2. Build the desktop application

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
```

### 3. Run

```bash
./build/melyar
```

If the executable is produced at a different path in your branch, use the output
path reported by CMake.

---

## Installation

```bash
sudo cmake --install build
```

CMake's default install prefix is `/usr/local`:

| File | Path |
|---|---|
| Binary | `/usr/local/bin/melyar` |
| Web UI | `/usr/local/share/melyar/web/` |
| Desktop entry | `/usr/local/share/applications/melyar.desktop` |
| Icon | `/usr/local/share/icons/hicolor/scalable/apps/melyar.svg` |

To install into the system directory instead:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
sudo cmake --install build
```

The application resolves the web UI in this order: current working directory →
next to the binary → `/usr/share/melyar/web/` → `/usr/local/share/melyar/web/`.
To point it at a live Vite dev server, set `MELYAR_DEV_URL`.

### Arch / AUR

A `PKGBUILD` is included in the repository:

```bash
makepkg -si
```

---

## Waybar / status bar integration

Melyar runs a zero-latency Unix Domain Socket IPC server at
`$XDG_RUNTIME_DIR/melyar.sock`, for use with Waybar, Polybar, Hyprland and
i3status.

`~/.config/waybar/config.jsonc`:

```jsonc
"custom/melyar": {
    "format": "{icon} {}",
    "return-type": "json",
    "exec": "socat -u UNIX-CONNECT:${XDG_RUNTIME_DIR:-/tmp}/melyar.sock -",
    "on-click": "echo toggle | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "on-click-right": "echo next | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "on-click-middle": "echo prev | nc -U ${XDG_RUNTIME_DIR:-/tmp}/melyar.sock",
    "interval": 1
}
```

Supported commands: `toggle`, `next`, `prev`, `stop`.

Full setup instructions, CSS, and Hyprland/Sway keybinding examples are in
[`docs/WAYBAR.md`](docs/WAYBAR.md).

---

## Local data

| Data | Location |
|---|---|
| Database (favorites, history, lyrics cache) | `~/.local/share/melyar/melyar.db` |
| IPC socket | `$XDG_RUNTIME_DIR/melyar.sock` |

---

## Roadmap

The following are goals and ongoing areas of work; **do not assume every item is
already implemented**:

- Stabilize responsive layout, panel stacking, and Liquid Glass transitions.
- Improve lyrics timing, active-line highlighting, and manual-scroll behavior.
- Finish reliable queue, sharing, and context-menu interactions.
- Refine local music library scanning and portable library import/export.
- Build a provider/plugin architecture that allows optional integrations.
- Investigate library import or migration workflows for Spotify, Apple Music, and
  Yandex Music where supported by legitimate export formats or documented APIs.
- Improve performance, accessibility, error handling, and automated testing.

Third-party services may require their own accounts, subscriptions, authorization,
or API access. Melyar does not make paid features of another service free, and
integrations must respect that service's terms and technical restrictions.

---

## Development

After changing the Rust core, run the checks supported by the current workspace:

```bash
cargo fmt --all
cargo clippy --manifest-path core_rs/Cargo.toml --all-targets
cargo test --manifest-path core_rs/Cargo.toml
```

For UI changes:

```bash
cd ui_web
pnpm build
```

Then rebuild the desktop application if the change affects Qt integration or
packaged UI assets:

```bash
cd ..
cmake --build build -j"$(nproc)"
```

Every push to `master` runs the same checks automatically via
[GitHub Actions](.github/workflows/ci.yml): Rust format/lint/build, TypeScript
typecheck, web bundle build, and a full Qt6 CMake build.

Before submitting a change, test the affected feature in the actual desktop
application — not only in a browser preview. In particular, verify playback,
seeking, lyrics synchronization, queue behavior, panel open/close behavior, and
window resizing when those areas are touched.

---

## Privacy and accounts

- Melyar itself does not require a Melyar user account to launch.
- The project is designed to keep the desktop experience local-first and avoid
  requiring a Melyar-hosted cloud backend.
- External providers may perform network requests and may have their own
  authentication, privacy policy, subscription, and usage requirements.
- Never commit credentials, access tokens, personal listening data, or local
  configuration files to the repository.
- Do not claim that an external integration is anonymous or account-free unless
  its actual implementation and provider requirements have been verified.

Local persistence details may evolve during development. Consult the current
implementation before making claims about a specific storage format or
database-free operation.

---

## Contributing

Contributions, bug reports, and focused pull requests are welcome.

Before submitting a change:

1. Explain the problem and the intended behavior.
2. Keep changes focused and avoid unrelated rewrites.
3. Preserve working playback and bridge behavior.
4. Include tests or reproducible verification steps where practical.
5. Do not add dependencies without a clear technical reason.
6. Do not commit build output, credentials, personal data, or machine-specific paths.

For UI changes, include screenshots or a short recording when useful. For
playback or lyrics fixes, provide reproducible steps and relevant logs with
secrets removed.

---

## Bug reports

When reporting a bug, include:

- Operating system and desktop environment.
- Melyar version or commit.
- Steps to reproduce the issue.
- Expected behavior and actual behavior.
- Relevant logs, with tokens and private data removed.

For layout issues, include the window size and whether the queue or expanded
player was open. For lyrics issues, include the track, playback position, and
whether the lyrics are timestamped or plain text.

---

## License

Melyar is dual-licensed. You may use it under the terms of either:

- **MIT** — [`LICENSE-MIT`](LICENSE-MIT)
- **Apache License 2.0** — [`LICENSE-APACHE`](LICENSE-APACHE)

`SPDX-License-Identifier: MIT OR Apache-2.0`

---

## Acknowledgements

Melyar builds on open-source software and is inspired by modern desktop
music-player design and Liquid Glass visual concepts. All third-party projects
remain the property of their respective authors and are subject to their own
licenses.

---

## Notes

- Melyar is an unofficial client. It is not affiliated with, endorsed by, or
  sponsored by YouTube, Google, Spotify, or any other provider.
- Content licenses, account terms, and the laws of your jurisdiction apply to
  you as the end user.

---

<div align="center">
<sub>Built with Rust, Qt 6, React and a lot of care for the details.</sub>
</div>
