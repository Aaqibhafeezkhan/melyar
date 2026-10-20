## What this changes

<!-- What does this pull request do, and which problem does it solve? -->

## Why

<!-- The reasoning. The diff already shows what changed. -->

Closes #

## How it was verified

<!-- Be specific. "Works on my machine" is not verification. -->

- [ ] `cargo fmt --all -- --check`
- [ ] `cargo clippy --manifest-path core_rs/Cargo.toml --all-targets -- -D warnings`
- [ ] `cargo test --manifest-path core_rs/Cargo.toml`
- [ ] `pnpm exec tsc --noEmit` and `pnpm build` (if `ui_web/` changed)
- [ ] `cmake --build build` (if the build setup changed)
- [ ] Manual test in the desktop application

**Manual test steps:**

<!--
For playback or lyrics changes, describe what you listened to and what you
observed. For UI changes, say which panels you opened and resized.
-->

## Screenshots

<!-- Required for visual changes. Before and after is ideal. -->

## Checklist

- [ ] The change is focused and does not contain unrelated edits
- [ ] Build output, credentials, personal data, and machine-specific paths are not committed
- [ ] `ui_web/dist/` is regenerated and committed if `ui_web/src/` changed
- [ ] No new dependency without a stated technical reason
- [ ] Native playback and the C++/Rust bridge still work
