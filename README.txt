MORROWIND LIVING EXPERIENCE (MLX)
Version 0.9.0 — Public Beta

Experience through living, not grinding.
MLX replaces conventional skill-use leveling with experience earned through
exploration, discovery, social progress, practical activities and adventuring.

REQUIREMENTS
- PC Morrowind with MWSE 2.1 (current build recommended), MGE XE and the
  Tribunal and Bloodmoon expansions (tested configuration).
- Optional: Skills Module 2.1.1 and mods that use it; Morrowind Crafting 2.1.2.
- Ashfall and Ashfall Survival Start are optional, not dependencies.
- OpenMW is not supported by this MWSE-Lua release.
Tested with MWSE build 5399 and MGE XE 0.18.0.0 in a heavily modded game.

INSTALLATION
1. Exit Morrowind. Back up your saves.
2. Prefer a new character for beta testing. Disable other XP/leveling and
   vanilla skill-progression overhauls in a fresh test profile. Do not remove
   plugins from an established save merely to test MLX.
3. Extract the archive into the Morrowind folder so that main.lua resides at
   Data Files/MWSE/mods/MLX/main.lua. With a mod manager, install the Data Files
   contents as appropriate to that manager. No ESP or load-order entry needed.
4. Launch and check Mod Configuration for Morrowind Living Experience (MLX).
5. Open inventory and hover over the Experience marker for progress.
Upgrading from internal MLX builds: replace the existing MLX folder only;
keep saves. Earlier earned XP is not recalculated. F10 test recovery is removed.

ADVANCEMENT
XP required = round(1500 + 250 * current level ^ 1.35).
Level 1 requires 1750 XP; level 2 requires 2137 XP.
At the threshold, native attribute selection opens automatically outside other
menus; select three attributes (+1 each, subject to native limits). Native
health and level advancement follow. XP resets to zero, without carryover.
Allocate 25 points across the 27 vanilla skills (one point per increase, base
cap 100). If fewer than 25 increases are possible, the budget is reduced.
Confirm to commit. F9 reopens pending allocation during normal gameplay.
Natural vanilla skill-use gains are suppressed. Paid training and skill books
retain direct increases; they do not count toward vanilla character leveling.
Custom skills advance through their own mods; they are not allocation targets.
The MCM page is informational. XP rates are fixed by design.

XP REWARDS
Book: 25 per first acquisition (not reading).
Enchanted scroll: 15 per first acquisition.
Combat: 5 times defeated enemy level (tracked kills).
Ingredient: 1 per first confirmed consumption; excluded when Alchemy is major
or minor. Prepared Ashfall meals are not a separate XP source.
Exploration: 5 wilderness cell, 25 named location/cave/mine/tomb,
50 qualifying ruin/shrine; name-based classification and first-visit tracking.
Quest: 100 per qualifying journal completion (once per topic).
Reputation: 50 per new highest point.
Faction promotion: 50 times new rank per newly reached rank; joining earns 0.
Skills Module: 5 per new permanent whole skill point.
Morrowind Crafting: 5 per new tracked whole skill point.
Curated artifact acquisition: 100–500, once per registered item.
Successful potion: 15; successful repair: 5.
Lockpicking: 5–25 by lock difficulty; trap disarm: 10; pickpocket: 5.
Self-enchanting: 25; recharging: 5.
Starting inventory and various first-observed baselines are excluded.
Quest journal stages are not rewritten by MLX.

COMPATIBILITY AND LIMITATIONS
Do not combine with Morrowind XP, MXPS or competing leveling/progression
systems. Other mods that edit skill progression or level-up menus may conflict.
Books and journal completions are detected generically; this does not guarantee
support for every quest or mod. Exploration is heuristic, artifacts are curated,
and custom skill integrations depend on the supported event/data interfaces.
Existing-save adoption, long-term play, different load orders, high-level caps,
other screen resolutions and successive advancement cycles need broader testing.
Uninstalling does not undo character changes; restore a pre-install save for a
clean rollback. Keep a separate beta save. Report failures before continuing.

CREDITS
Morrowind and its assets: Bethesda Game Studios.
Conceptual inspiration: Morrowind XP and the experience-based leveling tradition.
MLX is a separately developed MWSE-Lua implementation, not a patch or fork of
Morrowind XP or MXPS. Neither original mod is bundled. No endorsement implied.
Thanks to the MWSE and Morrowind modding communities.
AI-assisted Lua development with human design decisions and in-game testing.

SUPPORT
See BETA-TESTING.txt for reporting instructions. This is a public beta, not a
claim of universal compatibility or a completed long-term stability test.
