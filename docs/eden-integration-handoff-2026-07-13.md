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

## Next edge cases

1. Test first-time install and update paths against both Eden nightly artifact variants and release-page changes.
2. Test firmware/key links after path migration and clean uninstall/reinstall.
3. Test ABXY and BAYX layouts with one through five controllers.
4. Validate SRM, ES-DE, Pegasus, and launcher behavior with the same Switch game set.
5. Confirm CloudSync behavior when Eden is both installed and absent.
6. Check deterministic default-emulator behavior when Eden, Citron, and Ryujinx are all installed.
