# EmuDeck

[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-908a85?logo=gitpod)](https://gitpod.io/from-referrer/)
<img src="https://www.emudeck.com/img/hero.png">

EmuDeck is a collection of scripts that allows you to autoconfigure your Steam Deck or any other Linux Distro, it creates your roms directory structure and downloads all of the needed Emulators for you along with the best configurations for each of them. EmuDeck works great with [Steam Rom Manager](https://github.com/SteamGridDB/steam-rom-manager) or with [EmulationStation DE](https://es-de.org)

Ready to switch it up and go full Steam ahead, with handheld-friendly defaults and room for the whole couch to join in.

### A note on Switch emulation and Nintendo's patents

You may notice Switch emulators in this space have a habit of disappearing, getting renamed, or changing hands (Yuzu, Ryujinx, Citra → Lime3DS...). Nintendo has leaned on patents as part of that pressure, not just copyright/DMCA claims. Whether those patents actually read on how these emulators work is genuinely contested — a fair number of engineers and IP lawyers who've looked at them think they're broad, of debatable validity, or asserted more as a deterrent than because of an airtight infringement case. We're not going to pretend we have a definitive legal opinion here.

Writing and distributing emulator software is legal; what you dump, download, or run through it is a separate question that's on you. This fork keeps community-maintained Switch emulators (like Eden) configured on that basis.

(Also, for the record: our balls are round, thrown underhand, and only good for catching bugs in the tracker — no meter in the corner of the screen telling you the odds first. And renaming one a "Spherical Capture Apparatus" wouldn't save us anyway — patents cover what a thing does, not what you call it. That's trademark's job.)

### What this fork adds

Beyond stock EmuDeck, this fork adds:

- **Eden support** — a nightly, Steam Deck-optimized AppImage installer for [Eden](https://git.eden-emu.dev) with version tracking, so updates only re-download when there's actually a new build.
- **Shared Switch storage** across Eden, Citron, and Ryujinx — one common data folder instead of each emulator keeping its own separate copy.
- **Eden set as the default Switch emulator** in ES-DE automatically once it's installed (falls back to Ryujinx otherwise), plus its own SRM parser, find rules, and BIOS check.
- **ABXY/BAYX controller layout switching and full uninstall support** for Eden, matching what the other standalone emulators already had.
- **Version-tracked Ryujinx installs** so it also only re-downloads Canary builds when a newer tag is actually out.

## How to use EmuDeck?

We recommend you take a look at our extensive Wiki, you'll find guides, videos and all sorts of content about the project:

[EmuDeck Wiki](https://emudeck.github.io/how-to-install-emudeck/steamos/)

## Developers, developers, developers.

If you wanna help us improve EmuDeck we are open to accept your PR! Just keep in mind this simple guide:

- Think that EmuDeck is for everybody, tech savvy and is specially directed to regular users that are new to Emulation, so everything has to be properly explained.
- Things using sudo are a big no no, there are exceptions but always try to find a way of prevent using sudo.
- Every Emulator needs to have a SRM profile and follow the AmberElec hotkey mapping.
- Always do your PR to the dev branch.

## Submitting a PR Request for a Steam ROM Manager Parser

If you would like to submit a PR request for a Steam ROM Manager parser, use the following format:

### The Basics

- Spell out console names - no acronyms
  - For example, `PSP` should be spelled out as `PlayStation Portable`
- Respect original capitalization and spacing
  - A few examples:
    - `RetroArch` uses a capital `R` and capital `A`
    - The `Nintendo Game Boy` uses a capital `N`, `G`, and `B` with spaces between each word
    - The `PlayStation Portable` uses a capital `P` and `S` in `PlayStation` as do the other `PlayStation` handhelds and consoles

### Parser Structure

- `configTitle`:
  - `COMPANYNAME SYSTEMNAME - EMULATORNAME RETROARCHCORENAME`
    - If the standalone emulator name is identical to the RetroArch core name, add `(Standalone)` behind the `EMULATORNAME`
  - A few examples:
    - Config Title: `"configTitle": "Amiga - RetroArch PUAE",`
    - Config Title: `"configTitle": "Nintendo Game Boy Color - mGBA (Standalone)",`
    - Config Title: `"configTitle": "Sony PlayStation 2 - PCSX2",`
- `steamCategory`:
  - **Note:** Non-Default Parsers refer to when a system has multiple emulation choices (through alternative emulators or RetroArch cores). Only one of these parsers is enabled by default and any alternative choices are disabled by default.
  - Default Parsers:
    - `COMPANYNAME CONSOLENAME`
  - Non-Default Parsers:
    - Standalone: `COMPANYNAME CONSOLENAME - EMULATORNAME`
    - RetroArch Core: `COMPANYNAME CONSOLENAME - RETROARCHCORENAME`
      - If the RetroArch core's name is identical to the Standalone emulator name, add `RetroArch` in front of the `RETROARCHCORENAME`
      - If the standalone emulator name is identical to the RetroArch core name, add `(Standalone)` behind the `EMULATORNAME`
  - A few examples:
    - Default Parsers:
      - Mupen64Plus Next (RetroArch core for Nintendo 64)
        - Steam Category Name: `"steamCategory": ""${Nintendo 64}",`
      - DuckStation (PSX Emulator)
        - Steam Category Name: `"steamCategory": "${Sony PlayStation}",`
    - Non-Default Parsers:
      - Rosalie's Mupen GUI (N64 Emulator)
        - Steam Category Name: `"steamCategory": "${Nintendo 64 - Rosalie's Mupen GUI}",`
      - Beetle PSX HW (RetroArch core for PSX)
        - Steam Category Name: `"steamCategory": "${Sony PlayStation - Beetle PSX HW}",`

### Parser Filename

`companyname_systemname-emulatorname-retroarchcore.json`

If it is a RetroArch core, replace `emulatorname` with `ra`.

- A few examples:
  - `nintendo_wii-dolphin.json`
  - `nintendo_64-rmg.json`
  - `nintendo_gba-ra-mgba.json`
  - `sega_saturn-ra-mednafen.json`
 
## Credits

### Configurations

* bbilford83
   * Tweaked and fine-tuned the Model 2 Emulator and Supermodel for EmuDeck on SteamOS
* Warped Polygon
   * Created the wonderful controls for the Model 2 Emulator and Supermodel
   * [Model 2 Emulator](https://forums.launchbox-app.com/files/file/3926-sega-model-2-emulator-everything-pre-configured-inc-controls-for-pc-controller-mouse-light-guns-test-menus-configured-analogue-inputs-calibrated-free-play-all-games-in-english-2-player-mouse-support-no-screen-flash/)
   * [Supermodel](https://forums.launchbox-app.com/files/file/3857-sega-model-3-supermodel-git-everything-pre-configured-inc-controls-for-pc-controller-mouse-light-guns-test-menus-configured-free-play-all-games-in-english-2-player-mouse-support-audio-adjusted-layout-imagesthe-whole-9-yards/)

### Contributors

* AngelofWoe
* doctorjei
* DragoonDoorise
* DylanTackoor
* exp111
* EXtremeExploit
* frostymm 
* Godsbane
* GloriousEggroll
* JesseTG
* Kardbord
* KingIzzymon
* rawdatafeel
* Rosalie241 
* SilentException
* WedgeSparda
* WingOfAGriffin
