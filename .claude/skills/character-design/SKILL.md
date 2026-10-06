---
name: character-design
description: Designing how Eleblorb's named residents and populations look — dress, hair, skin tone, jewellery, build and body plan — for a whole community and for each person in it. Use when planning a new population's appearance, writing a settlement's dress charter, assigning looks to named residents, adding a garment or ornament to the figure code, or when characters read as uniform, costumed, muddy, clipped or underdressed. Works with settlement-design (who these people are) and figure-rig (how the bodies are built and move).
---

# Character design and styling for Eleblorb

Dress follows the person and the place, the way a building follows its
program. A resident's look should say where they live, what the climate and
environment demand, what culture they belong to, what they do all day, and who
they are within their household. A villager who looks like everyone else, or
like a costume of a real culture, has not been designed.

Companion skills: `settlement-design` fixes the community, households and work
first; `figure-rig` covers how bodies are built and animated. Use this skill
between them: after the census, before any appearance code.

## 1. Process

1. **Read the people.** From the world bible and the settlement brief: each
   resident's age, work, household, temperament and any stated look.
2. **Write the community's dress charter** (section 3) in the settlement brief,
   next to its architecture charter. Environment first, then culture, then
   palette.
3. **Assign individual looks** from the charter's kit, varying each person on
   the axes in section 5. Write the look down per resident before coding.
4. **Check readability** (section 6): contrast, silhouette, household variety.
5. **Record** new appearance facts in `docs/world_bible.md`, as the project
   rules require for any new fact about a person.

## 2. What the project already does (precedent)

Learn from these before inventing anything. Each was a deliberate decision,
several after the user corrected an earlier version.

| Population | Environment and culture expressed in dress | Where |
|---|---|---|
| **Ohio** | deliberately colourful, vibrant and varied: saturated shirts, trousers and shoes chosen independently (a couple of dark options kept so not everyone is bright head to toe); "interesting" hair colours including teal and purple alongside natural tones; eight skin tones across the full range; seeded sleeve split; dresses for some women; palettes cycled without repeats so neighbours never match | `town_generator.gd`, `NPC_*_COLORS`, `_assign_figure_variant()` | `town_generator.gd`, `_assign_figure_variant()` |
| **Snow Village** | cold climate: long sleeves for everyone, gloves, opaque tights or trousers under every skirt (`dress_has_covered_legs`), winter jewel-tone shirts, eight skin tones across the full human range for a cosmopolitan people | `ice_kingdom_village.gd`, `WINTER_APPEARANCE`, applied through `VillagerAppearance.apply_profile()` |
| **Chinese village** | East Asian skin range (four warm tones), black to dark-brown hair, children's pigtails and buns, the Emperor's beard, raised court bun, crown and gold robe (`wears_emperor_regalia`), the Royal Chef's hat with a red band | `chinese_village.gd`, `SKIN_COLORS`, `HAIR_COLORS` |
| **Sea folk** | (planned) a smooth tail of the player mermaid tail's design emerging seamlessly from the hips, hips and legged form in the tail's material; Fish Goblins alone keep the segmented, lobster-like tail; no textiles underwater: shiny **scale clothing** in silver, dark blue or brown (silver formal, brown for work); sleeveless or short; some cropped tops (`has_midriff`); shells or sea flowers set in women's hair; teal skin; tails in teal, blue, red and mauve | `merfolk.gd`, `ocean_kingdom_city.gd` |
| **Tempestars** | sky people: pastel skins, very light clothing (sky blue, dusk purple, near-white), never muted or earthen; gold jewellery; a gold laurel wreath for rulers; the lower body is cloud; the same sleeve split as the sea folk | `tempestar.gd`, `sky_kingdom.gd` |
| **Lava people** | no textile dress at all: molten material over every body, garment and hair mesh, silhouettes shaped from their own bodies, living eyes left visible | `npc.gd`, `lava_body` |
| **Pirates** | two captain's hats (bicorne and tricorn variants), hooks, peg legs, cropped trousers with bare lower legs, stubble and full beards, red shirts over dark trousers | `ocean_kingdom_denizens.gd`, `npc.gd` |

## 3. The dress charter (one per community)

Write it in the settlement's brief. It names:

1. **Environment rules.** What the climate or medium forces. Cold means long
   sleeves, gloves, covered legs and boots. Underwater means no woven cloth.
   Sky means light, airy, pastel. Molten means no textile at all. Work hazards
   count too: a smith's apron, a diver's bare arms.
2. **Cultural sources.** Which real traditions inform the dress, which specific
   garments or ornaments are borrowed, and what is excluded.
3. **Skin and hair ranges.** Match the community's stated ancestry. A
   cosmopolitan community spans the full human range (the Snow Village's eight
   tones). A community with a stated ancestry uses that range (the Chinese
   village's four tones) and adds others only for residents whose background
   says so (Kai Mālie's international families). Never assign skin tone by
   role.
4. **Palette.** Garment colours tied to the settlement's architectural palette:
   about 60 percent everyday base, 30 percent secondary, 10 percent accent.
5. **Garment kit.** Which existing options the community uses (section 4), and
   any new garment it needs.
6. **Hair kit.** Which `FigureHair` styles appear, and any ornaments.
7. **Signature item.** One element repeated across the community so it reads as
   one people (the Snow Village's gloves, the sea folk's scale cloth, the
   Tempestars' gold).
8. **Hierarchy.** What rulers, elders, officials or ceremonial roles add (the
   Emperor's regalia, the Tempestar ruler's laurel).
9. **Exclusions.**

## 4. The toolkit

Use what exists before adding anything, and add new things to the shared figure
code rather than to one character's script.

- **Human NPCs** (`npc.gd`): `skin_color`, `shirt_color`, `pants_color`,
  `shoe_color`, `glove_color` (transparent means bare hands), `sleeve_style`
  (`ProceduralFigure.SLEEVE_STYLE_LONG`, `_SHORT`, `_NONE`), `body_scale`,
  `chest_build_scale`, `hip_build_scale`, `abdomen_width_scale`, `hair_style`,
  `hair_color`, `hair_length_variance`, `has_glasses`, `wears_dress`,
  `dress_color`, `dress_has_covered_legs`, `wears_full_boots`,
  `cropped_trousers`, `beard_style`, `beard_color`, `beard_scale`,
  `wears_pirate_captain_hat` with `pirate_hat_variant`, `wears_chef_hat`,
  `wears_emperor_regalia`, `hook_hand`, `peg_leg`, `lava_body`.
- `has_glasses` (lensless frames) and `wears_full_boots` (the Emperor's boots)
  exist; no population uses glasses yet.
- **Hair styles** (`FigureHair`): buzzcut, afro, flat top, bun, pigtails,
  ponytail, long, hero, bald. `is_female` gates the bun in the generic picker.
- **Community profiles** (`VillagerAppearance.apply_profile()`): a dictionary of
  colour pools, build ranges per gender, hair pools, dress indices, covered
  legs and sleeve style. Prefer a profile over ad hoc assignment for any
  population of more than a few.
- **Head ornaments** (`HairOrnaments`): placement that reads each hairstyle's
  real envelope (`FigureHair.hair_edges()`), so wreaths, shells and flowers sit
  on the hair instead of clipping into it. Every head-mounted ornament goes
  through it.
- **Non-human bodies:** `merfolk.gd` (upper rig over `AquaticTail`, scale
  clothing, hair ornaments, midriff), `tempestar.gd` (upper rig over
  `TornadoTail`, gold wreath), molten `lava_body`.
- **Worn gameplay items** (helmets, crowns, hats a blorb becomes) belong to the
  blorb suit and item systems, not to NPC dress.

When a charter needs a garment the kit lacks (a lei, an aloha shirt, an apron,
a robe), add it as a reusable option in the shared figure code, as `FigureDress`
was, with a flag on `npc.gd`, and record it in this section.

## 4a. Gendered bodies and dress

`is_female` drives the rig's proportions and several dress rules. Set it
explicitly for every named resident; leaving it at the default builds a male
body and draws from male pools.

**Body proportions.** Height and build come from separate per-gender pools
(`town_generator.gd`, `NPC_*_SCALES`; mirrored in community profiles such as
`WINTER_APPEARANCE`):

| Measure | Women | Men | Notes |
|---|---|---|---|
| `body_scale` (height) | 0.84 to 0.99 | 0.97 to 1.16 | overlapping at the middle |
| `chest_build_scale` | 0.86 to 1.0 | 1.01 to 1.18 | only men get broad chests; arms follow the chest |
| `hip_build_scale` | 0.98 to 1.16 | 0.92 to 1.07 | women wider in the hips; the legs attach at a fixed fraction of hip width (`ProceduralFigure`, leg pivots at 0.55 of the hip's half-width plus a shift), so women's legs are set wider apart, and leg thickness follows the hips |
| `abdomen_width_scale` | should be narrower (see below) | 0.94 to 1.32 | currently one shared pool; 1.0 is the narrow end; front overhang past the chest is for men only |

Per-gender pools need their own counters; a shared counter indexing a gendered
pool was a real bug. Non-human peoples set fixed gendered proportions in their
own scripts (sea folk chest 0.90 and hips 1.06 for women, 1.02 and 0.92 for
men; Tempestar height 1.02 and 1.10, chest 0.88 and 1.02, hips 1.08 and 0.92).

**Hair.** Women draw from a pool that always includes the bun, plus long and
ponytail; men's pool is buzzcut, afro, flat top, bald and hero. Pigtails appear
for girls and some women. Deliberate exceptions follow culture and rank, not
the pool: the Emperor's raised court bun, the Chinese farmer's bald head.
Beards (`stubble`, `full`) are for men only.

**Dress.**
- `wears_dress` is for women in ordinary use (Ohio's 32 percent chance, the Snow
  Village's chosen indices). The dress colour follows the trousers colour, so a
  woman's look stays in one palette.
- The same garment serves as a man's **robe** where culture or rank calls for it:
  the Emperor wears it, in red, with regalia and full boots. Describe it as a
  robe in briefs.
- Cold climates cover the legs under every skirt (`dress_has_covered_legs`).
- Sea folk: cropped tops (`has_midriff`) and hair ornaments (shells, sea
  flowers) are for women; men wear the full scale top.
- Sleeve length is not gendered: the sleeveless, short and long split applies
  to everyone, set by climate and work.

**Women's abdomens never protrude past the thorax.** A woman's abdomen is no
wider, no deeper at the back and no further forward at the front than her
chest. `ProceduralFigure.build()` caps width and back depth at the chest for
everyone, but lets the front protrude up to `ABDOMEN_FRONT_OVERHANG_MAX`
(1.12 times the chest's front depth) as a slight belly. That allowance is for
men only. Today it applies to women too, and the abdomen pools in Ohio, the
Snow Village and the Fire Kingdom are not split by gender, so a woman can draw
a large value and show a belly past her chest. Fix: give women an overhang of
1.0 (flush with the chest), and give them their own narrower abdomen pool.

**Writing gender into a census.** Name each resident's gender in the
settlement brief when the census is written, and keep it consistent with the
name and the world bible. Do not infer it from a name in code.

## 5. Individual variation

Residents are siblings, not clones. Vary each person strongly on two or three
axes and mildly on the rest, and give the variation a reason:

- **Work:** the forge apron, the farmer's rolled sleeves, the diver's bare arms,
  the clerk's glasses.
- **Age:** children smaller and plainer; elders with grey or white hair, a
  slightly heavier build or a stoop where the rig allows.
- **Rank and role:** one extra element at most (a wreath, a chain, a hat).
- **Household:** a family shares a colour or an item; neighbours do not.
- **Temperament:** bright or sober colours, tidy or careless.

No two members of one household share more than half their axes (sleeve,
garment colour, hair style, hair colour, build, accessory).

## 6. Readability

- **Skin against clothing:** the colours must differ clearly. The Tempestar
  rule is the model: when a pick is too close (RGB distance under about 0.22),
  choose a *different entry from the same palette*. Never darken or desaturate
  to force contrast; that is how pale sky clothing turned into muddy earth
  tones.
- **Hair against skin and clothing:** distinguishable at conversation distance.
- **Silhouette:** at a distance, residents of one community should be told apart
  by outline (hair shape, sleeve length, dress, hat, build), not colour alone.
- **Never underdressed by accident:** defaults must produce a dressed person.
  An earlier default made new one-off NPCs look naked until configured.

## 7. Cultural care

- Borrow from real dress with specificity and respect: name the garment and
  its tradition, and use it as people of that culture actually wear it.
- No costume or stereotype: no "national dress" on everyone, no exaggerated
  features, no assigning skin tone or dress by villainy or role.
- Sacred, royal and ceremonial items are not everyday decoration. For example,
  Hawaiian feather cloaks (*ʻahu ʻula*) and feather helmets (*mahiole*) belonged
  to chiefs and are not village wear, whereas lei, kapa patterns and modern
  aloha shirts are ordinary.
- Modern communities wear modern clothes informed by their heritage, as people
  do (Ohio's blend; Kai Mālie's aloha shirts and lei; the Fire Kingdom's
  scientists).
- Fantasy peoples (Tempestars, sea folk, lava people) take their dress from
  their environment and body first, and from human sources only as named in
  their charter.

## 8. Mistakes that have shipped

- Every Tempestar in the same t-shirt because `sleeve_style` was never set.
- Tempestar clothing darkened to fix contrast, turning the sky people's pastels
  into muted earth tones.
- Hair ornaments and jewellery clipping into the head or hidden by certain
  hairstyles, before `HairOrnaments` read the real hair envelope.
- New NPCs appearing undressed because the clothing default was skin colour.
- A winter village in bare legs and bare hands before the winter profile.
- Pirate crews built without `is_female`: Mara Reef, Nell Crow and Ada Shoal
  have male bodies and male hair, and the stubble rule (indices 2, 5 and 7)
  gives Ada stubble. Still to fix in `ocean_kingdom_denizens.gd`.

## 9. Checklist

1. The dress charter is written in the settlement brief and names environment
   rules, sources, skin and hair ranges, palette, kit, signature item,
   hierarchy and exclusions.
2. Every named resident has a written look derived from their work, age, rank,
   household and temperament.
3. Skin, hair and clothing contrast pass; no forced darkening.
4. Households vary; the community still reads as one people.
5. Head ornaments use `HairOrnaments`; new garments live in shared figure code.
6. No sacred or royal item is used as decoration; no stereotype.
7. Appearance facts are recorded in the world bible.
