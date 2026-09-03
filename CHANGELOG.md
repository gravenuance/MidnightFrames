# Changelog

All notable changes to MidnightFrames are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
