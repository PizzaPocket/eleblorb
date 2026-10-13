"""The Chinese village on its broken-plateau islands: every compound, building, court, field
and garden placed and checked (chinese_village.md 4.0 to 4.5, 4.2a; chinese_village_palace.md 3).

    python3 tools/chinese_village_plan.py [--json out.json]

It reads the islands, rim and bridges from tools/chinese_village_gorge.py and places the
program of chinese_village.md 4.1.2 and 4.1.3 on them. It follows the rank charter (4.2):
- the palace: yellow glaze and vermilion;
- the inn: the Shihu Yuan finery;
- the homes: brick plinth and piers with white plaster panels, grey hard-gable roofs.

It checks:
- everything inside its island's walkable top (2.5 m in from the edge, for the parapet
  and a walk);
- buildings at least 1.5 m apart;
- every bridge landing's 6 x 6 m apron clear;
- a route 3 m wide (2 m in gardens) from every landing to every door and to every other
  landing on the island;
- the land each program needs.

Coordinates: each island's own (x, z) in metres from its centroid, x east, z south, as the
islands' frame in the gorge tool. A home faces south: its main room on the north side of
its walled court, its gate in the south wall.
"""
import io, json, math, runpy, sys, contextlib
from shapely.geometry import Polygon, Point, LineString, box
from shapely.ops import unary_union
from shapely import affinity

_argv = sys.argv; sys.argv = ['chinese_village_gorge.py']
with contextlib.redirect_stdout(io.StringIO()):
    try: G = runpy.run_path(__file__.replace('chinese_village_plan.py', 'chinese_village_gorge.py'))
    except SystemExit: raise SystemExit('the islands do not pass their own checks: run tools/chinese_village_gorge.py')
sys.argv = _argv
ISL = G['ISLANDS']; BR = G['BR']
CEN = {k: (g.centroid.x, g.centroid.y) for k, g in ISL.items()}
EDGE = 2.5          # parapet and a walk inside every edge
GAP = 1.5           # between buildings
ROUTE = 3.0; GARDEN_PATH = 2.0; APRON = 6.0

## ---- items: island, key, name, kind, (x, z, w, d, rot), and what it is
## kind: compound (a walled court with its buildings: solid at its walls, entered by its gate),
## building, court (open, walked across), platform (a raised terrace, walked across by its ramp),
## field (worked ground, walked round), grove, feature (inside a court: a well, a stall, a rock)
I = []
def item(island, key, name, kind, rect, door='+z', style='home', roof='hard_gable', who='', program='', on=None, storeys=1, **extra):
    I.append(dict(island=island, key=key, name=name, kind=kind, rect=rect, door=door, style=style, roof=roof, who=who,
                  program=program, on=on, storeys=storeys, **extra))
H = (11.0, 17.0)    # a home and its court: three-bay main room, court, side shed (4.1.2)

# Gate: the gatehouse is the bridge-head of the entry and the axis; Lian Fu lives above it
item('gate', 'gatehouse', 'Gatehouse', 'building', (1, 8, 12, 10, 0), door='-z', style='gatehouse', roof='hard_gable', storeys=2,
     who='Lian Fu (above)', program='a passage through for the entry and the axis; lamp store; Lian Fu\'s room upstairs', through=True)
item('gate', 'gate_forecourt', 'Arrival forecourt', 'court', (1, -8, 12, 12, 0), program='arrival; lamp posts; the four landings meet here')

# E, Inn: front court, two-storey hall with gallery, back court, kitchen, latrine, guest wing; a Shihu garden court beside it
item('inn', 'inn', 'Inn and restaurant', 'compound', (-3, 2, 22, 28, 0), door='+z', style='inn', roof='hard_gable_green', storeys=2,
     who='Lu, Lu Hao; Chen lodges', program='front court; two-storey common room with gallery; back court; kitchen; latrine; guest wing',
     moon_gate='+x')
item('inn', 'inn_garden', "Inn's garden court", 'court', (18, -5, 13, 13, 0), style='shihu',
     program='a small Shihu Yuan court: lotus pond, rockery, hexagonal pavilion, scholar\'s rock, cloud-pruned pine; reached by the moon gate',
     garden=True)

# C, Roofers
item('roofers', 'roofer_home', "Roofer's home", 'compound', (-4.5, -8, H[0], H[1], 0), who='Wen Zhao', program='three-bay main room with kang; court; side shed')
item('roofers', 'roof_yard', 'Roof yard', 'court', (10, -9, 10, 12, 0), style='yard', who='Wen Zhao', program='stacks of grey tile and timber; a practice roof frame')
item('roofers', 'westend_home', 'West end home', 'compound', (-4, 14, H[0], H[1], 0), who='Shu Mei, Pei', program='three-bay main room with kang; court; side shed')

# A, Lantern Row: Sun Wu Kong's rock and a lookout on the north rim; the children's play hut in its lee
item('lantern', 'sealing_rock', "Sun Wu Kong's rock", 'feature', (0, -30, 8, 10, 0), style='rock', program='the sealing rock under its gold band; a lookout beside it')
item('lantern', 'play_yard', 'Play hut and yard', 'court', (4, -19, 12, 12, 0), style='play', who='Xiu, Bao, and the others', program='the stick play hut; the staff among the loose sticks')
item('lantern', 'lantern_home', 'Lantern home and workshop', 'compound', (-3, -4, 14, 18, 0), door='+x', who='Mei Lian, Jin Wei, Xiu', program='main room with kang; workshop; paper and frames drying')
item('lantern', 'tile_home', 'Tile home', 'compound', (-11, 15, 12, 16, 0), door='+x', who='Yun Tao, Bao', program='main room with kang; tile stack; the one wave coping on a home\'s yard wall', wave_coping=True)

# B, Market: the square with Chen's stall and the well; the bao house; the carrier's home and loading shed
item('market', 'market_square', 'Market square', 'court', (0, 1.5, 15, 17, 0), style='market', program='Chen\'s stall; the well; gossip', public=True)
item('market', 'well', 'Well', 'feature', (1, 3, 2.4, 2.4, 0), on='market_square', style='well', program='from a spring in the island\'s rock heart')
item('market', 'chen_stall', "Chen's stall", 'feature', (-5, -3, 5, 3, 0), on='market_square', style='stall', who='Chen', program='including the Seed of Life')
item('market', 'bao_house', 'Bao house', 'compound', (-6, -21, 12, 20, 0), door='+z', style='shop', who='Hua Chen, Ting', program='shopfront on the square side; steamers; main room with kang')
item('market', 'carrier_home', "Carrier's home and loading shed", 'compound', (14, 24, 12, 18, 0), door='-z', style='home', who='Bo Xiang, Rong', program='main room with kang; loading shed for the levy and Ohio goods')

# D, Fields: strips, household plots by the B bridge, threshing floor, shed, compost and night-soil pits downwind on the east rim
item('fields', 'threshing', 'Threshing floor', 'court', (-8, -19, 15, 15, 0), style='threshing', program='harvest and festivals; Mei Lian\'s lanterns hung for them', public=True)
for i in range(8):
    item('fields', 'plot%d' % (i + 1), 'Household plot', 'field', (5.5 + (i % 4) * 5.4, -30 + (i // 4) * 9, 5, 8, 0), style='plot', program='one per household, each kept differently')
# the strips leave a lane down the west side, from the B bridge to the farm bridge
for j, (z, x0, x1) in enumerate([(-2, -15, 31), (9, -20, 31), (20, -22, 25), (31, -21, 20)]):
    item('fields', 'strip%d' % (j + 1), 'Field strip', 'field', ((x0 + x1) / 2, z, x1 - x0, 10.5, 0), style='strip', program=['millet', 'wheat', 'soybeans', 'millet'][j])
item('fields', 'field_shed', 'Field shed', 'building', (-21, -8, 6, 5, 0), door='+x', style='shed', roof='hard_gable', program='tools; seed')
item('fields', 'pits', 'Compost and night-soil pits', 'field', (31, -10, 5, 6, 0), style='pits', program='downwind, on the east rim')

# Bamboo, Farm: the grove on the north half, Tian Bo's home and Pandy's pen, bean terraces stepping down the south
item('bamboo', 'grove', 'Bamboo grove', 'grove', (-17, -14, 40, 16, 0), style='grove', program='clumping bamboo, 6 to 10 clumps; a path and two clearings')
item('bamboo', 'farm_home', "Tian Bo's home", 'compound', (13, -4, H[0], H[1], 0), who='Tian Bo, Pandy', program='three-bay main room with kang; court; side shed')
item('bamboo', 'pen', "Shed and Pandy's pen", 'building', (27, 3, 10, 9, 0), door='-z', style='shed', roof='hard_gable', who='Pandy', program='shed and pen')
for j, (x, z, w) in enumerate(((6, 11, 36), (6, 18, 36), (8, 25, 34))):
    item('bamboo', 'terrace%d' % (j + 1), 'Bean terrace', 'field', (x, z, w, 6, 0), style='terrace', program='beans; the levy\'s boundary stones on the top one before the quest')

# Palace (chinese_village_palace.md 3, in the palace island's own frame)
P_ = [
    ('palace_apron', 'Axis landing apron', 'court', (0, 55, 8, 6, 0), {}),
    ('gate_pavilion', 'Gate pavilion', 'building', (0, 47.5, 16, 7, 0), dict(style='palace', roof='xieshan', through=True, door='+z', program='the axis bridge-head: chains anchored in its base')),
    ('front_court', 'Front court', 'court', (0, 32, 40, 22, 0), dict(style='palace', program='paved, an axis of white stone; the village square after the quest', public=True)),
    ('dining_hall', 'Dining Hall', 'building', (28, 32, 9, 16, 0), dict(style='palace', roof='xieshan', door='-x', program='communal dining after the quest')),
    ('throne_terrace', 'Throne terrace', 'platform', (0, 3, 46, 34, 0), dict(style='marble', program='three tiers of 1.4 m with balustrades; a central ramp in three flights', height=4.2)),
    ('throne_hall', 'Throne Hall', 'building', (0, 1, 28, 16, 0), dict(style='palace', roof='wudian2', on='throne_terrace', door='+z', program='the throne; the village hall after the quest', height=4.2)),
    ('inner_court', 'Inner court', 'platform', (0, -24, 36, 14, 0), dict(style='marble', program='1.4 m above the throne terrace', height=5.6)),
    ('apartments', 'Inner apartments', 'building', (-26, -24, 14, 20, 0), dict(style='palace', roof='xieshan', door='+x', program='records, meeting and reading rooms after the quest', height=5.6)),
    ('kitchen', 'Royal Kitchen', 'building', (29, -22, 18, 12, 0), dict(style='palace_service', roof='xuanshan', door='+x', program='the Chef\'s fight floor; Lu\'s community kitchen after')),
    ('chef_quarters', "Chef's quarters", 'building', (29, -34, 8, 6, 0), dict(style='palace_service', roof='xuanshan', door='+x', program='Liang Zhen\'s room after the quest')),
    ('service_yard', 'Service yard', 'court', (45, -18, 10, 30, 0), dict(style='yard', program='packed earth; well; latrine closet; cart turn; the B bridge lands here')),
    ('levy_store', 'Levy store', 'building', (46, -8, 6, 10, 0), dict(style='palace_service', roof='xuanshan', on='service_yard', door='-x', program='the levy; the village store after')),
    ('high_pavilion', 'High pavilion', 'building', (0, -44, 10, 10, 0), dict(style='palace', roof='cuanjian2', door='+z', storeys=2, program='the Emperor\'s private view north; a public lookout after', height=9.8)),
    ('moon_court', 'Moon-gate court', 'court', (-18, -46, 14, 12, 0), dict(style='shihu', garden=True, program='a pomegranate; entered by moon gates')),
    ('pond_court', 'Pond court', 'court', (14, -45, 16, 13, 0), dict(style='shihu', garden=True, program='lotus pond, zigzag bridge, rockery and waterfall, hexagonal pavilion')),
    ('rock_garden', 'Rock garden', 'court', (-32, -44, 11, 11, 0), dict(style='shihu', garden=True, program='weathered stones; scholar\'s rocks on plinths; the west garden gate')),
    ('bamboo_court', 'Bamboo screen court', 'court', (-38, -12, 10, 14, 0), dict(style='shihu', garden=True, program='a bamboo screen and a bench')),
]
for key, name, kind, rect, ex in P_:
    ex = dict(ex); I.append(dict(island='palace', key=key, name=name, kind=kind, rect=rect, door=ex.pop('door', '+z'), style=ex.pop('style', 'palace'),
                                  roof=ex.pop('roof', 'none'), who=ex.pop('who', ''), program=ex.pop('program', ''), on=ex.pop('on', None), storeys=ex.pop('storeys', 1), **ex))

NEED_PLOTS = {'inn': 2290, 'market': 2290, 'lantern': 1963, 'roofers': 1521, 'fields': 3632, 'bamboo': 3217, 'gate': 1018, 'palace': 12076}

# ---- geometry
def rect_poly(it):
    x, z, w, d, rot = it['rect']; k = it['island']; cx, cz = CEN[k]
    return affinity.rotate(box(cx + x - w / 2, cz + z - d / 2, cx + x + w / 2, cz + z + d / 2), rot, origin=(cx + x, cz + z))
DOORV = {'+z': (0, 1), '-z': (0, -1), '+x': (1, 0), '-x': (-1, 0)}
def door_point(it):
    x, z, w, d, rot = it['rect']; cx, cz = CEN[it['island']]; dx, dz = DOORV[it['door']]
    return (cx + x + dx * (w / 2 + 0.8), cz + z + dz * (d / 2 + 0.8))
TOP = {k: g.buffer(-EDGE, 4) for k, g in ISL.items()}
for it in I:
    it['poly'] = rect_poly(it)
    if it['kind'] in ('field', 'grove'):      # worked ground follows the island's edge
        it['poly'] = it['poly'].intersection(TOP[it['island']].buffer(-0.3))
LANDINGS = {}
for b in BR:
    for side, k in ((0, b['a']), (1, b['b'])):
        if k in ISL: LANDINGS.setdefault(k, []).append(dict(at=tuple(b['ends'][side]), to=b['b'] if side == 0 else b['a'], width=b['width']))
problems = []
# 1. inside the walkable top
for it in I:
    if not TOP[it['island']].buffer(0.05).contains(it['poly']): problems.append((it['island'], it['key'], 'reaches the edge strip (%.1f m out)' % it['poly'].difference(TOP[it['island']]).area))
# 2. buildings and compounds apart; nothing solid in a court unless it stands on or in it
SOLID = ('building', 'compound')
by = {}
for it in I: by.setdefault(it['island'], []).append(it)
for k, its in by.items():
    for i in range(len(its)):
        for j in range(i + 1, len(its)):
            a, b = its[i], its[j]
            if a.get('on') == b['key'] or b.get('on') == a['key']: continue
            if a['kind'] == 'feature' or b['kind'] == 'feature': continue
            g = a['poly'].distance(b['poly'])
            if a['kind'] in SOLID and b['kind'] in SOLID and g < GAP - 1e-6: problems.append((k, a['key'], b['key'], 'only %.1f m apart' % g))
            elif (a['kind'] in SOLID) != (b['kind'] in SOLID) and a['poly'].intersection(b['poly']).area > 0.5: problems.append((k, a['key'], b['key'], 'overlap'))
            elif a['kind'] == b['kind'] == 'court' and a['poly'].intersection(b['poly']).area > 0.5: problems.append((k, a['key'], b['key'], 'courts overlap'))
# 3. landing aprons clear
APRONS = {}
for k, ls in LANDINGS.items():
    for l in ls:
        x, z = l['at']; c = Point(x, z); g = ISL[k]
        # the apron lies on the island, just in from the edge where the bridge meets it
        cx, cz = CEN[k]; d = math.hypot(cx - x, cz - z); ux, uz = (cx - x) / d, (cz - z) / d
        ap = affinity.rotate(box(x + ux * APRON / 2 - APRON / 2, z + uz * APRON / 2 - APRON / 2, x + ux * APRON / 2 + APRON / 2, z + uz * APRON / 2 + APRON / 2), math.degrees(math.atan2(uz, ux)), origin=(x + ux * APRON / 2, z + uz * APRON / 2))
        APRONS[(k, l['to'])] = ap; l['apron'] = ap; l['inner'] = (x + ux * (APRON + 0.5), z + uz * (APRON + 0.5))
        for it in by.get(k, []):
            if it['kind'] in SOLID + ('field', 'grove') and not it.get('through') and it['poly'].intersection(ap).area > 0.3:
                problems.append((k, 'the landing from %s' % l['to'], 'is blocked by %s' % it['key']))
# 4. routes: every landing to every door and every other landing, round the solid things
ROUTES = []
def clear(k, pts, own, w):
    band = LineString(pts).buffer(w / 2, 4)
    if not TOP[k].buffer(EDGE - 0.6).contains(band): return False
    for it in by.get(k, []):
        if it['key'] in own or it.get('through'): continue
        if it['kind'] in SOLID + ('field',) or (it['kind'] == 'feature' and it['style'] in ('rock',)):
            if band.intersects(it['poly'].buffer(-0.05)): return False
    return True
def route(k, a, b, own, w):
    if clear(k, [a, b], own, w): return [a, b]
    cx, cz = CEN[k]; xs = [cx + i for i in range(-60, 61, 2)]; zs = [cz + i for i in range(-75, 76, 2)]
    cand = [(x, z) for x in xs for z in zs if TOP[k].contains(Point(x, z))]
    for wpt in sorted(cand, key=lambda q: math.dist(a, q) + math.dist(q, b))[:2500]:
        if clear(k, [a, wpt, b], own, w): return [a, wpt, b]
    sa = [q for q in cand if clear(k, [a, q], own, w)]; sb = [q for q in cand if clear(k, [q, b], own, w)]
    for p1, p2 in sorted(((p, q) for p in sa[:300] for q in sb[:300]), key=lambda t: math.dist(a, t[0]) + math.dist(*t) + math.dist(t[1], b))[:6000]:
        if clear(k, [a, p1, p2, b], own, w): return [a, p1, p2, b]
    return None
for k, ls in LANDINGS.items():
    starts = [(l['to'], l['inner']) for l in ls]
    s0name, s0 = starts[0]
    for it in by.get(k, []):
        if it['kind'] not in SOLID or it.get('on'): continue
        w = GARDEN_PATH if it['style'] == 'shihu' else ROUTE
        r = route(k, s0, door_point(it), {it['key']}, w)
        if r is None: problems.append((k, it['key'], 'no %g m route from the %s landing to its door' % (w, s0name)))
        else: ROUTES.append(dict(island=k, frm=s0name, to=it['key'], pts=[[round(a, 2), round(b, 2)] for a, b in r]))
    for name, s in starts[1:]:
        r = route(k, s0, s, set(), ROUTE)
        if r is None: problems.append((k, 'no 3 m route between the %s and %s landings' % (s0name, name)))
        else: ROUTES.append(dict(island=k, frm=s0name, to='landing:' + name, pts=[[round(a, 2), round(b, 2)] for a, b in r]))
# 5. land: the program fits its island (checked in the gorge tool), and the fields hold their area
strips = sum(it['poly'].area for it in I if it['style'] == 'strip')
if strips < 1550: problems.append(('fields', 'strips are %.0f m2, under 1,550' % strips))
terr = sum(it['poly'].area for it in I if it['style'] == 'terrace')
if terr < 580: problems.append(('bamboo', 'terraces are %.0f m2, under 600' % terr))

# 6. parapets 1 m in from every edge, open at the bridge landings: marble round the palace,
# fences round worked ground, brick with a tile coping elsewhere
PARAPET_KIND = {'palace': 'marble', 'fields': 'fence', 'bamboo': 'fence'}
PARAPETS = []
for k, g in ISL.items():
    ring = g.buffer(-1.0, 4).exterior
    gaps = unary_union([ap.buffer(1.2) for (kk, t), ap in APRONS.items() if kk == k])
    rest = ring.difference(gaps) if not gaps.is_empty else ring
    for ln in (rest.geoms if hasattr(rest, 'geoms') else [rest]):
        if ln.length > 1.0: PARAPETS.append(dict(island=k, kind=PARAPET_KIND.get(k, 'brick'), pts=[[round(x, 2), round(z, 2)] for x, z in ln.simplify(0.4).coords]))

for p in problems: print('PROBLEM', p)
def out(p):
    if p.geom_type != 'Polygon': p = max(p.geoms, key=lambda q: q.area)
    return [[round(x, 2), round(z, 2)] for x, z in p.exterior.coords]
data = dict(G['data'], items=[dict({k: v for k, v in it.items() if k != 'poly'}, outline=out(it['poly']), door_at=door_point(it), centre=[round(CEN[it['island']][0] + it['rect'][0], 2), round(CEN[it['island']][1] + it['rect'][1], 2)]) for it in I],
            routes=ROUTES, parapets=PARAPETS, aprons=[dict(island=k, to=t, outline=out(p)) for (k, t), p in APRONS.items()], tops={k: out(v) for k, v in TOP.items()},
            plan_problems=[list(map(str, p)) for p in problems])
if '--json' in sys.argv: json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
print('%d items on %d islands; %d routes; strips %.0f m2, terraces %.0f m2; %d problems' % (len(I), len(by), len(ROUTES), strips, terr, len(problems)))
if problems: sys.exit(1)
