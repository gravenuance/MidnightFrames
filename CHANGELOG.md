# Changelog

All notable changes to MidnightFrames are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- In a group of more than 20, MidnightFrames' raid frames stay hidden and
  Blizzard's raid frames take over; back at 20 or fewer, Blizzard's hide
  again. The switch waits for combat to end. Raid frames also re-check their
  visibility when combat ends, since a roster change in combat left them stale.

### Fixed
- Saved frame sizes and positions now reach the frames after a reload. The
  profile database and every unit frame were built while the files loaded,
  before WoW had assigned the saved variables; both now run from this
  addon's `ADDON_LOADED`, and the second `InitDB` at `PLAYER_LOGIN` is gone.
- Arena DR icons no longer flag the first stun as immune. Four tray
  functions were hooked, so one DR update ran the "already active, so
  immune" check about four times; only `UpdateOrAddTrayItem` is hooked now
  and immunity is read from Blizzard's own indicator. A finished tray
  cooldown clears only its own icon instead of every DR icon on the frame.
- Party and raid DR icons (from loss-of-control) no longer re-flag running
  effects as immune or restart their timers on every update. Effects are
  keyed by `auraInstanceID`, and only a new one inside a running window
  counts as a DR hit. Loss-of-control types now map onto the DR categories
  (stun, incap, disorient, silence, disarm, root).
- Blizzard's non-raid-style `PartyFrame` is hidden too, not just the
  raid-style `CompactPartyFrame`.
- Boss frames now appear when a boss is pulled. Visibility was only
  refreshed on zone changes, so the unit watch was never registered; it is
  now registered once at load and only test mode takes it off.
- Blizzard's boss frames are hidden through `MF.HideBlizzardFrame` instead of
  being set to alpha 0, so they can no longer be clicked.
- A duplicate aura (same instance already shown via another filter) is now
  skipped on its own; before, it ended the scan and hid every aura after it.
  A secret `icon` is no longer truth-tested (`SetAuraTexture` already
  type-checks it), and a texture that fails to set skips that aura only.
- The player power label tests for a missing value with `MF.IsNil`, not a
  direct comparison that could see a secret value.
- Aura filters the API rejected now work: `DISPELLABLE` became
  `RAID_PLAYER_DISPELLABLE`, and the single `PLAYER|RAID_IN_COMBAT` entry
  (which lacked `HELPFUL`/`HARMFUL`) split into separate HoTs and DoTs
  filters. Saved on/off choices carry over to the new keys (schema version 3).
- `MF_DB` now records its schema version (it had a default of 2, which
  AceDB never writes, so the legacy-format branch could not run). The
  migration works on the raw saved table before AceDB binds it, and keeps one
  backup of the old data under `migrationBackup`.
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
