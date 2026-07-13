# Eden / Switch integration handoff — 2026-07-13

## Snapshot status

This note records the Eden/Switch work before more edge-case investigation. During upload, `main` was found to already contain the same integration and later audited fixes, including `bbdebfe4` (Eden integration and shared Switch storage/keys/firmware). This handoff is therefore documented on top of the current remote `main` without replacing any newer code.

## Work captured

- Eden nightly installation discovers a Steam Deck release artifact, preferring the clang PGO AppImage and falling back to the gcc standard AppImage.
- Eden is integrated with installation, setup, migration, BIOS folders/checks, CloudSync health, launchers, uninstall, ES-DE, Pegasus, and Steam ROM Manager.
- The integration adds Eden storage, firmware/key paths, a Steam ROM Manager parser, Pegasus metadata, and Eden frontend discovery rules.
- Eden configuration is updated from Citron-specific names and paths to Eden-specific values.
- Controller setup supports players 1–5 and both ABXY and BAYX layouts during Eden initialization.
- Settings and JSON conversion include Eden defaults and compatibility fallbacks for older payloads.
- The shared configuration-line updater uses fixed-string matching for exact replacement.

## Local verification before upload

- Bash syntax validation passed for every changed shell script.
- `versions.json` and the Eden Steam ROM Manager parser parsed successfully as JSON.
- ES-DE emulator rules parsed successfully as XML.
- Git's whitespace/conflict-marker check passed.

Functional tests still require a configured SteamOS/EmuDeck environment. GitHub Actions runs ShellCheck for the repository.

## Published Linux packaging validation

Commit `06b53a3c` adds `Eden AppImage Validation`, a GitHub-hosted Ubuntu
workflow that exercises the official nightly discovery path without games,
firmware, keys, or ROMs. The first run succeeded:

- Run: `29288265245`
- Artifact: `Eden-Linux-9a0e6b3c28-steamdeck-clang-pgo.AppImage`
- Build identifier: `9a0e6b3c28`
- Downloaded bytes: `74695448`
- SHA-256: `67933c1d36661cdb025e3aa0873195ecbf393d9681be6d71ea0df06d563f26fe`

The workflow validates the selected AppImage as ELF/AppImage Type 2, extracts
it, and requires an executable `squashfs-root/AppRun`. It does not launch a
game or test SteamOS desktop, Steam, controller, frontend, firmware, or key
behavior.

## Confirmed edge cases

1. **Fresh setup can create Eden integration without Eden installed.**
   Default settings enable `doSetupEden` while disabling `doInstallEden`.
   `Eden_init` then unconditionally adds the Steam ROM Manager parser,
   launcher, desktop shortcut, and (if present) ES-DE configuration. A fresh
   default setup can therefore expose a non-functional Eden entry.

2. **Firmware health can be a false positive.** `Eden_setEmulationFolder`
   always creates `putfirmwarehere.txt` in the shared firmware directory.
   `checkEdenBios` only requires any firmware-directory entry plus
   `prod.keys`; with keys and only that placeholder, it reports that the BIOS
   is ready even though no firmware content exists.

3. **Switch-emulator setup jobs race on Steam ROM Manager configuration.**
   Setup starts Yuzu, Citron, Eden, and Ryujinx in the same background batch.
   Each can call `addParser`, which reads and rewrites the shared
   `userConfigurations.json` through the same relative `temp.json` filename.
   The read-modify-write operations are not serialized, so parsers can be
   lost or the temporary file can be overwritten.

4. **Resolution changes do not target Eden's actual Qt settings.**
   `Eden_setResolution` delegates to `RetroArch_setConfigOverride`, which
   searches for `resolution_setup =` and `use_docked_mode =`. Eden's template
   uses no-space keys inside `[Renderer]` and `[System]`. The helper instead
   appends new lines after the final INI section, leaving the real settings
   unchanged and placing the values in the wrong section.

5. **Existing non-symlink BIOS folders are not safely migrated.**
   `unlink` cannot replace a real `bios/eden/keys` or `bios/eden/firmware`
   directory. The subsequent `ln -sfn` can create a nested link rather than
   replace the folder. User material left in the old BIOS directory is then
   neither migrated to nor consumed from the shared Switch location.

6. **Backslash-bearing controller default keys cannot be reliably updated.**
   `updateOrAppendConfigLine` finds keys such as
   `player_0_button_a\default=` literally, but `changeLine` does not escape
   backslashes for its `sed` match. A pre-existing default flag can therefore
   survive unchanged even though the caller believes it was updated.

7. **Uninstall leaves a broken launcher and desktop entry.**
   `Eden_uninstall` removes the parser and AppImage but not the deployed
   launcher copies or `eden.desktop`. The remaining launcher looks for an
   AppImage and then tries to run a matching Flatpak; after a normal AppImage
   uninstall with no Flatpak installed, the surviving desktop entry fails.

8. **Locale support is dormant.** `Eden_setLanguage` contains the mapping and
   configuration logic, but `Eden_init` only contains a commented-out call.
   Fresh setup therefore retains the template language and region rather than
   applying the user's locale.

## Remaining edge cases

1. Test first-time install and update paths against both Eden nightly artifact variants and release-page changes.
2. Test firmware/key links after path migration and clean uninstall/reinstall.
3. Test ABXY and BAYX layouts with one through five controllers.
4. Validate SRM, ES-DE, Pegasus, and launcher behavior with the same Switch game set.
5. Confirm CloudSync behavior when Eden is both installed and absent.
6. Check deterministic default-emulator behavior when Eden, Citron, and Ryujinx are all installed.
