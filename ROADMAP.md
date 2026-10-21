# Melyar Roadmap

Melyar is a native YouTube Music client for Linux. This document is the honest
version of where it is, where it is going, and what you can pick up.

For the current feature set, see the [README](README.md).
For the system design, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## The positioning

There are other YouTube Music clients. Two of them are good. This is why
Melyar exists anyway, and what it has to prove.

| | Melyar | Spotube | BloomeeTunes | Official YouTube Music |
|---|---|---|---|---|
| Language stack | Rust + Qt6/QML + React | Flutter/Dart | Flutter/Dart | Electron/Web |
| Linux | Native | Native | Native | Native (web app) |
| Other platforms | — | Win, macOS, Android, iOS, Web | Win, macOS, Android, iOS, Web | Win, macOS, Android, iOS, Web |
| Runtime footprint | Small (no bundled browser engine beyond Qt WebEngine) | Large | Large | Large |
| MPRIS | Full | Partial | Partial | No |
| Status bar IPC (Waybar/Polybar) | Built in | No | No | No |
| License | MIT OR Apache-2.0 | BSD-4 | GPL-2.0 | Proprietary |
| Cross-platform | No | Yes | Yes | Yes |

**The bet:** on Linux, a native client that integrates with the desktop
properly beats a cross-platform one that does not. Melyar is not trying to
out-muscle Spotube on Windows. It is trying to be the best client *on Linux*.

Three concrete bets:

1. **Native beats emulated.** A Rust core with a Qt shell starts fast, holds a
   small memory footprint, and responds to key presses and IPC without a
   framework in between. No Flutter engine, no Electron process tree.
2. **Desktop integration is a feature, not a checkbox.** MPRIS, a Waybar socket
   with sub-millisecond latency, global media keys, and a proper `.desktop`
   integration are the difference between an application and a native citizen.
3. **Permissive licensing.** MIT or Apache-2.0 lets distributors embed it.
   GPL-2.0 does not.

### Where the competitors are currently stronger

Being honest about this is part of the pitch:

- **Cross-platform.** Melyar is Linux-only. Spotube and BloomeeTunes run
  everywhere.
- **Provider breadth.** BloomeeTunes reaches several services; Melyar speaks
  InnerTube only, with Spotify and Apple Music import on the roadmap but not
  built.
- **Maturity.** Both competitors have years of history. Melyar has months.
- **Mobile.** Neither competitor's mobile story is a target for Melyar.

Closing the first two gaps is what turns "promising Linux client" into "the
client to switch to".

---

## Milestones

### M1 - Solid Linux citizen

*Make the native experience complete before adding breadth.*

- [x] Rust core: InnerTube client, cipher solver, stream resolution
- [x] mpv playback engine with gapless prefetch
- [x] Synchronized LRC lyrics with plain-text fallback
- [x] SQLite library: favorites, history, search history
- [x] MPRIS D-Bus service
- [x] Waybar / Polybar / i3status socket IPC
- [x] Global media and application shortcuts
- [x] `.desktop` entry, scalable SVG icon, AUR packaging
- [x] **Internationalisation** - the interface is English and Turkish, with a
      language switcher and a translation system new contributors can extend
- [x] **Twelve languages** - English, Turkish, Spanish, German, French, Italian,
      Portuguese, Russian, Ukrainian, Japanese, Chinese and Korean
- [x] **Settings persist across restarts** - a settings panel backed by the
      core's SQLite database: theme, accent colour, language, compact mode,
      animations, crossfade, gapless, streaming quality and the playback
      preferences
- [ ] **Right-to-left languages** - the layout uses physical margins in a few
      places, so Arabic and Hebrew need the spacing converted to logical
      properties first
- [ ] **Keyboard-first navigation** - full focus traversal, visible focus rings
- [ ] **Accessibility pass** - screen reader labels, contrast in the light
      theme, respect for the reduced-motion preference everywhere
- [ ] **Crash-safe database writes** - the history table is written on every
      track change

### M2 - Library that works

*Turn the library from a list into a usable collection.*

- [ ] **Library import / export** as portable JSON, so a user is never locked in
- [ ] **Local music folder support** - scan a directory, merge it with the
      streamed library
- [ ] **Smart playlists** - recently added, most played, never finished
- [ ] **Playlist editing** - reorder, remove, rename, add to
- [ ] **Offline metadata cache** - browse your library without a network

### M3 - Provider breadth

*Reach the libraries users actually have, legally.*

- [ ] **Spotify library import** via the official export format and the
      documented API where permitted
- [ ] **Apple Music library import** likewise
- [ ] **Provider plugin architecture** - a documented interface so a provider
      can be added without touching the core
- [ ] **Provider-agnostic search** with a unified result model

> These integrations must respect each service's terms, API access rules, and
> rate limits. Melyar does not make paid features of another service free.

### M4 - Cross-platform, if it earns its place

*Only after the Linux experience is genuinely excellent.*

- [ ] Evaluate a Wayland + X11 portable shell, and a macOS / Windows build of
      the QML layer with the Rust core unchanged
- [ ] Decide honestly whether the added surface is worth the maintenance cost,
      and publish the decision either way

---

## Good first issues

These are scoped so that a new contributor can finish them without needing to
understand the whole system.

**Rust core**
- [ ] Cache resolved stream URLs for the duration of a track to avoid
      re-resolving on prefetch
- [ ] Add `Display` implementations for the error types in `core_rs`
- [ ] Cover the InnerTube parser with unit tests for the shapes it actually
      receives

**Web interface**
- [ ] Wire `ui_web/src/lib/lyrics.test.ts` into CI with `vitest`
- [ ] Add a `vitest` job to the `web-ui` workflow
- [ ] Extract the duplicated glass surface styling into one shared component
- [ ] Add a reduced-motion audit for the `LiquidLyricsView` animations
- [ ] **Translate Melyar into your language** - the easiest first contribution
      there is. Copy `ui_web/src/locales/en.ts`, translate the values, register
      the locale in `ui_web/src/lib/i18n.ts`, and add a flag to `LOCALES`.
      No TypeScript knowledge is needed, only the language.

**Qt / QML**
- [ ] Move the web UI path resolution into a small helper with unit tests
- [ ] Add a `QML` linting step to CI

**Build and packaging**
- [ ] Add a `deb` packaging recipe alongside the existing `PKGBUILD`
- [ ] Publish a `flake.nix` for Nix users
- [ ] Cache the Cargo registry in CI to cut build time

**Documentation**
- [ ] Expand `docs/WAYBAR.md` with Polybar and i3status examples
- [ ] Document the SQLite schema in `docs/`

---

## How to claim an issue

Comment on the issue to say you are picking it up, then open a pull request
against the relevant branch. If you are unsure where a change belongs,
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) describes the boundaries.

Not sure what to start with? Open a
[discussion](https://github.com/MAKHMUDuz/melyar/discussions) and ask.

---

## Beyond the roadmap

Ideas that do not fit any milestone are welcome as
[feature requests](https://github.com/MAKHMUDuz/melyar/issues/new?template=feature_request.yml).
The ones that get worked on will end up here.
