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
- every opening (gate, door, through passage, garden opening) opens onto ground or onto its
  building's raised level, and facing openings are joined;
- the palace's raised levels each reached by a ramp from the ground;
- one path network on each island, grown on a 0.5 m grid round everything solid, joining every
  landing, passage, ramp foot, yard and field;
- the land each program needs.

Coordinates: each island's own (x, z) in metres from its centroid, x east, z south, as the
islands' frame in the gorge tool. A home faces south: its main room on the north side of
its walled court, its gate in the south wall.

When every check passes it writes scripts/chinese_plan.gd (tools/gd_plan.py), the one plan the game's builder
and validator read; edit here and rerun, never the generated file.
"""
import io, json, math, runpy, sys, contextlib, re
from pathlib import Path
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
item('gate', 'gatehouse', 'Gatehouse', 'building', (0, 8, 12, 10, 0), door='-z', style='gatehouse', roof='hard_gable', storeys=2,
     who='Lian Fu (above)', program='a passage through for the entry and the axis; lamp store; Lian Fu\'s room upstairs', through=True)
item('gate', 'gate_forecourt', 'Arrival forecourt', 'court', (0, -8, 12, 12, 0), program='arrival; lamp posts; the four landings meet here')

# E, Inn: front court, two-storey hall with gallery, back court, kitchen, latrine, guest wing; a Shihu garden court beside it
item('inn', 'inn', 'Inn and restaurant', 'compound', (-3, 2, 22, 28, 0), door='+z', style='inn', roof='hard_gable_green', storeys=2,
     who='Lu, Lu Hao; Chen lodges', program='front court; two-storey common room with gallery; back court; kitchen; latrine; guest wing',
     moon_gate='+x')
item('inn', 'inn_garden', "Inn's garden court", 'court', (18, -5, 13, 13, 0), style='shihu',
     program='a small Shihu Yuan court: lotus pond, rockery, hexagonal pavilion, scholar\'s rock, cloud-pruned pine; reached by the moon gate',
     garden=True, openings=[('s', 0.0, 'oct'), ('w', -2.0, 'moon'), ('n', -2.0, 'round')])

# C, Roofers
item('roofers', 'roofer_home', "Roofer's home", 'compound', (-4.5, -8, H[0], H[1], 0), who='Wen Zhao', program='three-bay main room with kang; court; side shed')
item('roofers', 'roof_yard', 'Roof yard', 'court', (10, -9, 10, 12, 0), style='yard', who='Wen Zhao', program='stacks of grey tile and timber; a practice roof frame')
item('roofers', 'westend_home', 'West end home', 'compound', (-4, 14, H[0], H[1], 0), who='Shu Mei, Pei Pei', program='three-bay main room with kang; court; side shed')

# A, Lantern Row: Sun Wu Kong's rock and a lookout on the north rim; the children's play hut in its lee
item('lantern', 'sealing_rock', "Sun Wu Kong's rock", 'feature', (0, -30, 8, 10, 0), style='rock', program='the sealing rock under its gold band; a lookout beside it')
item('lantern', 'play_yard', 'Play hut and yard', 'court', (4, -19, 12, 12, 0), style='play', who='Xiu Xiu, Bao Bao, and the others', program='the stick play hut; the staff among the loose sticks')
item('lantern', 'lantern_home', 'Lantern home and workshop', 'compound', (-3, -4, 14, 18, 0), door='+x', who='Mei Lian, Jin Wei, Xiu Xiu', program='main room with kang; workshop; paper and frames drying')
item('lantern', 'tile_home', 'Tile home', 'compound', (-11, 14, 12, 14, 0), door='+x', who='Yun Tao, Bao Bao', program='main room with kang; tile stack; the one wave coping on a home\'s yard wall', wave_coping=True)

# B, Market: the square with Chen's stall and the well; the bao house; the carrier's home and loading shed
item('market', 'market_square', 'Market square', 'court', (0, 1.5, 15, 17, 0), style='market', program='Chen\'s stall; the well; gossip', public=True)
item('market', 'well', 'Well', 'feature', (1, 3, 2.4, 2.4, 0), on='market_square', style='well', program='from a spring in the island\'s rock heart')
item('market', 'chen_stall', "Chen's stall", 'feature', (-5, -3, 5, 3, 0), on='market_square', style='stall', who='Chen', program='including the Seed of Life')
item('market', 'bao_house', 'Bao house', 'compound', (-6, -21, 12, 20, 0), door='+z', style='shop', who='Hua Chen, Ting Ting', program='shopfront on the square side; steamers; main room with kang')
item('market', 'carrier_home', "Carrier's home and loading shed", 'compound', (15.5, 24, 12, 18, 0), door='-z', style='home', who='Bo Xiang, Rong Rong', program='main room with kang; loading shed for the levy and Ohio goods')

# D, Fields: strips, household plots by the B bridge, threshing floor, shed, compost and night-soil pits downwind on the east rim
item('fields', 'threshing', 'Threshing floor', 'court', (-8, -19, 15, 15, 0), style='threshing', program='harvest and festivals; Mei Lian\'s lanterns hung for them', public=True)
for i in range(8):
    item('fields', 'plot%d' % (i + 1), 'Household plot', 'field', (5.5 + (i % 4) * 5.4, -30 + (i // 4) * 9, 5, 8, 0), style='plot', program='one per household, each kept differently')
# the strips leave a lane down the west side, from the B bridge to the farm bridge
for j, (z, x0, x1) in enumerate([(-2, -15, 31), (9, -20, 31), (20, -19, 25), (31, -18, 20)]):
    item('fields', 'strip%d' % (j + 1), 'Field strip', 'field', ((x0 + x1) / 2, z, x1 - x0, 10.8, 0), style='strip', program=['millet', 'wheat', 'soybeans', 'millet'][j])
item('fields', 'field_shed', 'Field shed', 'building', (-12.5, -24.5, 5, 4, 0), door='+z', style='shed', roof='hard_gable', on='threshing', program='tools; seed; at the threshing floor\'s corner, its door onto the floor')
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
    ('gate_pavilion', 'Gate pavilion', 'building', (0, 47.5, 16, 7, 0), dict(style='palace', roof='xieshan', height=1.2, through=True, door='+z', program='the axis bridge-head: chains anchored in its base')),
    ('front_court', 'Front court', 'court', (0, 32, 40, 22, 0), dict(style='palace', program='paved, an axis of white stone; the village square after the quest', public=True)),
    ('dining_hall', 'Dining Hall', 'building', (28, 32, 9, 16, 0), dict(style='palace', roof='xieshan', door='-x', program='communal dining after the quest')),
    ('throne_terrace', 'Throne terrace', 'platform', (0, 3, 46, 34, 0), dict(style='marble', program='three tiers of 1.4 m with balustrades; a central ramp in three flights', height=4.2)),
    ('throne_hall', 'Throne Hall', 'building', (0, 1, 28, 16, 0), dict(style='palace', roof='wudian2', on='throne_terrace', door='+z', program='the throne; the village hall after the quest', height=4.2)),
    ('inner_court', 'Inner court', 'platform', (0, -24, 36, 14, 0), dict(style='marble', program='1.4 m above the throne terrace', height=5.6)),
    ('apartments', 'Inner apartments', 'building', (-25, -24, 14, 20, 0), dict(style='palace', roof='xieshan', door='+x', program='records, meeting and reading rooms after the quest', height=5.6)),
    ('kitchen', 'Royal Kitchen', 'building', (32, -22, 18, 12, 0), dict(style='palace_service', roof='xuanshan', door='-x', door_width=2.0, program='the Chef\'s fight floor; Lao Ye\'s community kitchen after')),
    ('chef_quarters', "Chef's quarters", 'building', (32, -34, 8, 6, 0), dict(style='palace_service', roof='xuanshan', door='+x', program='Liang Zhen\'s room after the quest')),
    ('service_yard', 'Service yard', 'court', (47, -6, 16, 20, 0), dict(style='yard', program='packed earth; well; latrine closet; cart turn; the B bridge lands here')),
    ('levy_store', 'Levy store', 'building', (49, -8, 6, 10, 0), dict(style='palace_service', roof='xuanshan', on='service_yard', door='-x', program='the levy; the village store after')),
    ('high_pavilion', 'High pavilion', 'building', (0, -44, 10, 10, 0), dict(style='palace', roof='cuanjian2', door='+z', storeys=2, program='the Emperor\'s private view north; a public lookout after', height=9.8)),
    ('moon_court', 'Moon-gate court', 'court', (-18, -46, 14, 12, 0), dict(style='shihu', garden=True, program='a pomegranate; entered by moon gates', openings=[('s', 0.0, 'moon'), ('e', 0.0, 'moon'), ('w', 0.0, 'oct'), ('n', 0.0, 'round')])),
    ('pond_court', 'Pond court', 'court', (14, -45, 16, 13, 0), dict(style='shihu', garden=True, program='lotus pond, zigzag bridge, rockery and waterfall, hexagonal pavilion', openings=[('s', -3.0, 'moon'), ('e', 0.0, 'oct'), ('n', 2.0, 'round'), ('n', -4.0, 'round')])),
    ('rock_garden', 'Rock garden', 'court', (-33, -44, 11, 11, 0), dict(style='shihu', garden=True, program='weathered stones; scholar\'s rocks on plinths; the west garden gate', openings=[('s', 0.0, 'oct'), ('e', 2.0, 'moon'), ('w', 0.0, 'moon')])),
    ('bamboo_court', 'Bamboo screen court', 'court', (-38, -12, 10, 14, 0), dict(style='shihu', garden=True, program='a bamboo screen and a bench', openings=[('n', 0.0, 'moon'), ('s', 2.0, 'square')])),
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
# 4. openings and paths.
# Every way into or out of every item is data here: gates, doors, a through building's two ends,
# moon gates and the other garden openings, windows. The drawing builds its walls from this list,
# so a wall and its opening cannot disagree. Each passage must open onto ground a person can stand
# on (or onto the raised level its building stands on), not into a wall, a field, another building
# or the drop. Then one path network per island joins its bridge landings, every passage and every
# ramp foot: a spine between the landings first, then a branch from each door to the nearest point
# of the network, found on a 0.5 m grid round everything solid and smoothed into curves.
import heapq
import numpy as np
import shapely
SIDES = {'s': ((0, 1), lambda W, D, a: (a, D / 2)), 'e': ((1, 0), lambda W, D, a: (W / 2, -a)),
         'n': ((0, -1), lambda W, D, a: (-a, -D / 2)), 'w': ((-1, 0), lambda W, D, a: (-W / 2, a))}
DOOR_YAW = {'+z': 0.0, '+x': math.pi / 2, '-z': math.pi, '-x': -math.pi / 2}
PASSAGE = ('gate', 'door', 'moon', 'oct', 'square', 'gap')
OPEN_W = {'gate': 1.7, 'door': 1.4, 'moon': 2.2, 'oct': 2.0, 'square': 2.0, 'gap': 2.4, 'round': 1.0, 'lattice': 0}
def local_frame(it):
    yaw = DOOR_YAW[it['door']]; side = it['door'] in ('+x', '-x')
    W, D = (it['rect'][3], it['rect'][2]) if side else (it['rect'][2], it['rect'][3])
    cx, cz = CEN[it['island']][0] + it['rect'][0], CEN[it['island']][1] + it['rect'][1]
    def to_world(x, z): return (cx + x * math.cos(yaw) + z * math.sin(yaw), cz - x * math.sin(yaw) + z * math.cos(yaw))
    def dir_world(x, z): return (x * math.cos(yaw) + z * math.sin(yaw), -x * math.sin(yaw) + z * math.cos(yaw))
    return W, D, to_world, dir_world
def default_openings(it):
    if 'openings' in it: return it['openings']
    if it['kind'] == 'compound':
        ops = [('s', 0.0, 'gate')]
        if it.get('moon_gate'): ops.append(('e', 9.0, 'moon'))
        return ops
    if it['kind'] == 'building':
        return [('s', 0.0, 'door')] + ([('n', 0.0, 'door')] if it.get('through') else [])
    return []
OPENINGS = []
for it in I:
    ops = default_openings(it); it['openings'] = ops
    if not ops: continue
    W, D, tw, dw = local_frame(it)
    for side, at, kind in ops:
        (nx, nz), f = SIDES[side]; ex, ez = f(W, D, at)
        edge = tw(ex, ez); n = dw(nx, nz)
        opening_width = 4.0 if it['key'] in ('gatehouse','gate_pavilion') and kind == 'door' else (it.get('door_width', OPEN_W[kind]) if kind == 'door' else OPEN_W[kind])
        OPENINGS.append(dict(island=it['island'], item=it['key'], side=side, at=at, kind=kind, width=opening_width,
                             edge=[round(edge[0], 2), round(edge[1], 2)], normal=[round(n[0], 3), round(n[1], 3)],
                             level=it.get('height', 0.0) if it['kind'] == 'building' else 0.0,
                             passage=kind in PASSAGE))

# the palace's raised levels and the ramps between them (chinese_village_palace.md 3)
P0 = CEN['palace']
def pl(x, z): return (P0[0] + x, P0[1] + z)
def pbox(x0, z0, x1, z1): return box(P0[0] + x0, P0[1] + z0, P0[0] + x1, P0[1] + z1)
LEVELS = {   # raised spaces: polygon (world), height
    'gate base': (pbox(-8,42,8,53),1.2),
    'terrace': (pbox(-18,-14,18,13.12),4.2),
    'inner court': (pbox(-18, -31, 18, -17), 5.6),
    'pavilion plinth': (pbox(-7.5, -38, 7.4, -31), 5.6),
    'mound': (pbox(-6, -50, 6, -38), 9.8),
}
RAMPS = [    # name, from (space or 'ground'), to, foot (world), head (world), rise, width; drawn by the model where marked
    dict(name='gate front ramp', a='ground', b='gate base', foot=pl(0,55.4), head=pl(0,53), width=5.0, drawn='gate'),
    dict(name='gate back ramp', a='ground', b='gate base', foot=pl(0,39.6), head=pl(0,42), width=5.0, drawn='gate'),
    dict(name='the terrace ramp, three flights', a='ground', b='terrace', foot=pl(0, 22.24), head=pl(0, 13.12), width=3.2, drawn='terrace', segments=[
        dict(kind='flight', a=pl(0,22.24), b=pl(0,20), from_y=0.0, to_y=1.4),
        dict(kind='landing', a=pl(0,20), b=pl(0,18.8), height=1.4),
        dict(kind='flight', a=pl(0,18.8), b=pl(0,16.56), from_y=1.4, to_y=2.8),
        dict(kind='landing', a=pl(0,16.56), b=pl(0,15.36), height=2.8),
        dict(kind='flight', a=pl(0,15.36), b=pl(0,13.12), from_y=2.8, to_y=4.2),
    ]),
    dict(name='inner court flights', a='terrace', b='inner court', foot=pl(-16, -14), head=pl(-16, -17), width=3.2, drawn='terrace'),
    dict(name='inner court flights (east)', a='terrace', b='inner court', foot=pl(16, -14), head=pl(16, -17), width=3.2, drawn='terrace'),
    dict(name='to the pavilion plinth', a='inner court', b='pavilion plinth', foot=pl(0, -31), head=pl(0, -31), width=6, drawn='level'),
    dict(name='the high pavilion flights', a='pavilion plinth', b='mound', foot=pl(-6, -36.4), head=pl(5.7, -38), width=3.2, drawn='pavilion'),
    # The route hugs the east edge of the inner court. Its paired 4.5 m runs
    # descend 2.8 m each (31.9 degrees), with 1.2 m end and mid landings.
    # The ground landing opens onto the 1.8 m approach beside the west kitchen door; all dimensions
    # are plan geometry, also used by the runtime and the 3D drawing.
    dict(name='inner court to royal kitchen', a='inner court', b='ground', foot=pl(18, -29.2), head=pl(19.6, -15.8), width=3.2, drawn='kitchen', rise=5.6,
         segments=[
             dict(kind='landing', a=pl(18.0, -29.2), b=pl(21.2, -29.2), height=5.6),
             dict(kind='flight', a=pl(19.6, -27.6), b=pl(19.6, -23.1), from_y=5.6, to_y=2.8),
             dict(kind='landing', a=pl(19.6, -23.1), b=pl(19.6, -21.9), height=2.8),
             dict(kind='flight', a=pl(19.6, -21.9), b=pl(19.6, -17.4), from_y=2.8, to_y=0.0),
             dict(kind='landing', a=pl(19.6, -17.4), b=pl(19.6, -15.8), height=0.0),
         ]),
    # down from the plinth to the garden on its east side: 5.6 m in two 32 deg flights with a landing
    dict(name='east garden ramp', a='ground', b='pavilion plinth', foot=pl(17.9, -33.5), head=pl(7.4, -33.5), width=2.4, drawn='garden', rise=5.6, landing_length=1.2),
]
RAMP_POLYS = []
for ramp in RAMPS:
    if 'ground' not in (ramp['a'], ramp['b']): continue
    sections = ramp.get('segments', [dict(a=ramp['foot'], b=ramp['head'])])
    RAMP_POLYS.append(unary_union([LineString([s['a'],s['b']]).buffer(ramp['width']/2,cap_style=2) for s in sections]))
# the covered corridors along the garden's south side are paths themselves (walked, roofed)
CORRIDORS = [dict(island='palace', pts=[pl(-26, -36.6), pl(-12, -36.6)], width=2.4), dict(island='palace', pts=[pl(10, -36.6), pl(22, -36.6)], width=2.4)]
# the level graph: every raised space reached from the ground
reach = {'ground'}; changed = True
while changed:
    changed = False
    for r in RAMPS:
        for x, y in ((r['a'], r['b']), (r['b'], r['a'])):
            if x in reach and y not in reach: reach.add(y); changed = True
for sp in LEVELS:
    if sp not in reach: problems.append(('palace', sp, 'is not reached by any ramp from the ground'))
# what is solid at ground level, per island: the obstacle a path keeps clear of
WALLED_COURTS = ('shihu',)
def solid_poly(it):
    if it['kind'] in ('compound', 'building', 'field', 'grove', 'platform'): return it['poly']
    if it['kind'] == 'court' and it['style'] in WALLED_COURTS: return it['poly']
    if it['kind'] == 'feature': return it['poly']
    return None
SOLID_BY = {}
for it in I:
    g = solid_poly(it)
    if g is None: continue
    if it.get('through'):   # a passage through the building, along its door axis
        W, D, tw, dw = local_frame(it)
        lane = Polygon([tw(-2.0, -D / 2 - 0.2), tw(2.0, -D / 2 - 0.2), tw(2.0, D / 2 + 0.2), tw(-2.0, D / 2 + 0.2)])
        g = g.difference(lane)
    SOLID_BY.setdefault(it['island'], []).append((it['key'], g))
for (sp, (poly, h)) in LEVELS.items():
    SOLID_BY['palace'].append(('level:' + sp, poly))
for g in RAMP_POLYS: SOLID_BY['palace'].append(('ramp', g))
OWNER = {}   # which raised space or item a door's outside point may stand in

# each passage opens onto somewhere you can stand
WALK_EDGE = 1.6              # paths keep inside the parapet (1 m in, 0.4 thick) with a margin
for o in OPENINGS:
    if not o['passage']: continue
    k = o['island']; e, n = o['edge'], o['normal']
    out = Point(e[0] + n[0] * 1.0, e[1] + n[1] * 1.0); o['out'] = [round(out.x, 2), round(out.y, 2)]
    if o['level'] > 0:
        sp = [s for s, (poly, h) in LEVELS.items() if abs(h - o['level']) < 0.05 and poly.buffer(0.3).contains(out)]
        if not sp: problems.append((k, o['item'], '%s %s opens onto nothing at its level (%.1f m)' % (o['kind'], o['side'], o['level'])))
        else: o['onto'] = sp[0]
        continue
    if not ISL[k].buffer(-WALK_EDGE).contains(out): problems.append((k, o['item'], '%s %s opens onto the edge' % (o['kind'], o['side']))); continue
    hit = [key for key, g in SOLID_BY.get(k, []) if key != o['item'] and g.contains(out)]
    if hit:
        # into another walled court is fine only through that court's own opening, face to face
        ok = all(any(q['item'] == h and q['passage'] and math.dist(q['edge'], o['edge']) < 1.5 for q in OPENINGS) for h in hit)
        if not ok: problems.append((k, o['item'], '%s %s opens into %s' % (o['kind'], o['side'], ', '.join(hit))))
        else: o['onto'] = hit[0]
    else: o['onto'] = 'ground'

# openings that face each other across a gap are joined directly: the courts in sequence
LINKS = []
ps = [o for o in OPENINGS if o['passage'] and o.get('onto') == 'ground']
for i in range(len(ps)):
    for j in range(i + 1, len(ps)):
        a, b = ps[i], ps[j]
        if a['island'] != b['island'] or a['normal'][0] * b['normal'][0] + a['normal'][1] * b['normal'][1] > -0.95: continue
        d = (b['edge'][0] - a['edge'][0], b['edge'][1] - a['edge'][1])
        along = d[0] * a['normal'][0] + d[1] * a['normal'][1]; lateral = abs(d[0] * a['normal'][1] - d[1] * a['normal'][0])
        if 0 < along < 5.0 and lateral < 0.8:
            a['linked'] = b['item']; b['linked'] = a['item']
            LINKS.append(dict(island=a['island'], to='%s to %s' % (a['item'], b['item']), kind='link', width=min(a['width'], b['width']) + 0.4, pts=[a['edge'], b['edge']]))
# open ground people go to: every open court, and an access side on every field, grove and the rock
def access_points(it):
    W, D, tw, dw = local_frame(it)
    if it['kind'] == 'court' and it['style'] not in WALLED_COURTS and not it.get('on') and it['island'] != 'palace':
        return [(tw(-4 if it['key']=='market_square' else 0, 0), dw(0, 1))]
    if it['kind'] in ('field', 'grove') or (it['kind'] == 'feature' and it['style'] == 'rock'):
        if it['style'] == 'plot' and it['key'] != 'plot1': return []      # one access for the plot block
        cx, cz = CEN[it['island']]
        cands = []
        for side, ((nx, nz), f) in SIDES.items():
            e = tw(*f(W, D, 0)); n = dw(nx, nz); cands.append((math.dist(e, (cx, cz)), e, n))
        return [(e, n) for _, e, n in sorted(cands)]
    return []

# ---- the path network
GRID = 0.5
SPINE_W, BRANCH_W, BUND_W = 3.0, 2.4, 1.6   # a bund: the flat earth footpath along a field's end
def chaikin(pts, n=3):
    for _ in range(n):
        out = [pts[0]]
        for a, b in zip(pts, pts[1:]):
            out += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]), (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        out.append(pts[-1]); pts = out
    return pts
WORKYARDS = {'roof_yard': dict(tile_center=[-2.2,-4.0],tile_half=[1.5,1.1],frame_center=[0,3.3],frame_half=[1.6,1.0],rack_center=[3.2,1.7],rack_half=[1.4,.6])}
PATHS = []
for k in ISL:
    grid=0.25 if k=="palace" else GRID
    solids = unary_union([g for key, g in SOLID_BY.get(k, [])]) if SOLID_BY.get(k) else Polygon()
    columns=[]
    for gallery in CORRIDORS:
        if gallery['island']!=k: continue
        a,b=gallery['pts']; length=math.dist(a,b); dx=(b[0]-a[0])/length; dz=(b[1]-a[1])/length
        bays=max(1,math.ceil(length/2.4))
        for i in range(bays+1):
            for side in (-1,1):
                point=(a[0]+(b[0]-a[0])*i/bays-dz*side*gallery['width']*.43,
                       a[1]+(b[1]-a[1])*i/bays+dx*side*gallery['width']*.43)
                if any(o['passage'] and math.dist(o['edge'],point)<1.2 for o in OPENINGS): continue
                columns.append(Point(point).buffer(.20))
    if columns: solids=unary_union([solids]+columns)
    fitted=[]
    for bridge in G['data']['bridges']:
        if bridge['kind']!='chain': continue
        aa,bb=bridge['ends']; dx=bb[0]-aa[0]; dz=bb[1]-aa[1]; length=math.hypot(dx,dz); dx/=length;dz/=length
        for endpoint,island in enumerate((bridge['a'],bridge['b'])):
            if island!=k: continue
            direction=(dx,dz) if endpoint==0 else (-dx,-dz)
            point=(aa if endpoint==0 else bb); origin=(point[0]-direction[0]*2.5,point[1]-direction[1]*2.5)
            xaxis=(direction[1],-direction[0])
            for side in (-1,1):
                cx=origin[0]+xaxis[0]*side*(bridge['width']/2+1.1);cz=origin[1]+xaxis[1]*side*(bridge['width']/2+1.1)
                fitted.append(Polygon([(cx+xaxis[0]*x+direction[0]*z,cz+xaxis[1]*x+direction[1]*z) for x,z in [(-.8,-2.5),(.8,-2.5),(.8,2.5),(-.8,2.5)]]))
    for yard_key,layout in WORKYARDS.items():
        item=next(it for it in I if it['key']==yard_key)
        if item['island']!=k: continue
        ox=CEN[k][0]+item['rect'][0];oz=CEN[k][1]+item['rect'][1]
        for part in ('tile','frame','rack'):
            x,z=layout[part+'_center'];hx,hz=layout[part+'_half']
            fitted.append(box(ox+x-hx,oz+z-hz,ox+x+hx,oz+z+hz))
    if fitted: solids=unary_union([solids]+fitted)
    area = ISL[k].buffer(-WALK_EDGE)
    x0, z0, x1, z1 = area.bounds
    xs = np.arange(x0, x1 + grid, grid); zs = np.arange(z0, z1 + grid, grid)
    XX, ZZ = np.meshgrid(xs, zs)
    free = {}
    for w in (SPINE_W, BRANCH_W, BUND_W, 1.4, 2.0):
        ok = shapely.contains_xy(area.buffer(-w / 2 + 0.3), XX, ZZ) & ~shapely.contains_xy(solids.buffer(w / 2 + (0.10 if w==1.4 else 0.25)), XX, ZZ)
        free[w] = ok
    # a cost that keeps paths off walls: cheaper in the middle of open ground
    dist = shapely.distance(solids.boundary.union(area.boundary), shapely.points(XX.ravel(), ZZ.ravel())).reshape(XX.shape) if not solids.is_empty else np.full(XX.shape, 9.0)
    extra = np.clip(3.0 - dist, 0, None) * 0.6
    nz_, nx_ = XX.shape
    def cell(p): return (int(round((p[1] - z0) / grid)), int(round((p[0] - x0) / grid)))
    def pt(c): return (x0 + c[1] * grid, z0 + c[0] * grid)
    network = {}          # cell -> path index
    def search(start, w, targets):
        """Dijkstra from start to any target cell (or the given goal set); walking on the network costs less."""
        fr = free[w]; best = {start: 0.0}; prev = {}; h = [(0.0, start)]
        while h:
            c0, c = heapq.heappop(h)
            if c in targets and c != start:
                out = [c]
                while out[-1] in prev: out.append(prev[out[-1]])
                return out[::-1]
            if c0 > best.get(c, 1e9): continue
            for dz, dx, L in ((1, 0, 1), (-1, 0, 1), (0, 1, 1), (0, -1, 1), (1, 1, 1.414), (1, -1, 1.414), (-1, 1, 1.414), (-1, -1, 1.414)):
                q = (c[0] + dz, c[1] + dx)
                if not (0 <= q[0] < nz_ and 0 <= q[1] < nx_) or not (fr[q] or q in targets): continue
                cost = c0 + L * grid * (0.35 if q in network else 1.0 + extra[q])
                if cost < best.get(q, 1e9): best[q] = cost; prev[q] = c; heapq.heappush(h, (cost, q))
        return None
    def stub(p, n, w):
        """From an opening's outside point, out along its normal to the first cell a path of width w fits."""
        for s in np.arange(0, 9.01, 0.25):
            q = (p[0] + n[0] * s, p[1] + n[1] * s); c = cell(q)
            if 0 <= c[0] < nz_ and 0 <= c[1] < nx_ and free[w][c]: return q, c
        return None, None
    nodes = []   # (name, point, normal, kind[, other access points])
    for l in LANDINGS.get(k, []):
        cx, cz = CEN[k]; ix, iz = l['inner']; d = math.hypot(cx - ix, cz - iz)
        if k=='palace' and l['to']=='gate':
            # The bridge joins the raised gate passage via its front/back ramps.
            # Ground-level routes join the EXIT stair, never cut through the plinth.
            ramp=next(r for r in RAMPS if r['name']=='gate back ramp')
            ix,iz=ramp['foot']; iz-=1.0
            nodes.append(('landing:'+l['to'],(ix,iz),(0,-1),'landing'))
        else:
            nodes.append(('landing:' + l['to'], (ix, iz), ((cx - ix) / d, (cz - iz) / d), 'landing'))
    for o in OPENINGS:
        if o['island'] == k and o['passage'] and o.get('onto') == 'ground' and not o.get('linked'): nodes.append((o['item'] + ':' + o['side'], tuple(o['out']), tuple(o['normal']), 'opening'))
    for it in by.get(k, []):
        aps = access_points(it)
        if aps: nodes.append((it['key'], aps[0][0], aps[0][1], 'access', aps))
    for r in RAMPS:
        if k == 'palace' and 'ground' in (r['a'], r['b']):
            ground = r['foot'] if r['a'] == 'ground' else r['head']
            raised = r['head'] if r['a'] == 'ground' else r['foot']
            d = (ground[0] - raised[0], ground[1] - raised[1]); L = math.hypot(*d) or 1
            nodes.append(('ramp:' + r['name'], ground, (d[0] / L, d[1] / L), 'ramp'))
    for c in CORRIDORS:
        if c['island'] == k:
            for p, q in ((c['pts'][0], c['pts'][1]), (c['pts'][1], c['pts'][0])):
                d = (p[0] - q[0], p[1] - q[1]); L = math.hypot(*d); nodes.append(('corridor end', p, (d[0] / L, d[1] / L), 'corridor'))
    # the spine: landings first, then everything else by distance from the network
    order = [n_ for n_ in nodes if n_[3] == 'landing'] + sorted([n_ for n_ in nodes if n_[3] != 'landing'], key=lambda n_: math.dist(n_[1], nodes[0][1]))
    for i, node in enumerate(order):
        name, p, n, kind = node[:4]
        if k=='palace' and name=='kitchen:s': n=(0,1)
        w = SPINE_W if kind == 'landing' else BUND_W if kind == 'access' and name.startswith(('strip', 'terrace', 'plot', 'pits')) else 1.4 if k == 'palace' else BRANCH_W
        sp_, sc = stub(p, n, w)
        if sp_ is None and kind=='landing':
            for pinch in (2.4,2.0,1.6):
                sp_,sc=stub(p,n,pinch)
                if sp_ is not None: w=pinch;break
        if sp_ is None and kind == 'access':
            for p2, n2 in node[4][1:]:
                sp_, sc = stub(p2, n2, w)
                if sp_ is not None: p, n = p2, n2; break
        if sp_ is None:
            problems.append((k, name, 'no room for a %.1f m path outside it' % w))
            continue
        if not network:
            network[sc] = -1; continue
        cs = search(sc, w, set(network))
        if cs is None and kind=='landing':
            for pinch in (2.4,2.0,1.6):
                sp2,sc2=stub(p,n,pinch)
                if sp2 is None: continue
                cs2=search(sc2,pinch,set(network))
                if cs2 is not None: w=pinch;sp_=sp2;sc=sc2;cs=cs2;break
        if cs is None: problems.append((k, name, 'no %.1f m path joins it to the rest' % w)); continue
        raw = [p] + [pt(c) for c in cs]
        # string-pull: keep only the turns the ground forces, then round them off
        keep = [raw[0]]; j = 0
        while j < len(raw) - 1:
            m = len(raw) - 1
            while m > j + 1 and not (LineString([raw[j], raw[m]]).buffer(w / 2 + 0.2).difference(area.buffer(-0.05)).is_empty and not LineString([raw[j], raw[m]]).buffer(w / 2 + 0.2).intersects(solids)):
                m -= 1
            keep.append(raw[m]); j = m
        # a long straight run wanders a little, as a walked path does, wherever the ground allows
        def meander(pts, amp):
            out = [pts[0]]
            for j_, (a_, b_) in enumerate(zip(pts, pts[1:])):
                L_ = math.dist(a_, b_)
                if L_ > 7.0:
                    m_ = int(L_ // 7.0); ux, uz = (b_[0] - a_[0]) / L_, (b_[1] - a_[1]) / L_
                    for t_ in range(1, m_ + 1):
                        f_ = t_ / (m_ + 1); off = amp * min(L_ * 0.05, 1.4) * (1 if (t_ + j_ + len(name)) % 2 else -1)
                        out.append((a_[0] + (b_[0] - a_[0]) * f_ - uz * off, a_[1] + (b_[1] - a_[1]) * f_ + ux * off))
                out.append(b_)
            return out
        best_ = keep
        tried = [(meander(keep, 1.0), 3), (meander(keep, 0.5), 3), (keep, 3), (keep, 2), (keep, 1)]
        for base_, it_ in tried:
            sm = chaikin(base_, it_)
            band = LineString(sm).buffer(w / 2)
            if not band.intersects(solids.buffer(-0.05)) and area.buffer(0.3).contains(band): best_ = sm; break
        PATHS.append(dict(island=k, to=name, kind='spine' if kind == 'landing' else 'branch', width=w, pts=[[round(a, 2), round(b, 2)] for a, b in best_]))
        for c in cs: network.setdefault(c, len(PATHS) - 1)
PATHS += LINKS
for c in CORRIDORS: PATHS.append(dict(island=c['island'], to='covered corridor', kind='corridor', width=c['width'], pts=[[round(a, 2), round(b, 2)] for a, b in c['pts']]))

# 4b. what each way is made of (chinese_village.md 4.0b). The palace keeps the bridges and their heads, so the palace
# island, the gate island and every bridgehead apron are laid in dressed stone flags, with the imperial way of long
# slabs on the palace axis. The village's main way from bridge to bridge across each island is a slab road (shiban lu):
# rough granite slabs laid crosswise, worn hollow, on an earth bed with a gutter. Lanes to the inn, the market and the bao
# house are brick, which trade can pay for; lanes to homes, yards, the shed, the pen and the grove are packed earth,
# crowned to shed rain; fields are reached along flush worn-earth walks. Inside the palace garden the walks are pebble
# mosaic (huajie pudi). Inside every home's yard a brick cross walk (shizi yonglu) runs from the gate to the main room's
# door, with a cross bar to the side shed; the rest of the yard is packed earth.
BRICK_TO = ('inn', 'inn_garden', 'market_square', 'bao_house', 'chen_stall', 'well')
GARDEN_COURTS = ('moon_court', 'pond_court', 'rock_garden', 'bamboo_court')
def surface_of(pth):
    k, to, kind = pth['island'], pth['to'], pth['kind']
    item = to.split(':')[0]
    if kind == 'corridor': return 'flag'
    if kind == 'link': return 'pebble' if k == 'palace' else 'brick'
    if k in ('palace', 'gate'): return 'pebble' if item in GARDEN_COURTS or to == 'corridor end' else 'flag'
    if kind == 'spine': return 'slab'
    if pth['width'] < 2: return 'earth'
    if item in BRICK_TO: return 'brick'
    return 'earth'
for pth in PATHS: pth['surface'] = surface_of(pth)
COURT_PAVING = {'palace_apron': 'flag', 'front_court': 'imperial', 'service_yard': 'earth', 'gate_forecourt': 'flag',
                'market_square': 'flag', 'roof_yard': 'earth', 'play_yard': 'earth', 'threshing': 'threshing', 'inn_garden': 'garden'}
for it in I:
    if it['kind'] == 'court': it['paving'] = COURT_PAVING.get(it['key'], 'garden' if it['style'] == 'shihu' else 'earth')
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
    gaps_list = [ap.buffer(1.2) for (kk, t), ap in APRONS.items() if kk == k]
    # The cut is the bridge's complete swept width as well as the inland
    # apron. A spur can project past the face and otherwise leave a guard
    # across the bridge itself, which the earlier apron-only cut missed.
    for bridge in G['data']['bridges']:
        if k not in (bridge['a'], bridge['b']): continue
        aa,bb = bridge['ends']; axis = np.array(bb)-np.array(aa); axis=axis/np.linalg.norm(axis)
        gaps_list.append(LineString([np.array(aa)-axis*3,np.array(bb)+axis*3]).buffer(bridge['width']/2+.5))
    gaps = unary_union(gaps_list)
    rest = ring.difference(gaps) if not gaps.is_empty else ring
    for ln in (rest.geoms if hasattr(rest, 'geoms') else [rest]):
        if ln.length > 1.0: PARAPETS.append(dict(island=k, kind=PARAPET_KIND.get(k, 'brick'), pts=[[round(x, 2), round(z, 2)] for x, z in ln.simplify(0.4).coords]))

for p in problems: print('PROBLEM', p)
def out(p):
    if p.geom_type != 'Polygon': p = max(p.geoms, key=lambda q: q.area)
    return [[round(x, 2), round(z, 2)] for x, z in p.exterior.coords]
# Survey the bank overlap on each bridge's actual axis. Chain bearings stay
# level over those tails; sag begins only after the full body clears the bank.
for bridge in G['data']['bridges']:
    if bridge['kind']!='chain': continue
    line=LineString(bridge['ends']); length=line.length
    for endpoint,field in [(bridge['a'],'bearing_start'),(bridge['b'],'bearing_end')]:
        island=next(q for q in G['data']['islands'] if q['key']==endpoint)
        cut=line.intersection(Polygon(island['outline']).buffer(.55))
        parts=list(cut.geoms) if hasattr(cut,'geoms') else [cut]
        distances=[line.project(Point(p)) for part in parts if hasattr(part,'coords') for p in part.coords]
        reach=max(distances,default=0) if field=='bearing_start' else length-min(distances,default=length)
        bridge[field]=round(min(length*.20,reach)/length,5)
PALACE_ARCHITECTURE = {
    'throne_hall': dict(bays=7, column_height=6.6, roof='wudian2'),
    'gate_pavilion': dict(bays=3, column_height=4.6, roof='xieshan', through=True),
    'dining_hall': dict(bays=5, column_height=4.4, roof='xieshan'),
    'apartments': dict(bays=5, column_height=4.0, roof='xieshan'),
    'high_pavilion': dict(bays=3, column_height=3.2, roof='cuanjian2', storeys=2),
}
data = dict(G['data'], palace_architecture=PALACE_ARCHITECTURE, items=[dict({k: v for k, v in it.items() if k != 'poly'}, outline=out(it['poly']), door_at=door_point(it), centre=[round(CEN[it['island']][0] + it['rect'][0], 2), round(CEN[it['island']][1] + it['rect'][1], 2)]) for it in I],
            paths=PATHS, openings=OPENINGS, ramps=[dict(r, foot=[round(v, 2) for v in r['foot']], head=[round(v, 2) for v in r['head']]) for r in RAMPS], parapets=PARAPETS, aprons=[dict(island=k, to=t, outline=out(p)) for (k, t), p in APRONS.items()], tops={k: out(v) for k, v in TOP.items()},
            plan_problems=[list(map(str, p)) for p in problems])
# Exact freestanding lamp arrangements expressed by the approved model.
# Wall/eave lanterns remain a separate type, never substituted by route posts.
import math
lamps = []
by_key = {it['key']: it for it in data['items']}
def lamp_local(key, x, z, y=0, kind='post'):
    it = by_key[key]; angle = {'+z': 0, '+x': math.pi/2, '-z': math.pi, '-x': -math.pi/2}[it['door']]
    c, sn = math.cos(angle), math.sin(angle)
    lamps.append(dict(owner=key, kind=kind, at=[round(it['centre'][0]+x*c+z*sn,3),round(it['centre'][1]-x*sn+z*c,3)],base_y=y))
for sx in (-1,1):
    for sz in (-1,1): lamp_local('gate_forecourt',sx*5.4,sz*5.4)
    lamp_local('market_square',sx*(by_key['market_square']['rect'][2]/2-.5),by_key['market_square']['rect'][3]/2-.5)
for x,z in [(-14,6),(14,6),(-14,-6),(14,-6)]: lamp_local('front_court',x,z)
for i in range(4):
    angle=i/4*6.28+.6; it=by_key['threshing']
    lamp_local('threshing',math.cos(angle)*(it['rect'][2]/2-.4),math.sin(angle)*(it['rect'][3]/2-.4))
for it in data['items']:
    if it['kind']=='compound' and it['key']!='inn':
        side=it['door'] in ('+x','-x'); w=it['rect'][3] if side else it['rect'][2]; d=it['rect'][2] if side else it['rect'][3]
        for sx in (-1,1): lamp_local(it['key'],sx*(w-.2)/3,-d/2+5.45,3.15,'eave')
for sx in (-1,1): lamp_local('gatehouse',sx*2.2,5.5,3.0,'eave')
# Resolve conflicts already present between the illustrative lamps and the
# surveyed route ribbons. Keep the reference point, move only to the nearest
# clear bay in the same court, and draw that same resolved set in the model.
for lamp in lamps:
    if lamp['kind']!='post': continue
    it=by_key[lamp['owner']]; original=lamp['at'][:]
    ways=[LineString(q['pts']).buffer(q['width']/2+.45) for q in PATHS if q['island']==it['island']]
    def clear_lamp(at):
        return abs(at[0]-it['centre'][0])<=it['rect'][2]/2-.35 and abs(at[1]-it['centre'][1])<=it['rect'][3]/2-.35 and all(not way.contains(Point(at)) for way in ways)
    if not clear_lamp(original):
        choices=sorted(((dx*.25,dz*.25) for dx in range(-16,17) for dz in range(-16,17)),key=lambda q:q[0]*q[0]+q[1]*q[1])
        for dx,dz in choices:
            at=[round(original[0]+dx,3),round(original[1]+dz,3)]
            if clear_lamp(at):
                lamp['at']=at;lamp['reference_at']=original;break
        else: raise RuntimeError('No clear lamp bay in '+it['key'])
data['lanterns']=lamps
# Garden furniture shares one surveyed local layout between model and runtime.
data['workyards']=WORKYARDS
data['gardens'] = {
    'pond_court': dict(pavilion=[-3.4, 0, -3.7], pavilion_yaw=-math.pi/2, pine=[-4.1,0,3.6], pond_radii=[5.6,4.0],
        crossing=[[-5.7,.12,0],[-2.4,.12,.65],[1.5,.12,-.65],[6.3,.12,0]],
        approach=[[-3.4,.45,-2.2],[-3.4,.12,-.32]]),
    'inn_garden': dict(pavilion=[-3.9,0,-3.7], pavilion_yaw=0, pine=[3.7,0,3.8], pond_radii=[3.4,2.4],
        crossing=[[-1.7,.12,.6],[4.1,.12,.6]], approach=[]),
}
# A continuous pond crossing, with the pavilion approach joined at one datum.
# Polygonize the shared boundaries before triangulation so junction vertices
# belong to both adjacent surfaces instead of producing overlapping slabs.
from shapely import constrained_delaunay_triangles
from shapely.ops import polygonize, nearest_points
for key, garden in data['gardens'].items():
    route=garden['crossing']; deck_y=route[0][1]
    main=LineString([(q[0],q[2]) for q in route]).buffer(.725,quad_segs=6,cap_style=1,join_style=1)
    approach=garden['approach']
    branch=None
    if approach:
        x,y,z=approach[0]
        branch=box(x-.75,z,x+.75,approach[-1][2]+.7)
    top=main.union(branch) if branch is not None else main
    outer=top.buffer(.03,quad_segs=3,join_style=1)
    def height(x,z):
        point=Point(x,z)
        if not approach or main.buffer(.00001).covers(point): return deck_y
        start=approach[0]
        cross=LineString([(x,-20),(x,20)]).intersection(main)
        entry=cross.bounds[1] if not cross.is_empty else approach[-1][2]
        return deck_y+(start[1]-deck_y)*max(0,min(1,(entry-z)/(entry-start[2])))
    def bevel_height(x,z):
        q=Point(x,z); near=nearest_points(top,q)[0]
        return height(near.x,near.y)-min(.03,q.distance(top))
    vertices=[]
    def vertex(x,y,z): return [round(x,4),round(y,4),round(z,4)]
    faces=list(polygonize(unary_union([main.boundary,branch.boundary]))) if branch is not None else [main]
    for face in faces:
        if not top.covers(face.representative_point()): continue
        for tri in constrained_delaunay_triangles(face).geoms:
            vertices.extend(vertex(x,height(x,z),z) for x,z in list(tri.exterior.coords)[:3])
    for tri in constrained_delaunay_triangles(outer.difference(top)).geoms:
        vertices.extend(vertex(x,bevel_height(x,z),z) for x,z in list(tri.exterior.coords)[:3])
    outline=list(outer.exterior.coords)
    for (ax,az),(bx,bz) in zip(outline,outline[1:]):
        ay=bevel_height(ax,az);end_y=bevel_height(bx,bz)
        a=vertex(ax,ay,az);b=vertex(bx,end_y,bz);c=vertex(bx,end_y-.08,bz);d=vertex(ax,ay-.08,az)
        vertices.extend([a,b,c,a,c,d])
    for tri in constrained_delaunay_triangles(outer).geoms:
        vertices.extend(vertex(x,bevel_height(x,z)-.08,z) for x,z in list(tri.exterior.coords)[:3][::-1])
    # Godot's front faces use clockwise winding; GEOS emits the reverse.
    for i in range(0,len(vertices),3): vertices[i+1],vertices[i+2]=vertices[i+2],vertices[i+1]
    garden['walk_vertices']=vertices
# Constructed paving is one surveyed union per island, not overlapping ribbons.
# Constrained triangulation preserves holes and concave corners without UVs.
from shapely import constrained_delaunay_triangles
paving_network = []
for island_key in ISL:
    paving_strips = [LineString(q['pts']).buffer(q['width']/2, quad_segs=4, cap_style=1, join_style=1)
              for q in PATHS if q['island']==island_key and q['surface'] in ('flag','brick','pebble','garden','imperial')]
    paving_strips += [p for (k, _), p in APRONS.items() if k==island_key]
    if not paving_strips: continue
    surface = unary_union(paving_strips).intersection(ISL[island_key].buffer(-.12,4))
    masks = [it['poly'] for it in I if it['island']==island_key and it['kind'] in ('court','compound','platform','building')]
    for it in I:
        if it['key']=='high_pavilion' and island_key=='palace':
            masks.append(it['poly'].buffer(3.0,join_style=2))
    if masks: surface = surface.difference(unary_union(masks))
    surface = surface.simplify(.015,preserve_topology=True)
    triangles = constrained_delaunay_triangles(surface)
    points=[]
    for tri in triangles.geoms:
        if not surface.buffer(.001).covers(tri): raise RuntimeError('Paving triangle leaves its authored footprint')
        # GEOS rings face down after XY is mapped to Godot XZ.
        ring=list(tri.exterior.coords)[:3]
        points.extend([[round(x,4),round(z,4)] for x,z in (ring[0],ring[2],ring[1])])
    paving_network.append(dict(island=island_key,triangles=points,area=round(surface.area,3)))
data['paving_network']=paving_network
if '--json' in sys.argv: json.dump(data, open(sys.argv[sys.argv.index('--json') + 1], 'w'))
import sys as _s, os as _o; _s.path.insert(0, _o.path.dirname(_o.path.abspath(__file__))); from gd_plan import write_plan
if not problems:
    write_plan('ChinesePlan', 'chinese_plan.gd', [
        "The Chinese village's single plan (docs/architecture/chinese_village.md 4.0, 4.0a and 4.0b): the broken",
        "plateau's islands and keels, the Abyss's rim, the bridges and their abutments, every compound, building,",
        'court, field and feature, every wall and gate opening, the ramps, the path network with its surfaces, the',
        'parapets and the bridgehead aprons. Backlog C1: scripts/chinese_village.gd and its validator read only this.',
        '',
        'Village-local metres from VILLAGE_CENTER (as scripts/chinese_village.gd): x east, z south, y up.'],
        {k.upper(): v for k, v in data.items() if k != 'plan_problems'}, 'tools/chinese_village_plan.py')
    model_path = Path(__file__).resolve().parent.parent / 'docs/drawings/chinese_gorge_3d.html'
    model = model_path.read_text()
    model, replacements = re.subn(r'(?<=/\*DATA\*/).*?(?=/\*END\*/)', lambda _: json.dumps(data), model, count=1, flags=re.S)
    if replacements != 1: raise RuntimeError('Chinese model data markers are missing')
    model_path.write_text(model)
    print('wrote scripts/chinese_plan.gd and the Three.js reference data')
print('%d items on %d islands; %d openings; %d paths; strips %.0f m2, terraces %.0f m2; %d problems' % (len(I), len(by), len(OPENINGS), len(PATHS), strips, terr, len(problems)))
if problems: sys.exit(1)
