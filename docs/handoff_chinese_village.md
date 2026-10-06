# Handoff: Chinese Village pass (population and story approved, layout not started)

Nothing from this work is committed. The working tree holds many unrelated
modified files, so review `git status` before staging. Follow `AGENTS.md` and
`CLAUDE.md` for publishing (regenerate and validate `build/web` before any push,
never credit an AI as author or co-author).

Read in this order: this file, `docs/architecture/chinese_village.md` (audit,
population, provisional layout), `docs/architecture/settlement_backlog.md`
section 3, the Chinese village entries in `docs/world_bible.md`.

## Ground rules

- Use the scratch-copy workflow in `docs/handoff_ohio_village.md` ("Tools you now have") to run Godot while the editor is open.

- Never run headless Godot while the user's editor is open, and never run two
  Godot processes at once. Check `pgrep -fl Godot` first. On 2026-10-04 the
  editor opened mid-session and one headless probe ran against it. It finished
  cleanly. If the editor misbehaves, delete `.godot/imported` and reopen.
- A new `class_name` needs `Godot --headless --path . --import` before it
  resolves. The capture tool (`tools/village_aerial_capture.gd`) needs a window,
  not `--headless`. The validator is the headless one.
- Build props from SuperEgg parts. Use `CollisionPolicy` for substantial
  geometry. Use `UIKit`/`UITheme` for any UI.
- No in-game text that explains a mechanic or nudges the player.
- Prose: no em dashes as a clause joiner, no hollow intensifiers. Dialogue gets
  a final `no-ai-slop` pass. Every resident here speaks Chinese.
- Every stall item needs a maker in the plan's trade ledger.
- People decide buildings. Do not place a building that no named person or
  defined communal use needs.

## Decisions already made (2026-10-04)

- Population, households, history, quest resolution, postquest civic use and
  the Ohio link are approved
  (`chinese_village.md` section 3, recorded in the world bible).
- The southern town in Bo Xiang's old line is Ohio, due south about 730 m.
  Flour and salt come in from Ohio's mill, lanterns, beans and bamboo goods go
  out.
- The innkeeper is 林静, native to the island, Lin family inn of three
  generations. Done in code (`INNKEEPER_NAME`, `INNKEEPER_LINES` in
  `scripts/chinese_village.gd`, new `lines` parameter on `VillageInn.create`).
  Unrun in Godot beyond one headless probe that showed the new name.
- No palace steward for now.
- The Emperor is **Liang Zhen (梁臻)**. The hero never fights him. The Royal
  Chef is the only boss in this chain.
- After the Chef is defeated, Liang Zhen relinquishes the title. Tian Bo
  becomes village chief, the palace becomes a public civic centre, and Liang
  Zhen becomes the community chef. He and Hua Chen grow close over later
  visits rather than resolving their romance immediately.
- Not decided: layout re-fit, gate island, bamboo island move, courtyard
  charter (`chinese_village.md` 4.2), palace restructure (4.3).

## Households (summary; full table in the audit doc)

Lantern (Mei Lian, Jin Wei, Xiu). Tile (Yun Tao, Bao). Bao house (Hua Chen, a
single mother, and Ting). Lamp keeper (Lian Fu, separate home and household).
Carrier (Bo Xiang, Rong). West end (Shu Mei, Pei). Roofer (Wen Zhao, alone).
Farm (Tian Bo, Pandy). Inn (林静, Chen lodges). Palace before the quest (Liang
Zhen, Royal Chef). Five children exist already: Ting, Xiu, Pei, Rong, Bao.

## Anchors that must keep working

These are story and gameplay hooks in `scripts/chinese_village.gd`. Moving them
means moving the matching quest code and checking its state flags.

- Emperor at palace (0, -5), inside the south-facing hall. `_build_emperor`,
  `_on_emperor_talk`, `_apply_blorb_captivity`.
- Royal Kitchen at palace (0, -31), Chef, captive blorb counter, cleaver pickup.
  `_build_royal_kitchen`, `_on_royal_chef_talk`, `_rescue_kitchen_blorbs`.
- Farmer and Pandy: `_build_farmer_and_pandy_quest`, `_on_farmer_talk`. Now at
  bamboo island (0, -22) local.
- Sun Wu Kong sealed on the castle crown (`SUN_WU_KONG_CASTLE_Y`).
- Play hut on island A with the Jingu Bang among the loose sticks.
- Vendor stall on island B, shop category `chinese_village`.
- The village needs no portal gate and belongs to no kingdom. The Abyss is
  `terrain_generator.gd` (`chinese_village_abyss_coverage`,
  `get_chinese_village_island_surface_y`). Islands share one surface y near -61.
- NPCs on islands use `fixed_ground_y`. Sun Wu Kong and Pandy are abyss-aware.
- Preserve explicit story states for captive blorbs, Chef defeated, Liang Zhen
  restored, Tian Bo installed as chief, palace opened, community kitchen active
  and the Liang Zhen/Hua Chen relationship stages. Do not infer these only from
  NPC position or current dialogue.

## The pass, in order

1. **Layout re-fit (next, not started).** Rewrite `chinese_village.md` section 4
   from the civic program in 3.6: eleven or twelve buildings (eight dwellings with
   trade fronts, inn, stall, play hut, well or cistern) across seven islands,
   with the gate island and bamboo island move reconsidered. Needs the user's
   approval before any code. Defects to fix are in section 2 (entry bridge
   through the bamboo island, inn on a house, random house rotation, empty
   islands C/D/E, no bridge hierarchy or landings, no well or bean terraces).
2. **`ChinesePlan` data file** (`scripts/chinese_plan.gd`) modelled on
   `scripts/snow_plan.gd`: islands, bridges and gates, buildings with door
   direction and facing, paths, yards, residents with homes and schedules, trade
   ledger. It exposes `layout_report()` like `SnowPlan`.
3. **Validator.** Extend `tools/validate_village.gd` with a China mode: building
   overlaps and island-edge fit, door-front paths, bridge landing height and
   clearance, ledger, schedules. Wire it into `tools/check_village_layout.sh`
   and `.githooks/pre-push` the way Snow was.
4. **Rebuild** islands and bridges, courtyard homes and workshops, the inn,
   palace axis and service yard, royal garden, clumping bamboo (specs in
   `chinese_village.md` 4.2 to 4.5), then interiors.
5. **Residents and story states:** homes, schedules (`configure_daily_schedule`,
   world coords), before/during/after quest placements, Chinese dialogue per
   household, characters for display names of villagers still using Latin
   transliterations (Emperor, farmer, Chef are already characters). Include
   staged revisit scenes for Liang Zhen and Hua Chen. Final `no-ai-slop` pass.
6. **Traversal:** player, Blorbus and mount across every bridge, landing,
   residence entry, palace level and kitchen door. Eye-level interior checks.
7. **Capture audit:** aerial and eye-level renders to `wip/village_audit/`.
   `tools/village_aerial_capture.gd` already has a China target with a ground
   override. `tools/audit_china.tscn` lists islands, NPCs and non-island nodes.

## Open items from earlier settlements (carry forward)

- **Ohio:** the user is about to do a live walkthrough and report bugs and
  polish. Do that before the China layout. Fold each reported issue into the
  Ohio plan or generator and re-run `tools/check_village_layout.sh`.
- **Snow:** see `docs/handoff_snow_village.md` (visual and walk checks owed).
- **Temporary debug start buttons** (Snow, Ocean, Plant, Lava) on the title
  screen are to be removed later. See memory note `debug-start-buttons`. Lava
  "1-2" in the request was read as one button; confirm.
- **Crossroads Fishing Village** now precedes China implementation (see backlog
  section 3 and `docs/handoff_fishing_village.md`). The approved China story
  brief remains valid while construction is held. The Crossroads portal to the
  Ocean Kingdom must stay functional.
