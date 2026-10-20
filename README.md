Melyar
A local-first desktop music player with a Liquid Glass-inspired interface.

Melyar brings music discovery, playback, lyrics, queues, and a personal listening library into one desktop application. It is built around a Rust core, a Qt/C++ desktop bridge, and a React + TypeScript interface.
Project status: Work in progress. Melyar is actively developed. Some UI interactions and provider integrations are still being refined, so expect changes and occasional bugs.

Highlights
- Music playback powered by mpv, with stream resolution through yt-dlp for the current YouTube Music workflow.
- Search and discovery for music available through the currently implemented provider.
- Playback controls including play/pause, previous/next, seeking, volume, shuffle, and repeat where supported by the current build.
- Lyrics with LRC timestamp parsing and plain-text fallback when synchronized lyrics are unavailable.
- Queue management for upcoming tracks.
- Personal library views for liked tracks, listening history, songs, albums, and artists.
- Liquid Glass-inspired UI with translucent surfaces, artwork-focused layouts, and animated controls.
- Desktop integration designed around native desktop playback controls and Linux MPRIS support.
- Local-first direction: Melyar does not require a Melyar account or a Melyar-hosted cloud service to launch.
Availability can vary by provider, track, operating system, and external service behavior. See Roadmap for integrations that are not yet complete.
Screenshots
Screenshots will be added as the interface stabilizes.
Architecture
Melyar separates its interface, desktop integration, and playback logic:
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
Main areas:
- core_rs/ — Rust core, playback coordination, track models, lyrics, provider-related logic, and local application data handling.
- ui_cpp/ — Qt/C++ integration and the bridge between the web interface and the core.
- ui_web/ — React + TypeScript interface, views, components, and Liquid Glass styling.
The exact directory structure may change during development. Check the repository before relying on internal APIs.
Current functionality
The current codebase includes the following areas, although some interactions are still being polished:
- Search and browse available tracks.
- Start playback and control playback state.
- View and manage the playback queue.
- Display synchronized LRC lyrics when timestamped lyrics are available, with plain-text fallback.
- Browse songs, liked tracks, history, albums, and artists.
- Use an artwork-focused player and a larger Now Playing view.
- Control playback through the application UI and supported desktop media integrations.
External streaming sources can change their APIs, availability, and access requirements. Melyar cannot guarantee that every track or provider will always be available.
Roadmap
The following are goals and ongoing areas of work; do not assume every item is already implemented:
- Stabilize responsive layout, panel stacking, and Liquid Glass transitions.
- Improve lyrics timing, active-line highlighting, and manual-scroll behavior.
- Finish reliable queue, sharing, and context-menu interactions.
- Refine local music library scanning and portable library import/export.
- Build a provider/plugin architecture that allows optional integrations.
- Investigate library import or migration workflows for Spotify, Apple Music, and Yandex Music where supported by legitimate export formats or documented APIs.
- Improve performance, accessibility, error handling, and automated testing.
Third-party services may require their own accounts, subscriptions, authorization, or API access. Melyar does not make paid features of another service free, and integrations must respect that service's terms and technical restrictions.
Requirements
The following are the current Linux-oriented build requirements. Confirm exact version requirements against the checked-out branch and its build files.
- Rust toolchain and Cargo
- CMake and a C/C++ build toolchain
- Qt 6 with the modules used by the project, including WebEngine/Quick and WebChannel components
- Node.js 20 or newer
- pnpm 9 or newer
- mpv and the libmpv development library
- yt-dlp available on PATH
On Linux, install the Qt development packages appropriate for your distribution, including the Qt WebEngine and WebChannel components required by the project.
Build from source
Clone the repository and enter the project directory:
git clone <repository-url>
cd melyar
Replace <repository-url> with the URL of your Melyar repository.
1. Build the web UI
cd ui_web
pnpm install
pnpm build
cd ..
2. Build the desktop application
cmake -S . -B build
cmake --build build -j"$(nproc)"
3. Run
./build/melyar
If the executable is produced at a different path in your branch, use the output path reported by CMake.
Dependency checks
Verify that the required tools are available:
rustc --version
cargo --version
cmake --version
node --version
pnpm --version
mpv --version
yt-dlp --version
If the application cannot resolve a stream, first confirm that yt-dlp is installed, executable, and available in the environment used to launch Melyar. Playback and provider availability can also be affected by external services.
Development
After changing the Rust core, run the checks supported by the current workspace:
cargo check
cargo test
For UI changes:
cd ui_web
pnpm build
Then rebuild the desktop application if the change affects Qt integration or packaged UI assets:
cd ..
cmake --build build -j"$(nproc)"
Before submitting a change, test the affected feature in the actual desktop application—not only in a browser preview. In particular, verify playback, seeking, lyrics synchronization, queue behavior, panel open/close behavior, and window resizing when those areas are touched.
Privacy and accounts
- Melyar itself does not require a Melyar user account to launch.
- The project is designed to keep the desktop experience local-first and avoid requiring a Melyar-hosted cloud backend.
- External providers may perform network requests and may have their own authentication, privacy policy, subscription, and usage requirements.
- Never commit credentials, access tokens, personal listening data, or local configuration files to the repository.
- Do not claim that an external integration is anonymous or account-free unless its actual implementation and provider requirements have been verified.
Local persistence details may evolve during development. Consult the current implementation before making claims about a specific storage format or database-free operation.
Contributing
Contributions, bug reports, and focused pull requests are welcome.

Before submitting a change:
1. Explain the problem and the intended behavior.
2. Keep changes focused and avoid unrelated rewrites.
3. Preserve working playback and bridge behavior.
4. Include tests or reproducible verification steps where practical.
5. Do not add dependencies without a clear technical reason.
6. Do not commit build output, credentials, personal data, or machine-specific paths.
For UI changes, include screenshots or a short recording when useful. For playback or lyrics fixes, provide reproducible steps and relevant logs with secrets removed.
Bug reports
When reporting a bug, include:
- Operating system and desktop environment.
- Melyar version or commit.
- Steps to reproduce the issue.
- Expected behavior and actual behavior.
- Relevant logs, with tokens and private data removed.
For layout issues, include the window size and whether the queue or expanded player was open. For lyrics issues, include the track, playback position, and whether the lyrics are timestamped or plain text.
License
Choose and add a license file before publishing or distributing the project. Until a LICENSE file is present, the repository's license is unspecified; do not assume that public availability automatically grants permission to reuse, modify, or redistribute the code.
Acknowledgements
Melyar builds on open-source software and is inspired by modern desktop music-player design and Liquid Glass visual concepts. All third-party projects remain the property of their respective authors and are subject to their own licenses.
