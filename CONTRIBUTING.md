# Contributing

## Commits

- One logical change per commit.
- Subject line in the imperative mood, explaining the *why*, not just the *what*.
  Example: `Cache resolved aura filters to cut UNIT_AURA cost`.
- No `type:` prefixes (`feat:`, `fix:`, `chore:` …) — plain imperative only.
- No `Co-Authored-By` trailers on commits pushed to `origin`.

## Before pushing

- Run `luacheck .` (config in `.luacheckrc`). CI runs the same check on every
  push and PR; a red run blocks merge.
- Load the addon in-game and exercise the changed frames — `luacheck` catches
  syntax and undefined-global errors, not WoW API behaviour.

## Releases

Push a `vX.Y.Z` tag. The release workflow zips the addon, creates a GitHub
Release, and uses that version's `CHANGELOG.md` section as the notes. Move the
`Unreleased` entries under the new version with today's date before tagging.
