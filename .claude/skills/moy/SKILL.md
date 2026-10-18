---
name: moy
description: Pick up the Moy city build from its roadmap. Use when the user types /moy, optionally with a package id (P3, P17) and a verb (plan, review, brief, status). Loads the roadmap, the package's brief and the files it names, and works the package as a planning session.
---

# /moy: pick up the Moy build

The user's shorthand for starting a planning session on the city of Moy.

## Forms

| The user types | You do |
|---|---|
| `/moy` | **Status.** Read the roadmap; list the packages with their status in one short table; name the one or two that should go next and why. Do nothing else until the user picks. |
| `/moy P3` | **Take the package.** If its brief is *ready* and no diagnostic exists, say it is waiting on a build and offer to refine the brief. If a diagnostic exists, review it (below). If it has no brief, write one (below). |
| `/moy plan P17` or `/moy brief P17` | **Write or revise the package's brief**, `docs/architecture/moy_pkg_P17.md`, and mark it *ready*. |
| `/moy review P1` | **Review the build.** Read the package's newest `docs/diagnostics/*moy*P1*` (or the diagnostic the roadmap names) and its screenshots against the brief. Pass: mark it *done* at its level. Fail: add a dated fix list as a new section of the brief and mark it *fix*. |
| `/moy <anything else>` | Treat it as a Moy design question or change request, starting from the roadmap. |

## Always, before anything else

1. Read `docs/architecture/moy_build_roadmap.md`. It is the source of truth
   for packages, status, levels of finish and where everything is.
2. Read the package's brief if it has one, and only the design docs and plan
   data the brief names. Do not read the whole of `docs/architecture/city.md`
   (it is very long): grep it for the package's area.
3. Read `CLAUDE.md`'s rules; they always hold.

## How a planning session works

- **Plan data** lives in `tools/city_layout.py`, which writes
  `scripts/city_plan.gd` (never edit that by hand). Run
  `python3 tools/city_layout.py --json <scratch>/c.json`; any `PROBLEM` line
  means it exits 1 without writing the JSON. Fix the cause, never the check.
- **Drawings** stay in sync with the plan: re-embed the JSON with
  `python3 tools/embed_drawing_data.py docs/drawings/<page>.html <scratch>/c.json`
  for `moy_city_3d.html`, `moy_plan.html` and `moy_grand_hotel_3d.html`.
  Load-check each page in Chromium (Playwright) and look at a screenshot of
  the places you changed. City model mapping: model x = world x + 560, z the
  same, height = model y − 60.
- **Republish** the models you changed to their existing artifact URLs (in
  the roadmap's "Where everything is"), never as new artifacts.
- **Briefs** follow `moy_pkg_P0.md` and `moy_pkg_P3.md`: area, target level,
  depends on, read first, what to build, collision, checks, viewpoints,
  report, decisions log. Short lines and bullets; no in-game text.
- **Lore:** new lore goes into `docs/world_bible.md` in the same turn, and
  its Open threads stay current.
- **Finish every turn** by updating the package's row in the roadmap, then
  commit as the repository owner with no AI credit or co-author line, and
  push to main (fetch and rebase if rejected).
- Builds are done by the implementation chat (Luna), not here, unless the
  user asks otherwise. Give the user the build prompt from the roadmap's
  quick start, filled in with the package id.

## Reply

End with: what changed, what the package's status is now, and the one-line
prompt to paste into the build chat if a brief is ready.
