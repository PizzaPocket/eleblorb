> Superseded clothing assessment: the 2026-10-17 walkthrough correction restores separate thorax/abdomen forms and removes detached jacket apron plates. See [walkthrough corrections](2026-10-17-china-platforming-and-character-corrections.md).

# China Village NPC appearance pass

The owner authorized reviewing every village resident and specifically the
Emperor and Royal Chef. The project character-design and figure-rig skills were
read. The approved settlement dress charter and individual looks in sections
4.7–4.8 supplied the designs; no new people, businesses or quest rules were added.

## What changed

All 20 named residents now receive fixed appearance records before their rig is
built, rather than random shirt/pants colors, builds and identical adult buns.
The shared `chinese_appearance.gd` table covers the eight household adults, five
children, three inn family members, Chen, Tian Bo, Liang Zhen and the Royal Chef.
Liang Zhen has an additional advisor wardrobe, not an additional NPC.

The reusable `figure_chinese_clothing.gd` kit adds fitted jacket shells bridging
the rig's separate body parts, standing collars, bound centre or side closures,
frog knots, below-hip front/back hems with open sides, wider sleeves with bound
cuffs, sashes, vests, aprons with straps and pockets, serving cloths, travel packs
and pale welts on black cloth shoes. Limb additions attach to the actual mesh,
not a guessed joint centre. Fine clothing details are explicitly decorative;
the existing actor collider and shared motion rig remain authoritative.

`HairOrnaments` now fits pins, wraps, kerchiefs, ribbons and straw hats to the
real hairstyle envelopes. Elders have grey pinned buns or wrapped topknots;
children retain their approved soft builds, pigtails/twin buns or small knots.
Existing ordinary-adult skin defaults were retained. Body, outfit and headwear
vary by named person independently of random spawn ordering.

The household designs include:

- Mei Lian: grey sleeves, black vest, red binding, grey pinned bun. Jin Wei:
  light indigo, jade binding, bound short sleeves. Xiu: lantern red and twin buns.
- Yun Tao: pale hemp and tile green; Bao: indigo and a small wrapped knot.
- Hua Chen: white half sleeves, indigo binding, kerchief and work apron;
  Ting: light blue and pigtails.
- Bo Xiang: broad, sleeveless natural cloth and straw hat; Rong: brown and green.
- Wen Zhao: brown work jacket, cropped trousers and pushed-back straw hat.
- Lian Fu: deep indigo and red binding; Shu Mei: grey long jacket, black vest
  and grey pinned bun; Pei: jade green and pigtails.
- Lao Lao: blue-grey side closure, red binding, plum-grey trousers and a grey
  pinned bun. Lao Ye: indigo, white apron and serving cloth. Lu Hao: lighter
  indigo and red, with serving cloth. Chen: brown, wrapped knot and travel pack.
- Tian Bo: muted green, brown binding, short sleeves, bald beneath his straw hat.

## Emperor and chef

Liang Zhen's crown has a black top, red underside and supported cap, with twelve
jade-bead strands at both front and back. Crimson remains his robe color. A
lower court collar, raised coiled gold roundels and jade belt plaques replace
the prototype's plain cords and gold waist block. His beard and black boots stay.
On deposition he changes into his already-approved grey advisor gown and black
vest, with a plain topknot wrap. A visual-only wardrobe rebuild preserves the
actor, collider, dialogue callback and schedule. The same appearance restores
when the region reloads after deposition.

The chef retains his approved foreign court-kitchen toque and red band. Bound
pale half sleeves, apron, straps and pocket give the uniform a working structure.
His beard is shortened to clear the bib. The apron and pocket also darken with
his existing demon reveal; the equipped cleaver and combat rig are unchanged.

## Verification and limits

The China runtime validator checks that all 20 named looks actually spawn, every
actor receives its garment kit, crown strand count is correct, and advisor
wardrobe replacement removes regalia while retaining covered legs and the
quest dialogue hook. Existing water, route, gallery, pine, ramp, mount,
unload/reload and threaded activation checks still pass.

Ohio: 0 failures / 8 existing warnings; Snow: 0 failures / 5 existing warnings.
Design-language, source whitespace and static-bake agreement checks pass. Final
logs are checked for script errors, not just engine exit status. The known
headless macOS certificate-store warning remains unrelated to this change.

`tools/chinese_character_review.tscn` renders the complete roster and advisor
wardrobe, with gait captures for articulated clothing review. Images are in
`wip/diagnostics/2026-10-16-china-npc-pass/`. The proof covers clothing and
silhouette, not facial animation or a complete combat playthrough. The new
costumes retain the game's simple procedural figure language; they are not
high-resolution cloth simulation. A carried shoulder pole, pleated panel skirts,
fine stains and richer individual wear are still outside this implemented kit.

At 1600 × 1000, isolated village QA staged in 2.984 s, measured 60.0–60.1 FPS at
the palace view and 55.2–55.3 FPS at the fields. Static memory was 357.4–360.2 MiB,
video memory 718.4 MiB, and draw calls 4389 / 4532. This adds approximately 13 MiB
static memory over the prior building pass. These measurements precede the
small two-shoe-welt correction and are fixed-camera samples, not a Crossroads
startup soak. NPC garment batching is a future optimization target; active
characters still unload with their region.

Sources are uncommitted. The deprecated web build was not regenerated.


## Final verification, 2026-10-17

A fresh isolated project was imported after the session resumed. The final
costumes, including cloth-shoe welts, the emperor's side closure and shoulder
roundels, were rendered again. All twenty residents and the advisor wardrobe
build; the full China runtime validator passes again. The final roster and gait
images were copied into the repository's diagnostic directory. The render has
no script errors; the runtime log contains only the known certificate-store
warning. Changes remain uncommitted.
