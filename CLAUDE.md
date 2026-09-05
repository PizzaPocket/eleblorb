# Eleblorb — Project Instructions

## Publishing and attribution

Follow the complete publishing contract in `AGENTS.md`. In particular, every
push must regenerate and validate the committed `build/web` deployment first.
Use the human owner’s configured Git identity and never credit Claude, Codex,
another AI system, or an AI vendor as an author, committer, co-author,
contributor, or generated-by credit.

## World bible

This project keeps a lore/world-building knowledge base at `docs/world_bible.md` — narrative and setting facts (characters, creatures, currencies, locations, plot elements), not implementation details.

**Whenever new lore is introduced** — the user describes a story/character/setting/plot detail, names something previously unnamed, or a request implies new world-building (e.g. a new elemental type, a new location, a new NPC with a backstory) — update `docs/world_bible.md` to reflect it as part of that turn's work, not as a separate follow-up task. If new information supersedes or contradicts an existing entry, update that entry in place rather than appending a conflicting one. Keep the "Open threads" section current: remove items once they're resolved, add new ones as they come up.

## In-game text and player guidance

Eleblorb's design philosophy deliberately avoids heavy-handed player guidance. Never write in-game text — `Hud.show_message()`/`Hud.show_passive_message()` calls, NPC/vendor dialogue, lock/gate messages, tooltips, or any other player-facing string — that spells out a mechanic, states a numeric requirement, or nudges the player toward the "correct" next action (e.g. "Two fire blorbs are needed to cross lava," or a locked portal saying "maybe Blorbus could open it"). This applies even when the underlying mechanic is real and correctly implemented — the mechanic itself is fine, only the text announcing it is the problem.

Prefer atmospheric/diegetic flavor or plain state description instead (an NPC's in-character remark, an environmental cue, a reaction to the failed action without explaining why it failed). If a mechanic needs to be discoverable, lean on visual/environmental design or subtler cues rather than direct text hints. When a task calls for new player-facing text, check it against this rule before adding it, and flag it back rather than defaulting to an explanatory tooltip.

## UI design system

This project keeps a shared UI design system in `scripts/ui_theme.gd` (design tokens — colors, type scale, spacing, panel/button/chip/slot styleboxes — plus a "Design language" section documenting the conventions below) and `scripts/ui_kit.gd` (reusable builder functions consuming those tokens). Every UI surface (Hud, DialogUI, ShopUI, InventoryUI, and any future one) is built through these rather than hand-rolled `Control.new()` + ad hoc styling.

**Whenever adding or changing UI**, use the existing `UIKit` builders and `UITheme` tokens rather than introducing new ad hoc styling. If a genuinely new pattern is needed, add it to `UIKit`/`UITheme` (not inline in the calling script) so it's reusable, and update `ui_theme.gd`'s "Design language" section to record it. Key established conventions:

- Never anchor a top-level, dynamically-sized `Control` with `set_anchors_and_offsets_preset(..., PRESET_MODE_KEEP_SIZE, ...)` — it snapshots the control's *current* size before layout has run (reads as zero), which has silently mis-anchored several things this way already. Use `UIKit.anchor_to_edge()` instead.
- Any `Label` that must stay on one line inside a flexible row (next to other controls) needs explicit non-wrap protection (`UIKit.inline_caption()` or `UIKit.stat_badge()`), not the default `caption_label()`/`body_label()` — a cramped row can squeeze a wrapping label down to one character per line.
- Modal panels: translucent background, no border stroke — a soft drop shadow carries the depth cue instead. Interactive controls (buttons, chips) keep their border for click affordance.
- Icon-style close buttons (dismissing a window-style modal) use a small drawn icon (`UIKit.close_button()`), not a Unicode glyph. Text buttons are for dialogue/conversational choices, not window chrome.
- A passive HUD readout whose info is also available on demand elsewhere (e.g. the Tokoins count, also shown in ShopUI/InventoryUI) fades in briefly on a relevant change and back out, rather than staying permanently on screen.
