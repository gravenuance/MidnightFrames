# Changelog

All notable changes to MidnightFrames are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Saved frame sizes and positions now reach the frames after a reload. The
  profile database and every unit frame were built while the files loaded,
  before WoW had assigned the saved variables; both now run from this
  addon's `ADDON_LOADED`, and the second `InitDB` at `PLAYER_LOGIN` is gone.
- The reload popup no longer references `STATICPOPUP_NUMDIALOGS`, a global
  that no longer exists in 12.1.5.
- The addon now lists the 12.1.5 interface version (120105) in its `.toc`.

### Added
- Offline test suite (`lua5.1 tests/run.lua`) for the pure-logic modules,
  run by CI and kept out of the release zip.

## [1.1.1] - 2026-09-12

### Fixed
- Raid frames could stay stacked at a stale position after a roster change
  landed mid-combat, if combat ended without any other raid-frame event
  following to retry the layout.

### Changed
- `UNIT_AURA` (the hottest event this addon handles) no longer allocates a
  fresh table and closure per call; the aura-icon builder reuses one shared
  scratch table instead.

## [1.1.0] - 2026-09-03

### Changed
- Options panel stripped of explanatory paragraphs — controls now stand on
  their labels and layout alone.
- Test mode is one internal service (`MF.Test`) instead of six globals and
  three parallel lookup tables spread across the frame files.
- The eight `UNIT_SPELLCAST_*` registrations and their dispatch branch,
  previously copy-pasted into six frame files, moved to
  `MF.RegisterCastEvents` / `MF.IsCastEvent`.
- Per-group frame counts and repeated highlight colors pulled into named
  constants (`MF.GroupSize`, `Setup.lua` locals).

### Added
- `MF_DB` carries a `schemaVersion`; load migrates an older shape forward
  and warns instead of crashing on a newer one.
- `luacheck` config and a lint workflow that runs on every push and PR.
- Release workflow: pushing a `vX.Y.Z` tag builds the addon zip and a
  GitHub Release from this file's matching section.
- Dependabot for GitHub Actions.

### Fixed
- Debug `print()` calls on internal failure paths no longer leak into the
  chat frame.
- `Enum.DispelType` shim is a file local instead of a write to the shared
  global `Enum` table.
- Loss-of-control category check goes through `MF.IsSecretSafe` rather than
  calling `issecretvalue` unguarded.

## [1.0.0]

First changelogged release. Vertical player/target/party/arena/boss frames,
raid frames, pet and focus frames, class-colored gradient health bars,
filtered auras, PvP trinket and DR tracking, raid target markers, a compact
cast indicator, range checking, profile-backed settings, and Move Mode.
