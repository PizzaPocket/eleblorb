"""Authoring tool for Kai Mālie's plan (docs/architecture/ocean_island_village_layout.md
and ocean_island_village_buildings.md). It holds the island's zones, the green,
the paths and every building with its walls, lānai, eaves and room program,
checks them, and writes scripts/kai_malie_plan.gd, the one plan the village
builder and tools/validate_kai_malie_plan.tscn read.

    python3 tools/kai_malie_layout.py [--json out.json]

Edit here, never in kai_malie_plan.gd. Local metres on the main island:
u points from the island's centre toward the arrival dock, v to its right;
(0, 0) is the island centre at world (-118, 72). Heights are metres above sea
level. Sizes are world scale (about 1.1 x real, docs/world_bible.md).
"""
import json, math, os, sys

CENTER = (-118.0, 72.0)
U = (0.854, -0.521)
V = (0.521, 0.854)
def world(u, v): return (round(CENTER[0] + u * U[0] + v * V[0], 2), round(CENTER[1] + u * U[1] + v * V[1], 2))

## Zones, as (u0, v0, u1, v1) in local metres (layout 3 and 4).
PLAIN = (36.0, -46.0, 66.0, 56.0)       # the coastal plain: +3.0 m at u 36 to +1.2 m at u 66
BEACH = (66.0, -60.0, 74.0, 62.0)       # sand to the waterline at about u 72
TERRACES = (14.0, -35.0, 38.0, 5.0)     # the loʻi kalo: six terraces, nothing built on them
STREAM_V = -50.0                        # where the stream crosses the plain (a 3 m band)
REEF_FLAT = (74.0, -60.0, 130.0, 45.0)
GREEN = (48.0, -9.0, 60.0, 9.0)
PIER = (62.0, -1.8, 134.0, 1.8)         # 3.6 m wide, from the pier head to the dock
PIER_HEAD = (60.0, -5.0, 68.0, 5.0)
FISHPOND = (76.0, -58.0, 108.0, -20.0)  # the wall's arc encloses about 30 x 36 m
MEETING_ROCKS = (126.0, -40.0)
WATERFALL = (8.0, -18.0)
DOCK_U = 138.0
KAHALA_GARDEN = (31.0, 9.0, 37.0, 19.0)
PIRATES_BEACH = (66.0, 46.0, 74.0, 58.0)
def plain_height(u): return round(3.0 + (1.2 - 3.0) * min(1.0, max(0.0, (u - 36.0) / 30.0)), 2)

## Room minimums at world scale (architecture skill 5): (short, long) side.
MIN_ROOM = {
    'bed2': (3.2, 3.4),    # a double: 1.7 x 2.45 frame, 0.6 m both sides, 0.9 m at the foot
    'bed1': (3.0, 3.2),    # a single: 1.0 x 2.45 frame
    'living': (3.2, 3.6),
    'kitchen': (2.8, 3.0),
    'bath': (1.4, 1.8),    # toilet, basin, shower
    'store': (1.6, 1.6),
    'work': (3.0, 3.0),
    'hall': (1.4, 1.4),
}

## Buildings. walls = (u0, v0, u1, v1); lanai = {side: depth}, side one of
## 'u+' (toward the sea), 'u-' (upslope), 'v+', 'v-'; front = the side the
## main lānai and door face. floors = list of rows per floor: each row is
## (depth along u, [(room, kind, width along v), ...]) from the upslope side.
B = []
def b(key, name, kind, walls, front, lanai, eaves, floors, who, extra=None):
    d = dict(key=key, name=name, kind=kind, walls=walls, front=front, lanai=lanai, eaves=eaves,
             floors=floors, who=who)
    if extra: d.update(extra)
    B.append(d)

b('halau', 'Hālau', 'hale', (39.0, -8.0, 47.0, 8.0), 'u+', {}, 0.6,
  [[(8.0, [('hula floor', 'open', 16.0)])]],
  ['Puanani Akana (teaches)', 'the kūpuna (meet)'], {'paepae': 0.8, 'open_side': 'u+'})
b('kahananui', 'Kahananui home', 'home', (41.6, -25.6, 49.6, -16.0), 'v+', {'v+': 2.4, 'u-': 2.4}, 1.2,
  [[(4.0, [('kitchen', 'kitchen', 3.2), ('bath', 'bath', 2.0), ('Kawika and Malia', 'bed2', 4.4)]),
    (4.0, [('Keoni', 'bed1', 3.2), ('living room', 'living', 6.4)])]],
  ['Kawika Kahananui', 'Malia Kahananui', 'Keoni Kahananui'], {'work_lanai': 'u-'})
b('kealoha', 'Kealoha home', 'home', (40.0, -44.8, 48.0, -35.2), 'u+', {'u+': 2.4}, 1.2,
  [[(4.0, [('bath', 'bath', 2.4), ('Noelani', 'bed1', 3.2), ('Leilani and Makoa', 'bed2', 4.0)]),
    (4.0, [('kitchen', 'kitchen', 4.8), ('living room', 'living', 4.8)])]],
  ['Leilani Kealoha', 'Makoa Kealoha', 'Noelani Kealoha'], {'back_door': 'u-', 'net_store': 'u-'})
b('akana', 'Akana home', 'home', (55.8, -42.6, 62.2, -36.2), 'u+', {'u+': 2.4}, 1.2,
  [[(3.2, [('bedroom', 'bed2', 3.6), ('kitchen', 'kitchen', 2.8)]),
    (3.2, [('living room', 'living', 4.8), ('bath', 'bath', 1.6)])]],
  ['Puanani Akana'])
b('guest_house', 'Okafor guest house', 'rest', (55.0, -26.0, 63.0, -13.2), 'u+', {'u+': 2.4}, 1.2,
  [[(3.1, [('kitchen', 'kitchen', 5.2), ('ramp', 'ramp', 7.6)]),
    (4.9, [('Sam', 'bed1', 3.6), ('day toilet', 'bath', 1.6), ('common room', 'living', 7.6)])],
   [(1.4, [('bathroom', 'bath', 2.6), ('linen cupboard', 'cupboard', 2.6), ('ramp opening', 'ramp', 7.6)]),
    (1.7, [('landing corridor', 'hall', 12.8)]),
    (4.9, [('guest room', 'bed2', 3.6), ('guest room', 'bed2', 3.6), ('party room', 'bed2', 5.6)])]],
  ['Sam Okafor'], {'rest_point': True, 'price': 25, 'toilet': 'flush toilet and shower upstairs; toilet and basin by the common room',
                   'waste': 'septic tank behind the house, away from the stream and the reef'})
b('medeiros', 'Medeiros home and ukulele workshop', 'home', (39.2, 13.0, 45.6, 25.8), 'u+', {'u+': 2.4}, 1.2,
  [[(3.2, [('workshop', 'work', 4.8), ('bedroom', 'bed2', 4.0), ('bath', 'bath', 1.6), ('drying room', 'store', 2.4)]),
    (3.2, [('workshop', 'work', 4.8), ('living room', 'living', 4.8), ('kitchen', 'kitchen', 3.2)])]],
  ['Manny Medeiros', 'Kahala Medeiros'], {'plan': 'L: the workshop wing on the green side'})
b('kahale', 'Kahale home', 'home', (39.2, 31.4, 45.6, 39.4), 'u+', {'u+': 2.4}, 1.2,
  [[(3.2, [('Kahiau', 'bed1', 3.2), ('Iolana', 'bed1', 3.2), ('bath', 'bath', 1.6)]),
    (3.2, [('living room', 'living', 4.8), ('kitchen', 'kitchen', 3.2)])]],
  ['Kahiau Kahale', 'Iolana Kahale'])
b('nakamura', 'Nakamura store and home', 'shop', (55.4, 13.2, 63.4, 22.8), 'v-', {'v-': 2.4}, 1.2,
  [[(4.0, [('storeroom', 'store', 3.2), ('store', 'work', 6.4)]),
    (4.0, [('shave ice counter', 'work', 3.2), ('store', 'work', 6.4)])],
   [(4.0, [('bedroom', 'bed2', 4.0), ('bath', 'bath', 2.4), ('kitchen', 'kitchen', 3.2)]),
    (4.0, [('living room', 'living', 9.6)])]],
  ['Hiro Nakamura', 'Grace Nakamura'], {'shop_counter': 'v-', 'outside_ramp': 'u-'})
b('varga', 'Varga cottage', 'home', (56.0, 28.4, 60.8, 33.2), 'u+', {'u+': 2.0}, 1.2,
  [[(3.4, [('room', 'bed1', 4.8)]), (1.4, [('bath and wet bench', 'bath', 4.8)])]],
  ['Elena Varga'])
b('canoe_house', 'Canoe house', 'hale', (60.2, 38.0, 74.0, 44.4), 'u+', {}, 0.6,
  [[(13.8, [('canoes', 'open', 6.4)])]],
  ['Kahiau Kahale (keeps it)'], {'paepae': 0.3, 'open_side': 'u+'})

## Paths: (name, width, [(u, v), ...]) as centre lines (layout 7).
PATHS = [
    ('main path', 3.0, [(66.0, 0.0), (54.0, 0.0), (48.6, 0.0)]),
    ('loʻi ramp', 2.0, [(39.0, -10.5), (37.0, -10.5), (33.0, -10.5)]),
    ('green to the loʻi', 2.0, [(48.0, -10.5), (39.0, -10.5)]),
    ('beach path', 2.5, [(67.2, 36.6), (67.2, -48.0), (71.0, -54.0)]),
    ('west lane', 2.0, [(52.6, -10.5), (52.6, -44.0)]),
    ('east lane', 2.0, [(52.6, 10.5), (52.6, 40.0)]),
]
RESIDENTS = ['Kawika Kahananui', 'Malia Kahananui', 'Keoni Kahananui', 'Leilani Kealoha', 'Makoa Kealoha',
             'Noelani Kealoha', 'Kahiau Kahale', 'Iolana Kahale', 'Puanani Akana', 'Hiro Nakamura',
             'Grace Nakamura', 'Manny Medeiros', 'Kahala Medeiros', 'Sam Okafor', 'Elena Varga']

# ---- derived footprints and checks
SIDES = {'u+': (2, 1), 'u-': (0, -1), 'v+': (3, 1), 'v-': (1, -1)}
def footprint(bd):
    r = list(bd['walls'])
    for side, dep in bd['lanai'].items():
        i, s = SIDES[side]; r[i] += s * dep
    e = bd['eaves']
    return (r[0] - e, r[1] - e, r[2] + e, r[3] + e)
def ov(a, c, gap=0.0): return a[0] < c[2] + gap and c[0] < a[2] + gap and a[1] < c[3] + gap and c[1] < a[3] + gap
def gap_between(a, c):
    du = max(c[0] - a[2], a[0] - c[2], 0); dv = max(c[1] - a[3], a[1] - c[3], 0)
    return math.hypot(du, dv) if du and dv else max(du, dv)
problems = []
for bd in B:
    w = bd['walls']; W_v = w[3] - w[1]; D_u = w[2] - w[0]
    for fi, rows in enumerate(bd['floors']):
        if abs(sum(d for d, _ in rows) - D_u) > 0.05:
            problems.append((bd['key'], 'floor %d rows add to %.2f, not the depth %.2f' % (fi, sum(d for d, _ in rows), D_u)))
        for d, rooms in rows:
            if abs(sum(x[2] for x in rooms) - W_v) > 0.05:
                problems.append((bd['key'], 'floor %d row adds to %.2f, not the width %.2f' % (fi, sum(x[2] for x in rooms), W_v)))
            for name, kind, wd in rooms:
                if kind in MIN_ROOM:
                    lo, hi = MIN_ROOM[kind]
                    if min(wd, d) < lo - 0.01 or max(wd, d) < hi - 0.01:
                        problems.append((bd['key'], '%s is %.1f x %.1f, under %.1f x %.1f' % (name, wd, d, lo, hi)))
    fp = footprint(bd)
    zone = PLAIN if bd['key'] != 'canoe_house' else (PLAIN[0], PLAIN[1], BEACH[2], PLAIN[3])
    if not (fp[0] >= zone[0] - 1.4 and fp[2] <= zone[2] + 0.8 and fp[1] >= zone[1] and fp[3] <= zone[3]):
        problems.append((bd['key'], 'stands outside the coastal plain', fp))
    if ov(fp, TERRACES): problems.append((bd['key'], 'stands on the taro terraces'))
    if fp[1] < STREAM_V + 3.0 and fp[3] > STREAM_V - 3.0: problems.append((bd['key'], 'stands in the stream'))
    if ov(fp, GREEN): problems.append((bd['key'], 'stands on the green'))
    if ov(fp, PIER_HEAD): problems.append((bd['key'], 'stands on the pier head'))
for i in range(len(B)):
    for j in range(i + 1, len(B)):
        g = gap_between(footprint(B[i]), footprint(B[j]))
        if g < 2.99: problems.append((B[i]['key'], B[j]['key'], 'only %.1f m apart at the eaves' % g))
homes = {}
for bd in B:
    for who in bd['who']:
        homes.setdefault(who, bd['key'])
for r in RESIDENTS:
    if r not in homes and not any(r in w for bd in B for w in bd['who']): problems.append(('resident without a building', r))
for bd in B:
    if bd.get('rest_point') and not bd.get('toilet'): problems.append((bd['key'], 'rest point without a toilet'))
# no path runs through walls or a lānai (eaves may overhang)
def body(bd):
    r = list(bd['walls'])
    for side, dep in bd['lanai'].items():
        i, s_ = SIDES[side]; r[i] += s_ * dep
    return r
for nm, wd, pts in PATHS:
    for (a, c) in zip(pts, pts[1:]):
        seg = (min(a[0], c[0]) - wd / 2, min(a[1], c[1]) - wd / 2, max(a[0], c[0]) + wd / 2, max(a[1], c[1]) + wd / 2)
        for bd in B:
            if ov(seg, body(bd)): problems.append((nm, 'runs through', bd['key']))
# every front faces a path within 8 m
def near_path(pt, reach):
    for _, wd, pts in PATHS:
        for (a, c) in zip(pts, pts[1:]):
            du, dv = c[0] - a[0], c[1] - a[1]; L = du * du + dv * dv
            t = max(0, min(1, ((pt[0] - a[0]) * du + (pt[1] - a[1]) * dv) / L)) if L else 0
            if math.hypot(pt[0] - a[0] - t * du, pt[1] - a[1] - t * dv) <= reach + wd / 2: return True
    return False
for bd in B:
    w = bd['walls']; side = bd['front']; i, s = SIDES[side]
    mid = [(w[0] + w[2]) / 2, (w[1] + w[3]) / 2]
    edge = w[i] + s * bd['lanai'].get(side, 0)
    if i in (0, 2): mid[0] = edge
    else: mid[1] = edge
    if not near_path(mid, 8.0) and not (ov((mid[0] - 3, mid[1] - 3, mid[0] + 3, mid[1] + 3), GREEN)):
        problems.append((bd['key'], 'its front faces no path or the green'))
if problems:
    for p in problems: print('PROBLEM', p)
    sys.exit(1)

# ---- write the plan
def q(t): return json.dumps(t, ensure_ascii=False)
def v2(p): return 'Vector2(%g, %g)' % p
def rect(r): return 'Rect2(%g, %g, %g, %g)' % (r[0], r[1], r[2] - r[0], r[3] - r[1])
out = []; w_ = out.append
w_('class_name KaiMaliePlan')
w_('extends RefCounted')
w_('')
w_('## Kai Mālie\'s single plan (docs/architecture/ocean_island_village_layout.md and')
w_('## ocean_island_village_buildings.md). GENERATED by tools/kai_malie_layout.py:')
w_('## edit there and rerun, never here. The village builder and')
w_('## tools/validate_kai_malie_plan.tscn read only this.')
w_('##')
w_('## Local metres on the main island: u (Rect2 x) points from the island centre')
w_('## toward the arrival dock, v (Rect2 y) to its right. to_world() converts.')
w_('')
w_('const CENTER := %s' % v2(CENTER))
w_('const U_AXIS := %s' % v2(U))
w_('const V_AXIS := %s' % v2(V))
for nm, r in [('PLAIN', PLAIN), ('BEACH', BEACH), ('TERRACES', TERRACES), ('REEF_FLAT', REEF_FLAT), ('GREEN', GREEN),
              ('PIER', PIER), ('PIER_HEAD', PIER_HEAD), ('FISHPOND', FISHPOND), ('KAHALA_GARDEN', KAHALA_GARDEN),
              ('PIRATES_BEACH', PIRATES_BEACH)]:
    w_('const %s := %s' % (nm, rect(r)))
w_('const STREAM_V := %g' % STREAM_V)
w_('const MEETING_ROCKS := %s' % v2(MEETING_ROCKS))
w_('const WATERFALL := %s' % v2(WATERFALL))
w_('const DOCK_U := %g' % DOCK_U)
w_('## The coastal plain falls from +3.0 m at u 36 to +1.2 m at u 66.')
w_('const PLAIN_HIGH := 3.0')
w_('const PLAIN_LOW := 1.2')
w_('')
w_('## Every building: walls and footprint (with lānai and eaves) as local Rect2s,')
w_('## the side its front faces (u+ seaward, u- upslope, v+, v-), and its floors as')
w_('## rows of rooms (depth along u, then rooms with their width along v).')
w_('const BUILDINGS := [')
for bd in B:
    floors = '[' + ', '.join('[' + ', '.join('[%g, [%s]]' % (d, ', '.join('[%s, %s, %g]' % (q(n), q(k), wd) for n, k, wd in rooms)) for d, rooms in rows) + ']' for rows in bd['floors']) + ']'
    extra = {k: v for k, v in bd.items() if k not in ('key', 'name', 'kind', 'walls', 'front', 'lanai', 'eaves', 'floors', 'who')}
    w_('\t{"key": %s, "name": %s, "kind": %s, "walls": %s, "footprint": %s, "front": %s, "lanai": %s, "eaves": %g, "floor_height": %g, "floors": %s, "who": %s, "extra": %s},' % (
        q(bd['key']), q(bd['name']), q(bd['kind']), rect(bd['walls']), rect(footprint(bd)), q(bd['front']),
        q(bd['lanai']), bd['eaves'], plain_height((bd['walls'][0] + bd['walls'][2]) / 2) + (bd.get('paepae', 0.8)),
        floors, q(bd['who']), q(extra)))
w_(']')
w_('')
w_('## Paths: name, width, centre-line points.')
w_('const PATHS := [')
for nm, wd, pts in PATHS: w_('\t[%s, %g, [%s]],' % (q(nm), wd, ', '.join(v2(p) for p in pts)))
w_(']')
w_('')
w_('const RESIDENTS: Array[String] = [%s]' % ', '.join(q(r) for r in RESIDENTS))
w_('')
w_('')
w_('static func to_world(local: Vector2) -> Vector2:')
w_('\treturn CENTER + U_AXIS * local.x + V_AXIS * local.y')
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
open(os.path.join(root, 'scripts', 'kai_malie_plan.gd'), 'w').write('\n'.join(out) + '\n')
if '--json' in sys.argv:
    path = sys.argv[sys.argv.index('--json') + 1]
    json.dump(dict(buildings=[dict(bd, footprint=footprint(bd)) for bd in B], paths=PATHS, plain=PLAIN, beach=BEACH,
                   terraces=TERRACES, reef=REEF_FLAT, green=GREEN, pier=PIER, pier_head=PIER_HEAD, fishpond=FISHPOND,
                   rocks=MEETING_ROCKS, waterfall=WATERFALL, garden=KAHALA_GARDEN, pirates=PIRATES_BEACH,
                   stream_v=STREAM_V, center=CENTER, u=U, v=V), open(path, 'w'), ensure_ascii=False)
print('wrote scripts/kai_malie_plan.gd: %d buildings, %d paths, %d residents' % (len(B), len(PATHS), len(RESIDENTS)))
