# Where Melyar stands

A comparison against the other YouTube Music clients, with the numbers
measured rather than estimated.

The short version: Melyar is not yet the lightweight client it wants to be,
and the reason is structural rather than a matter of polish. This document
lays out the measurements, the gaps, and the two ways forward.

Everything in the memory section was measured on Arch Linux, Qt 6.12, mpv
2.5, on an idle machine with the application running and no playback.

---

## 1. The memory picture

| Configuration | Resident memory |
|---|---|
| Native Qt Quick shell, no web engine | **64 MB** |
| Empty Qt WebEngine window | **315 MB** |
| Melyar, as it was | 494 MB |
| Melyar, with the GPU stack turned off | **435 MB** |
| Melyar, also in a single process | 395 MB |

Three things follow from this table.

**The web engine is the whole story.** An empty Qt WebEngine window costs
315 MB. That is 64 percent of Melyar's footprint before a single line of
Melyar code runs. The React interface itself is cheap: loading the real
interface into an empty web engine adds about 9 MB.

**We were paying for a GPU we do not use.** Breaking the main process down
through `/proc/PID/smaps` showed where the 370 MB actually sat:

| Mapping | Resident | What it is |
|---|---|---|
| `libQt6WebEngineCore.so` | 67 MB | Chromium core |
| anonymous | 54 MB | Chromium's own allocations |
| `libLLVM.so` | 33 MB | The V8 just-in-time compiler |
| `libnvidia-gpucomp.so` | 27 MB | NVIDIA compute driver |
| `libgallium` | 14 MB | Mesa's software rasteriser |
| `libnvidia-glcore.so` | 12 MB | NVIDIA OpenGL |
| `/dev/nvidiactl` | 10 MB | NVIDIA device |
| `libnvidia-eglcore.so` | 7 MB | NVIDIA EGL |
| heap | 25 MB | Everything else |

About 70 MB was the graphics stack. A music player draws no video, so it was
paying for a GPU it never used, and because only compositing was disabled
Mesa's software rasteriser was pulled in as a fallback. Turning the whole
stack off is now part of the default flags and saves 59 MB.

**The single-process mode is not worth it.** It saves another 40 MB and drops
the process count from three to one, which is attractive. But Chromium logs
`Cannot use V8 Proxy resolver in single process mode`, the mode is not
supported for production use, and a media player that spends its life talking
to the network is the wrong place to take that risk. It is left off.

### What the numbers mean against the field

| Player | Memory | Source |
|---|---|---|
| ytcast-open | 13 MB idle, 41 MB streaming | measured by the project |
| Spotifast | 100-250 MB | the project's own figure |
| Elisa | 206 MB | rox.music benchmark |
| Strawberry | 434 MB | rox.music benchmark |
| Museeks | 436 MB | rox.music benchmark |
| Spotube | ~341 MB under playback | one user's `top` output in issue #2467 |
| Official Spotify | ~650 MB | community reports |
| **Melyar** | **435 MB** | measured here |

Every client in the Electron or Chromium family sits between 340 and 650 MB.
Melyar is in that family. It is not the lightweight client yet.

---

## 2. The feature picture

| | Melyar | Spotube | BloomeeTunes | Limusic |
|---|---|---|---|---|
| Stack | Rust + Qt6 + React | Flutter | Flutter + Rust core | Rust + Tauri + Svelte |
| Equalizer | setting only | **no** | 10-band, all platforms | 10-band |
| Plugin system | no | metadata + audio source | sandboxed `.bex` | no |
| Download / offline | no | yes | yes | yes |
| Local music | no | yes | yes | yes |
| Last.fm scrobbling | no | yes | yes | yes |
| Discord presence | no | yes | yes | yes |
| Word-by-word lyrics | no | no | yes | yes |
| MPRIS | yes, native | yes, buggy | yes | yes |
| Status bar socket | **yes** | no | no | no |
| Languages | 13 | 30 | 6 | 18 |
| Uses an account | no | Spotify account | no | optional |

Two things stand out.

**Spotube has no equalizer.** Issue #465 has been open since April 2023,
with duplicates closed as such. It is the most requested feature in the
project. We already have the settings for one, so this is the cheapest
meaningful gap to close.

**We are the only one with a status bar socket.** Waybar, Polybar and
i3status integration is not something the others have at all, and it is
cheap for us because the socket server is already written.

---

## 3. The real threat

The research on how these projects behave in practice turned up the same
story repeatedly: the clients do not break because of missing features, they
break because YouTube changes things underneath them.

- ytmdp issue #213, April 2026: playback freezes at 0:49 for every track,
  blamed on a server-side change.
- ytmdp issue #247, August 2026: no audio plays at all, even for Premium.
- Spotube issue #2947: the whole app broken by HTTP 429 from InnerTube.
- yt-dlp issue #17406: a 429 on the first page fetch means the visitor data
  cannot be obtained, and every later step fails with it.
- The NewPipe maintainer, on InnerTube: *"A massive pain point for third
  party youtube apps like newpipe which break every few months due to it."*

**This is the single most important thing to fix.** A client that is
slightly heavier but never breaks beats a client that is light and stops
playing.

And Melyar has the same exposure, in three specific places.

**We depend on an external program for playback.** `get_stream_url` calls
`yt-dlp` first and only falls back to our own InnerTube path if that fails.
That means every user needs Python and a current `yt-dlp`, and inherits its
update cycle and its breakage cycle.

**The fallback uses a client identity from 2024.** The fallback player
request sends `clientName: WEB_REMIX` with `clientVersion:
1.20240403.01.00`. The research is explicit that client versions drift and
that a pool with automatic fallback is now the norm: `YTMUSIC` with
`ANDROID_VR` and `TVHTML5` behind it, yt-dlp as the last resort.

**We have no PO Token support.** PO Tokens are now required for the
`web_music` client, which is the YouTube Music client. They come from
BotGuard, DroidGuard or iOSGuard, they are bound to a single video, and
without one the media URLs come back as HTTP 403. Premium subscribers are
exempt, which is why some of this is easy to miss.

The good news: we already have the hard part. `core_rs/src/innertube/cipher.rs`
interprets the cipher actions in pure Rust, with no JavaScript runtime. Most
of the ecosystem shells out to `yt-dlp`, or embeds Node, Deno or QuickJS to
run the EJS solver. We do not need a runtime for the transform we handle.

---

## 4. The two ways forward

### Path A: keep the web interface, get lighter

Turn off what is not needed, shrink the bundle, defer loading the engine.

Result: about 435 MB, a few weeks of work, and still in the Electron class.
It does not win the "ultra lightweight" argument, because the 315 MB
Chromium baseline is the floor for any web-engine interface.

### Path B: make the native interface the default

The important discovery: **the native interface already exists.**
`ui_cpp/qml/components/` holds 7208 lines of QML across 39 components, with
a home view, a player bar, a settings view, a search view, album and
playlist details, a queue, synced lyrics, an equalizer band, a colour
picker and a shortcut editor. Every bridge method those components call
exists in the current bridge. It is not a rewrite. It is a shell that never
got assembled, left behind when the web interface replaced it.

That changes the arithmetic:

| | Path A | Path B |
|---|---|---|
| Interface | Qt WebEngine | native QML |
| Steady memory | 435 MB | ~120-150 MB |
| Processes | 3 | 1-2 |
| Where the UI lives | `ui_web/src`, ~5000 lines of TSX | `ui_cpp/qml`, 7208 lines |
| Extra work | small | the QML view has to catch up on i18n, settings and import |

A 120-150 MB client would be the lightest of the serious ones by a wide
margin, and it would be the one that looks like it belongs on the desktop.

**And it solves the fragility problem in the same move.** Limusic, the
project that has the best reputation for not breaking, mints its PO Tokens
in a hidden webview that is isolated from the interface. The insight is that
you need a browser engine for the token, but you do not need one for the
interface. A native interface plus a small on-demand token helper gets
both: the light footprint and the robustness.

---

## 5. Recommendation

**Path B for the interface, with a token helper for robustness.**

The order matters, because the light interface is what makes the difference
visible, and the robustness is what keeps the client in use.

1. **Finish the immediate wins.** The GPU flags are done, 59 MB saved.
   Next: defer the web engine until the interface is visible, and split the
   bundle so the locale tables load on demand. Thirteen locales are
   compiled into one file today.
2. **Make the QML interface real.** Assemble the 7208 lines into a root
   view, wire it to the bridge, and ship it as the default with the web
   interface behind a flag. Bring it to parity in the order that matters:
   the equaliser, the settings, the import, the translations.
3. **Build the equaliser.** The settings exist, the UI exists in QML
   (`EqualizerBand.qml`), and mpv has a filter chain that is waiting for
   it. Spotube has wanted this since 2023.
4. **Own the fragility.** A client pool with automatic fallback, an embedded
   JavaScript runtime for the parts of the cipher we cannot interpret in
   Rust yet, and a PO Token provider. Make `yt-dlp` optional rather than
   required. This is the work that turns "a client" into "the client that
   keeps working".
5. **Then the features the competitors have:** offline downloads, local
   music, Last.fm, a plugin architecture for providers.

The plugin architecture is worth doing early even though it looks like a
feature. It is the answer to the fragility problem, and it is how the
community adds providers without touching the core.

---

## 6. Honest summary of the position

**Ahead of the field:** status bar integration, native MPRIS, a permissive
licence, a Rust core, a cipher solver that needs no JavaScript runtime, and
a native interface that is already written.

**Level with the field:** playback, search, the library, lyrics, MPRIS, the
language count, packaging.

**Behind the field:** memory use, the equaliser, downloads, local music,
scrobbling, plugins, and above all robustness when YouTube changes things.

**The one thing that would change the ranking:** a native interface. It
turns the weakest number into the strongest one, and the work is mostly
already on disk.

---

## Sources

Memory figures for Melyar were measured here; the other projects' figures
come from their issue trackers, the rox.music benchmark (published by a
competing product, so treat it as a rough cross-check) and the projects'
own claims. The state of the InnerTube API comes from the yt-dlp PO Token
guide, the yt-dlp issue tracker and the client projects' own changelogs.
