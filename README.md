![UI](/Media/screenshot.png)
# MidnightFrames

This UI originated as a WeakAura during BfA. With the decline of WeakAuras, I’ve since converted it into a standalone addon.

The core philosophy is simple: the default interface is built on a horizontal axis. As a result, UI frames must compete with one another for limited horizontal space, which often leads to visual clutter. This problem is amplified by addons that introduce additional frames on the same plane. For me, the issue became especially apparent when I had to adjust my camera simply to see nameplates beneath party and arena frames.

Because horizontal space is constrained, child elements are often forced to be smaller or placed outside their parent frames. This has long affected both buff and cooldown tracking. Buff icons tend to be too small to read comfortably, while cooldown trackers (now largely obsolete, but still relevant) were commonly pushed toward the corners of the screen. Both choices make it harder to process information efficiently.

This UI instead uses vertically oriented frames for the player, target, party, arena, and boss units. These frames share a consistent construction and expand outward from the center, with party and arena units distributed symmetrically to the left and right (Party 1…X, Arena 1…X). This symmetry makes unit positions intuitive—Party 2 and Arena 2, for example, are equally distant from the center point. Raid frames are the one exception: with group sizes up to 40, they stay horizontal, since forcing that many vertical bars onto the screen would recreate the same clutter this UI is meant to avoid.

By occupying the left and right sides of the screen along a neutral Y-axis, the center, top, and bottom remain unobstructed. This ensures that nameplates directly in front of the player and in their immediate surroundings are always visible. An additional benefit of vertical frames is that attached elements—buffs, debuffs, and other indicators—can be displayed as larger, more legible icons without obscuring the health bar.

MidnightFrames is a complete replacement for the default unit frames, not a supplement to them—Blizzard's player, target, party, and raid frames are hidden automatically, so there's nothing to manually disable or tuck out of the way.

I intend to maintain this UI for as long as I continue playing; I’ve grown too accustomed to its clarity and ergonomics to return to the default layout.

## Features

* Complete UI replacement: Default Blizzard player, target, party, and raid frames are hidden automatically, with no manual setup required.

* Class-based color coding: Each unit frame is color coded by class for immediate visual identification, rendered as a gradient fill rather than a flat color.

* Interactive highlighting: Frames respond to mouseover and target states with a layered, soft-bloom glow, providing clear visual feedback for interaction and focus.

* Filtered buff display: Buffs are selectively shown to reduce visual noise and emphasize relevant information.

* PvP utilities: Party and arena frames include trinket tracking, while arena frames additionally display diminishing return (DR) trackers.

* Extended unit coverage: The addon includes raid frames, dedicated boss frames, and a player pet frame.

* Raid target markers: Raid target icons (skull, cross, etc.) are shown in the corner of every applicable frame.

* Cast indicator: A compact corner icon—not a traditional castbar—shows what the player, target, party, and boss units are casting, complete with an interrupt-state color and cooldown sweep, without adding a new horizontal element to the UI.

* Enhanced player frame: The player frame displays current power as a percentage for quick resource evaluation.

* Range awareness: A lightweight, lazy-approximation range check provides contextual awareness without excessive overhead.

## Potential Features

* Better DR, when Blizzard starts allowing access to the required functions.

* ~~Better range tracking.~~

* ~~Raid frames.~~
