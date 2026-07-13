# Eden AppImage Linux Runner Design

## Goal

Provide a repeatable Linux validation path for Eden's Steam Deck AppImage without requiring WSL, a game, firmware, or console keys.

## Decision

Use a dedicated GitHub Actions workflow on `ubuntu-latest`. WSL is unavailable on the development machine, while the repository already uses GitHub-hosted Ubuntu runners for ShellCheck.

## Workflow behavior

The workflow will run manually and when the Eden installer, launcher, or workflow changes. It will:

1. Fetch Eden's official nightly release page.
2. Apply the same Steam Deck artifact-selection rules as `Eden_install`: clang-PGO first, then gcc-standard.
3. Fail if neither artifact is found or if the selected URL is unreachable.
4. Download the selected AppImage to the runner's temporary directory.
5. Confirm the file is an ELF binary and an AppImage Type 2 image.
6. Run `--appimage-extract` and require the extracted `AppRun` entry point.

The workflow will report the selected URL, derived build version, byte count, and SHA-256 hash in its logs.

## Boundaries

- This validates release discovery, download integrity, and basic Linux executable packaging.
- It does not launch a game or require firmware, product keys, or ROMs.
- It does not claim SteamOS-specific coverage such as controller mappings, Flatpak behavior, FUSE mounting, Steam integration, or frontend launch behavior.
- The job uses only Eden's official release host and GitHub-hosted Ubuntu runners.

## Alternatives rejected

- Local WSL: unavailable because its Windows platform component cannot be installed from this environment.
- Docker: not installed on the development machine.
- Game-based testing: deferred until a SteamOS environment and user-owned test material are available.
