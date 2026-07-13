# Eden AppImage Linux Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repeatable GitHub-hosted Linux test that validates Eden's Steam Deck AppImage without games, firmware, or keys.

**Architecture:** A dedicated workflow runs only on demand and when Eden installation or launcher files change. Its Bash step mirrors `Eden_install`'s release-selection order, downloads the chosen artifact, checks the ELF and AppImage Type 2 header, then extracts the image and verifies its `AppRun` entry point.

**Tech Stack:** GitHub Actions, Ubuntu runner, Bash, curl, file, xxd, sha256sum.

## Global Constraints

- Use only `https://git.eden-emu.dev/eden-ci/nightly/releases/` and the selected official `nightly.eden-emu.dev` artifact URL.
- Prefer `steamdeck-clang-pgo`; use `steamdeck-gcc-standard` only if PGO is absent.
- Download no firmware, keys, ROMs, or game content.
- Treat this as a configuration-only test-runner change; the workflow itself is the test artifact under the user-approved TDD exception for configuration files.
- Keep the existing ShellCheck workflow unchanged.

---

### Task 1: Add the Eden AppImage validation workflow

**Files:**
- Create: `.github/workflows/eden-appimage.yml`
- Test: GitHub Actions workflow run named `Eden AppImage Validation`

**Interfaces:**
- Consumes: the official Eden nightly release page and the selection format implemented by `Eden_install` in `functions/EmuScripts/emuDeckEden.sh`.
- Produces: an Actions log containing `selected_url`, `derived_version`, `downloaded_bytes`, and `sha256`, or a non-zero job for discovery, download, format, or extraction failure.

- [ ] **Step 1: Create the workflow with the following content**

```yaml
name: Eden AppImage Validation

on:
  workflow_dispatch:
  push:
    paths:
      - 'functions/EmuScripts/emuDeckEden.sh'
      - 'functions/installEmuAI.sh'
      - 'tools/launchers/eden.sh'
      - '.github/workflows/eden-appimage.yml'
  pull_request:
    paths:
      - 'functions/EmuScripts/emuDeckEden.sh'
      - 'functions/installEmuAI.sh'
      - 'tools/launchers/eden.sh'
      - '.github/workflows/eden-appimage.yml'

permissions:
  contents: read

jobs:
  validate-appimage:
    name: Discover, download, and extract Eden
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4

      - name: Validate the current Steam Deck AppImage
        shell: bash
        run: |
          set -euo pipefail

          release_page_url='https://git.eden-emu.dev/eden-ci/nightly/releases/'
          release_page="$(curl --fail --location --silent --show-error "$release_page_url")"
          clang_pattern='https://nightly\.eden-emu\.dev/[^"[:space:]]*/Eden-Linux-[^"[:space:]]*-steamdeck-clang-pgo\.AppImage'
          gcc_pattern='https://nightly\.eden-emu\.dev/[^"[:space:]]*/Eden-Linux-[^"[:space:]]*-steamdeck-gcc-standard\.AppImage'

          selected_url="$(grep -Eo "$clang_pattern" <<< "$release_page" | head -n 1 || true)"
          selected_variant='clang-pgo'
          if [[ -z "$selected_url" ]]; then
            selected_url="$(grep -Eo "$gcc_pattern" <<< "$release_page" | head -n 1 || true)"
            selected_variant='gcc-standard'
          fi

          [[ -n "$selected_url" ]]
          file_name="$(basename "$selected_url")"
          derived_version="$(sed -E 's/^Eden-Linux-([^-]+)-.*$/\1/' <<< "$file_name")"
          [[ -n "$derived_version" && "$derived_version" != "$file_name" ]]

          curl --fail --location --retry 2 --output Eden.AppImage "$selected_url"
          [[ "$(file --brief Eden.AppImage)" == *ELF* ]]
          [[ "$(xxd -p -l 12 Eden.AppImage)" == 7f454c46*41490200 ]]

          chmod +x Eden.AppImage
          ./Eden.AppImage --appimage-extract >/dev/null
          [[ -x squashfs-root/AppRun ]]

          echo "selected_variant=$selected_variant"
          echo "selected_url=$selected_url"
          echo "derived_version=$derived_version"
          echo "downloaded_bytes=$(stat --format=%s Eden.AppImage)"
          echo "sha256=$(sha256sum Eden.AppImage | awk '{print $1}')"
```

- [ ] **Step 2: Commit the workflow**

```bash
git add .github/workflows/eden-appimage.yml
git commit -m "ci: validate Eden Steam Deck AppImage"
```

### Task 2: Verify the hosted Linux test

**Files:**
- Modify: `.github/workflows/eden-appimage.yml` only if the first run exposes a workflow or artifact-format failure.
- Test: `Eden AppImage Validation` in GitHub Actions.

**Interfaces:**
- Consumes: the pushed workflow created in Task 1.
- Produces: a completed successful job whose log contains the four required summary fields.

- [ ] **Step 1: Push the workflow commit to `main`**

```bash
git push origin HEAD:main
```

- [ ] **Step 2: Confirm the workflow run succeeds**

Expected log fields:

```text
selected_variant=clang-pgo
selected_url=https://nightly.eden-emu.dev/...
derived_version=<Eden build identifier>
downloaded_bytes=<positive integer>
sha256=<64 lowercase hexadecimal characters>
```

- [ ] **Step 3: If the runner fails, preserve the log and change only the failing workflow command**

Run the workflow again after the single correction. A valid result must still download no game, firmware, keys, or ROMs.

- [ ] **Step 4: Commit any one-command correction separately**

```bash
git add .github/workflows/eden-appimage.yml
git commit -m "ci: fix Eden AppImage validation"
git push origin HEAD:main
```

## Plan Self-Review

- Scope is limited to one new workflow; the existing CI and emulator behavior are untouched.
- Task 1 covers discovery, selection fallback, download, ELF/AppImage validation, extraction, and logging from the approved design.
- Task 2 covers the hosted execution and requires one isolated correction per failed run.
- The plan contains no placeholders or unspecified file paths.
