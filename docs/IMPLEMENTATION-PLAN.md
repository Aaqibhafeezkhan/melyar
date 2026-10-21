# Implementation plan

What has to be done to make Melyar the client that is both the lightest and
the one that keeps working.

This follows [COMPETITIVE.md](COMPETITIVE.md), which contains the
measurements and the comparison. This document is the work breakdown.

**How to read it**

- **Effort** is in working days for one person who knows the codebase.
- **Risk** is the chance of the work going wrong, not the chance of it being
  unnecessary. Everything in phase 1 is necessary; the risk is about the
  schedule.
- **Payoff** is the measurable result, in resident memory unless stated
  otherwise.

---

## The two things that matter

1. **Weight.** At 435 MB we are in the same class as Electron clients, and
   the Chromium baseline of 315 MB is most of it. The native interface
   already exists in the repository, so this is not a rewrite.
2. **Durability.** Every project in this space breaks when YouTube changes
   something underneath it. We have three concrete exposures: a hard
   dependency on `yt-dlp` for playback, a fallback path that still
   identifies itself with a client version from 2024, and no PO Token
   support.

A client that is 130 MB and never breaks beats one that is 90 MB and stops
playing. The order of the phases follows that.

---

## Phase 0 - Weight

### 0.1 Turn the graphics stack off - DONE

The browser engine was loading the whole GPU stack for an interface that
draws no video. Disabling it rather than only the compositing saved 59 MB,
494 MB became 435 MB.

**File:** `ui_cpp/main.cpp`
**Result:** 435 MB, measured

### 0.2 Split the locale tables out of the main bundle

Thirteen locales are compiled into the interface bundle, which is 136 KB of
the 429 KB of JavaScript. A user only ever reads one of them.

**Worth doing, but not for the reason it first appears.** The bundle is read
from the local disk, so a hundred kilobytes costs nothing at startup. The
gain is a smaller repository and a faster build, and it only becomes a real
saving once the project has thirty languages, where the tables would be
around 300 KB.

**What to do**

1. Move each locale file behind a dynamic import in
   `ui_web/src/lib/i18n.ts`, so only the detected locale is fetched.
2. Keep `en` bundled, because it is the fallback and the most common one.
3. Load the others on demand when the language is switched.
4. Cache the loaded tables in a module level map so switching back and forth
   does not refetch.

**Acceptance criteria**

- The initial bundle no longer contains the other twelve locales.
- Switching to a language that has not been loaded yet still works and does
  not flash the key names.

**Effort:** 1 day. **Payoff:** a smaller repository rather than a faster
start.

### 0.3 Do not start the browser engine before it is needed

The engine is created when the window opens, whether or not the interface
that needs it is on screen. The native interface does not need it at all.

**What to do**

- Only create the web view when the web interface is actually selected.
- When the native interface is the default, the engine never starts, and
  with it the 315 MB Chromium baseline.

**Acceptance criteria**

- Starting the application with the native interface shows no
  `QtWebEngineProc` in the process list.

**Effort:** 1 day. **Depends on:** phase 1.3.7.

### 0.4 A memory budget that fails the build when it regresses

Weight is the thing we are selling, and it is the thing that quietly
regresses. A number in a document does not protect it.

**What to do**

1. Add a step to the `desktop-app` job that starts the application with a
   throwaway data directory, waits for the window, and reads the resident
   memory from `/proc/<pid>/status`.
2. Fail the job when the total goes above a budget. Start at 460 MB for the
   web interface, and lower it as the native interface takes over.
3. Print the figure in the job summary so a change is visible.

**Acceptance criteria**

- A change that costs 30 MB of memory fails the build.

**Effort:** 1 day.

---

## Phase 1 - The native interface

### 1.1 What is already in the repository

`ui_cpp/qml/components/` holds **7208 lines across 41 components**. It is a
complete interface, not a sketch.

| Already there | Lines |
|---|---|
| `SettingsView.qml` with `SettingRow`, `ShortcutEditor`, `ColorPicker` | 880 + 39 + 38 + 37 |
| `PlayerBar.qml` | 695 |
| `HomeView.qml` | 534 |
| `SearchView.qml` | 434 |
| `Sidebar.qml` | 403 |
| `AlbumDetailView.qml`, `PlaylistDetailView.qml` | 408, 343 |
| `FloatingLiquidPlayer.qml` | 364 |
| `VirtualTrackList.qml`, `ArtistDetailView.qml` | 233, 231 |
| `LiquidLyricsView.qml`, `SyncedLyrics.qml` | 167, 165 |
| `LibraryView.qml`, album and artist grids and items, and the rest | 1200 |

The components read from the bridge the same way the web interface does,
through `bridge.currentTitle`, `bridge.isPlaying`, `bridge.favorites` and the
rest. They were written against an earlier bridge, and the bridge has moved
on since.

### 1.2 The gap

Checked mechanically against the current bridge:

| Question | Answer |
|---|---|
| Bridge members the QML calls | 46 |
| Of those, present in the bridge today | **43** |
| Missing | `searchAlbums`, `searchArtists`, `searchPlaylists` |
| Bridge members the QML does not use yet | 18, including `loadSettings`, `saveSetting`, `importLibrary`, `importProgress`, `requestFilePick`, `pendingUri`, `openUri` |

That last row is the important one. **Everything built in the last two
releases is already reachable from the QML interface without touching the
bridge.** The settings persistence, the library import and the deep links
all have their bridge methods in place, unused by the native side.

Two components have real work left in them:

- `Sidebar.qml:369` - creating a playlist is not wired to the bridge.
- `SearchView.qml:296,321,345` - the album, artist and playlist sections
  use placeholder models of 10 and 20 rows, with a comment in the source
  saying the bridge properties would need to be added.

### 1.3 The steps

#### 1.3.1 A root view

There is no root view that assembles the components. `Main.qml` is 94 lines
and holds only the web engine.

**What to do**

1. Add `ui_cpp/qml/NativeShell.qml` with the window chrome: the sidebar on
   the left, the player bar at the bottom, and a `StackView` or `Loader` in
   the middle that swaps between the home, search and library views.
2. Drive the view from the bridge. The QML side already tracks an
   `activeTab` string, which is enough to start with.
3. Load it from `main.cpp` when the native interface is selected.

**Acceptance criteria**

- The window opens, the sidebar renders, and the player bar shows the
  current track.
- Switching views works.

**Effort:** 3 days. **Risk:** medium. This is the part with no reference
implementation, so it is where the surprises will be.

#### 1.3.2 The three missing search methods

**What to do**

1. Add `searchAlbums`, `searchArtists` and `searchPlaylists` to the bridge.
   They are `Q_INVOKABLE` methods that return a `QVariantList` of maps, the
   same shape as `searchResults` already uses.
2. Behind them, call the InnerTube browse endpoints. The Rust core can
   already reach them, so the work is a thin Rust function per call, plus
   the parsing that `innertube/parser.rs` already does for search results.
3. Wire the three `ListView`s in `SearchView.qml` to the new properties.

**Acceptance criteria**

- Searching for an artist returns albums, artists and playlists, and the
  three sections fill.

**Effort:** 2 days. **Risk:** low. The parsing work already exists.

#### 1.3.3 Settings that survive a restart

`SettingsView.qml` has a `settings` QtObject with about twenty properties.
It changes them and forgets them.

**What to do**

1. On the view opening, read `bridge.loadSettings()`, which returns the
   settings as a JSON string, and push the values into the `settings`
   object.
2. On every change, call `bridge.saveSetting(key, value)`. The keys are
   already defined in the Rust core and in `ui_web/src/lib/settings.ts`, so
   both interfaces write the same rows and either can read what the other
   wrote.
3. Add the keys that only exist on the native side: the shortcuts map, the
   streaming quality, the proxy settings.

**Acceptance criteria**

- A setting changed in the panel is still there after a restart.
- A setting changed in the web interface shows up in the native one.

**Effort:** 2 days. **Risk:** low.

#### 1.3.4 The library import

**What to do**

1. Call `bridge.requestFilePick()`. The native file dialog is already in
   `Main.qml` and already answers with `bridge.setPickedFile(url)`.
2. On the answer, call `bridge.importLibrary(path)`.
3. Follow `bridge.importProgress` for the progress, and `bridge.loadFavorites`
   when it finishes.

The Rust side needs no change at all. It reads the export, matches every
entry and writes the result.

**Acceptance criteria**

- A Spotify export can be imported from the native interface and the
  matches appear in the library.

**Effort:** 1 day. **Risk:** low.

#### 1.3.5 Deep links

`bridge.openUri` and `bridge.pendingUri` are already there. The native
interface reads the URI and acts on it: `melyar://settings`,
`melyar://search/<query>`, `melyar://track/<id>`.

**Effort:** 1 day. **Risk:** low.

#### 1.3.6 Translations

The QML interface is in English. The web interface is in thirteen
languages.

**What to do**

1. Add a small QML translation helper that loads a JSON table from
   `ui_web/src/locales/`, so the tables are shared rather than duplicated.
2. Replace the literals in the QML with `qsTr()` style calls, or with calls
   to the helper.
3. Start with the navigation, the player bar and the settings, which is
   where most of the text is.

**Effort:** 4 days for a first pass over the visible text, more for the
whole interface. **Risk:** medium, because it touches every file.

**Note:** the QML side already has a `Melyar.Theme` singleton with the
colours and the metrics. Moving the locale tables next to it keeps the two
in one place.

#### 1.3.7 Choosing between the two interfaces

**What to do**

1. Add a command line flag and a setting: `--web` for the web interface,
   the native one by default.
2. The `MELYAR_DEV_URL` environment variable already forces the web
   interface for development, so keep that working.
3. Report the choice in the log line that already says which interface was
   loaded.

**Acceptance criteria**

- The native interface is the default.
- `--web` still opens the web interface.
- `MELYAR_DEV_URL` still works for web development.

**Effort:** 1 day. **Risk:** low.

### 1.4 What the phase is worth

| | Before | After |
|---|---|---|
| Resident memory | 435 MB | **about 130-150 MB** |
| Processes | 3 | 1 |
| Startup | web engine start | none |

The 130-150 MB figure is the measured native shell at 64 MB, plus mpv and
the Rust core.

### 1.5 The risks, stated plainly

- **The native interface is behind.** The web interface has the settings
  panel, the import, the translations and the newer Liquid Glass work. The
  native one has to catch up. Phase 1.3.3, 1.3.4 and 1.3.6 are the work
  that closes the gap, and they are in the plan for that reason.
- **Two interfaces is two of everything.** Every feature from here on has
  to be built twice until one of them is retired. The web interface stays
  as the reference implementation, and the native one becomes the product.
- **The 7208 lines are untested.** They compile, and every method they
  call exists, but nobody has run them. Budget for the surprises in
  1.3.1.

---

## Phase 2 - The equaliser - DONE

The most requested feature in the whole space, and the one we could close
cheapest.

**Why it was cheap**

- The setting existed: `equalizerEnabled` in the settings table.
- The interface existed: `EqualizerBand.qml`, a slider from -12 to +12 dB.
- mpv has the filters: `af` with `lavfi=[equalizer=...]`.
- The engine already talks to mpv through `mpv_command_string`, so no new
  plumbing was needed.

**What was done**

1. `set_equalizer_bands` in the Rust engine builds the whole chain as one
   lavfi filter and hands it to mpv in a single command, so the equaliser is
   replaced in one go rather than one command per band. The band centres are
   the usual octave centres, 31 Hz to 16 kHz.
2. The bridge exposes it as `setEqualizerBands`, and the interface stores the
   gains in the settings as a JSON array.
3. The settings panel shows one slider per band and applies the change as it
   is made.
4. The command the core builds is covered by a test that runs against a real
   mpv: the chain has to be accepted, and a filter that does not exist has to
   be reported. The second half matters, because it is what proves the first
   half is not vacuous.

**Acceptance criteria**

- Moving a band changes the sound. MET
- The setting survives a restart, and the bands are restored with it. MET

**Effort:** 2 days. **Risk:** low.

**Note:** Spotube has wanted this since April 2023 and still has not built
it. BloomeeTunes has it on every platform. This is the cheapest visible
difference available.

---

## Phase 3 - Durability

The part that decides whether Melyar is still here in a year.

### 3.1 A pool of InnerTube clients

**The problem:** the fallback path sends `clientName: WEB_REMIX` with
`clientVersion: 1.20240403.01.00`, a version from April 2024. Client
versions drift, and a single fixed identity is exactly what breaks.

**What to do**

1. Try a list of client identities in order: `YTMUSIC`, `ANDROID_VR`,
   `TVHTML5`, `WEB_REMIX`.
2. Read the API key and the client version from the live web client at
   runtime rather than hardcoding them, the way the other clients do.
3. Remember which identity worked last and try it first.
4. When one starts failing, move to the next and log it.

**Acceptance criteria**

- A change on the server that breaks one client identity does not stop
  playback.

**Effort:** 3 days. **Risk:** medium, because the identities are not
documented and have to be checked against the live service.

### 3.2 PO Tokens

**The problem:** the `web_music` client needs a PO Token for anything
beyond GVS. It comes from BotGuard, it is bound to a single video, and
without one the media URLs come back as HTTP 403. Premium accounts are
exempt, which is why this is easy to miss.

**What to do**

1. Get a token per video, from a provider that can produce one.
2. The options, in order of how much they cost:
   - a hidden webview that runs the BotGuard flow, the way Limusic does it.
     We already have a web engine, so this is the cheapest.
   - a separate short lived helper process, the way the `bgutil` sidecar
     works, at about 66 MB while it runs and nothing while it does not.
   - a pure Rust implementation, which is not realistic.
3. Cache the token per video and the player response it belongs to.
4. A token expires, so fetch a new one when a request comes back 403.

**Acceptance criteria**

- Playback works on a free account.

**Effort:** 5 days for the hidden webview approach. **Risk:** high, since
it depends on a flow YouTube does not document.

### 3.3 The parts of the cipher that Rust cannot interpret yet

**The problem:** `core_rs/src/innertube/cipher.rs` interprets the cipher
actions in pure Rust, with no JavaScript runtime. That covers the signature
transform. The `n` parameter needs the full evaluation of a function that
YouTube changes regularly.

**What to do**

1. Embed a JavaScript runtime in the Rust core. `boa` is a pure Rust
   engine with no system dependencies; `rquickjs` wraps QuickJS and is
   faster, at the cost of a build dependency.
2. Run the `n` transform in the embedded runtime, with the Rust
   interpreter handling the cases it can.
3. Keep the runtime optional, so a build without it still works for the
   clients that do not need it.

**Acceptance criteria**

- The `n` parameter is computed without an external process.
- `yt-dlp` is no longer needed for playback.

**Effort:** 5 days. **Risk:** medium.

### 3.4 Make `yt-dlp` optional

**What to do**

1. Once 3.2 and 3.3 work, `yt-dlp` becomes a fallback rather than the
   primary path.
2. The README and the packaging stop requiring it. It stays supported,
   because it is a good escape hatch when YouTube changes something.

**Acceptance criteria**

- A fresh install without `yt-dlp` plays music.

**Effort:** 1 day. **Risk:** low. **Depends on:** 3.2 and 3.3.

---

## Phase 4 - The features the competitors have

In the order that the field has them and we do not.

| Feature | They have it | Notes | Effort |
|---|---|---|---|
| Last.fm scrobbling | all three | A simple HTTP call, but the rules about what counts as a scrobble are fiddly. | 2 days |
| Discord presence | all three | The Discord IPC socket. | 2 days |
| Downloads and offline | Spotube, Bloomee, Limusic | Needs a downloader, a cache format and a policy for what is allowed. | 10 days |
| Local music | Spotube, Bloomee, Limusic | A file scanner and a second source in the queue. | 8 days |
| Word by word lyrics | Bloomee, Limusic | Needs a provider that returns word timings, not line timings. | 5 days |
| More languages | Spotube has 30 | A translation job per language, not a programming job. | 1 day each |

---

## Phase 5 - A plugin architecture

This looks like a feature and is really the answer to phase 3.

**What the competitors do**

- Spotube has metadata provider plugins and audio source plugins. The
  audio source plugins are how it survives a YouTube change: Piped,
  Invidious, NewPipe and JioSaavn are all options.
- BloomeeTunes has `.bex` plugins, a Rust runtime with `waclay` and
  `wasmi`, sandboxed, with a repository that updates itself.

**What to do**

1. Define a provider interface in the Rust core: search, resolve a stream,
   fetch lyrics, list a catalogue.
2. Define a manifest: a name, a version, an endpoint, and what the provider
   can do.
3. Run the providers in a sandbox. The research is clear that a plugin
   system without a sandbox is a liability, because a provider is remote
   code.
4. Ship two providers to begin with: InnerTube, and one alternative source
   such as Piped or Invidious. The second is the point: when YouTube
   breaks, the alternative does not.

**Acceptance criteria**

- A new provider can be added without changing the core.
- A broken provider does not stop the others from working.

**Effort:** 15 days. **Risk:** high, and it should not be started before
phase 3, because the design depends on what the core needs to expose.

---

## Order

```
Phase 0  weight                0.1 done, 0.2 - 0.4 small
  |
  +-- Phase 1  native interface    1.1 - 1.3.7   the big one
  |     1.3.1 root view                     3 days
  |     1.3.2 search methods                2 days
  |     1.3.3 settings persistence          2 days
  |     1.3.4 library import                1 day
  |     1.3.5 deep links                    1 day
  |     1.3.6 translations                  4 days
  |     1.3.7 interface switch              1 day
  |
  +-- Phase 2  equaliser                    2 days   can run in parallel
  |
  +-- Phase 3  durability                  14 days
  |     3.1 client pool                     3 days
  |     3.2 PO tokens                       5 days
  |     3.3 embedded JavaScript runtime     5 days
  |     3.4 yt-dlp optional                 1 day
  |
  +-- Phase 4  the features the field has  28 days
  |
  +-- Phase 5  plugin architecture         15 days
```

Phases 1 and 2 can run in parallel with each other. Phase 3 is where the
schedule risk lives. Phase 5 comes last because its design depends on what
phase 3 exposes.

---

## Effort summary

| Phase | Days | Result |
|---|---|---|
| 0.2 Split the locales | 1 | smaller bundle |
| 0.3 Lazy web engine | 1 | depends on 1.3.7 |
| 0.4 Memory budget in CI | 1 | weight stops regressing |
| 1 Native interface | 14 | **435 MB becomes about 135 MB** |
| 2 Equaliser | 2 | the most requested feature |
| 3 Durability | 14 | **stops breaking when YouTube changes** |
| 4 The missing features | 28 | parity with the field |
| 5 Plugin architecture | 15 | survives the next change |
| **Total** | **76** | |

Phase 1 and phase 2 are what the goal needs. Phases 3 to 5 are what keep
it there.

---

## What not to do

- **Do not rewrite the web interface in QML from scratch.** It exists and
  it works. Bring the native side up to it instead.
- **Do not add a JavaScript runtime before it is needed.** Phase 3.3 is
  three phases away, and the Rust cipher solver covers the common case
  today.
- **Do not build the plugin system before phase 3.** The interface depends
  on what the core exposes, and the core is about to change.
- **Do not chase the feature list.** Spotube has thirty languages and no
  equaliser. The equaliser is worth more than nine languages.
- **Do not add Electron-style web features to the native interface.** A
  music player should not have a browser engine at all.
