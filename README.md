![UI](/Media/screenshot.png)
# MidnightFrames

This UI started as a WeakAura back in BfA. Once WeakAuras started fading, I turned it into a standalone addon.

The default UI is built around a horizontal axis, so frames compete for horizontal space and get cluttered fast, especially with extra addons on the same plane. I noticed it most when I had to tilt my camera just to see nameplates under my party and arena frames.

That squeeze also hurts buff and cooldown tracking. Buff icons get too small to read, and cooldown trackers end up crammed into screen corners.

So this UI uses vertical frames instead, for player, target, party, arena, and boss. They share the same layout and expand outward from the center, with party and arena mirrored left and right (Party 2 and Arena 2 sit the same distance from center, for example). Raid is the exception, since group sizes up to 40 would just recreate the same clutter vertically.

Keeping frames on the left and right sides leaves the center, top, and bottom of the screen clear, so nameplates stay visible. Vertical frames also mean buffs and debuffs can be shown as bigger, easier to read icons without covering the health bar.

MidnightFrames replaces the default frames instead of sitting alongside them. Blizzard's player, target, party, and raid frames are hidden automatically.

I plan to keep maintaining this as long as I play. I'm too used to it now to go back to the default layout.

## Features

* Complete UI replacement: hides the default Blizzard player, target, party, and raid frames automatically.
* Class-colored health bars, rendered as a gradient instead of a flat color.
* Mouseover and target highlights with a soft glow.
* Filtered buff display, so only relevant buffs show up.
* PvP trinket tracking on party and arena frames, plus DR tracking on arena.
* Raid frames, dedicated boss frames, and a pet frame.
* Raid target markers (skull, cross, etc.) shown on every frame.
* A compact cast indicator icon instead of a full castbar, with interrupt-state color and a cooldown sweep.
* Player frame shows current power as a percentage.
* Lightweight range check.

## Potential Features

* Better DR, once Blizzard allows access to the needed functions.
* ~~Better range tracking.~~
* ~~Raid frames.~~
