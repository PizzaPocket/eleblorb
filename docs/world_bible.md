# Eleblorb — World Bible

A living reference for the game's story, characters, and world-building facts, as they've been established during development. This is lore/narrative content only — implementation details (how something is built in Godot) belong in code, not here.

## Premise

The player wakes from a coma in a grass field with amnesia. A small town sits nearby, including an antique shop the player is meant to visit. The overarching plot conflict is a **Demon King** who wants to exterminate all elemental energy in the world.

### The Demon King's mirror world

The Demon King's domain is a mirror world: a reverse reflection of ours, inverted and mirrored beneath it. Skeletons are the first minions known to manifest from it, rising directly up out of the ground into the wasteland above.

The Demon King feeds off living things elsewhere in the world too. In the Primate Kingdom, that feeding takes the form of a curse on the monkeys living there (see Kingdoms, below).

## Protagonist

- An amnesiac player character (no name established yet).
- Has a sentient companion named **Blorbus** — in fact, Blorbus *is* one of the player's own three starting blorbs (see Blorbs, below), not a separate character. Specifically: whichever of the three is still ungemmed once the player has merged elemental gems into the other two. That blorb turns a dull, greyish pink — "brain pink," not a bright bubblegum tone — and starts talking, unprompted, taking the name Blorbus for itself. Once awake, it can never be merged with a gem itself. Why it specifically wakes up this way, and what (if anything) it remembers or knows, is still unexplained — Blorbus's own account of it amounts to "I don't know why either."
- Blorbus is a **Psychic-type** blorb. His core opens into a pocket-universe storage space that functions as the player's inventory: he psychically manages the items kept there and coordinates the player's other blorbs. The inventory interface is therefore a manifestation of Blorbus himself rather than an ordinary abstract menu.
- The player's awareness can switch psychically between their own body and Blorbus whenever he is not being worn as part of the blorb suit. While inhabiting Blorbus, the player's body follows him like a companion blorb. If Blorbus enters the body of the wasteland's Size blorb, **Humongous**, in this state, he psychically merges with it and can direct the giant's movement; returning awareness to the player separates Blorbus from Humongous again.

## Blorbs

Creatures the player finds and befriends, apart from the one settled giant
that remains in the wasteland.

- **Normal type** blorbs: a classic slime silhouette — a smooth, continuously-curved dome/blob body (no flat-cut geometry), sagging low and wide like a water balloon settled under its own weight rather than a symmetric dome. Light, neutral off-white in color, with individual blorbs varying in subtle shade. Rendered with a viscous, gooey, slightly translucent material. Two large, round eyes.
- **Size type blorb**: a single immense resident farther out in the northern wasteland beyond the main plateau, named **Humongous**. It is at least fifty times the size of a normal blorb, broadly flattened and deeply settled into the ground as though gliding across its surface. Its enormous mass makes every movement exceptionally slow, and on its own it glides without ever hopping. While Blorbus is psychically merged with it, however, deliberate control can make the entire giant jump with the same squash-and-stretch motion as a smaller blorb. Once more than half of a person's body has entered its viscous mass, they are slowly lifted to its surface, where they can walk across the giant's goo and make a superjump three times higher than a normal blorb jump; it never gives the ordinary blorb trampoline bounce.
- Every blorb carries a **core**: an apple-sized, many-faceted object suspended inside its body, visible through the translucent flesh. Pale and opalescent in a normal blorb.
- Giving a blorb an elemental gem transforms it into an elemental blorb of that type: the gem is thrown into the blorb, and it merges into the core through some pocket-dimension property of the core itself — no matter how large the merged object actually is, the core simply takes it in. The merge changes both the core's glow and the blorb's whole body: a water merge turns the body a deep, viscous blue; a fire merge turns it molten orange-red, like slow-moving lava.
- Fire and Electric blorbs specifically give off real light from their core, not just a color change — a small, steady glow bright enough to notice in the dark. The other elements don't share this trait.
- The player starts the game with three companion blorbs, which stay nearby and follow once the player wanders far enough away. Whichever of the three is still ungemmed once the other two have taken an elemental gem turns pink and wakes up as **Blorbus** — see Protagonist, above.
- **Wild blorbs**, found out in the world, don't stay put once found. Once the player gets close enough, a wild blorb notices them and starts tagging along after the party's own blorbs rather than the player directly. After it's spent enough time actually traveling with the party (not necessarily all at once — falling behind and catching back up doesn't undo the progress), it joins outright. Once the player owns the corroded pocket compass (see the antique shop, below), it points them toward the nearest not-yet-partied wild blorb so they can go find it — the compass doing the elemental-tracking job its own lore already describes, rather than a glow on the blorb itself. Finding every wild blorb currently out in the field doesn't end the hunt: a fresh few appear elsewhere shortly after, so there's always another one for the compass to point toward.
- Most wild blorbs found out in the world are plain, unmerged Normal blorbs. A smaller number are found already naturally elemental — encountered already merged, rather than merged by hand with a thrown gem (see below). The electric blorb, the rock blorb, and the jungle biome's plant blorbs (see Setting, below) were all met this way.
- **Shiny blorbs**: a rare wild variant, cosmetic only and not tied to any element — a shiny blorb carries no elemental power and can never accept a gem. It's a plain blorb with a distinctly bright, glossy, pearlescent finish rather than the ordinary off-white body most wild blorbs have. Only a handful exist in the field at once, against many plain wild blorbs, so encountering one is meant to read as a genuine rare find.

### The Blorb Suit

The player can call their whole party onto their own body at once, and dismiss them again just as physically — each blorb visibly hops across the ground and up onto its spot rather than appearing there, and hops back off to land scattered around the player when dismissed. Landed, a blorb flattens into one flexible covering over a body part: a full arm from shoulder to hand, a full leg from hip to boot, an oval covering the torso, or, on the head, an inflated spherical blorb helmet enclosing the whole head like a deep-sea diver's air supply. Every covering keeps its own blorb's elemental color and core, the core still sitting just behind its own eyes. A worn head blorb allows underwater swimming; the other coverings have no power yet — see Open Threads.

## Elemental Gems

- Used to turn a normal blorb into an elemental blorb (thrown into it; see the merge mechanic above). Some blorbs are also found already naturally elemental out in the world, without ever needing a gem thrown at them — see Blorbs, above.
- Elemental types confirmed so far: **Water** (blue), **Fire** (orange/red), **Electric** (yellow, crackling), **Rock** (warm banded sandstone brown/tan, not grey — matches the canyon biome's own look), **Ground** (a distinct, darker loamy brown — its own element, not a synonym for Rock), **Air** (a naturally hovering blorb with wings), and **Plant** (leafy green).
- Physically, gems are small (apple-sized), faceted, crystalline objects.
- The Fire Gem and the Electric Gem are both bought from the antique dealer in town, using tokoins.
- The Water Gem isn't sold anywhere; it rests in the fountain at the center of the plaza, free for anyone who finds it.
- The Rock Gem and the Ground Gem are both found out in the canyon biome (see Setting, below) rather than sold — the Rock Gem lying on the canyon floor, the Ground Gem waiting atop the biome's tallest hoodoo.
- The Air Gem is not sold; it waits on the peak of a nearby hill overlooking town.
- The Plant Gem is not sold; it waits atop one of the jungle biome's own trees (see Setting, below).

## Tokoins (currency)

- The game's currency.
- Physical tokoins appear in the world as large coins (dinner-plate sized) standing up on their edge, found lying around for the player to collect.
- Collecting one physical tokoin adds **10** to the player's tokoin currency total.
- Spent on goods from town vendors, including elemental gems.

## Setting

- **World orientation**: the sun rises in the **east** and sets in the **west**. Maps use that convention: the town lies toward the east of the world, while the canyon/mesa biome lies toward the west.
- **The wasteland**: the low-lying area surrounding the main plateau.
  - The wasteland north of the plateau is home to the sole known Size type blorb: **Humongous**, an enormous, slow-moving non-hopping giant.
  - East of the plateau, the wasteland opens into a vast lake. Its waterline sits below the surrounding desert, exposing a narrow natural beach along the upper basin slope. The plateau's eastern cliff falls into the submerged basin; beneath the water, the old wasteland slopes down through the bowl before rising again at the distant mountain foot.
  - Lake shells and freshwater clams collect around the shore and shallows, while harvestable lakeweed grows across the deeper basin floor. The fishing village's shops buy all three.
  - The wasteland floor is gently undulating desert scattered with loose rocks rather than a perfectly flat plain. The main plateau's sides are interrupted by occasional lower grassy shelves, with flat ledges capable of supporting bushes and other vegetation.
- **Starting field**: the grassy field where the player wakes up from their coma.
- **The town**: a small fantasy village near the starting field, with a central plaza/fountain, market stalls, houses, and NPC villagers going about their day.
- **The canyon biome** (also called the **Mesa Biome**, same landmark): a large banded-sandstone rock formation out in the wilderness, distinct from the grassy starting field and the smaller rocky outcrops scattered nearer town. Striped orange/rust/tan/white rock, a slab-paved canyon floor, towering stacked-slab hoodoos, and a natural rock arch. A dramatic climbable landmark, not tied to any plot event yet.
  - Its tallest hoodoo — the **Mesa Tower** — sits at the biome's own center, notably taller and more tiered than the others around it. Reaching the **Ground Gem** waiting on top means climbing it tier by tier, real jump-to-jump parkour rather than a guaranteed path up.
  - A **Rock Gem** rests on the canyon floor elsewhere in the same biome — a shorter find for a player exploring on foot, not gated behind the tower climb.
- **The jungle biome**: a separate, smaller plateau of its own, southwest of the main plateau — a lush, thick, varied landscape distinct from every other biome. Its sloping sides are broken up by small, flat, grass-capped shelves at varying elevations, with bushes and grass growing on the ledges. Its trees run larger and taller than the ones found elsewhere: palm trees (trunks ranging in height with a natural lean/curve), shorter banana trees bearing banana fruit, durian trees bearing large, naturally spiky durian fruit, sprawling banyan trees, stout baobab trees, flowering trees, and hanging vines strung between the canopy.
  - Its resident is a small monkey named **Xiao Hou Zi**, of the **stuffed animal monkey** class (see Primate Kingdom's own jungle villagers, below, for the other member of that class, and the taxonomy note there for how it differs from the world's other primates). He roams the plateau on his own until a player wanders close, at which point he leaves off wandering to come find them specifically. Stick around him long enough and he'll join the party — following the player the way a bonded blorb does, though he is his own companion rather than a blorb himself. Once recruited, the player can also take direct control of him the same way they can with Blorbus. He'll talk if approached, with a loose, chatty handful of lines about the jungle, its fruit, and the vague things "the older vines whisper."
  - A handful of wild **Plant blorbs** live within the plateau, found already naturally elemental the same way the electric and rock blorbs are (see Blorbs, above) rather than merged by hand.
  - A **Plant Gem** waits on top of one of the plateau's own trees, for a player willing to climb up after it.
- **The antique shop**: the market stall the player is meant to visit. Run by an antique dealer who deals mostly in old, unexplained curiosities, plus a couple of elemental gems on the side (currently the Fire Gem and the Electric Gem; the Water, Rock, and Ground Gems are not for sale here, see Elemental Gems above). Confirmed stock:
  - **A corroded pocket compass.** Its needle never settles. Older residents say it was built to point toward elemental energy rather than north, back when someone still needed to track it.
  - **A sealed reliquary locket.** Doesn't open, no matter what's tried on it. Etched with symbols nobody in town can read, though a couple of the older carvings around the fountain use a similar hand. Just an antique curiosity, with no deeper mystery or connection to the plot.
  - **A cracked hourglass**, sand stopped mid-fall. No particular story attached to this one yet. Just a curiosity.
- The fountain in the plaza holds a Water Gem, resting in the water at the bottom of the basin rather than sold anywhere.
- **Fruit trees**: scattered through the wilds alongside the ordinary round-canopy and pine trees, sometimes standing alone and sometimes grouped into a small orchard of the same species planted in tidy rows. Confirmed varieties so far: apple, orange, lemon, and plum. Fruit collects on the ground beneath a tree, already fallen, free for anyone who finds it.
- **Domestic cats** have varied coat colors and can settle into a fully grounded, curled sleeping/resting pose. No named cat character or specific home is established yet.
- **The armorer's stall**: a red-canopied market stall selling basic adventuring gear for anyone heading out of town. Run by an armorer (no name established yet). Confirmed stock:
  - **A notched shortsword.** Seen some use, still holds an edge.
  - **A dented breastplate.** Whoever wore it last, it stopped whatever hit it.
  - **A pitch torch.** Burns steady without ever needing relighting or fuel — it just stays lit.
- **The provisioner's stall**: a green-canopied market stall selling food for the road. Run by a provisioner (no name established yet). Confirmed stock:
  - **A rye loaf.** Dense enough to survive the bottom of a pack.
  - **A wedge of cheese.** Waxed rind, sharp inside.
  - **Dried berries.** Shriveled, but they'll keep for months.

## Kingdoms

Beyond the outskirts — the starting field, town, wasteland, and biomes described under Setting above — lie separate **kingdoms**, each reached through its own portal gate rather than by walking there directly.

- Blorbus's psychic power is what makes the trip possible: a gate only opens for a player who is directly piloting Blorbus (or Humongous while merged with him), never for the player's own body or while riding along as a companion. Walking a piloted Blorbus through an open gate triggers the crossing.
- Arriving in a kingdom sets the player down near a twin gate that leads back to the outskirts, so the same psychic crossing works in reverse.
- The party (bonded blorbs and Xiao Hou Zi) and the player's inventory both travel with the player across a crossing.
- Three gates are confirmed so far, each standing in the outskirts biome it thematically matches:
  - **City Kingdom** — gate stands in the town/city biome. First-pass content: a full-scale avenue/cross-street grid (the same layout style as the outskirts city, repeated out to the mountain ring) lined with houses on every block, ringed by a distant, endless skyscraper skyline. Has its own day/night cycle. No named districts, NPCs, or plot content yet.
  - **Primate Kingdom** — gate stands in the jungle biome, Xiao Hou Zi's home. First-pass content: undulating jungle ground spanning out to the mountains ringing it, under a thick jungle canopy as dense as the crossroads jungle biome's own, broken up by a handful of open clearings, rocky outcrops, and a winding river carved into the ground (mirroring how the crossroads lake sits pushed down below the surrounding land). The kingdom's first village is a handful of giant emergent trees (a new towering tree species with climbable branch-ramps spiraling up their trunks, each landing sprouting its own small leaf-tipped twigs) with small treehouses mounted on every third landing, up and down each trunk. Has its own day/night cycle. Populated by named jungle villagers (see below) standing on treehouse decks or wandering the village clearing, and by wild blorbs of several types (including a scatter of naturally elemental Plant blorbs) roaming the jungle floor.
    - **Jungle villagers**: a second primate species distinct from Xiao Hou Zi in build, but the same **stuffed animal monkey** class as him — larger and taller, with no yellow cheek markings and no heart-shaped facial marking, hips set a bit closer together, proportionally longer limbs that taper less toward the hands/feet, no foot pads, and a torso that reads less sharply pear-shaped than Xiao Hou Zi's own. Individuals vary in height, limb length, tail length, and fur color, which ranges from dark charcoal through grey and light grey to shades of brown. Ambient wildlife: each individual now has their own name and their own two lines of dialogue on "Talk," the same way the outskirts town's villagers do, but still no join/recruit mechanic.
    - **Primate taxonomy.** The world's primates split into two classes: **monkeys** (Xiao Hou Zi and the jungle villagers above, the "stuffed animal monkey" class) always have tails and stay comparatively small; **apes** never have tails and run noticeably larger, with essentially no size overlap between the two classes — an ape's smallest is still bigger than a monkey's biggest. No ape species has actually appeared in the world yet (see Open threads, below).
    - **The curse.** The kingdom is under a curse: whenever a new baby monkey is born, the kingdom's monkeys are reduced to ashes. Their shadows survive the ashing, since shadows can't burn. This is how the Demon King feeds off the Primate Kingdom (see The Demon King's mirror world, above). Lifting the curse is the kingdom's central plot quest, tied to the player's overall fight against the Demon King.
    - **Rewards for lifting the curse.** Once the curse is lifted, the monkeys thank the player by confirming Xiao Hou Zi's place in the party for the rest of the game, on top of the informal recruit that already happens back in the outskirts jungle biome (see Blorbs, above, and Xiao Hou Zi's roam/approach/recruit behavior). Completing a handful of the kingdom's side quests and buying goods with tokoins also earns the player a trusty horse mount named **Manchego** (see Mounts, below).
    - **Training dummy.** One of the kingdom's side quests unlocks a new Aggro type, the training dummy (see Aggros, below).
  - **Ocean Kingdom** — gate stands at the lake. First-pass content: the entire kingdom is open water (a submerged floor far below a constant water surface, swimmable everywhere, extending out to the same scale as the other kingdoms), with a single wooden arrival dock on stilts — matching the fishing village's own dock — holding the return gate and the player's landing spot, plus climbable ramps on both sides so a swimmer can get back onto the deck from anywhere in the water. Has its own day/night cycle. Populated so far only by wild Water and Air blorbs, swimming and hovering through the open water. No named locations, NPCs, or plot content yet.
- What each kingdom actually contains beyond this first pass (named locations, NPCs, plot content) is not yet established — see Open threads.

## Mounts

- **Manchego**: a horse companion, the Primate Kingdom's reward for completing its side quests and buying goods with tokoins (see Kingdoms, above). Horse-sized relative to the player, built on a horse's own joint structure rather than the humanoid/monkey figure rigs used elsewhere. Colored like a Przewalski's horse: a dun body with black lower legs and tail, but with a warmer, orangish-brown mane rather than black. His eyes are shaped like Xiao Hou Zi's.
- Ridden via a **Ride Manchego** interaction, similar in spirit to the direct-control mechanic Blorbus and Xiao Hou Zi already have. Currently grants faster ground movement than walking; no other gameplay effect yet.
- Future plans, not yet built: possibly equipping blorbs onto Manchego somehow.

## Aggros

Hostile creatures — "NME"s — that oppose the player and their blorbs, as opposed to the peaceful wildlife and townsfolk found elsewhere.

- **Skeletons**: the first Aggro, and the first minions manifesting from the Demon King's mirror world (see above). They rise straight up out of the ground out in the open wasteland — never in town, the village, or the lake. Built on the same base figure as a person or NPC, but bone-white all over, with noticeably skinnier arms and legs to read as bare bone, and no abdomen — in its place, a column of small spine segments runs from hip to chest, tilted back a little the way a real spine would sit.
- Skeletons are aggressive: they close in on the player and any of the party's free-roaming blorbs and attack with punches. Blorbs are what actually fight them off — jumping in for a melee bounce-attack, or, for the water and fire blorbs, streaming their element at the skeleton straight from their core. A skeleton that's fought off sinks back into the ground it rose from.
- A blorb that takes enough damage to fully deplete its HP loses its mass entirely, leaving only its core behind until the core regenerates it a full blorb again.
- **Training dummies**: a second Aggro type, unlocked through one of the Primate Kingdom's side quests (see Kingdoms, above). A training dummy starts as inert training equipment, harmless to walk past. Left unobserved for three in-game nights, it comes to life and behaves like a skeleton, but is noticeably harder to defeat.

## Open threads

Not yet established — flag these back to the user if a future task depends on them rather than assuming an answer:

- The player character's name and identity (the amnesia is presumably a plot hook resolved later).
- Why Blorbus specifically wakes up sentient when the third starter blorb is left ungemmed — the mechanism and his psychic inventory-keeper role are now established (see Protagonist, above), but not the underlying reason or deeper backstory.
- The rest of the elemental roster beyond Water, Fire, Electric, Rock, Ground, Plant, and Blorbus's unique Psychic type.
- The Demon King's motivation/backstory in more depth, and their name (the mirror-world mechanism they manifest minions through is now established, see The Demon King's mirror world, above).
- What (if anything) each element's blorb-suit covering actually grants the player once worn — the suit exists as a cosmetic mechanic so far, with no gameplay effect tied to it yet.
- Xiao Hou Zi's deeper personality and backstory, and any role in the plot beyond being a recruitable jungle companion — his physical design, roam/approach/recruit behavior, and a first pass of talk-dialogue lines are established, but who he really is (and the "something's coming for this world" aside one of his lines hints at) is still open.
- What happens when the player's own HP (new alongside skeletons, see Aggros above) reaches 0 — it currently just clamps there with no death or respawn state, same open-ended gap as the blorb-suit covering's missing gameplay effect above.
- What the City and Ocean Kingdoms actually contain beyond first-pass terrain/scenery (see Kingdoms above) is still unestablished: no named locations, NPCs, or plot content yet. The Primate Kingdom now has a central plot quest (the curse, see Kingdoms above), but its step-by-step questline, who gives it, and what lifting the curse actually looks like in play are still unestablished, as are the kingdom's other side quests beyond the training dummy unlock.
- Further kingdoms beyond the three confirmed gates: a snow kingdom, a China-themed kingdom, and a candy kingdom have been mentioned as future destinations, with no biome, gate location, or content established yet.
- Where training dummies actually appear in the world once unlocked (just the Primate Kingdom, or elsewhere too), and who places or sells them to the player.
- The Primate Kingdom curse's step-by-step questline is deliberately not yet designed (see Kingdoms, above) — don't assume an answer, more is coming later.
- Ape species, and a third monkey type distinct from the "stuffed animal monkey" class (see Primate taxonomy under Primate Kingdom, above), don't exist in the world yet — an in-progress base rig/pose template exists in the codebase that can build either (see `scripts/ape_template.gd`'s own class doc comment: has_tail=false for an ape, true for this other monkey type), but no actual species, name, personality, or placement in the world is established for either.
