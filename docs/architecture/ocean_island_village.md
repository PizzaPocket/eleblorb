# Ocean Kingdom: Kai Mālie, the Island Village

Status: concept brief, first planning pass, in review (2026-10-06). Read with
`ocean_kingdom.md`. Hawaiian words and every line of Hawaiian dialogue must be
reviewed by a fluent speaker before they ship.

## 1. Premise

A small modern village on the Ocean Kingdom's largest island, rooted in
ancient Hawaiian culture in the way Ohio is rooted in an old Western village
tradition with a modern blend. The proposed name is **Kai Mālie**, "calm sea."

Most residents are Native Hawaiian. Others have the international backgrounds
of modern Hawaiʻi (Japanese, Filipino and Portuguese family lines from the
plantation era) or arrived more recently through the lake gate from the
Crossroads. Every resident speaks Hawaiian, the language of the community,
using the same learning dialogue system as the Chinese village.

### History (proposed)

The founding families' ancestors reached these islands by voyaging canoe,
navigating by stars, swells and birds, as the Polynesian navigators did. The
village has lived with the sea folk for generations through a quiet exchange
at the shore. Later families came by other routes, and since the lake gate
opened, a few people from the Crossroads have stayed.

### Values that shape the plan

- **Ahupuaʻa:** land managed as a whole from the uplands to the reef, so that
  water, food and fishing are one system.
- **Mālama ʻāina:** care for the land and sea, which supply the village.
- **ʻOhana and kūpuna:** extended family, and elders whose counsel guides
  shared decisions.
- **Hoʻokipa:** hospitality to visitors, within limits (the pirates are
  welcome on the beach, and no further).

## 2. What exists now

- The main island: centre world `(-118, 72)`, rising to about 10.5 m, with
  dense Plant-Kingdom-like vegetation (`ocean_kingdom_terrain.gd`, `ISLANDS`).
  Its listed radius is 116 m, but dry land reaches only about 55 m from the
  centre, with a steep shore and no beach (see `ocean_island_village_layout.md`).
- The arrival dock and return gate stand on stilts at world `(0, 0)`, about
  83 m off the island's nearest shore, over 18 to 40 m of water.
- No village, residents or language exist on the island yet.

### Non-regression requirements

- The arrival dock, its ramps and the return gate.
- The island's dense vegetation and its role as the main exploration space.
- Open water for the Kraken route and the ships' route.

## 3. Community

The census proposes **fifteen residents in seven households**.

| Household | Residents | Work |
|---|---|---|
| **Kahananui** | **Kawika Kahananui**, elder; **Malia Kahananui**, his wife; **Keoni**, their grandson, 12 | Kawika keeps the fishpond (*kahu loko iʻa*) and sits with the kūpuna; Malia makes lei and *kapa* (bark cloth); Keoni helps at the pond |
| **Kealoha** | **Leilani Kealoha**; **Makoa Kealoha**, her husband; **Noelani Kealoha**, their daughter, 17 | Leilani farms the *loʻi kalo* (taro terraces) and makes poi; Makoa fishes with throw nets; Noelani surfs and is the beach's lifeguard |
| **Kahale** | **Kahiau Kahale**; **Iolana Kahale**, his niece | Kahiau is the navigator and canoe builder who keeps the canoe house; Iolana is his apprentice |
| **Akana** | **Puanani Akana** | *kumu hula* and the village schoolteacher; keeper of chant and history |
| **Nakamura** | **Hiro Nakamura**; **Grace Nakamura** | the village store and shave ice counter; Hiro's family line goes back to plantation-era Japanese arrivals, Grace's to Filipino ones |
| **Medeiros** | **Manny Medeiros**; **Kahala Medeiros**, his wife | Manny, of Portuguese family line, makes ukulele and plays; Kahala practises *lāʻau lapaʻau*, Hawaiian plant medicine |
| **Newcomers** | **Sam Okafor**; **Elena Varga** | Sam came through the lake gate from Ohio and keeps the guest house; Elena is a marine biologist who studies the reef with the sea folk's Talisa |

### Governance and relations

- **Kūpuna:** Kawika, Malia and Puanani meet as the council of elders in the
  *hālau* when the village must decide something together.
- **Discord now, harmony later.** When the hero arrives, the Demon King's
  discord has set every community in the kingdom against the others (how is
  still open). Restoring harmony is the kingdom's story.
- **The sea folk:** the shoreline exchange is generations old but has broken
  off; each side blames the other for damage to its waters. Kawika and Pelaju,
  old friends, no longer speak, and Elena's work with Talisa has stopped.
- **The pirates:** both crews used to anchor offshore to trade for water and
  food on the beach. Now they are barred from it.
- **The Crossroads:** goods come through the lake gate, which links the island
  to the fishing village's portal landing.

### Economy and trade (to be completed in the trade ledger)

Taro and poi from the *loʻi*; fish from the fishpond and the reef; lei and
*kapa*; ukulele; the store's goods, partly brought through the gate; the guest
house. The store is the hero's shop; for now it sells fruit (bananas from the
village's own *maiʻa*, with oranges and lemons brought through the gate), a
placeholder until its stock is designed.

## 4. Settlement structure (pre-layout)

The plan follows an ahupuaʻa in miniature, running from the island's high
centre down to its eastern reef, facing the arrival dock.

1. **Uplands:** the island's dense forest, left wild, with a spring that feeds
   the village's water.
2. **Loʻi kalo:** flooded taro terraces fed by an *ʻauwai* (irrigation ditch)
   from the spring, stepping down toward the village.
3. **The village:** homes, the store, the guest house, the *hālau* and the
   canoe house around a shared green near the shore.
4. **The beach:** the landing facing the arrival dock, the canoe launch, the
   surf break and the pirates' trading beach at one end.
5. **The fishpond:** a *loko kuapā*, a curved lava-rock wall enclosing reef
   flat, with *mākāhā* (sluice gates) where young fish enter and grown fish
   cannot leave.
6. **The reef:** Makoa's fishing grounds and the sea folk's meeting place at
   the shore.

The arrival sequence: from the gate dock, the visitor sees the beach, the
canoe house and the village green under the island's forest, with the taro
terraces stepping up behind.

## 5. Architectural charter (draft)

- **Primary, about 70 percent: Hawaiian plantation and regional modern.**
  Single-wall board-and-batten houses raised on posts over lava-rock piers;
  the **double-pitched hip roof** (steeper above, flatter over the eaves) of
  Hawaiian regional architecture, with deep eaves; wide *lānai* (verandas);
  jalousie windows; corrugated metal or shingle roofs; open-plan rooms for
  cross-ventilation.
- **Secondary, about 25 percent: traditional *hale*.** For communal and
  cultural buildings only: the canoe house (*hale waʻa*) and the *hālau*, with
  steep thatched roofs of pili grass on timber frames, standing on lava-rock
  platforms (*paepae*).
- **Accent, about 5 percent:** dry-laid lava-rock walls, the fishpond wall and
  the *ʻauwai*.
- **Palette:** weathered timber and painted board in soft greens, creams and
  warm reds 60 percent; dark lava rock and thatch 30 percent; flowering plants
  and *kapa* patterns 10 percent.
- **Exclusions:** *heiau* (temple platforms) and any sacred structure or
  carving used as decoration; tiki-bar kitsch; resort architecture.

## 6. Language

Every resident speaks Hawaiian, the language of the community, presented
exactly as the Chinese village's lines are: the line is shown in Hawaiian, and each word can be selected to see
its meaning.

- **Spelling:** standard modern orthography, with the *ʻokina* written as
  U+02BB (ʻ), never an apostrophe, and long vowels with the *kahakō* (ā ē ī ō
  ū). Both game fonts (Varela Round and Noto Sans SC) contain these
  characters.
- **System:** `ChineseLexicon` is written for Chinese (its words carry pinyin).
  The rebuild should generalise it into one lexicon interface with a lexicon
  per language, so `DialogUI` can present Hawaiian the same way. A Hawaiian
  entry carries its meaning and, optionally, a pronunciation or stress guide in
  place of pinyin.
- **Who speaks what:** everyone in the village speaks Hawaiian, whatever their
  background, including the two newcomers from the Crossroads.
- **Accuracy:** every Hawaiian line and gloss must be checked by a fluent
  speaker before release.

## Fixed, proposed and open

**Fixed (from direction):** a modern village on the largest island rooted in
ancient Hawaiian culture; mostly Native Hawaiian residents with some of
international background; every resident speaks Hawaiian through the Chinese
village's language system; the Demon King's discord with the kingdom's other
communities at first.

**Proposed:** the name Kai Mālie; the voyaging history; the census of fifteen
in seven households; the ahupuaʻa plan from spring to reef; the plantation and
regional modern charter with traditional *hale* for communal buildings; the
guest house as one of the kingdom's two rest points (Sam charges the ordinary
Crossroads rate of 10 Tokoins through the shared transaction interface); the
generalised lexicon.

**Open:** the island's spring and terrain changes the *loʻi* need; whether the
village has a part in the Tidekeeper or Kraken stories.
