# P10 builder handoff

Use the existing P3–P9 implementation checkout, after P7–P9 integrated review.
Checkpoint local source, generated plan, bake and evidence before merging this
planning package. Published main does not contain the full earlier city build.

Read `moy_pkg_P10.md`. Build in this order:

1. One hollow car and one real boarding platform: geometry, doors and collision.
2. Working continuous consist/reversal and terminal turnouts/block ownership.
   Resolve fit inside existing guideway before mass rollout; no track teleport.
3. Roll fleet onto three services, preserving derived hourly timetable.
4. Add safe day/night transition, Watch service and rider-aware streaming.
5. Finish station interfaces and maintenance Line House, respecting P7/P11/P12.
6. Genuine integrated bake, focused gameplay checks, screenshots and diagnostic.

Prompt:

> Build P10 from `docs/architecture/moy_pkg_P10.md` and follow
> `docs/architecture/moy_p10_build_handoff.md`. Preserve the existing P3–P9
> implementation. Use the updated train model and TRAIN.kit SuperEgg schedule;
> finish hollow cars/boarding first, then continuous route operation and night
> service, station finishing and Line House. Write the focused diagnostic and
> stop for review before P11.
