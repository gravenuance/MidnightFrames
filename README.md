![UI](/image.png)
# MV Frames

This UI originated as a WeakAura during BfA. With the decline of WeakAuras, I’ve since converted it into a standalone addon.

The core philosophy is simple: the default interface is built on a horizontal axis. As a result, UI frames must compete with one another for limited horizontal space, which often leads to visual clutter. This problem is amplified by addons that introduce additional frames on the same plane. For me, the issue became especially apparent when I had to adjust my camera simply to see nameplates beneath party and arena frames.

Because horizontal space is constrained, child elements are often forced to be smaller or placed outside their parent frames. This has long affected both buff and cooldown tracking. Buff icons tend to be too small to read comfortably, while cooldown trackers (now largely obsolete, but still relevant) were commonly pushed toward the corners of the screen. Both choices make it harder to process information efficiently.

This UI instead uses vertically oriented frames for the player, party, target, and arena. These frames share a consistent construction and expand outward from the center, with party and arena units distributed symmetrically to the left and right (Party 1…X, Arena 1…X). This symmetry makes unit positions intuitive—Party 2 and Arena 2, for example, are equally distant from the center point.

By occupying the left and right sides of the screen along a neutral Y-axis, the center, top, and bottom remain unobstructed. This ensures that nameplates directly in front of the player and in their immediate surroundings are always visible. An additional benefit of vertical frames is that attached elements—buffs, debuffs, and other indicators—can be displayed as larger, more legible icons without obscuring the health bar.

I intend to maintain this UI for as long as I continue playing; I’ve grown too accustomed to its clarity and ergonomics to return to the default layout.

## Features

* Class-based color coding: Each unit frame is color coded by class for immediate visual identification.

* Interactive highlighting: Frames respond to mouseover and target states, providing clear visual feedback for interaction and focus.

* Filtered buff display: Buffs are selectively shown to reduce visual noise and emphasize relevant information.

* PvP utilities: Party and arena frames include trinket tracking, while arena frames additionally display diminishing return (DR) trackers.

* Extended unit coverage: The addon includes dedicated boss frames and a player pet frame.

* Enhanced player frame: The player frame displays current power as a percentage for quick resource evaluation.

* Range awareness: A lightweight, lazy-approximation range check provides contextual awareness without excessive overhead.

## Potential Features

* Better DR, when Blizzard starts allowing access to the required functions.

* Better range tracking.
  
* Raid frames.
